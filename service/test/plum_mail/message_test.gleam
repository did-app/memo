import gleam/int
import gleam/string
import gleam/http
import gleam/json
import plum_mail/authentication
import plum_mail/discuss/start_conversation
import plum_mail/web/helpers
import plum_mail/web/session
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

pub fn write_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier_id) = authentication.identifier_from_email(email_address)
  let user_session = session.authenticated(identifier_id)
  let topic = "Test topic"
  // conversation, could be domain and entity is thread/topic
  assert Ok(conversation) = start_conversation.execute(topic, identifier_id)
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation.id), "/message"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", session.to_string(user_session)),
    )
    |> helpers.set_req_json(json.object([
      tuple("content", json.string("My first message")),
    ]))

  let response = handle(request)
  should.equal(response.status, 201)

  let tuple(_id, topic, participants, messages) =
    support.get_conversation(conversation.id, session.to_string(user_session))

  messages
  |> should.equal([tuple("My first message")])
}
