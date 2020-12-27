import gleam/dynamic
import gleam/list
import gleam/option.{Option}
import gleam/json.{Json}
import gleam/pgo
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
import plum_mail/run_sql

// identification or discovery or contacts contact or network social graph
// relationships bonds collections connection correspondance
// word for how you know someone
// organisation assembly association
// acquaintance contacts
// relationships is direct or group membership
// a contact is my view of a connection
// pub fn fetch(identifier_id) {
//   let sql =
//     "
//     SELECT id, email_address
//     FROM identifiers
//     WHERE email_address = $1
//     "
//   let args = [pgo.text(email_address.value)]
//
//   try db_result = run_sql.execute(sql, args, authentication.row_to_identifier)
//
//   Ok(list.head(db_result))
// }
pub type Identifier {
  Identifier(id: Int, email_address: EmailAddress, greeting: Option(Json))
}

pub fn to_json(identifier: Identifier) {
  let Identifier(id, email_address, greeting) = identifier
  json.object([
    tuple("id", json.int(id)),
    tuple("email_address", json.string(email_address.value)),
    tuple("greeting", json.nullable(greeting, fn(x) { x })),
  ])
}

fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = email_address.validate(email_address)
  assert Ok(greeting) = dynamic.element(row, 2)
  assert Ok(greeting): Result(Option(Json), Nil) =
    run_sql.dynamic_option(greeting, fn(x) { Ok(dynamic.unsafe_coerce(x)) })
  Identifier(id, email_address, greeting)
}

pub fn find_or_create(email_address: EmailAddress) {
  // TODO drop refered_by
  let sql =
    "
  WITH new_identifier AS (
    INSERT INTO identifiers (email_address, referred_by)
    VALUES ($1, currval('identifiers_id_seq'))
    ON CONFLICT (email_address) DO NOTHING
    RETURNING id, email_address, greeting
  )
  SELECT id, email_address, greeting FROM new_identifier
  UNION ALL
  SELECT id, email_address, greeting FROM identifiers WHERE email_address = $1
  "
  let args = [pgo.text(email_address.value)]
  try db_result = run_sql.execute(sql, args, row_to_identifier)
  assert [identifier] = db_result
  Ok(identifier)
}

pub fn find(email_address: EmailAddress) {
  let sql =
    "
  SELECT id, email_address, greeting FROM identifiers WHERE email_address = $1
  "
  let args = [pgo.text(email_address.value)]
  try db_result = run_sql.execute(sql, args, row_to_identifier)
  run_sql.single(db_result)
  |> Ok
}

pub fn fetch_by_id(id) {
  let sql =
    "
    SELECT id, email_address, greeting
    FROM identifiers
    WHERE id = $1"
  let args = [pgo.int(id)]
  try db_result = run_sql.execute(sql, args, row_to_identifier)
  run_sql.single(db_result)
  |> Ok
}
// // https://www.postgresql.org/message-id/CAHiCE4VBFg7Zp75x8h8QoHf3qpH_GqoQEDUd6QWC0bLGb6ZhVg%40mail.gmail.com
