import gleam/pgo
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/conversation.{Conversation}

pub fn execute(c: Conversation, email_address) {
  try identifier = authentication.identifier_from_email(email_address)
  let sql =
    "
    INSERT INTO participants (conversation_id, identifier_id, cursor)
    VALUES ($1, $2, 0)
    "
  let args = [pgo.int(c.id), pgo.int(identifier.id)]
  try _ = run_sql.execute(sql, args, fn(x) { x })
  Ok(discuss.build_participation(c, identifier))
}
