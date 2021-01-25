import gleam/dynamic
import gleam/option.{None, Some}
import gleam/string
import gleam/pgo
import gleam_uuid
import plum_mail/email_address
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/identifier
import plum_mail/conversation/group

pub fn find_or_create(email_address) {
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = email_address.validate(email_address)
  identifier.find_or_create(email_address)
}

pub fn upgrade_to_shared(identifier_id, name, first_member) {
  assert Ok(identifier_id) = dynamic.string(identifier_id)
  assert Ok(identifier_id) = gleam_uuid.from_string(identifier_id)
  assert Ok(name) = dynamic.string(name)
  let maybe_name = case string.trim(name) {
    "" -> None
    name -> Some(name)
  }
  assert Ok(first_member) = dynamic.string(first_member)
  assert Ok(first_member) = email_address.validate(first_member)
  group.create_visible_group(maybe_name, identifier_id, first_member)
}

pub fn generate_link_token(identifier_id) {
  assert Ok(identifier_id) = dynamic.string(identifier_id)
  assert Ok(identifier_id) = gleam_uuid.from_string(identifier_id)
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
