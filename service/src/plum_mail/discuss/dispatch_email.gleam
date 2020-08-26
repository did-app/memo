pub type Message {
  Message(from: String, to: String, text_body: String)
}

pub fn load() {
    // TODO this is the same as whats needed for the detail of the notifications tab
    // https://postmarkapp.com/developer/user-guide/send-email-with-api/batch-emails
  let sql =
    "
    SELECT m.content, m.inserted_at, author.id, c.id, c.resolved, p.notification, recipient.email_address
    FROM messages AS m
    JOIN conversations AS c ON c.id = m.conversation_id
    JOIN participants AS p ON p.conversation_id = c.id
    LEFT JOIN message_notifications AS n ON n.message_id = m.id AND n.participant_id = p.id
    JOIN identifiers AS recipient ON recipient.id = p.identifier_id
    JOIN identifiers AS author ON author.id = m.author_id
    WHERE p.identifier_id <> m.author_id
    AND p.cursor < m.counter
    AND n.id IS NULL
    AND m.inserted_at < (now() at time zone 'utc') - '1 minute'::interval
    "
  todo("loading")
}

fn send(api_token, message: Message) {
  let data =
    json.object([
      tuple("From", json.string(message.from)),
      tuple("To", json.string(message.to)),
      tuple("TextBody", message.text_body),
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
