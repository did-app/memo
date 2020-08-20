import gleam/http/cowboy
import gleam/http.{Request, Response}
import gleam/bit_builder.{BitBuilder}
import gleam/bit_string

pub fn handle(req: Request(BitString)) -> Response(BitBuilder) {
  let body = "Hello, world!"
    |> bit_string.from_string
    |> bit_builder.from_bit_string

  http.response(200)
  |> http.prepend_resp_header("made-with", "Gleam")
  |> http.set_resp_body(body)
}
