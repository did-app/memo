import gleam/dynamic.{Dynamic}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/discuss/discuss.{Participation}

pub type Params {
  Params(counter: Int)
}

pub fn params(raw: Dynamic) {
  try counter = acl.required(raw, "counter", dynamic.int)
  Params(counter)
  |> Ok()
}

pub fn execute(participation, params) {
  let Participation(conversation: conversation, identifier: identifier, ..) =
    participation
  let Params(counter: counter) = params
  let sql =
    "
      UPDATE participants
      SET cursor = $3
      WHERE identifier_id = $1
      AND conversation_id = $2
      RETURNING *
      "
  let args = [
    pgo.int(identifier.id),
    pgo.int(conversation.id),
    pgo.int(counter),
  ]
  try [_] = run_sql.execute(sql, args, fn(x) { x })
  Ok(Nil)
}
