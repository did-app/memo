import gleam/dynamic
import gleam/pgo
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/start_conversation as inner_sc

fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = authentication.validate_email(email_address)
  authentication.Identifier(id, email_address)
}

pub fn identifier_from_email(email_address) {
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = authentication.validate_email(email_address)

  let sql =
    "
      INSERT INTO identifiers (email_address, referred_by)
      VALUES ($1, currval('identifiers_id_seq'))
      RETURNING id, email_address
      "
  // Could return True of False field for new user
  // Would enable Log or send email when new user is added
  let args = [pgo.text(email_address.value)]
  try [identifier] = run_sql.execute(sql, args, row_to_identifier)
  Ok(identifier)
}

pub fn start_conversation(topic, owner_id) {
  assert Ok(topic) = dynamic.string(topic)
  assert Ok(topic) = discuss.validate_topic(topic)
  assert Ok(owner_id) = dynamic.int(owner_id)
  inner_sc.execute(topic, owner_id)
}

pub fn generate_link_token(identifier_id) {
  assert Ok(identifier_id) = dynamic.int(identifier_id)
  authentication.generate_link_token(identifier_id)
}

pub fn delete_inactive() {
  let sql =
    "
    WITH ids AS (
      SELECT DISTINCT conversation_id
      FROM messages
      WHERE messages.counter > 1
  ), n AS (
      DELETE FROM message_notifications
      WHERE conversation_id NOT IN (SELECT conversation_id FROM ids)
      AND conversation_id < 800
      RETURNING *
  ), m AS (
      DELETE FROM messages
      WHERE conversation_id NOT IN (SELECT conversation_id FROM ids)
      AND conversation_id < 800
      RETURNING *
  ), p AS (
      DELETE FROM participants
      WHERE conversation_id NOT IN (SELECT conversation_id FROM ids)
      AND conversation_id < 800
      RETURNING *
  )
    DELETE FROM conversations
    WHERE id NOT IN (SELECT conversation_id FROM ids)
    AND id < 800
    RETURNING *;
    "
  let args = []
  run_sql.execute(sql, args, fn(x) { x })
}
