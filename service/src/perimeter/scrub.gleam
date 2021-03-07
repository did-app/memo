import gleam/bit_builder
import gleam/bit_string
import gleam/http
import gleam/json

// Cancellation sounds user initiated, is there a unexpected termination as single word.
// abort vs conclude complete
// scrub 
// Termination.Code
pub type Code {

  // Early
  // When the error is known about in the arguments/request
  // Also handles 404 because the path is an argument
  BadInput

  // Phone Customer Relations
  // When the client can't know about the Error with out further information,
  // Includes Expired, Gone, Username Conflict etc.
  Unprocessable

  // Phone C-suite strategy
  // When the programmer has made a mistake, or when invalid data has been sent to a downstream service
  ImplementationError

  // Phone the Devs
  // Network error, Filesystem error
  ServiceUnreachable

  // Phone your telco
  ServiceError

  // Phone your suppliers
  // Errors from dynamic where no further information of use can be gathered.
  UnknownError
}

// The general error can instead include a format of the dynamic 
pub type Report(code) {
  Report(code: code, title: String, detail: String)
}

// metadata: Map(String, String),
pub fn to_response(report) {
  let Report(code, title, detail) = report
  let tuple(status, code) = case code {
    BadInput -> tuple(400, "bad_input")
    Unprocessable -> tuple(422, "unprocessable")
    ImplementationError -> tuple(500, "implementation_error")
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
// Scratch your head
// Is there a way to Do error kind, code groups but with expected required fields.
// What about an error code for "Downstream" keep returning 400's for 
// Rust error is a trait with is_connect is_redirect as implementaitons
// Go is another mess of strings
// Code to include UnknownError
// receive 400 return 500 
// receive 500 return 503
