import gleam/bit_builder
import gleam/bit_string
import gleam/http
import gleam/json

pub type Code {
  RejectedInput
  Unprocessable
  LogicError
  ServiceUnreachable
  ServiceError
  UnknownError
}

pub type Report(code) {
  Report(code: code, title: String, detail: String)
}

pub fn to_response(report) {
  let Report(code, title, detail) = report
  let tuple(status, code) = case code {
    RejectedInput -> tuple(400, "rejected_input")
    Unprocessable -> tuple(422, "unprocessable")
    LogicError -> tuple(500, "logic_error")
    ServiceUnreachable -> tuple(502, "service_unreachable")
    ServiceError -> tuple(502, "service_error")
    UnknownError -> tuple(500, "unknown_error")
  }
  let data =
    json.object([
      tuple("code", json.string(code)),
      tuple("title", json.string(title)),
      tuple("detail", json.string(detail)),
    ])
  let body =
    data
    |> json.encode
    |> bit_string.from_string
    |> bit_builder.from_bit_string

  http.response(status)
  |> http.prepend_resp_header("content-type", "application/json")
  |> http.set_resp_body(body)
}
