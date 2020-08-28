import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import gleam/pgo
import plum_mail/run_sql

pub type Params {
  Params(content: String, from: Option(String), resolve: Bool)
}

fn required(raw, key, cast) {
  case dynamic.field(raw, key) {
    Ok(value) ->
      case cast(value) {
        Ok(value) -> Ok(value)
        Error(_) -> Error(todo)
      }
    Error(_) -> Error(todo)
  }
}

fn as_string(raw) {
  case dynamic.string(raw) {
    Ok(value) -> Ok(value)
    Error(_) -> Error(todo)
  }
}

pub fn params(raw: Dynamic) {
  try content = required(raw, "content", as_string)
  Params(content, None, False)
  |> Ok()
}

pub fn execute(participation, params) {
  let tuple(conversation_id, author_id) = participation
  let Params(content: content, ..) = params
  let sql =
    "
      INSERT INTO messages (conversation_id, content, author_id, counter)
      VALUES ($1, $2, $3, (SELECT COUNT(id) FROM messages WHERE conversation_id = $1) + 1)
      "
  let args = [pgo.int(conversation_id), pgo.text(content), pgo.int(author_id)]
  try _ = run_sql.execute(sql, args, fn(x) { x })
  Ok(Nil)
}
