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
import plum_mail/discuss/discuss
import plum_mail/discuss/conversation.{Conversation}
import plum_mail/discuss/start_conversation
import plum_mail/web/helpers as web
import plum_mail/web/session
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

fn set_notification(user_session, conversation: Conversation, preference) {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation.id), "/notify"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", session.to_string(user_session)),
    )
    |> web.set_req_json(json.object([tuple("notify", json.string(preference))]))

  handle(request, support.test_config())
}

pub fn successfully_set_notification_preference_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  let user_session = session.authenticated(identifier.id)
  let topic = "Test topic"

  assert Ok(conversation) = start_conversation.execute(topic, identifier.id)
  let response = set_notification(user_session, conversation, "concluded")

  should.equal(response.status, 201)

  let Ok(participant) =
    discuss.load_participation(conversation.id, user_session)
  should.equal(participant.notify, discuss.Concluded)
}
