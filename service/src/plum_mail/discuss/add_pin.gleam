import gleam/dynamic.{Dynamic}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/discuss/discuss.{Participation}

pub type Params {
  Params(counter: Int, content: String)
}

pub fn params(raw: Dynamic) {
  try counter = acl.required(raw, "counter", acl.as_int)
  try content = acl.required(raw, "content", acl.as_string)
  Params(counter, content)
  |> Ok()
}

pub fn execute(participation, params) {
  let Participation(conversation: conversation, identifier: identifier, ..) =
    participation
  let Params(counter: counter, content: content) = params
  let sql =
    "
        INSERT INTO pins (conversation_id, counter, authored_by, content)
        VALUES ($1, $2, $3, $4)
        RETURNING id
        "
  let args = [
    pgo.int(conversation.id),
    pgo.int(counter),
    pgo.int(identifier.id),
    pgo.text(content),
  ]
  try [inserted] = run_sql.execute(sql, args, fn(row) {
      assert Ok(id) = dynamic.element(row, 0)
      assert Ok(id) = dynamic.int(id)
      id
   })
  Ok(inserted)
}
