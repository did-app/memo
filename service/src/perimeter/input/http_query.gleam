import gleam/list
import perimeter/email_address
import perimeter/input.{CastFailure, NotProvided}

pub fn required(raw, key, cast) {
  case list.key_find(raw, key) {
    Ok(value) ->
      case cast(value) {
        Ok(value) -> Ok(value)
        Error(label) -> Error(CastFailure(key, label))
      }
    Error(_) -> Error(NotProvided(key))
  }
}

pub fn as_string(raw) {
  Ok(raw)
}

pub fn as_email(raw) {
  case email_address.validate(raw) {
    Ok(value) -> Ok(value)
    Error(Nil) -> Error("email address")
  }
}
