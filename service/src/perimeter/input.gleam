import gleam/atom
import gleam/bit_string
import gleam/dynamic
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/http.{Request}
import gleam/json
import gleam_uuid
import plum_mail/email_address
import perimeter/scrub.{BadInput, Report}

pub type Invalid {
  NotProvided(key: String)
  CastFailure(key: String, to: String)
}

// BadEncoding
//  Assume JSON therefore no tuples
pub fn required(raw, key, cast) {
  let null = dynamic.from(atom.create_from_string("null"))

  case dynamic.field(raw, key) {
    Ok(value) if value == null -> Error(NotProvided(key))
    Ok(value) ->
      case cast(value) {
        Ok(value) -> Ok(value)
        Error(label) -> Error(CastFailure(key, label))
      }
    Error(_) -> Error(NotProvided(key))
  }
}

pub fn optional(raw, key, cast) {
  let null = dynamic.from(atom.create_from_string("null"))
  case dynamic.field(raw, key) {
    Ok(value) if value == null -> Ok(None)
    Ok(value) ->
      case cast(value) {
        Ok(value) -> Ok(Some(value))
        Error(label) -> Error(CastFailure(key, label))
      }
    Error(_) -> Ok(None)
  }
}

pub fn as_email(raw) -> Result(email_address.EmailAddress, String) {
  case dynamic.string(raw) {
    Ok(value) ->
      case email_address.validate(value) {
        Ok(value) -> Ok(value)
        Error(Nil) -> Error("email address")
      }
    Error(reason) -> Error("email address")
  }
}

pub fn as_list(raw, cast) {
  dynamic.typed_list(raw, cast)
}

pub fn as_uuid(raw) {
  try raw = as_string(raw)
  case gleam_uuid.from_string(raw) {
    Ok(value) -> Ok(value)
    Error(Nil) -> Error("Expected a UUID ")
  }
}

pub fn as_string(raw) {
  case dynamic.string(raw) {
    Ok(value) -> Ok(value)
    Error(reason) -> Error("UTF-8 string")
  }
}

pub fn as_int(raw) {
  case dynamic.int(raw) {
    Ok(value) -> Ok(value)
    Error(reason) -> Error("integer")
  }
}

// Don't always need to go through intermediary
fn check_method(request, methods) {
  let Request(method: method, path: path, ..) = request
  case list.contains(methods, method) {
    True -> Ok(Nil)
    False ->
      Error(Report(
        BadInput,
        "Unaccepted HTTP method",
        string.concat([
          "Method '",
          http.method_to_string(method),
          "' is not accepted for route '",
          path,
          "'.",
        ]),
      ))
  }
}

fn get_body(request) {
  let Request(body: body, ..) = request
  case bit_string.to_string(body) {
    Ok(body) -> Ok(body)
    Error(Nil) ->
      Error(Report(
        BadInput,
        "Invalid request body",
        "The request body contained invalid UTF-8 values.",
      ))
  }
}

pub fn parse_json(request) {
  try _ = check_method(request, [http.Post])
  try body = get_body(request)
  case json.decode(body) {
    Ok(params) -> Ok(dynamic.from(params))
    Error(_) ->
      Error(Report(
        BadInput,
        "Invalid request JSON",
        "The request body contained invalid JSON.",
      ))
  }
}

// pub fn as_int() {
// }
pub fn to_report(reason, field_type) {
  case reason {
    NotProvided(key) ->
      Report(
        BadInput,
        string.concat(["Missing ", field_type]),
        string.concat([field_type, " '", key, "' is required"]),
      )
    CastFailure(key, to) ->
      Report(
        BadInput,
        string.concat(["Invalid ", field_type]),
        string.concat([field_type, " '", key, "' is not a valid ", to]),
      )
  }
}
