import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/discuss/discuss.{Participation}

pub type Params {
  Params(content: String, conclusion: Bool)
}

pub fn params(raw: Dynamic) {
  try content = acl.required(raw, "content", acl.as_string)
  try conclusion = acl.required(raw, "conclusion", acl.as_bool)
  Params(content, conclusion)
  |> Ok()
}

pub fn execute(participation, params) {
  let Participation(conversation: conversation, identifier: identifier, ..) =
    participation
  let Params(content: content, conclusion: conclusion) = params
  let sql =
    "
      WITH new_message AS (
          INSERT INTO messages (conversation_id, content, authored_by, counter, conclusion)
          VALUES ($1, $2, $3, (SELECT COUNT(counter) FROM messages WHERE conversation_id = $1) + 1, $4)
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
    pgo.bool(conclusion),
  ]
  try [_] = run_sql.execute(sql, args, fn(x) { x })
Ok(Nil)
}
