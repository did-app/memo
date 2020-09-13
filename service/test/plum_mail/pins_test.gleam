import gleam/int
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import gleam/json
import gleam/http
import plum_mail/discuss/discuss
import plum_mail/discuss/start_conversation
import plum_mail/discuss/write_message
// import plum_mail/discuss/add_pin
import plum_mail/authentication
import plum_mail/web/router.{handle}
import plum_mail/web/helpers as web
import plum_mail/support
import gleam/should

fn add_pin(user_session, conversation_id, counter, content) {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation_id), "/pin"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", user_session),
    )
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> web.set_req_json(json.object([
      tuple("counter", json.int(counter)),
      tuple("content", json.string(content)),
    ]))

  handle(request, support.test_config())
}

pub fn pin_content_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)
  assert Ok(tuple(_, session_token)) =
    authentication.authenticate(Some(link_token), None, "ua")

  let topic = "Test topic"
  assert Ok(conversation) = start_conversation.execute(topic, identifier.id)
  assert Ok(participation) =
    discuss.load_participation(conversation.id, identifier.id)

  let Ok(_) =
    write_message.execute(
      participation,
      write_message.Params("My Message", None, False),
    )
  let response = add_pin(session_token, conversation.id, 1, "Some sub content")
  response.status
  |> should.equal(201)

  assert Ok([pin]) = discuss.load_pins(conversation.id)
  pin.counter
  |> should.equal(1)
  pin.identifier_id
  |> should.equal(identifier.id)
  pin.content
  |> should.equal("Some sub content")
}
