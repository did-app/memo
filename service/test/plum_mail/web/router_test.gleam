import gleam/bit_string
import gleam/io
import gleam/string
import gleam/http
import plum_mail/support
import plum_mail/web/router.{handle}
import gleam/should
// pub fn ping_root_test() {
//   let request =
//     http.default_req()
//     |> http.set_req_body(<<>>)
//   let response = handle(request, support.test_config())
//
//   should.equal(response.status, 200)
// }

// Test wiring of certain features.
