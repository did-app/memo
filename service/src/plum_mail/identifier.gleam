import gleam/atom
import gleam/bit_string.{BitString}
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/json.{Json}
import gleam/pgo
// Note should this be gleam/uuid
import gleam_uuid.{UUID}
import plum_mail/email_address.{EmailAddress}
import plum_mail/run_sql

// identification or discovery or contacts contact or network social graph
// relationships bonds collections connection correspondance
// word for how you know someone
// organisation assembly association
// acquaintance contacts
// relationships is direct or group membership
// a contact is my view of a connection
// TODO is inbox a better name for this? it identifies an inbox
// identifier is Individual or Shared
// "a single human being as distinct from a group."
// "of or for a particular person."
// Personal had connotations of not work
pub type Identifier {
  Personal(id: UUID, email_address: EmailAddress, greeting: Option(Json))
  Shared(id: UUID, email_address: EmailAddress, greeting: Option(Json))
}

pub fn id(identifier) {
  case identifier {
    Personal(id, ..) -> id
    Shared(id, ..) -> id
  }
}

pub fn email_address(identifier) {
  case identifier {
    Personal(email_address: email_address, ..) -> email_address
    Shared(email_address: email_address, ..) -> email_address
  }
}

pub fn to_json(identifier: Identifier) {
  let tuple(identifier_type, id, email_address, greeting) = case identifier {
    Personal(id, email_address, greeting) -> tuple(
      "personal",
      id,
      email_address,
      greeting,
    )
    Shared(id, email_address, greeting) -> tuple(
      "shared",
      id,
      email_address,
      greeting,
    )
  }
  json.object([
    tuple("id", json.string(gleam_uuid.to_string(id))),
    tuple("type", json.string(identifier_type)),
    tuple("email_address", json.string(email_address.value)),
    tuple("greeting", json.nullable(greeting, fn(x) { x })),
  ])
}

pub fn row_to_identifier(row, offset) {
  assert Ok(id) = dynamic.element(row, offset + 0)
  assert Ok(id) = dynamic.bit_string(id)
  let id = run_sql.binary_to_uuid4(id)
  assert Ok(email_address) = dynamic.element(row, offset + 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = email_address.validate(email_address)
  assert Ok(greeting) = dynamic.element(row, offset + 2)
  assert Ok(greeting): Result(Option(Json), Nil) =
    run_sql.dynamic_option(greeting, fn(x) { Ok(dynamic.unsafe_coerce(x)) })
  assert Ok(group_id) = dynamic.element(row, offset + 3)
  assert Ok(group_id) =
    run_sql.dynamic_option(
      group_id,
      fn(id) {
        try id = dynamic.bit_string(id)
        Ok(run_sql.binary_to_uuid4(id))
      },
    )

  case group_id {
    Some(_) -> Shared(id, email_address, greeting)
    None -> Personal(id, email_address, greeting)
  }
}

pub fn find_or_create(email_address: EmailAddress) {
  let sql =
    "
  WITH new_identifier AS (
    INSERT INTO identifiers (email_address)
    VALUES ($1)
    ON CONFLICT (email_address) DO NOTHING
    RETURNING *
  )
  SELECT id, email_address, greeting, group_id FROM new_identifier
  UNION ALL
  SELECT id, email_address, greeting, group_id FROM identifiers WHERE email_address = $1
  "
  let args = [pgo.text(email_address.value)]
  try db_result = run_sql.execute(sql, args, row_to_identifier(_, 0))
  assert [identifier] = db_result
  Ok(identifier)
}

pub fn fetch_by_id(id) {
  let sql =
    "
    SELECT id, email_address, greeting, group_id
    FROM identifiers
    WHERE id = $1"
  let args = [run_sql.uuid(id)]
  try db_result = run_sql.execute(sql, args, row_to_identifier(_, 0))
  run_sql.single(db_result)
  |> Ok
}

pub fn update_greeting(identifier_id, greeting: Json) {
  let sql =
    "
    UPDATE identifiers 
    SET greeting = $2 
    WHERE id = $1
    RETURNING *
    "
  let args = [
    run_sql.uuid(identifier_id),
    dynamic.unsafe_coerce(dynamic.from(greeting)),
  ]
  try db_result = run_sql.execute(sql, args, fn(x) { x })
  db_result
  |> run_sql.single()
  |> Ok
}
