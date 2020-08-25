import gleam/http
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

pub fn create_conversation_test() {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/sign_in")
    |> http.set_req_body(<<"email_address=bill@example.com":utf8>>)
  let response = handle(request)
  should.equal(response.status, 303)
  assert Ok(tuple("session", session)) = support.get_resp_cookie(response)

  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/c/create")
    |> http.set_req_cookie("session", session)
    |> http.set_req_body(<<"topic=New+topic":utf8>>)
  let response = handle(request)

  should.equal(response.status, 303)
  http.get_resp_header(response, "location")
  |> should.equal(Ok("/c/1"))
}
