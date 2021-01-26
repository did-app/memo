import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/json.{Json}
import gleam/pgo
import gleam_uuid.{UUID}
import plum_mail/email_address.{EmailAddress}
import plum_mail/run_sql

pub type Group {
  Group(id: UUID, name: String, thread_id: UUID, participants: List(String))
}

pub fn from_row(row, offset, participants) {
  assert Ok(id) = dynamic.element(row, offset + 0)
  assert Ok(id) = dynamic.bit_string(id)
  assert id = run_sql.binary_to_uuid4(id)

  assert Ok(name) = dynamic.element(row, offset + 1)
  assert Ok(name) = dynamic.string(name)
  assert Ok(thread_id) = dynamic.element(row, offset + 2)
  assert Ok(thread_id) = dynamic.bit_string(thread_id)
  assert thread_id = run_sql.binary_to_uuid4(thread_id)
  case participants {
    Some(participants) -> Group(id, name, thread_id, participants)
    None -> {
      assert Ok(participants) = dynamic.element(row, offset + 3)
      assert Ok(participants) =
        dynamic.typed_list(
          participants,
          fn(raw) {
            assert Ok(email_address) = dynamic.field(raw, "email_address")
            assert Ok(email_address) = dynamic.string(email_address)
            Ok(email_address)
          },
        )
      Group(id, name, thread_id, participants)
    }
  }
}

pub fn to_json(group) {
  let Group(id, name, participants: participants, ..) = group
  io.debug(participants)
  json.object([
    tuple("type", json.string("group")),
    tuple("id", json.string(gleam_uuid.to_string(id))),
    tuple("name", json.string(name)),
    tuple("participants", json.list(list.map(participants, json.string))),
  ])
}

const create_group_sql = "
WITH new_thread AS (
  INSERT INTO threads
  DEFAULT VALUES
  RETURNING *
), new_group AS (
  INSERT INTO groups (name, thread_id)
  VALUES ($1, (SELECT id FROM new_thread))
  RETURNING *
), group_identifier AS (
  -- This is a no-op when $2 is NULL
  UPDATE identifiers
  SET group_id = (SELECT id FROM new_group)
  WHERE id = $2
  AND group_id IS NULL
), new_invitation AS (
  INSERT INTO invitations(group_id, identifier_id)
  VALUES ((SELECT id FROM new_group), $3)
  RETURNING *
), new_participation AS (
  INSERT INTO participations(thread_id, identifier_id, acknowledged)
  VALUES ((SELECT thread_id FROM new_group), $3, 0)
)
SELECT id, name, thread_id FROM new_group;
"

// Uses the same SQL by setting the identifier ($2) to null no identifier is affected in the group identifier clause
pub fn create_group(name, identifier_id) {
  let args = [pgo.text(name), pgo.null(), run_sql.uuid(identifier_id)]
  try [group] =
    run_sql.execute(create_group_sql, args, from_row(_, 0, Some([])))
  Ok(group)
}

// Turns an existing personal identifier (checks group_id currently NULL) into a group identifier with a first member.
pub fn create_visible_group(name, shared_identifier_id, first_member_id) {
  let args = [
    pgo.text(name),
    run_sql.uuid(shared_identifier_id),
    run_sql.uuid(first_member_id),
  ]
  try [group] =
    run_sql.execute(create_group_sql, args, from_row(_, 0, Some([])))
  Ok(group)
}

pub fn invite_member(group_id, invited_id, inviting_id) {
  let sql =
    "
    -- group is a SQL keyword
    WITH this_group AS (
      SELECT * 
      FROM groups 
      -- This checks the inviting_id has already been invited
      JOIN invitations AS i ON i.group_id = groups.id AND i.identifier_id = $3
      WHERE id = $1
    ), new_invitation AS (
      INSERT INTO invitations(group_id, identifier_id, invited_by)
      VALUES ($1, $2, $3)
      RETURNING *
    ), new_participation AS (
      INSERT INTO participations(thread_id, identifier_id, acknowledged)
      VALUES ((SELECT thread_id FROM this_group), $2, 0)
    ), participant_lists AS (
      -- Could be a view
      SELECT invitations.group_id, json_agg(json_build_object(
        'identifier_id', invitations.identifier_id,
        'email_address', identifiers.email_address
      )) as participants
      FROM invitations
      JOIN identifiers ON identifiers.id = invitations.identifier_id
      GROUP BY (invitations.group_id)
    )
    SELECT id, name, thread_id, participants FROM this_group
    JOIN participant_lists ON participant_lists.group_id = this_group.id;
    "
  let args = [
    run_sql.uuid(group_id),
    run_sql.uuid(invited_id),
    run_sql.uuid(inviting_id),
  ]
  try [group] = run_sql.execute(sql, args, from_row(_, 0, None))
  Ok(group)
}
