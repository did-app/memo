import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
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

fn add_pin(identifier_id, conversation_id, counter, content) {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation_id), "/pin"],
      "",
    ))
    |> http.set_req_cookie(
      "token",
      web.auth_token(identifier_id, "ua-test", support.test_config().secret),
    )
    |> http.prepend_req_header("user-agent", "ua-test")
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> web.set_req_json(json.object([
      tuple("counter", json.int(counter)),
      tuple("content", json.string(content)),
    ]))

  handle(request, support.test_config())
}

pub fn pin_content_test() {
  assert Ok(identifier) = support.generate_identifier("example.test")

  assert Ok(topic) = discuss.validate_topic("Test topic")
  assert Ok(conversation) = start_conversation.execute(topic, identifier.id)
  assert Ok(participation) =
    discuss.load_participation(conversation.id, identifier.id)

  let Ok(_) =
    write_message.execute(
      participation,
      write_message.Params("My Message", False),
    )
  let response = add_pin(identifier.id, conversation.id, 1, "Some sub content")

  response.status
  |> should.equal(200)

  assert Ok(body) =
    response.body
    |> bit_builder.to_bit_string()
    |> bit_string.to_string()
  assert Ok(data) = json.decode(body)
  let data = dynamic.from(data)
  assert Ok(pin_id) = dynamic.field(data, "id")
  assert Ok(pin_id) = dynamic.int(pin_id)

  assert Ok([pin]) = discuss.load_pins(conversation.id)
  pin.id
  |> should.equal(pin_id)
  pin.counter
  |> should.equal(1)
  pin.identifier_id
  |> should.equal(identifier.id)
  pin.content
  |> should.equal("Some sub content")

  // Other user can't write pin
  assert Ok(identifier) = support.generate_identifier("other.test")
  let response = add_pin(identifier.id, conversation.id, 1, "Some sub content")
  response.status
  |> should.equal(403)
}
