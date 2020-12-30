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
import plum_mail/config.{Config}
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Identifier}
import plum_mail/discuss/discuss.{Topic}

pub fn run() {
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
    notes.content
  FROM notes
  JOIN participants ON participants.thread_id = notes.thread_id
  LEFT JOIN note_notifications AS notifications
    ON notifications.thread_id = notes.thread_id
    AND notifications.counter = notes.counter
    AND notifications.identifier_id = participants.thread_id
  WHERE notifications IS NULL
  AND notes.counter > participants.ack
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
        assert Ok(topic) = dynamic.element(row, 2)
        assert Ok(topic) = dynamic.string(topic)
        assert Ok(content) = dynamic.element(row, 3)
        assert Ok(content) = dynamic.typed_list(content, block_from_dynamic)

        tuple(recipient_id, recipient_email_address, topic, content)
      },
    )
  deliveries
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
      let title = dynamic.field(raw, "title")
      |> result.then(dynamic.string)
      |> option.from_result()
      Ok(Link(title, url))
    }
    "softbreak" -> {
      Ok(Softbreak)
    }
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
// pub fn load() {
//   // TODO this is the same as whats needed for the detail of the notifications tab
//   // https://postmarkapp.com/developer/user-guide/send-email-with-api/batch-emails
//   // TODO Add to recipient a field that says don't email me because I check plummail
//   let sql =
//     "
//     SELECT m.counter, m.content, m.inserted_at, author.id, c.id, c.topic, m.conclusion, recipient.id, recipient.email_address, author.email_address
//     FROM messages AS m
//     JOIN conversations AS c ON c.id = m.conversation_id
//     JOIN participants AS p ON p.conversation_id = c.id
//     LEFT JOIN message_notifications AS n
//         ON n.conversation_id = m.conversation_id
//         AND n.counter = m.counter
//         AND n.identifier_id = p.identifier_id
//     JOIN identifiers AS recipient ON recipient.id = p.identifier_id
//     JOIN identifiers AS author ON author.id = m.authored_by
//     WHERE p.identifier_id <> m.authored_by
//     AND recipient.email_address <> 'peter@plummail.co'
//     AND recipient.email_address <> 'richard@plummail.co'
//     AND p.cursor < m.counter
//     AND n.id IS NULL
//     AND (p.notify = 'all' OR (p.notify = 'concluded' AND m.conclusion))
//     -- AND m.inserted_at < (now() at time zone 'utc') - '1 minute'::interval
//     ORDER BY m.inserted_at ASC
//     "
//   let args = []
//   let mapper = fn(row) {
//     assert Ok(counter) = dynamic.element(row, 0)
//     assert Ok(counter) = dynamic.int(counter)
//     assert Ok(content) = dynamic.element(row, 1)
//     assert Ok(content) = dynamic.string(content)
//     // assert Ok(inserted_at) = dynamic.element(row, 2)
//     // assert Ok(inserted_at) = dynamic.string(inserted_at)
//     assert Ok(authored_by) = dynamic.element(row, 3)
//     assert Ok(authored_by) = dynamic.int(authored_by)
//     assert Ok(conversation_id) = dynamic.element(row, 4)
//     assert Ok(conversation_id) = dynamic.int(conversation_id)
//     assert Ok(topic) = dynamic.element(row, 5)
//     assert Ok(topic) = dynamic.string(topic)
//     // TODO remove
//     assert Ok(fallback_topic) = discuss.validate_topic("A fallback topic")
//     let topic = result.unwrap(discuss.validate_topic(topic), fallback_topic)
//     // assert Ok(closed) = dynamic.element(row, 6)
//     // assert Ok(closed) = dynamic.bool(closed)
//     assert Ok(recipient_id) = dynamic.element(row, 7)
//     assert Ok(recipient_id) = dynamic.int(recipient_id)
//     assert Ok(recipient_email_address) = dynamic.element(row, 8)
//     assert Ok(recipient_email_address) = dynamic.string(recipient_email_address)
//     assert Ok(recipient_email_address) =
//       email_address.validate(recipient_email_address)
//     assert Ok(author_email_address) = dynamic.element(row, 9)
//     assert Ok(author_email_address) = dynamic.string(author_email_address)
//     assert Ok(author_email_address) =
//       email_address.validate(author_email_address)
//     Message(
//       id: tuple(conversation_id, counter),
//       conversation: tuple(conversation_id, topic),
//       author: Identifier(
//         id: authored_by,
//         email_address: author_email_address,
//         greeting: todo("greting"),
//       ),
//       to: Identifier(
//         id: recipient_id,
//         email_address: recipient_email_address,
//         greeting: todo("greting"),
//       ),
//       content: content,
//     )
//   }
//   run_sql.execute(sql, args, mapper)
//   // Test last 1 should be
// }
// pub fn record_result(message: Message, success: Bool) {
//   // TODO rename to recipient id
//   let sql =
//     "
//     INSERT INTO message_notifications (conversation_id, counter, identifier_id, success)
//     VALUES ($1, $2, $3, $4)
//     "
//   let args = [
//     pgo.int(message.id.0),
//     pgo.int(message.id.1),
//     pgo.int(message.to.id),
//     pgo.bool(success),
//   ]
//   let mapper = fn(x) { x }
//   run_sql.execute(sql, args, mapper)
// }
// pub fn record_sent(message) {
//   record_result(message, True)
// }
// pub fn record_failed(message) {
//   record_result(message, False)
// }
// fn authenticated_link(origin, conversation_id, identifier_id) {
//   assert Ok(token) = authentication.generate_link_token(identifier_id)
//   [origin, "/c/", int.to_string(conversation_id), "#code", "=", token]
//   |> string.join("")
// }
// fn send(config, message: Message) {
//   let Config(
//     postmark_api_token: postmark_api_token,
//     client_origin: client_origin,
//     ..,
//   ) = config
//   let conversation_link =
//     authenticated_link(client_origin, message.id.0, message.to.id)
//   let prefix =
//     [
//       "<div style=\"padding:0.5em;border:2px solid rgb(60, 54, 107);border-radius:0.5em;max-width:640px\"><a href=\"",
//       conversation_link,
//       "\">",
//       message.author.email_address.value,
//       "</a> sent you this message using Plum Mail. <a href=\"",
//       conversation_link,
//       "\">Click here to reply</a></div>",
//     ]
//     |> string.join("")
//   let body =
//     [
//       "
//     <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
//     <html xmlns=\"http://www.w3.org/1999/xhtml\">
//       <head>
//         <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
//         <meta name=\"x-apple-disable-message-reformatting\" />
//         <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
//         <title></title>
//       </head>
//       <body>
//         <main style=\"max-width:640px;\">
//         <div style=\"max-width:640px;\">
//     ",
//       prefix,
//       to_email_html(message.content, conversation_link),
//       "
//     </div>
//     </main>
//     ",
//     ]
//     |> string.join("")
//   // TODO check valid domain and then addresses
//   let from_string = case message.author.email_address.value {
//     "richard@plummail.co" -> "Richard Shepherd <richard@plummail.co>"
//     "peter@plummail.co" -> "Peter Saxton <peter@plummail.co>"
//     string_email -> string.concat([string_email, " <notify@plummail.co>"])
//   }
//   let data =
//     json.object([
//       tuple("From", json.string(from_string)),
//       tuple(
//         "ReplyTo",
//         json.string(string.join(
//           ["c+", int.to_string(message.id.0), "@reply.plummail.co"],
//           "",
//         )),
//       ),
//       tuple("To", json.string(message.to.email_address.value)),
//       tuple(
//         "Subject",
//         json.string(discuss.topic_to_string(message.conversation.1)),
//       ),
//       // tuple("TextBody", json.string(message.content)),
//       tuple("HtmlBody", json.string(body)),
//     ])
//   let request =
//     http.default_req()
//     |> http.set_method(http.Post)
//     |> http.set_host("api.postmarkapp.com")
//     |> http.set_path("/email")
//     |> http.prepend_req_header("content-type", "application/json")
//     |> http.prepend_req_header("accept", "application/json")
//     |> http.prepend_req_header("x-postmark-server-token", postmark_api_token)
//     |> http.set_req_body(json.encode(data))
//   io.debug(request)
//   httpc.send(request)
//   |> io.debug()
// }
// pub fn execute() {
//   assert Ok(messages) = load()
//   list.map(
//     messages,
//     fn(message) {
//       case send(config.from_env(), message) {
//         Ok(http.Response(status: 200, ..)) -> record_sent(message)
//         // TODO why was that, handle case of bad email addresses
//         Ok(http.Response(status: 422, body: body, ..)) -> {
//           assert Ok(data) = json.decode(body)
//           let data = dynamic.from(data)
//           assert Ok(error_code) = dynamic.field(data, "ErrorCode")
//           assert Ok(error_code) = dynamic.int(error_code)
//           case error_code {
//             406 -> record_failed(message)
//             // Other error code retry
//             _ -> Ok([])
//           }
//         }
//       }
//     },
//   )
// }
