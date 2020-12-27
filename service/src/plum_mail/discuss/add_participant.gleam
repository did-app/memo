import gleam/dynamic.{Dynamic}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
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
  todo
  // let Params(email_address: email_address) = params
  // let Participation(conversation: conversation, identifier: author, ..) =
  //   participation
  // let sql =
  //   "
  //   WITH new_identifier AS (
  //       INSERT INTO identifiers (email_address, referred_by)
  //       VALUES ($1, $2)
  //       ON CONFLICT DO NOTHING
  //       RETURNING *
  //   ), invited AS (
  //       SELECT id FROM new_identifier
  //       UNION ALL
  //       SELECT id FROM identifiers WHERE email_address = $1
  //   ), new_participant AS (
  //       INSERT INTO participants (conversation_id, identifier_id, invited_by, cursor, notify, done)
  //       VALUES ($3, (SELECT id FROM invited), $2, 0, 'all', 0)
  //       ON CONFLICT (identifier_id, conversation_id) DO NOTHING
  //       RETURNING *
  //   )
  //   SELECT identifier_id, conversation_id FROM new_participant
  //   UNION ALL
  //   SELECT identifier_id, conversation_id FROM participants WHERE conversation_id = $3 AND identifier_id = (SELECT id FROM invited)
  //   "
  // let args = [
  //   pgo.text(email_address.value),
  //   pgo.int(author.id),
  //   pgo.int(conversation.id),
  // ]
  // try [loaded] =
  //   run_sql.execute(
  //     sql,
  //     args,
  //     fn(row) {
  //       assert Ok(invited_id) = dynamic.element(row, 0)
  //       assert Ok(invited_id) = dynamic.int(invited_id)
  //       assert Ok(conversation_id) = dynamic.element(row, 1)
  //       assert Ok(conversation_id) = dynamic.int(conversation_id)
  //       tuple(invited_id, conversation_id)
  //     },
  //   )
  // Ok(loaded)
}
