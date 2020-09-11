import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/discuss/discuss.{Participation}

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

pub fn execute(participation, params) {
  let Participation(conversation: conversation, identifier: identifier, ..) =
    participation
  let Params(content: content, from: _from, resolve: resolve) = params
  let sql =
    "
      WITH new_message AS (
          INSERT INTO messages (conversation_id, content, author_id, counter)
          VALUES ($1, $2, $3, (SELECT COUNT(counter) FROM messages WHERE conversation_id = $1) + 1)
          RETURNING counter
      ), participation AS (
          UPDATE participants
          SET cursor = (SELECT counter FROM new_message)
          WHERE identifier_id = $3
          AND conversation_id = $1
      )
      SELECT 42
      "
  let args = [
    pgo.int(conversation.id),
    pgo.text(content),
    pgo.int(identifier.id),
  ]
  try _ = run_sql.execute(sql, args, fn(x) { x })
  case resolve {
    True -> {
      let sql =
        "
          UPDATE conversations
          SET resolved = True
          WHERE id = $1
          "
      let args = [pgo.int(conversation.id)]
      try _ = run_sql.execute(sql, args, fn(x) { x })
      Ok(Nil)
    }
    False -> Ok(Nil)
  }
}
