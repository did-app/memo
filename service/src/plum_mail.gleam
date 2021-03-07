import gleam/dynamic
import gleam/io
import gleam/list
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

pub fn create_shared_inbox(name, shared_id, member_id) {
  assert Ok(name) = dynamic.string(name)
  assert Ok(shared_id) = dynamic.string(shared_id)
  assert Ok(shared_id) = gleam_uuid.from_string(shared_id)
  assert Ok(member_id) = dynamic.string(member_id)
  assert Ok(member_id) = gleam_uuid.from_string(member_id)

  group.create_visible_group(name, shared_id, member_id)
}

pub fn quick_team(name, email_address, members) {
  assert Ok(name) = dynamic.string(name)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = email_address.validate(email_address)

  assert Ok([first, ..rest]) = dynamic.typed_list(members, dynamic.string)

  assert Ok(shared) = identifier.find_or_create(email_address)
  assert identifier.Personal(id: shared_id, ..) = shared

  assert Ok(first) = email_address.validate(first)
  assert Ok(first) = identifier.find_or_create(first)
  assert Ok(group.Group(id: group_id, ..)) =
    group.create_visible_group(name, shared_id, identifier.id(first))
  list.each(
    rest,
    fn(member) {
      assert Ok(member) = email_address.validate(member)
      assert Ok(member) = identifier.find_or_create(member)
      assert Ok(_) =
        group.invite_member(
          group_id,
          identifier.id(member),
          identifier.id(first),
        )
      Nil
    },
  )
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
  run_sql.execute(sql, args)
}
