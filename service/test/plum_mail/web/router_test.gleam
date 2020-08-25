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
