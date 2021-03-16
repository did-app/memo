//// Note invalid response values are considered a service error, 
//// it is just as possible they are a logic error in the receiving code
//// Which service get's to define the API answers this question

import gleam/dynamic
import gleam/bit_string
import gleam/uri
import gleam/http.{Response}
import gleam/json
import perimeter/scrub.{Report, ServiceError}

// other api parse_body(as_json)
pub fn get_plain_text(request) {
  let Response(body: body, ..) = request
  case bit_string.to_string(body) {
    Ok(body) -> Ok(body)
    Error(Nil) ->
      Error(Report(
        ServiceError,
        "Invalid response from service",
        "The response body contained invalid UTF-8 values.",
      ))
  }
}

pub fn get_json(request) {
  try body = get_plain_text(request)
  case json.decode(body) {
    Ok(params) -> Ok(dynamic.from(params))
    Error(_) ->
      Error(Report(
        ServiceError,
        "Invalid response from service",
        "The authentication service returned invalid JSON",
      ))
  }
}
