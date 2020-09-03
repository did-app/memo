import gleam/atom
import gleam/dynamic.{Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/http
import gleam/httpc
import gleam/json
import gleam/pgo
import plum_mail/config.{Config}
import plum_mail/run_sql
import plum_mail/authentication.{Identifier}

pub type Message {
  Message(
    id: tuple(Int, Int),
    conversation: tuple(Int, String),
    // to can be participant
    // from can be author
    from: String,
    to: Identifier,
    content: String,
  )
}

external fn earmark_as_html(String) -> tuple(Dynamic, Dynamic, Dynamic) =
  "Elixir.Earmark" "as_html"

fn as_html(markdown) {
  let ok = dynamic.from(atom.create_from_string("ok"))
  case earmark_as_html(markdown) {
    tuple(tag, html, _) if tag == ok -> {
      assert Ok(html) = dynamic.string(html)
      html
    }
  }
}

pub fn load() {
  // TODO this is the same as whats needed for the detail of the notifications tab
  // https://postmarkapp.com/developer/user-guide/send-email-with-api/batch-emails
  let sql =
    "
    SELECT m.counter, m.content, m.inserted_at, author.id, c.id, c.topic, c.resolved, recipient.id, recipient.email_address, recipient.nickname
    FROM messages AS m
    JOIN conversations AS c ON c.id = m.conversation_id
    JOIN participants AS p ON p.conversation_id = c.id
    LEFT JOIN message_notifications AS n
        ON n.conversation_id = m.conversation_id
        AND n.counter = m.counter
        AND n.identifier_id = p.identifier_id
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
    assert Ok(counter) = dynamic.element(row, 0)
    assert Ok(counter) = dynamic.int(counter)
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
    assert Ok(recipient_nickname) = dynamic.element(row, 9)
    assert Ok(recipient_nickname) =
      run_sql.dynamic_option(recipient_nickname, dynamic.string)

    Message(
      id: tuple(conversation_id, counter),
      conversation: tuple(conversation_id, topic),
      from: string.append(int.to_string(conversation_id), "@plummail.co"),
      to: Identifier(
        id: recipient_id,
        email_address: recipient_email_address,
        nickname: recipient_nickname,
      ),
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
    INSERT INTO message_notifications (conversation_id, counter, identifier_id)
    VALUES ($1, $2, $3)
    "
  let args = [
    pgo.int(message.id.0),
    pgo.int(message.id.1),
    pgo.int(message.to.id),
  ]
  let mapper = fn(x) { x }
  run_sql.execute(sql, args, mapper)
}

fn send(postmark_api_token, message: Message) {
  let body =
    [
      "
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
    <html xmlns=\"http://www.w3.org/1999/xhtml\">
      <head>
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
        <meta name=\"x-apple-disable-message-reformatting\" />
        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        <title></title>
      </head>
      <body>
        <main>
    ",
      as_html(message.content),
      "
    <hr>
    <p>This message was sent from Plum Mail.</p>
    <a href=\"https://api.plummail.co/i/",
      int.to_string(message.id.0),
      "/",
      int.to_string(message.to.id),
      "\">Click here to reply</a>
    </main>
    ",
    ]
    |> string.join("")

  let data =
    json.object([
      tuple("From", json.string("updates@plummail.co")),
      tuple("To", json.string(message.to.email_address)),
      tuple("Subject", json.string(message.conversation.1)),
      // tuple("TextBody", json.string(message.content)),
      tuple("HtmlBody", json.string(body)),
    ])
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_host("api.postmarkapp.com")
    |> http.set_path("/email")
    |> http.prepend_req_header("content-type", "application/json")
    |> http.prepend_req_header("accept", "application/json")
    |> http.prepend_req_header("x-postmark-server-token", postmark_api_token)
    |> http.set_req_body(json.encode(data))
  io.debug(request)
  httpc.send(request)
}

pub fn execute() {
  let Config(postmark_api_token: postmark_api_token, ..) = config.from_env()
  assert Ok(messages) = load()
  list.map(
    messages,
    fn(message) {
      case send(postmark_api_token, message) {
        Ok(http.Response(status: 200, ..)) -> record_sent(message)
      }
    },
  )
}
