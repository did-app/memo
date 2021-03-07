import gleam/io
import gleam/http
import gleam/httpc

pub fn invalid_domain_test() {
  httpc.send(http.default_req())
  |> io.debug
}
// All kinds of errors.
// failed_connect
// https://github.com/erlang/otp/blob/7ca7a6c59543db8a6d26b95ae434e61a044b0800/lib/inets/src/http_client/httpc_handler.erl#L770
// https://erlang.org/doc/man/inet.html#type-posix enum of useful error types
// https://github.com/erlang/otp/blob/7ca7a6c59543db8a6d26b95ae434e61a044b0800/lib/inets/src/http_client/httpc_response.erl#L314
