import gleam/bit_string
import gleam/io
import gleam/string
import gleam/http
import plum_mail/web/router.{handle}
import gleam/should

pub fn ping_root_test() {
  let request =
    http.default_req()
    |> http.set_req_body(<<>>)
  let response = handle(request)

  should.equal(response.status, 200)
}

fn get_resp_cookie(response) {
  try set_cookie_header = http.get_resp_header(response, "set-cookie")
  let [pair, .._attributes] = string.split(set_cookie_header, ";")
  // try tuple(key, value) =
  string.split_once(pair, "=")
}

pub fn create_conversation_test() {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/sign_in")
    |> http.set_req_body(<<"email_address=bill@example.com":utf8>>)
  let response = handle(request)
  should.equal(response.status, 303)
  assert Ok(tuple("session", session)) = get_resp_cookie(response)

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

pub fn show_conversation_test() {
  let request =
    http.default_req()
    |> http.set_path("/c/1")
    |> http.prepend_req_header("cookie", "session=1")
    |> http.set_req_body(<<>>)
  let response = handle(request)

  should.equal(response.status, 200)
  io.debug(response.body)
  todo
}


pub fn add_participant_test() {
    todo

}
