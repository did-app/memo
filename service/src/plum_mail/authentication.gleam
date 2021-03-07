import gleam/bit_string
import gleam/base
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string
import gleam/crypto
import gleam/json
import gleam/pgo
import perimeter/scrub.{Report, Unprocessable}
import plum_mail/run_sql
import plum_mail/identifier

pub fn random_string(entropy) {
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
    run_sql.uuid(identifier_id),
  ]
  try rows = run_sql.execute(sql, args)
  assert [_] = rows
  Token(selector, secret)
  |> serialize_token()
  |> Ok()
}

const invalid_link_token = Report(
  Unprocessable,
  "Forbidden",
  "Unable to complete action due to invalid link token",
)

pub fn validate_link_token(token_string) {
  try Token(selector, secret) =
    parse_token(token_string)
    |> result.map_error(fn(_: Nil) { invalid_link_token })
  let sql =
    "
      SELECT i.id, i.email_address, i.greeting, i.group_id, validator, lt.inserted_at > NOW() - INTERVAL '7 DAYS'
      FROM link_tokens AS lt
      JOIN identifiers AS i ON i.id = lt.identifier_id
      WHERE selector = $1
      "
  let args = [pgo.text(selector)]
  try rows = run_sql.execute(sql, args)
  assert Ok(challenge_tokens) =
    list.try_map(
      rows,
      fn(row) {
        try identifier = identifier.row_to_identifier(row, 0)
        try validator = dynamic.element(row, 4)
        try validator = dynamic.string(validator)
        try current = dynamic.element(row, 5)
        try current = dynamic.bool(current)
        tuple(identifier, validator, current)
        |> Ok
      },
    )
  case challenge_tokens {
    [] -> Error(invalid_link_token)
    [tuple(identifier, validator, current)] -> {
      try _ =
        validate(secret, validator)
        |> result.map_error(fn(_: Nil) { invalid_link_token })
      case current {
        True -> Ok(identifier)
        False -> Error(invalid_link_token)
      }
    }
  }
}
