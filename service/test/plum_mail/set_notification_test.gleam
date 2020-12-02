import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/http
import gleam/json
import plum_mail/authentication
import plum_mail/discuss/discuss.{Conversation}
import plum_mail/discuss/start_conversation
import plum_mail/web/helpers as web
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

fn set_notification(identifier_id, conversation: Conversation, preference) {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation.id), "/notify"],
      "",
    ))
    |> http.set_req_cookie(
      "token",
      web.auth_token(identifier_id, "ua-test", support.test_config().secret),
    )
    |> http.prepend_req_header("user-agent", "ua-test")
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> web.set_req_json(json.object([tuple("notify", json.string(preference))]))

  handle(request, support.test_config())
}

pub fn successfully_set_notification_preference_test() {
  assert Ok(identifier) = support.generate_identifier("example.test")

  assert Ok(topic) = discuss.validate_topic("Test topic")
  assert Ok(conversation) = start_conversation.execute(topic, identifier.id)
  let response = set_notification(identifier.id, conversation, "concluded")

  should.equal(response.status, 200)
  let Ok(participant) =
    discuss.load_participation(conversation.id, identifier.id)
  should.equal(participant.notify, discuss.Concluded)
}
