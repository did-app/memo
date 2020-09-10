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

fn random_string(entropy) {
  crypto.strong_random_bytes(4)
  |> base.url_encode64(False)
}

// TODO probably not public
pub fn hash_string(secret) {
  secret
  |> bit_string.from_string()
  |> crypto.hash(crypto.Sha256, _)
  |> base.url_encode64(False)
}

pub type Token {
  Token(selector: String, secret: String)
}

// TODO probably not public
pub fn generate_token() {
  let selector = random_string(4)
  let secret = random_string(8)
  Token(selector, secret)
}

pub fn serialize_token(token) {
  let Token(selector, secret) = token
  string.join([selector, secret], ":")
}

pub fn parse_token(token_string) {
  try tuple(selector, secret) = string.split_once(token_string, ":")
  Ok(Token(selector, secret))
}

pub fn save_link_token(token, identifier_id) {
  let Token(selector, secret) = token

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
  |> Ok()
}

fn from_refresh_token(refresh_token) {
  let Token(selector, secret) = refresh_token
  // TODO return user_agent
  let sql =
    "
              SELECT validator, identifier_id
              FROM refresh_tokens
              WHERE selector = $1
              "
  let args = [pgo.text(selector)]
  let mapper = fn(row) {
    assert Ok(validator) = dynamic.element(row, 0)
    assert Ok(validator) = dynamic.string(validator)
    assert Ok(identifier_id) = dynamic.element(row, 1)
    assert Ok(identifier_id) = dynamic.int(identifier_id)
    tuple(validator, identifier_id)
  }
  try refresh_tokens = run_sql.execute(sql, args, mapper)
  case refresh_tokens {
    [] -> Error(Nil)
    [tuple(validator, identifier_id)] ->
      case crypto.secure_compare(
        bit_string.from_string(validator),
        bit_string.from_string(base.url_encode64(
          crypto.hash(crypto.Sha256, bit_string.from_string(secret)),
          False,
        )),
      ) {
        True -> Ok(identifier_id)
      }
  }
}

pub fn from_link_token(token) {
  let Token(selector, secret) = token
  let sql =
    "
      SELECT validator, identifier_id
      FROM link_tokens
      WHERE selector = $1
      "
  let args = [pgo.text(selector)]
  let mapper = fn(row) {
    assert Ok(validator) = dynamic.element(row, 0)
    assert Ok(validator) = dynamic.string(validator)
    assert Ok(identifier_id) = dynamic.element(row, 1)
    assert Ok(identifier_id) = dynamic.int(identifier_id)
    tuple(validator, identifier_id)
  }
  try challenge_tokens = run_sql.execute(sql, args, mapper)
  case challenge_tokens {
    [] -> todo
    [tuple(validator, identifier_id)] ->
      case crypto.secure_compare(
        bit_string.from_string(validator),
        bit_string.from_string(base.url_encode64(
          crypto.hash(crypto.Sha256, bit_string.from_string(secret)),
          False,
        )),
      ) {
        True -> Ok(identifier_id)
      }
  }
}

fn maybe_from_link_token(link_token) {
  case link_token {
    Some(link_token) -> from_link_token(link_token)
    None -> Error(Nil)
  }
}

fn maybe_from_refresh_token(link_token) {
  case link_token {
    Some(link_token) -> from_refresh_token(link_token)
    None -> Error(Nil)
  }
}

// So it's all very circular and needs a flow diagram
pub fn authenticate(link_token, refresh_token) {
  try identifier_id = case maybe_from_link_token(link_token) {
    Ok(identifier_id) -> Ok(identifier_id)
    Error(_) -> maybe_from_refresh_token(refresh_token)
  }

  let old_refresh_selector =
    option.map(refresh_token, fn(t: Token) { t.selector })

  let refresh_token = generate_token()
  let session_token = generate_token()

  let sql =
    "
  WITH new_refresh AS (
      INSERT INTO refresh_tokens (selector, validator, identifier_id)
      VALUES ($1, $2, $3)
  ), new_session AS (
      INSERT INTO session_tokens (selector, validator, refresh_selector)
      VALUES ($4, $5, $1)
  )
  DELETE FROM refresh_tokens
  WHERE selector = $6
  "
  let args = [
    pgo.text(refresh_token.selector),
    pgo.text(hash_string(refresh_token.secret)),
    pgo.int(identifier_id),
    pgo.text(session_token.selector),
    pgo.text(hash_string(session_token.secret)),
    pgo.nullable(old_refresh_selector, pgo.text),
  ]
  let mapper = fn(row) { row }
  try _ =
    run_sql.execute(sql, args, mapper)
    |> io.debug()

  //
  // // delete old selectors
  Ok(tuple(refresh_token, session_token))
}

pub type EmailAddress {
  EmailAddress(String)
}

pub fn validate_email(email_address) {
  let email_address = string.trim(email_address)
  try parts = string.split_once(string.reverse(email_address), "@")
  case parts {
    tuple("", _) -> Error(Nil)
    tuple(_, "") -> Error(Nil)
    _ -> Ok(email_address)
  }
}

pub type Identifier {
  Identifier(id: Int, email_address: String, nickname: Option(String))
}

fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(nickname) = dynamic.element(row, 2)
  assert Ok(nickname) = run_sql.dynamic_option(nickname, dynamic.string)
  Identifier(id, email_address, nickname)
}

pub fn fetch_identifier(id) {
  let sql =
    "
    SELECT id, email_address, nickname
    FROM identifiers
    WHERE id = $1"
  let args = [pgo.int(id)]
  try db_result = run_sql.execute(sql, args, row_to_identifier)
  run_sql.single(db_result)
  |> Ok
}

// https://www.postgresql.org/message-id/CAHiCE4VBFg7Zp75x8h8QoHf3qpH_GqoQEDUd6QWC0bLGb6ZhVg%40mail.gmail.com
pub fn identifier_from_email(email_address) {
  let sql =
    "
    WITH new_identifier AS (
        INSERT INTO identifiers (email_address)
        VALUES ($1)
        ON CONFLICT DO NOTHING
        RETURNING *
    )
    SELECT id, email_address, nickname FROM new_identifier
    UNION ALL
    SELECT id, email_address, nickname FROM identifiers WHERE email_address = $1
    "
  // Could return True of False field for new user
  // Would enable Log or send email when new user is added
  let args = [pgo.text(email_address)]
  try [row] = run_sql.execute(sql, args, row_to_identifier)
  Ok(row)
}

pub fn update_nickname(identifier_id, nickname) {
  let sql =
    "
    UPDATE identifiers
    SET nickname = $2
    WHERE id = $1
    RETURNING id, email_address, nickname
    "
  let args = [pgo.int(identifier_id), pgo.text(nickname)]
  run_sql.execute(sql, args, row_to_identifier)
}
