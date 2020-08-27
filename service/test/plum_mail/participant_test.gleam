import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/http
import gleam/json
import plum_mail/authentication
import plum_mail/discuss/start_conversation
import plum_mail/web/helpers as web
import plum_mail/web/session
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

pub fn add_participant_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier_id) = authentication.identifier_from_email(email_address)
  let user_session = session.authenticated(identifier_id)
  let topic = "Test topic"
  // conversation, could be domain and entity is thread/topic
  assert Ok(conversation) = start_conversation.execute(topic, identifier_id)

  let tuple(_id, topic, _participants, _messages) =
    support.get_conversation(conversation.id, session.to_string(user_session))

  let invited = support.generate_email_address("example.test")
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation.id), "/participant"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", session.to_string(user_session)),
    )
    |> web.set_req_json(json.object([
      tuple("email_address", json.string(email_address)),
    ]))

  let response = handle(request, support.test_config())
  should.equal(response.status, 201)
  let tuple(_id, topic, participants, _messages) =
    support.get_conversation(conversation.id, session.to_string(user_session))

  list.length(participants)
  |> should.equal(2)
}
