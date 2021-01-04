import gleam/dynamic
import gleam/pgo
import plum_mail/run_sql
import plum_mail/authentication

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
