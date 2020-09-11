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
import plum_mail/authentication.{EmailAddress}
import plum_mail/discuss/discuss.{Conversation}
import plum_mail/discuss/start_conversation
import plum_mail/web/helpers as web
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

fn add_participant(
  user_session,
  conversation: Conversation,
  email_address: EmailAddress,
) {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation.id), "/participant"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", user_session),
    )
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> web.set_req_json(json.object([
      tuple("email_address", json.string(email_address.value)),
    ]))

  handle(request, support.test_config())
}

pub fn successfully_add_new_participant_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)
  assert Ok(tuple(_, session_token)) =
    authentication.authenticate(Some(link_token), None, "ua")

  let topic = "Test topic"

  assert Ok(conversation) = start_conversation.execute(topic, identifier.id)

  let invited_email_address = support.generate_email_address("other.test")
  let response =
    add_participant(session_token, conversation, invited_email_address)

  should.equal(response.status, 201)
  assert Ok(participants) = discuss.load_participants(conversation.id)

  participants
  |> list.map(fn(x: authentication.Identifier) { x.email_address })
  |> should.equal([email_address, invited_email_address])

  // It is idempotent
  let response =
    add_participant(session_token, conversation, invited_email_address)

  should.equal(response.status, 201)
  assert Ok(participants) = discuss.load_participants(conversation.id)
  participants
  |> list.map(fn(x: authentication.Identifier) { x.email_address })
  |> should.equal([email_address, invited_email_address])
}
