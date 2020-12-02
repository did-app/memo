import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/option.{None, Some}
import gleam/string
import gleam/http
import gleam/json
import plum_mail/authentication
import plum_mail/discuss/discuss.{Topic}
import plum_mail/web/router.{handle}
import plum_mail/web/helpers as web
import plum_mail/support
import gleam/should

pub fn create_conversation_test() {
  let config = support.test_config()
  assert Ok(identifier) = support.generate_identifier("example.test")

  let topic = "Test topic"

  let body =
    string.append("topic=", topic)
    |> bit_string.from_string

  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/c/create")
    |> http.set_req_cookie(
      "token",
      web.auth_token(identifier.id, "ua-test", config.secret),
    )
    |> http.prepend_req_header("user-agent", "ua-test")
    |> http.prepend_req_header("origin", config.client_origin)
    |> http.set_req_body(body)

  let response = handle(request, config)

  should.equal(response.status, 303)
  assert Ok(location) = http.get_resp_header(response, "location")
  assert Ok(tuple(_, id)) = string.split_once(location, "/c/")
  assert Ok(id) = int.parse(id)

  assert Ok(participation) = discuss.load_participation(id, identifier.id)
  participation.conversation.topic
  |> dynamic.from
  |> dynamic.element(1)
  |> should.equal(Ok(dynamic.from(topic)))
  participation.owner
  |> should.equal(True)
}

pub fn create_conversation_with_participant_test() {
  let config = support.test_config()
  assert Ok(identifier) = support.generate_identifier("example.test")

  let topic = "Test topic"
  assert Ok(other) = support.generate_identifier("example.test")

  let body =
    string.append("topic=", topic)
    |> bit_string.from_string
    |> bit_string.append(bit_string.from_string("&participant="))
    |> bit_string.append(bit_string.from_string(other.email_address.value))

  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/c/create")
    |> http.set_req_cookie(
      "token",
      web.auth_token(identifier.id, "ua-test", config.secret),
    )
    |> http.prepend_req_header("user-agent", "ua-test")
    |> http.prepend_req_header("origin", config.client_origin)
    |> http.set_req_body(body)

  let response = handle(request, config)

  should.equal(response.status, 303)
  assert Ok(location) = http.get_resp_header(response, "location")
  assert Ok(tuple(_, id)) = string.split_once(location, "/c/")
  assert Ok(id) = int.parse(id)

  assert Ok(participation) = discuss.load_participation(id, identifier.id)
  participation.conversation.topic
  |> dynamic.from
  |> dynamic.element(1)
  |> should.equal(Ok(dynamic.from(topic)))
  participation.owner
  |> should.equal(True)

  assert Ok(participation) = discuss.load_participation(id, other.id)
  participation.owner
  |> should.equal(False)
}
