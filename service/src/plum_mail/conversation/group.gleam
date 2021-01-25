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
  Group(id: Int, name: String)
}

pub fn to_json(group) {
  let Group(id, name) = group
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
  RETURNING id, name
), group_identifier AS (
  UPDATE identifiers
  SET group_id = (SELECT id FROM new_group)
  WHERE id = $2
  AND group_id IS NULL
), new_individual AS (
  INSERT INTO identifiers (email_address)
  VALUES ($3)
  ON CONFLICT DO NOTHING
  RETURNING *
), invited AS (
    SELECT id FROM new_individual
  UNION ALL
    SELECT id FROM identifiers 
    WHERE email_address = $3
)

INSERT INTO invitations(group_id, identifier_id)
VALUES ((SELECT id FROM new_group), (SELECT id FROM invited))
RETURNING group_id, identifier_id;
"

// Uses the same SQL by setting the identifier ($2) to null no identifier is affected in the group identifier clause
pub fn create_group(name, first_member) {
  let EmailAddress(first_member) = first_member

  let args = [pgo.text(name), pgo.null(), pgo.text(first_member)]
  try [membership] = run_sql.execute(create_group_sql, args, row_to_membership)
  membership
  |> Ok
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

pub fn add_member(group_id, new_member) {
  let EmailAddress(new_member) = new_member

  let sql =
    "
    WITH new_individual AS (
      INSERT INTO identifiers (email_address)
      VALUES ($2)
      ON CONFLICT DO NOTHING
      RETURNING *
    ), invited AS (
        SELECT id FROM new_individual
      UNION ALL
        SELECT id FROM identifiers 
        WHERE email_address = $2
    )
    INSERT INTO invitations(group_id, identifier_id)
    VALUES ($1, (SELECT id FROM invited))
    RETURNING group_id, identifier_id;
    "
  let args = [pgo.int(group_id), pgo.text(new_member)]
  try [membership] = run_sql.execute(sql, args, row_to_membership)
  membership
  |> Ok
}

pub fn load_all(identifier_id) {
  // Might want a view for all threads showing latest message
  let sql =
    "
  WITH latest AS (
    SELECT DISTINCT ON(thread_id) * FROM memos
    ORDER BY thread_id DESC, inserted_at DESC
  )
  SELECT name, groups.thread_id, latest.inserted_at, latest.content, latest.position
  FROM groups
  LEFT JOIN latest ON latest.thread_id = groups.thread_id
  JOIN invitations ON invitations.group_id = groups.id
  WHERE identifier_id = $1
  "
  let args = [pgo.int(identifier_id)]
  run_sql.execute(sql, args, io.debug)
}
