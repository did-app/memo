import gleam/bit_string
import gleam/base
import gleam/dynamic
import gleam/io
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string
import gleam/crypto
import gleam/pgo
import plum_mail/run_sql
import plum_mail/error

fn random_string(entropy) {
  crypto.strong_random_bytes(entropy)
  |> base.url_encode64(False)
}

fn hash_string(secret) {
  secret
  |> bit_string.from_string()
  |> crypto.hash(crypto.Sha256, _)
  |> base.url_encode64(False)
}

pub fn validate(secret, validator) {
  let match =
    bit_string.from_string(secret)
    |> crypto.hash(crypto.Sha256, _)
    |> base.url_encode64(False)
    |> bit_string.from_string()
    |> crypto.secure_compare(bit_string.from_string(validator))
  case match {
    True -> Ok(Nil)
    False -> Error(Nil)
  }
}

type Token {
  Token(selector: String, secret: String)
}

fn generate_token() {
  let selector = random_string(4)
  let secret = random_string(8)
  Token(selector, secret)
}

fn serialize_token(token) {
  let Token(selector, secret) = token
  string.join([selector, secret], ":")
}

fn parse_token(token_string) {
  try tuple(selector, secret) = string.split_once(token_string, ":")
  Ok(Token(selector, secret))
}

pub fn generate_link_token(identifier_id) {
  let Token(selector, secret) = generate_token()

  let sql =
    "
  INSERT INTO link_tokens (selector, validator, identifier_id)
  VALUES ($1, $2, $3)
  RETURNING *
  "
  let args = [
    pgo.text(selector),
    pgo.text(hash_string(secret)),
    pgo.int(identifier_id),
  ]
  let mapper = fn(row) { Nil }
  try [Nil] = run_sql.execute(sql, args, mapper)
  Token(selector, secret)
  |> serialize_token()
  |> Ok()
}

pub fn validate_link_token(token_string) {
  try Token(selector, secret) = parse_token(token_string)
  let sql =
    "
      SELECT i.id, i.email_address, validator, selector, lt.inserted_at > NOW() - INTERVAL '7 DAYS'
      FROM link_tokens AS lt
      JOIN identifiers AS i ON i.id = lt.identifier_id
      WHERE selector = $1
      "
  let args = [pgo.text(selector)]
  let mapper = fn(row) {
    let identifier = row_to_identifier(row)
    assert Ok(validator) = dynamic.element(row, 2)
    assert Ok(validator) = dynamic.string(validator)
    assert Ok(link_token_selector) = dynamic.element(row, 3)
    assert Ok(link_token_selector) = dynamic.string(link_token_selector)
    assert Ok(current) = dynamic.element(row, 4)
    assert Ok(current) = dynamic.bool(current)
    tuple(identifier, validator, link_token_selector, current)
  }
  try challenge_tokens = run_sql.execute(sql, args, mapper)
  case challenge_tokens {
    [] -> todo
    [tuple(identifier, validator, link_token_selector, current)] -> {
      try _ = validate(secret, validator)
      case current {
        True -> Ok(identifier)
        False -> Error(Nil)
      }
    }
  }
}

pub type EmailAddress {
  EmailAddress(value: String)
}

pub fn validate_email(email_address) {
  let email_address = string.trim(email_address)
  try parts = string.split_once(string.reverse(email_address), "@")
  case parts {
    tuple("", _) -> Error(Nil)
    tuple(_, "") -> Error(Nil)
    _ -> Ok(EmailAddress(email_address))
  }
}

pub type Identifier {
  Identifier(id: Int, email_address: EmailAddress)
}

pub fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = validate_email(email_address)
  Identifier(id, email_address)
}

pub fn fetch_identifier(id) {
  let sql =
    "
    SELECT id, email_address
    FROM identifiers
    WHERE id = $1"
  let args = [pgo.int(id)]
  try db_result = run_sql.execute(sql, args, row_to_identifier)
  run_sql.single(db_result)
  |> Ok
}

// https://www.postgresql.org/message-id/CAHiCE4VBFg7Zp75x8h8QoHf3qpH_GqoQEDUd6QWC0bLGb6ZhVg%40mail.gmail.com
// TODO remove, or send in the correct write message for attemted login, might result in special sign in action not general auth one
pub fn lookup_identifier(email_address: EmailAddress) {
  let sql =
    "
    SELECT id, email_address FROM identifiers WHERE email_address = $1
    "
  // Could return True of False field for new user
  // Would enable Log or send email when new user is added
  let args = [pgo.text(email_address.value)]
  try rows = run_sql.execute(sql, args, row_to_identifier)
  case rows {
    [row] -> Ok(row)
    [] -> Error(error.UnknownIdentifier(email_address.value))
  }
}
