import gleam/atom
import gleam/bit_string.{BitString}
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/json.{Json}
import gleam/pgo
// Note should this be gleam/uuid
import gleam_uuid.{UUID}
import perimeter/email_address.{EmailAddress}
import plum_mail/run_sql

// identification or discovery or contacts contact or network social graph
// relationships bonds collections connection correspondance
// word for how you know someone
// organisation assembly association
// acquaintance contacts
// relationships is direct or group membership
// a contact is my view of a connection
// is inbox a better name for this? it identifies an inbox
// identifier is Individual or Shared
// "a single human being as distinct from a group."
// "of or for a particular person."
// Personal had connotations of not work
pub type Identifier {
  Personal(
    id: UUID,
    email_address: EmailAddress,
    name: Option(String),
    greeting: Option(Json),
  )
  Shared(
    id: UUID,
    email_address: EmailAddress,
    name: Option(String),
    greeting: Option(Json),
  )
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
  let tuple(identifier_type, id, email_address, name, greeting) = case identifier {
    Personal(id, email_address, name, greeting) -> tuple(
      "personal",
      id,
      email_address,
      name,
      greeting,
    )
    Shared(id, email_address, name, greeting) -> tuple(
      "shared",
      id,
      email_address,
      name,
      greeting,
    )
  }
  json.object([
    tuple("id", json.string(gleam_uuid.to_string(id))),
    tuple("type", json.string(identifier_type)),
    tuple("email_address", json.string(email_address.value)),
    tuple("name", json.nullable(name, json.string)),
    tuple("greeting", json.nullable(greeting, fn(x) { x })),
  ])
}

pub fn row_to_identifier(row, offset) {
  try id = dynamic.element(row, offset + 0)
  try id = dynamic.bit_string(id)
  let id = run_sql.binary_to_uuid4(id)
  try email_address = dynamic.element(row, offset + 1)
  try email_address = dynamic.string(email_address)
  try email_address =
    email_address.validate(email_address)
    |> result.map_error(fn(_) { todo("use input") })
  try name = dynamic.element(row, offset + 2)
  try name = run_sql.dynamic_option(name, dynamic.string)
  try greeting = dynamic.element(row, offset + 3)

  try greeting: Option(Json) =
    run_sql.dynamic_option(
      greeting,
      fn(x) -> Result(Json, String) { Ok(dynamic.unsafe_coerce(x)) },
    )
  try group_id = dynamic.element(row, offset + 4)
  try group_id =
    run_sql.dynamic_option(
      group_id,
      fn(id) {
        try id = dynamic.bit_string(id)
        Ok(run_sql.binary_to_uuid4(id))
      },
    )

  case group_id {
    Some(_) -> Shared(id, email_address, name, greeting)
    None -> Personal(id, email_address, name, greeting)
  }
  |> Ok
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
  SELECT id, email_address, name, greeting, group_id FROM new_identifier
  UNION ALL
  SELECT id, email_address, name, greeting, group_id FROM identifiers WHERE email_address = $1
  "
  let args = [pgo.text(email_address.value)]
  try rows = run_sql.execute(sql, args)
  assert [row] = rows
  assert Ok(identifier) = row_to_identifier(row, 0)
  Ok(identifier)
}

pub fn fetch_by_id(id) {
  let sql =
    "
    SELECT id, email_address, name, greeting, group_id
    FROM identifiers
    WHERE id = $1"
  let args = [run_sql.uuid(id)]
  try rows = run_sql.execute(sql, args)
  case rows {
    [row] -> {
  assert Ok(identifier) = row_to_identifier(row, 0)
  Ok(Some(identifier))

    }
    [] ->
    Ok(None)
  }
}

pub fn update_greeting(identifier_id, greeting: Json) {
  let sql =
    "
    UPDATE identifiers 
    SET greeting = $2 
    WHERE id = $1
    RETURNING id, email_address, name, greeting, group_id
    "
  let args = [
    run_sql.uuid(identifier_id),
    dynamic.unsafe_coerce(dynamic.from(greeting)),
  ]
  try rows = run_sql.execute(sql, args)
  assert [row] = rows
  assert Ok(identifier) = row_to_identifier(row, 0)
  Ok(identifier)
}
