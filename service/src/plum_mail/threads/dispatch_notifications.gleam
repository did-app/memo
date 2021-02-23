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
import gleam_uuid
import postmark/client as postmark
import plum_mail/config.{Config}
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Identifier}

pub fn load() {
  let sql =
    // Bit weird to call an email address a topic but it is the analogue for a thread
    "
  WITH participants AS (
    SELECT lower_identifier_id AS identifier_id, recipient.email_address, thread_id, contact.email_address AS contact, NULL as group_name, CAST(NULL AS uuid) AS group_id
    FROM pairs
    JOIN identifiers AS recipient ON lower_identifier_id = recipient.id
    JOIN identifiers AS contact ON upper_identifier_id = contact.id
    WHERE recipient.group_id IS NULL
    
    UNION ALL
    
    SELECT upper_identifier_id AS identifier_id, recipient.email_address, thread_id, contact.email_address AS contact, NULL as group_name, CAST(NULL AS uuid) AS group_id
    FROM pairs
    JOIN identifiers AS recipient ON upper_identifier_id = recipient.id
    JOIN identifiers AS contact ON lower_identifier_id = contact.id
    WHERE recipient.group_id IS NULL
    
    UNION ALL

    SELECT invitations.identifier_id, recipient.email_address, groups.thread_id, NULL, groups.name AS group_name, groups.id AS group_id
    FROM invitations
    JOIN identifiers AS recipient ON recipient.id = invitations.identifier_id
    JOIN groups ON groups.id = invitations.group_id 
  )
  SELECT 
    participants.identifier_id, 
    participants.email_address,
    participants.thread_id,
    memos.content,
    memos.position,
    participants.contact,
    participants.group_name,
    participants.group_id,
    authors.email_address
  FROM memos
  JOIN participants ON participants.thread_id = memos.thread_id
  LEFT JOIN memo_notifications AS notifications
    ON notifications.thread_id = memos.thread_id
    AND notifications.position = memos.position
    AND notifications.recipient_id = participants.identifier_id
  LEFT JOIN identifiers AS authors ON authors.id = memos.authored_by
  WHERE notifications IS NULL
  AND participants.email_address <> 'peter@sendmemo.app'
  AND participants.email_address <> 'richard@sendmemo.app'
  AND participants.identifier_id <> memos.authored_by
  ORDER BY memos.inserted_at ASC
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
        assert Ok(thread_id) = dynamic.element(row, 2)
        assert Ok(thread_id) = dynamic.bit_string(thread_id)
        assert thread_id = run_sql.binary_to_uuid4(thread_id)

        assert Ok(content) = dynamic.element(row, 3)
        assert content = dynamic.typed_list(content, block_from_dynamic)
        assert Ok(position) = dynamic.element(row, 4)
        assert Ok(position) = dynamic.int(position)

        assert Ok(contact) = dynamic.element(row, 5)
        assert Ok(contact) = run_sql.dynamic_option(contact, dynamic.string)
        let contact =
          option.map(
            contact,
            fn(contact) {
              assert Ok(contact) = email_address.validate(contact)
              contact
            },
          )

        assert Ok(group_name) = dynamic.element(row, 6)
        assert Ok(group_name) =
          run_sql.dynamic_option(group_name, dynamic.string)
        assert Ok(group_id) = dynamic.element(row, 7)
        assert Ok(group_id) =
          run_sql.dynamic_option(group_id, dynamic.bit_string)
        let group_id =
          option.map(group_id, fn(id) { run_sql.binary_to_uuid4(id) })

        assert Ok(author) = dynamic.element(row, 8)
        assert Ok(author) = dynamic.string(author)

        // io.debug(group_name)
        tuple(
          recipient_id,
          recipient_email_address,
          contact,
          thread_id,
          content,
          position,
          group_name,
          group_id,
          author,
        )
      },
    )
  deliveries
}

pub fn run() {
  let config = config.from_env()

  load()
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

fn block_to_text(block) {
  case block {
    Paragraph(spans) ->
      string.join(
        list.map(
          spans,
          fn(span) {
            case span {
              Text(text) -> text
              Link(title, url) -> option.unwrap(title, url)
              Softbreak -> "\r\n"
            }
          },
        ),
        "",
      )
    Annotation(blocks: [first, ..], ..) -> block_to_text(first)
    Annotation(..) -> ""
    Prompt(..) -> ""
  }
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
    contact,
    thread_id,
    content,
    position,
    group_name,
    group_id,
    author,
  ) = record

  let preview = case content {
    Ok([first, ..]) -> Some(block_to_text(first))
    _ -> None
  }

  let tuple(topic, path) = case contact, group_name, group_id {
    Some(email_address), None, None -> tuple(
      string.concat([email_address.value, " sent you a memo"]),
      email_address.to_path(email_address),
    )
    None, Some(name), Some(group_id) -> tuple(
      string.concat(["New memo in ", name]),
      string.concat(["/groups/", gleam_uuid.to_string(group_id)]),
    )
  }
  // contact link needs to handle adding position because it will be in a hash fragment.
  let authentication_url = contact_link(client_origin, path, recipient_id)

  let to = recipient_email_address.value
  // contact might be nill, we need to change this up to author
  // let from = case topic.value {
  //   "richard@sendmemo.app" -> "Richard Shepherd <richard@sendmemo.app>"
  //   "peter@sendmemo.app" -> "Peter Saxton <peter@sendmemo.app>"
  //   _ -> "memo <memo@sendmemo.app>"
  // }
  let from = "memo <memo@sendmemo.app>"

  io.debug(preview)
  let template_alias = "memo-notification"
  let template_model =
    json.object([
      tuple("authentication_url", json.string(authentication_url)),
      tuple("email_address", json.string(author)),
      tuple("content_preview", json.nullable(preview, json.string)),
    ])
  let response =
    postmark.send_email_with_template(
      from,
      to,
      template_alias,
      template_model,
      postmark_api_token,
    )
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

fn contact_link(origin, path, recipient_id) {
  assert Ok(code) = authentication.generate_link_token(recipient_id)
  [origin, path, "#code=", code]
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
