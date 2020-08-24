import gleam/bit_string
import gleam/http
import gleam/io
import plum_mail/web/router.{handle}
import gleam/should

pub fn ping_root_test() {
  let request =
    http.default_req()
    |> http.set_req_body(<<>>)
  let response = handle(request)

  should.equal(response.status, 200)
}

pub fn create_conversation_test() {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/c/create")
    |> http.prepend_req_header("cookie", "session=1")
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
}
