import gleam/io
import gleam/http
import perimeter/services/http_client
import perimeter/scrub
import gleam/should

pub fn invalid_domain_test() {
  assert Error(failure) = http_client.send(http.default_req())
  let report = http_client.to_report(failure)
  report.code
  |> should.equal(scrub.Unprocessable)
}
// All kinds of errors.
// failed_connect
// https://github.com/erlang/otp/blob/7ca7a6c59543db8a6d26b95ae434e61a044b0800/lib/inets/src/http_client/httpc_handler.erl#L770
// https://erlang.org/doc/man/inet.html#type-posix enum of useful error types
// https://github.com/erlang/otp/blob/7ca7a6c59543db8a6d26b95ae434e61a044b0800/lib/inets/src/http_client/httpc_response.erl#L314
