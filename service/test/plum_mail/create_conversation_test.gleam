import gleam/bit_string
import gleam/int
import gleam/string
import gleam/http
import plum_mail/authentication
import plum_mail/web/router.{handle}
import plum_mail/web/session
import plum_mail/support
import gleam/should

pub fn create_conversation_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier_id) = authentication.identifier_from_email(email_address)
  let user_session = session.authenticated(identifier_id)
  let topic = "Test topic"

  let body =
    string.append("topic=", topic)
    |> bit_string.from_string

  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/c/create")
    |> http.set_req_cookie("session", session.to_string(user_session))
    |> http.set_req_body(body)
  let response = handle(request)

  should.equal(response.status, 303)
  assert Ok(location) = http.get_resp_header(response, "location")
  assert Ok(tuple(_, id)) = string.split_once(location, "/c/")
  assert Ok(id) = int.parse(id)

  let conversation: tuple(Int, String, List(tuple(Int, String))) =
    support.get_conversation(id, session.to_string(user_session))
  should.equal(conversation.1, topic)
}
