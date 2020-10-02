import gleam/dynamic.{Dynamic}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/discuss/discuss.{Participation}

pub type Params {
  Params(pin_id: Int)
}

pub fn params(raw: Dynamic) {
  try pin_id = acl.required(raw, "pin_id", acl.as_int)
  Params(pin_id)
  |> Ok()
}

pub fn execute(participation, params) {
  let Participation(conversation: conversation, identifier: identifier, ..) =
    participation
  let Params(pin_id) = params
  let sql =
    "
        DELETE FROM pins
        WHERE conversation_id = $1
        AND id = $2
        "
  let args = [
    pgo.int(conversation.id),
    pgo.int(pin_id),
  ]
  try _ = run_sql.execute(sql, args, fn(x) { x })
  Ok(Nil)
}
