//// Extract values from a JSON object
////
//// This module works on dynamic data, however it will always assume the structure represents JSON.
//// This is necessary to understand null's etc.

import gleam/atom
import gleam/dynamic
import gleam/option.{None, Some}
import gleam_uuid.{UUID}
import perimeter/email_address.{EmailAddress}
import perimeter/input.{CastFailure, NotProvided}

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

pub fn as_email(raw) {
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
