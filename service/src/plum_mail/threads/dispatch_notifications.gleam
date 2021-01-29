import gleam/atom
import gleam/dynamic.{Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string
import gleam/http
import gleam/httpc
import gleam/json
import gleam/pgo
import postmark/client as postmark
import plum_mail/config.{Config}
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Identifier}

pub fn run() {
  let config = config.from_env()

  let sql =
    // Bit weird to call an email address a topic but it is the analogue for a thread
    "
  WITH participants AS (
    SELECT lower_identifier_id AS identifier_id, recipient.email_address, thread_id, contact.email_address AS topic
    FROM pairs
    JOIN identifiers AS recipient ON lower_identifier_id = recipient.id
    JOIN identifiers AS contact ON upper_identifier_id = contact.id
    
    UNION ALL
    
    SELECT upper_identifier_id AS identifier_id, recipient.email_address, thread_id, contact.email_address AS topic
    FROM pairs
        JOIN identifiers AS recipient ON upper_identifier_id = recipient.id
    JOIN identifiers AS contact ON lower_identifier_id = contact.id
    
    -- UNION ALL

    -- SELECT invitations.identifier_id, recipient.email_address, groups.thread_id, groups.name AS topic
    -- FROM invitations
    -- JOIN identifiers AS recipient ON recipient.id = invitations.identifier_id
    -- JOIN groups ON groups.id = invitations.group_id 
  )
  SELECT 
    participants.identifier_id, 
    participants.email_address,
    participants.topic,
    participants.thread_id,
    memos.content,
    memos.position
  FROM memos
  JOIN participants ON participants.thread_id = memos.thread_id
  LEFT JOIN memo_notifications AS notifications
    ON notifications.thread_id = memos.thread_id
    AND notifications.position = memos.position
    AND notifications.recipient_id = participants.identifier_id
  WHERE notifications IS NULL
  AND participants.email_address <> 'peter@sendmemo.app'
  AND participants.email_address <> 'richard@sendmemo.app'
  AND participants.identifier_id <> memos.authored_by
  "
  assert Ok(deliveries) =
    run_sql.execute(
      sql,
      [],
      fn(row) {
        assert Ok(recipient_id) = dynamic.element(row, 0)
        assert Ok(recipient_id) = dynamic.bit_string(recipient_id)
        let recipient_id = run_sql.binary_to_uuid4(recipient_id)
        assert Ok(recipient_email_address) = dynamic.element(row, 1)
        assert Ok(recipient_email_address) =
          dynamic.string(recipient_email_address)
        assert Ok(recipient_email_address) =
          email_address.validate(recipient_email_address)

        assert Ok(topic) = dynamic.element(row, 2)
        assert Ok(topic) = dynamic.string(topic)
        assert Ok(thread_id) = dynamic.element(row, 3)
        assert Ok(thread_id) = dynamic.bit_string(thread_id)
        assert thread_id = run_sql.binary_to_uuid4(thread_id)

        assert Ok(topic) = email_address.validate(topic)
        assert Ok(content) = dynamic.element(row, 4)
        assert Ok(content) = dynamic.typed_list(content, block_from_dynamic)
        assert Ok(position) = dynamic.element(row, 5)
        assert Ok(position) = dynamic.int(position)

        tuple(
          recipient_id,
          recipient_email_address,
          topic,
          thread_id,
          content,
          position,
        )
      },
    )
  deliveries
  |> list.each(dispatch_to_identifier(_, config))
}

fn block_from_dynamic(raw) {
  assert Ok(block_type) = dynamic.field(raw, "type")
  assert Ok(block_type) = dynamic.string(block_type)
  case block_type {
    "paragraph" -> {
      assert Ok(spans) = dynamic.field(raw, "spans")
      assert Ok(spans) = dynamic.typed_list(spans, span_from_dynamic)
      Ok(Paragraph(spans))
    }
    "annotation" -> {
      assert Ok(blocks) = dynamic.field(raw, "blocks")
      assert Ok(blocks) = dynamic.typed_list(blocks, block_from_dynamic)
      let reference = RangeReference
      Ok(Annotation(reference, blocks))
    }
    "prompt" -> {
      let reference = RangeReference
      Ok(Prompt(reference))
    }
  }
}

fn span_from_dynamic(raw) {
  assert Ok(span_type) = dynamic.field(raw, "type")
  assert Ok(span_type) = dynamic.string(span_type)
  case span_type {
    "text" -> {
      assert Ok(text) = dynamic.field(raw, "text")
      assert Ok(text) = dynamic.string(text)
      Ok(Text(text))
    }
    "link" -> {
      assert Ok(url) = dynamic.field(raw, "url")
      assert Ok(url) = dynamic.string(url)
      let title =
        dynamic.field(raw, "title")
        |> result.then(dynamic.string)
        |> option.from_result()
      Ok(Link(title, url))
    }
    "softbreak" -> Ok(Softbreak)
  }
}

pub type Reference {
  SectionReference(note_index: Int, block_index: Int)
  RangeReference
}

pub type Span {
  Text(text: String)
  Link(title: Option(String), url: String)
  Softbreak
}

pub type Block {
  Paragraph(spans: List(Span))
  Annotation(reference: Reference, blocks: List(Block))
  Prompt(reference: Reference)
}

fn dispatch_to_identifier(record, config) {
  let Config(
    postmark_api_token: postmark_api_token,
    client_origin: client_origin,
    ..,
  ) = config
  let tuple(
    recipient_id,
    recipient_email_address,
    topic,
    thread_id,
    _content,
    position,
  ) = record
  let link = contact_link(client_origin, topic, recipient_id)

  let body =
    string.concat([
      topic.value,
      " sent you a memo.\r\n\r\n",
      "Use this link ",
      link,
      " to read more\r\n\r\n",
      "Regards, the memo team",
    ])

  let subject = string.concat([topic.value, " sent you a memo"])
  let to = recipient_email_address.value
  let from = case topic.value {
    "richard@sendmemo.app" -> "Richard Shepherd <richard@sendmemo.app>"
    "peter@sendmemo.app" -> "Peter Saxton <peter@sendmemo.app>"
    _ -> "memo <memo@sendmemo.app>"
  }
  let response =
    postmark.send_email(from, to, subject, body, postmark_api_token)
  case response {
    Ok(Nil) -> {
      assert Ok(_) = record_sent(thread_id, position, recipient_id)
      Ok(Nil)
    }
    // why was that, handle case of bad email addresses
    Error(postmark.Failure(retry: True)) -> Ok(Nil)
    Error(postmark.Failure(retry: False)) -> {
      record_failed(thread_id, position, recipient_id)
      Ok(Nil)
    }
  }
}

fn contact_link(origin, contact, recipient_id) {
  assert Ok(code) = authentication.generate_link_token(recipient_id)
  [origin, email_address.to_path(contact), "#code=", code]
  |> string.join("")
}

pub fn record_result(thread_id, position, recipient_id, success) {
  let sql =
    "
    INSERT INTO memo_notifications (thread_id, position, recipient_id, success)
    VALUES ($1, $2, $3, $4)
    RETURNING *
    "
  let args = [
    run_sql.uuid(thread_id),
    pgo.int(position),
    run_sql.uuid(recipient_id),
    pgo.bool(success),
  ]
  let mapper = fn(x) { x }
  run_sql.execute(sql, args, mapper)
}

pub fn record_sent(thread_id, position, recipient_id) {
  record_result(thread_id, position, recipient_id, True)
}

pub fn record_failed(thread_id, position, recipient_id) {
  record_result(thread_id, position, recipient_id, False)
}
