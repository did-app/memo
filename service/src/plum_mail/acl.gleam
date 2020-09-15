// Anit corruption layer
import gleam/atom
import gleam/bit_string
import gleam/bit_builder
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/map
import gleam/option.{None, Some}
import gleam/string
import gleam/uri
import gleam/http.{Request}
import gleam/json
import plum_mail/error
import plum_mail/authentication
import plum_mail/web/helpers as web

fn check_method(request, methods) {
  let Request(method: method, ..) = request
  case list.contains(methods, method) {
    True -> Ok(Nil)
  }
}

fn get_body(request) {
  let Request(body: body, ..) = request
  case bit_string.to_string(body) {
    Ok(body) -> Ok(body)
    Error(Nil) -> Error(error.BadRequest("Invalid charachters in Request"))
  }
}

pub fn parse_form(request) {
  try _ = check_method(request, [http.Post])
  try body = get_body(request)
  case uri.parse_query(body) {
    Ok(params) -> Ok(map.from_list(params))
    Error(Nil) -> Error(error.BadRequest("Unable to parse request form"))
  }
}

pub fn parse_json(request) {
  try _ = check_method(request, [http.Post])
  try body = get_body(request)
  case json.decode(body) {
    Ok(params) -> Ok(dynamic.from(params))
    Error(_) -> Error(error.BadRequest("Unable to parse request json"))
  }
}

pub fn required(raw, key, cast) {
  case dynamic.field(raw, key) {
    Ok(value) ->
      case cast(value) {
        Ok(value) -> Ok(value)
        Error(_) ->
          Error(error.Unprocessable(
            field: key,
            failure: error.CastFailure("Could not cast parameter"),
          ))
      }
    Error(_) -> Error(error.Unprocessable(field: key, failure: error.Missing))
  }
}

pub fn optional(raw, key, cast) {
  let null = dynamic.from(atom.create_from_string("null"))
  case dynamic.field(raw, key) {
    Ok(value) if value == null -> Ok(None)
    Ok(value) ->
      case cast(value) {
        Ok(value) -> Ok(Some(value))
        Error(_) ->
          Error(error.Unprocessable(
            field: key,
            failure: error.CastFailure("Could not cast parameter"),
          ))
      }
    Error(_) -> Ok(None)
  }
}

pub fn as_string(raw) {
  case dynamic.string(raw) {
    Ok(value) -> Ok(value)
    Error(reason) -> Error(reason)
  }
}

pub fn as_int(raw) {
  case dynamic.int(raw) {
    Ok(value) -> Ok(value)
    Error(reason) -> Error(reason)
  }
}

pub fn as_email(raw) {
  try raw = as_string(raw)
  case authentication.validate_email(raw) {
    Ok(value) -> Ok(value)
    Error(Nil) -> Error("not a valid email")
  }
}

pub fn as_bool(raw) {
  case dynamic.bool(raw) {
    Ok(value) -> Ok(value)
    Error(reason) -> Error(reason)
  }
}

pub fn error_response(reason) {
  let tuple(status, detail) = case reason {
    error.BadRequest(detail) -> tuple(400, detail)
    error.Unauthenticated -> tuple(401, "")
    error.Forbidden -> tuple(403, "")
    error.Unprocessable(field: field, ..) -> tuple(
      422,
      string.append("Could not process with invalid field ", field),
    )
  }
  http.response(status)
  |> web.set_resp_json(json.object([tuple("detail", json.string(detail))]))
  // |> http.set_resp_body(bit_builder.from_bit_string(bit_string.from_string(body)))
}
