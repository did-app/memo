import gleam/dynamic.{Dynamic}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/discuss/discuss.{Participation}

pub type Params {
  Params(content: String)
}

pub fn params(raw: Dynamic) {
  try content = acl.required(raw, "content", acl.as_string)
  Params(content)
  |> Ok()
}

pub fn execute(participation, params) {
  let Participation(conversation: conversation, ..) = participation
  let Params(content: content) = params
  let sql =
    "
        INSERT INTO pins (conversation_id, content)
        VALUES ($1, $2)
        "
  let args = [pgo.int(conversation.id), pgo.text(content)]
  try _ = run_sql.execute(sql, args, fn(x) { x })
  Ok(Nil)
}
