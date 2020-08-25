import gleam/pgo
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/discuss/conversation.{Conversation}

// TODO need idenfier id
pub fn execute(c: Conversation, email_address) {
  try identifier_id = authentication.identifier_from_email(email_address)
  let sql =
    "
    INSERT INTO participants (conversation_id, identifier_id)
    VALUES ($1, $2)
    "
  let args = [pgo.int(c.id), pgo.int(identifier_id)]
  run_sql.execute(sql, args, fn(x) { x })
}
