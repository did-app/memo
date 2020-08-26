import gleam/bit_builder
import gleam/bit_string
import gleam/http
import gleam/json

pub fn set_req_json(request, data) {
  let body =
    data
    |> json.encode
    |> bit_string.from_string

  request
  |> http.prepend_req_header("content-type", "application/json")
  |> http.set_req_body(body)
}
pub fn set_resp_json(respuest, data) {
  let body =
    data
    |> json.encode
    |> bit_string.from_string
    |> bit_builder.from_bit_string

  respuest
  |> http.prepend_resp_header("content-type", "application/json")
  |> http.set_resp_body(body)
}
