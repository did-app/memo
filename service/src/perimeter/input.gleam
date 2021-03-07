import gleam/dynamic
import gleam/string
import perimeter/scrub.{BadInput, Report}

pub type Invalid {
  NotProvided(key: String)
  CastFailure(key: String, to: String)
}

// BadEncoding
//  Assume JSON therefore no tuples
pub fn required(raw, key, cast) {
  case dynamic.field(raw, key) {
    Ok(value) ->
      case cast(value) {
        Ok(value) -> Ok(value)
        Error(label) -> Error(CastFailure(key, label))
      }
    Error(_) -> Error(NotProvided(key))
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
