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
