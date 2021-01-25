import gleam/dynamic
import gleam/io
import gleam/json.{Json}
import gleam/pgo
import plum_mail/email_address.{EmailAddress}
import plum_mail/run_sql

pub type Membership {
  Membership(group_id: Int, identifier_id: Int)
}

pub type Group {
  Group(id: Int, name: String, thread_id: Int)
}

pub fn from_row(row, offset) {
  assert Ok(id) = dynamic.element(row, offset + 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(name) = dynamic.element(row, offset + 1)
  assert Ok(name) = dynamic.string(name)
  assert Ok(thread_id) = dynamic.element(row, offset + 2)
  assert Ok(thread_id) = dynamic.int(thread_id)
  Group(id, name, thread_id)
}

pub fn to_json(group) {
  let Group(id, name, ..) = group
  json.object([
    tuple("type", json.string("group")),
    tuple("id", json.int(id)),
    tuple("name", json.string(name)),
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
  let args = [pgo.text(name), pgo.null(), pgo.int(identifier_id)]
  try [group] = run_sql.execute(create_group_sql, args, from_row(_, 0))
  Ok(group)
}

// Turns an existing personal identifier (checks group_id currently NULL) into a group identifier with a first member.
pub fn create_visible_group(maybe_name, identifier_id, first_member) {
  let EmailAddress(first_member) = first_member

  // log in as individual will see unconfirmed memberships and be able to cancel as need be
  // So to create a visible group you need to be logged in as the address
  // create group, attach profile
  // let args = [pgo.nullable(name, pgo.text)]
  let args = [
    pgo.nullable(maybe_name, pgo.text),
    pgo.int(identifier_id),
    pgo.text(first_member),
  ]
  try [membership] = run_sql.execute(create_group_sql, args, row_to_membership)
  membership
  |> Ok
}

fn row_to_membership(row) {
  assert Ok(group_id) = dynamic.element(row, 0)
  assert Ok(group_id) = dynamic.int(group_id)
  assert Ok(identifier_id) = dynamic.element(row, 1)
  assert Ok(identifier_id) = dynamic.int(identifier_id)
  Membership(group_id, identifier_id)
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
    )
    SELECT id, name, thread_id FROM this_group;
    "
  let args = [pgo.int(group_id), pgo.int(invited_id), pgo.int(inviting_id)]
  try [group] = run_sql.execute(sql, args, from_row(_, 0))
  Ok(group)
}
// pub fn load_all(identifier_id) {
//   // Might want a view for all threads showing latest message
//   let sql =
//     "
//   WITH latest AS (
//     SELECT DISTINCT ON(thread_id) * FROM memos
//     ORDER BY thread_id DESC, inserted_at DESC
//   )
//   SELECT name, groups.thread_id, latest.inserted_at, latest.content, latest.position
//   FROM groups
//   LEFT JOIN latest ON latest.thread_id = groups.thread_id
//   JOIN invitations ON invitations.group_id = groups.id
//   WHERE identifier_id = $1
//   "
//   let args = [pgo.int(identifier_id)]
//   run_sql.execute(sql, args, )
// }
