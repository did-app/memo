import gleam/dynamic
import gleam/bit_string
import gleam/uri
import gleam/http.{Request}
import gleam/json
import perimeter/scrub.{RejectedInput, Report}

// other api parse_body(as_json)
pub fn get_plain_text(request) {
  let Request(body: body, ..) = request
  case bit_string.to_string(body) {
    Ok(body) -> Ok(body)
    Error(Nil) ->
      Error(Report(
        RejectedInput,
        "Invalid request body",
        "The request body contained invalid UTF-8 values.",
      ))
  }
}

pub fn get_json(request) {
  try body = get_plain_text(request)
  case json.decode(body) {
    Ok(params) -> Ok(dynamic.from(params))
    Error(_) ->
      Error(Report(
        RejectedInput,
        "Invalid request JSON",
        "The request body contained invalid JSON.",
      ))
  }
}

pub fn get_form(request) {
  try body = get_plain_text(request)
  case uri.parse_query(body) {
    // We make it dynamic to match JSON, there are very few form endpoints fo good enough for now
    Ok(params) -> Ok(params)
    Error(Nil) ->
      Error(Report(
        RejectedInput,
        "Invalid request form",
        "The request body contained invalid form data.",
      ))
  }
}
