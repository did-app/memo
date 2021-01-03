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
import plum_mail/discuss/discuss.{Topic}

pub fn run() {
  let config = config.from_env()

  let sql =
    // Bit weird to call an email address a topic but it is the analogue for a thread
    "
  WITH participants AS (
    SELECT lower_identifier_id AS identifier_id, recipient.email_address, lower_identifier_ack AS ack, thread_id, contact.email_address AS topic
    FROM pairs
    JOIN identifiers AS recipient ON lower_identifier_id = recipient.id
    JOIN identifiers AS contact ON upper_identifier_id = contact.id
    UNION ALL
    SELECT upper_identifier_id AS identifier_id, recipient.email_address, upper_identifier_ack AS ack, thread_id, contact.email_address AS topic
    FROM pairs
        JOIN identifiers AS recipient ON upper_identifier_id = recipient.id
    JOIN identifiers AS contact ON lower_identifier_id = contact.id

  )
  SELECT 
    participants.identifier_id, 
    participants.email_address,
    participants.topic,
    participants.thread_id,
    notes.content,
    notes.counter
  FROM notes
  JOIN participants ON participants.thread_id = notes.thread_id
  LEFT JOIN note_notifications AS notifications
    ON notifications.thread_id = notes.thread_id
    AND notifications.counter = notes.counter
    AND notifications.identifier_id = participants.thread_id
  WHERE notifications IS NULL
  AND notes.counter > participants.ack
  AND participants.email_address <> 'peter@plummail.co'
  AND participants.email_address <> 'richard@plummail.co'
  "
  assert Ok(deliveries) =
    run_sql.execute(
      sql,
      [],
      fn(row) {
        assert Ok(recipient_id) = dynamic.element(row, 0)
        assert Ok(recipient_id) = dynamic.int(recipient_id)
        assert Ok(recipient_email_address) = dynamic.element(row, 1)
        assert Ok(recipient_email_address) =
          dynamic.string(recipient_email_address)
        assert Ok(recipient_email_address) =
          email_address.validate(recipient_email_address)

        assert Ok(topic) = dynamic.element(row, 2)
        assert Ok(topic) = dynamic.string(topic)
        assert Ok(thread_id) = dynamic.element(row, 3)
        assert Ok(thread_id) = dynamic.int(thread_id)

        assert Ok(topic) = email_address.validate(topic)
        assert Ok(content) = dynamic.element(row, 4)
        assert Ok(content) = dynamic.typed_list(content, block_from_dynamic)
        assert Ok(counter) = dynamic.element(row, 5)
        assert Ok(counter) = dynamic.int(counter)

        tuple(
          recipient_id,
          recipient_email_address,
          topic,
          thread_id,
          content,
          counter,
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
}

// pub fn to_email_html(content, link) {
// markdown
// |> as_html()
// |> string.replace(
//   "href=\"#?\"",
//   string.join(["href=\"", conversation_link, "\""], ""),
// )
// list.map(content, fn(block){
//   case block {
//     Paragraph(spans) ->
//     Annotation() -> 
//   }
// })
// }
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
    content,
    counter,
  ) = record
  let link = contact_link(client_origin, topic, recipient_id)

  // let prefix =
  //   [
  //     // "<div style=\"padding:0.5em;border:2px solid rgb(60, 54, 107);border-radius:0.5em;max-width:640px\"><a href=\"",
  //     "<a href=\"",
  //     link,
  //     "\">",
  //     topic.value,
  //     "</a> sent you a memo using Plum Mail. <a href=\"",
  //     link,
  //     "\">Click here to read more ...</a></div>",
  //   ]
  //   |> string.join("")
  // let body =
  //   [
  //     "
  //   <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
  //   <html xmlns=\"http://www.w3.org/1999/xhtml\">
  //     <head>
  //       <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
  //       <meta name=\"x-apple-disable-message-reformatting\" />
  //       <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
  //       <title></title>
  //     </head>
  //     <body>
  //       <main style=\"max-width:640px;\">
  //       <div style=\"max-width:640px;\">
  //   ",
  //     prefix,
  //     "
  //   </div>
  //   </main>
  //   ",
  //   ]
  //   |> string.join("")
  let body =
    string.concat([
      topic.value,
      " sent you a memo using Plum Mail.\r\n\r\n",
      "Use this link ",
      link,
      " to read more\r\n\r\n",
      "Regards, the Plum Mail team",
    ])

  let subject = string.concat([topic.value, " sent you a memo"])
  let to = recipient_email_address.value
  let from = case topic.value {
    "richard@plummail.co" -> "Richard Shepherd <richard@plummail.co>"
    "peter@plummail.co" -> "Peter Saxton <peter@plummail.co>"
    // string_email -> string.concat([string_email, " <notify@plummail.co>"])
    _ -> "Memo (DID) <notify@plummail.co>"
  }
  let reply_to = "noreply@plummail.co"
  let response =
    postmark.send_email(from, to, subject, body, postmark_api_token)
  case response {
    Ok(_) -> {
      assert Ok(_) = record_sent(thread_id, counter, recipient_id)
      Ok(Nil)
    }
    // TODO why was that, handle case of bad email addresses
    Error(postmark.Failure(retry: True)) -> Ok(Nil)
    Error(postmark.Failure(retry: False)) -> {
      record_failed(thread_id, counter, recipient_id)
      Ok(Nil)
    }
  }

  todo("discuss")
}

fn send(request, postmark_api_token) {
  case postmark_api_token {
    _ ->
      httpc.send(request)
      |> io.debug()
  }
}

fn contact_link(origin, contact, identifier_id) {
  assert Ok(code) = authentication.generate_link_token(identifier_id)
  [origin, email_address.to_path(contact), "#code=", code]
  |> string.join("")
}

pub fn record_result(thread_id, counter, identifier_id, success) {
  // TODO rename to recipient id
  // TODO rename memo
  // TODO think about renaming counter
  let sql =
    "
    INSERT INTO note_notifications (conversation_id, counter, identifier_id, success)
    VALUES ($1, $2, $3, $4)
    "
  let args = [
    pgo.int(thread_id),
    pgo.int(counter),
    pgo.int(identifier_id),
    pgo.bool(success),
  ]
  let mapper = fn(x) { x }
  run_sql.execute(sql, args, mapper)
}

pub fn record_sent(thread_id, counter, identifier_id) {
  record_result(thread_id, counter, identifier_id, True)
}

pub fn record_failed(thread_id, counter, identifier_id) {
  record_result(thread_id, counter, identifier_id, False)
}
