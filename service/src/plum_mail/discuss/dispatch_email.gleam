import gleam/dynamic
import gleam/int
import gleam/string
import gleam/http
import gleam/json
import gleam/pgo
import plum_mail/run_sql

pub type Message {
  Message(id: Int, conversation: tuple(Int, String), // to can be participant
    // from can be author
    from: String, to: tuple(Int, String), content: String)
}

pub fn load() {
  // TODO this is the same as whats needed for the detail of the notifications tab
  // https://postmarkapp.com/developer/user-guide/send-email-with-api/batch-emails
  let sql =
    "
    SELECT m.id, m.content, m.inserted_at, author.id, c.id, c.topic, c.resolved, recipient.id, recipient.email_address
    FROM messages AS m
    JOIN conversations AS c ON c.id = m.conversation_id
    JOIN participants AS p ON p.conversation_id = c.id
    LEFT JOIN message_notifications AS n ON n.message_id = m.id AND n.participant_id = p.id
    JOIN identifiers AS recipient ON recipient.id = p.identifier_id
    JOIN identifiers AS author ON author.id = m.author_id
    WHERE p.identifier_id <> m.author_id
    AND p.cursor < m.counter
    AND n.id IS NULL
    -- AND m.inserted_at < (now() at time zone 'utc') - '1 minute'::interval
    ORDER BY m.inserted_at ASC
    "
  let args = []
  let mapper = fn(row) {
    assert Ok(message_id) = dynamic.element(row, 0)
    assert Ok(message_id) = dynamic.int(message_id)
    assert Ok(content) = dynamic.element(row, 1)
    assert Ok(content) = dynamic.string(content)
    assert Ok(inserted_at) = dynamic.element(row, 2)
    // assert Ok(inserted_at) = dynamic.string(inserted_at)
    assert Ok(author_id) = dynamic.element(row, 3)
    assert Ok(author_id) = dynamic.int(author_id)
    assert Ok(conversation_id) = dynamic.element(row, 4)
    assert Ok(conversation_id) = dynamic.int(conversation_id)
    assert Ok(topic) = dynamic.element(row, 5)
    assert Ok(topic) = dynamic.string(topic)
    assert Ok(resolved) = dynamic.element(row, 6)
    assert Ok(resolved) = dynamic.bool(resolved)
    assert Ok(recipient_id) = dynamic.element(row, 7)
    assert Ok(recipient_id) = dynamic.int(recipient_id)
    assert Ok(recipient_email_address) = dynamic.element(row, 8)
    assert Ok(recipient_email_address) = dynamic.string(recipient_email_address)

    let link =
      string.join(
        [
          "\r\n\r\nhttps://calm.did.app/c/",
          int.to_string(conversation_id),
          "?t=",
          int.to_string(recipient_id),
        ],
        "",
      )

    Message(
      id: message_id,
      conversation: tuple(conversation_id, topic),
      from: string.append(int.to_string(conversation_id), "@plummail.co"),
      to: tuple(recipient_id, recipient_email_address),
      content: content,
    )
  }
  run_sql.execute(sql, args, mapper)
  // Test last 1 should be
}

pub fn record_sent(message: Message) {
  // TODO rename to recipient id
  let sql =
    "
    INSERT INTO message_notifications (message_id, participant_id)
    VALUES ($1, $2)
    "
  let args = [pgo.int(message.id), pgo.int(message.to.0)]
  let mapper = fn(x) { x }
  run_sql.execute(sql, args, mapper)
}

fn send(api_token, message: Message) {
  let data =
    json.object([
      tuple("From", json.string(message.from)),
      tuple("To", json.string(message.to.1)),
      tuple("TextBody", json.string(message.content)),
    ])
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_host("api.postmarkapp.com")
    |> http.set_path("/email")
    |> http.prepend_req_header("content-type", "application/json")
    |> http.prepend_req_header("accept", "application/json")
    |> http.prepend_req_header("x-postmark-server-token", api_token)
    |> http.set_req_body(json.encode(data))
  todo("postmark")
}
