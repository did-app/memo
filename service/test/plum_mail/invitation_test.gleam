import gleam/int
import gleam/io
import gleam/string
import gleam/uri.{Uri}
import gleam/http
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/start_conversation
import plum_mail/discuss/add_participant
import plum_mail/web/router.{handle}
import plum_mail/web/session
import plum_mail/support
import gleam/should

pub fn follow_invitation_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)

  assert Ok(conversation) =
    start_conversation.execute("A shiny topic", identifier.id)

  let user_session = session.authenticated(identifier.id)
  assert Ok(participation) =
    discuss.load_participation(conversation.id, user_session)
  let email_address = support.generate_email_address("other.test")

  assert Ok(tuple(identifier_id, conversation_id)) =
    email_address
    |> add_participant.Params
    |> add_participant.execute(participation, _)

  let path = discuss.invite_link(identifier_id, conversation_id)
  let request =
    http.default_req()
    |> http.set_path(path)
    |> http.set_req_body(<<>>)
  let response = handle(request, support.test_config())

  response.status
  |> should.equal(303)

  assert Ok(location) = http.get_resp_header(response, "location")
  assert Ok(Uri(path: path, ..)) = uri.parse(location)

  assert Ok(set_cookie) = http.get_resp_header(response, "set-cookie")
  assert Ok(tuple(cookie, _)) = string.split_once(set_cookie, ";")

  let request =
    http.default_req()
    |> http.set_path(string.append("/c/", int.to_string(conversation.id)))
    |> http.prepend_req_header("cookie", cookie)
    |> http.set_req_body(<<>>)
  let response = handle(request, support.test_config())
  response.status
  |> should.equal(200)
}
