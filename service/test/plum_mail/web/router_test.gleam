import gleam/bit_string
import gleam/http
import plum_mail/web/router.{handle}
import gleam/should

pub fn ping_root_test() {
    let request = http.default_req()
    |> http.set_req_body(<<>>)
    let response = handle(request)

    should.equal(response.status, 200)
}
