import gleam/dynamic.{Dynamic}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/conversation.{Conversation}

pub type Params {
  Params(email_address: String)
}

pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_string)
  Params(email_address)
  |> Ok
}

pub fn execute(c: Conversation, params) {
  let Params(email_address: email_address) = params
  try identifier = authentication.identifier_from_email(email_address)
  let sql =
    "
    WITH new_participant AS (
        INSERT INTO participants (conversation_id, identifier_id, cursor, notify)
        VALUES ($1, $2, 0, 'all')
        ON CONFLICT (identifier_id, conversation_id) DO NOTHING
        RETURNING *
    )
    SELECT identifier_id, conversation_id FROM new_participant
    UNION ALL
    SELECT identifier_id, conversation_id FROM participants WHERE conversation_id = $1 AND identifier_id = $2
    "
  let args = [pgo.int(c.id), pgo.int(identifier.id)]
  try [_] = run_sql.execute(sql, args, fn(x) { x })
  Ok(discuss.build_participation(c, identifier))
}
