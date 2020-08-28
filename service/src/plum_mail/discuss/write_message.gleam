import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql

pub type Params {
  Params(content: String, from: Option(String), resolve: Bool)
}

pub fn params(raw: Dynamic) {
  try content = acl.required(raw, "content", acl.as_string)
  try from = acl.optional(raw, "from", acl.as_string)
  try resolve = acl.required(raw, "resolve", acl.as_bool)
  Params(content, from, resolve)
  |> Ok()
}

// TODO switch to participation type
pub fn execute(participation, params) {
  let tuple(conversation_id, author_id) = participation
  let Params(content: content, from: from, resolve: resolve) = params
  let sql =
    "
      INSERT INTO messages (conversation_id, content, author_id, counter)
      VALUES ($1, $2, $3, (SELECT COUNT(id) FROM messages WHERE conversation_id = $1) + 1)
      "
  let args = [pgo.int(conversation_id), pgo.text(content), pgo.int(author_id)]
  try _ = run_sql.execute(sql, args, fn(x) { x })
  case resolve {
    True -> {
      let sql =
        "
          UPDATE conversations
          SET resolved = True
          WHERE id = $1
          "
      let args = [pgo.int(conversation_id)]
      try _ = run_sql.execute(sql, args, fn(x) { x })
      Ok(Nil)
    }
    False -> Ok(Nil)
  }

  // case from {
  //     Some(value)  ->
  //     None -> Ok(Nil)
  // }

  Ok(Nil)
}
