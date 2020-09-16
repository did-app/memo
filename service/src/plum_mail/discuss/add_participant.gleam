import gleam/dynamic.{Dynamic}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication.{EmailAddress}
import plum_mail/discuss/discuss.{Participation}

pub type Params {
  Params(email_address: EmailAddress)
}

pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_email)
  Params(email_address)
  |> Ok
}

pub fn execute(participation, params) {
  let Params(email_address: email_address) = params
  try identifier = authentication.identifier_from_email(email_address)
  let Participation(conversation: conversation, ..) = participation

  // TODO have a creator or an "author"
  // have a notificatons table
  let sql =
    "
    WITH new_participant AS (
        INSERT INTO participants (conversation_id, identifier_id, owner, cursor, notify)
        VALUES ($1, $2, FALSE, 0, 'all')
        ON CONFLICT (identifier_id, conversation_id) DO NOTHING
        RETURNING *
    )
    SELECT identifier_id, conversation_id FROM new_participant
    UNION ALL
    SELECT identifier_id, conversation_id FROM participants WHERE conversation_id = $1 AND identifier_id = $2
    "
  let args = [pgo.int(conversation.id), pgo.int(identifier.id)]
  try [_] = run_sql.execute(sql, args, fn(x) { x })
  Ok(tuple(identifier.id, conversation.id))
}
