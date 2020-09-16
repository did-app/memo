import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/option.{None, Some}
import gleam/string
import gleam/http
import gleam/json
import plum_mail/authentication
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

pub fn create_conversation_test() {
  assert Ok(identifier) = support.generate_identifier("example.test")
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)
  assert Ok(tuple(_, session_token)) =
    authentication.authenticate(Some(link_token), None, "ua")

  let topic = "Test topic"

  let body =
    string.append("topic=", topic)
    |> bit_string.from_string

  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/c/create")
    |> http.set_req_cookie("session", session_token)
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> http.set_req_body(body)

  let response = handle(request, support.test_config())

  should.equal(response.status, 303)
  assert Ok(location) = http.get_resp_header(response, "location")
  assert Ok(tuple(_, id)) = string.split_once(location, "/c/")
  assert Ok(id) = int.parse(id)

  let tuple(_id, t, _p, _m) = support.get_conversation(id, session_token)
  should.equal(t, topic)

  let request =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.set_path("/inbox")
    |> http.set_req_cookie("session", session_token)
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> http.set_req_body(<<>>)
  let response = handle(request, support.test_config())

  assert Ok(body) =
    response.body
    |> bit_builder.to_bit_string()
    |> bit_string.to_string
  assert Ok(data) = json.decode(body)
  let data = dynamic.from(data)
  assert Ok(conversations) = dynamic.field(data, "conversations")
  assert Ok(conversations) = dynamic.list(conversations)
  assert [conversation] = conversations
  dynamic.field(conversation, "id")
  |> should.equal(Ok(dynamic.from(id)))

  dynamic.field(conversation, "topic")
  |> should.equal(Ok(dynamic.from(topic)))

  dynamic.field(conversation, "resolved")
  |> should.equal(Ok(dynamic.from(False)))
}
