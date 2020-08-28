// Anit corruption layer
import gleam/dynamic

pub fn required(raw, key, cast) {
  case dynamic.field(raw, key) {
    Ok(value) ->
      case cast(value) {
        Ok(value) -> Ok(value)
        Error(_) -> Error(todo)
      }
    Error(_) -> Error(todo)
  }
}

pub fn as_string(raw) {
  case dynamic.string(raw) {
    Ok(value) -> Ok(value)
    Error(_) -> Error(todo)
  }
}
