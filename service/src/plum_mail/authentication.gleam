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

fn from_refresh_token(refresh_token, user_agent) {
  let Token(selector, secret) = refresh_token
  let sql =
    "
  SELECT refresh_tokens.validator, refresh_tokens.link_token_selector
  FROM refresh_tokens
  JOIN link_tokens ON link_tokens.selector = refresh_tokens.link_token_selector
  WHERE refresh_tokens.selector = $1
  AND refresh_tokens.user_agent = $2
  AND refresh_tokens.inserted_at > NOW() - INTERVAL '2 DAYS'
  AND link_tokens.inserted_at > NOW() - INTERVAL '30 DAYS'
  "
  let args = [pgo.text(selector), pgo.text(user_agent)]
  let mapper = fn(row) {
    assert Ok(validator) = dynamic.element(row, 0)
    assert Ok(validator) = dynamic.string(validator)
    assert Ok(link_token_selector) = dynamic.element(row, 1)
    assert Ok(link_token_selector) = dynamic.string(link_token_selector)
    tuple(validator, link_token_selector)
  }
  try refresh_tokens = run_sql.execute(sql, args, mapper)
  case refresh_tokens {
    [] -> Error(Nil)
    [tuple(validator, link_token_selector)] -> {
      try _ = validate(secret, validator)
      Ok(link_token_selector)
    }
  }
}

fn from_link_token(token) {
  let Token(selector, secret) = token
  let sql =
    "
      SELECT validator, selector, inserted_at > NOW() - INTERVAL '7 DAYS'
      FROM link_tokens
      WHERE selector = $1
      "
  let args = [pgo.text(selector)]
  let mapper = fn(row) {
    assert Ok(validator) = dynamic.element(row, 0)
    assert Ok(validator) = dynamic.string(validator)
    assert Ok(link_token_selector) = dynamic.element(row, 1)
    assert Ok(link_token_selector) = dynamic.string(link_token_selector)
    assert Ok(current) = dynamic.element(row, 2)
    assert Ok(current) = dynamic.bool(current)
    tuple(validator, link_token_selector, current)
  }
  try challenge_tokens = run_sql.execute(sql, args, mapper)
  case challenge_tokens {
    [] -> todo
    [tuple(validator, link_token_selector, current)] -> {
      try _ = validate(secret, validator)
      case current {
        True -> Ok(link_token_selector)
        False -> Error(Nil)
      }
    }
  }
}

pub fn load_session(token_string) {
  try Token(selector, secret) = parse_token(token_string)
  let sql =
    "SELECT session_tokens.validator, link_tokens.identifier_id
    FROM session_tokens
    JOIN refresh_tokens ON refresh_tokens.selector = session_tokens.refresh_token_selector
    JOIN link_tokens ON link_tokens.selector = refresh_tokens.link_token_selector
    WHERE session_tokens.selector = $1
    AND session_tokens.inserted_at > NOW() - INTERVAL '1 DAYS'"
  let args = [pgo.text(selector)]
  let mapper = fn(row) {
    assert Ok(validator) = dynamic.element(row, 0)
    assert Ok(validator) = dynamic.string(validator)
    assert Ok(identifier_id) = dynamic.element(row, 1)
    assert Ok(identifier_id) = dynamic.int(identifier_id)
    tuple(validator, identifier_id)
  }
  try session_tokens = run_sql.execute(sql, args, mapper)
  case session_tokens {
    [] -> Error(Nil)
    [tuple(validator, identifier_id)] -> {
      try _ = validate(secret, validator)
      Ok(identifier_id)
    }
  }
}

fn maybe_from_link_token(link_token) {
  case link_token {
    Some(link_token) -> from_link_token(link_token)
    None -> Error(Nil)
  }
}

fn maybe_from_refresh_token(link_token, user_agent) {
  case link_token {
    Some(link_token) -> from_refresh_token(link_token, user_agent)
    None -> Error(Nil)
  }
}

pub fn generate_client_tokens(
  link_token_selector,
  user_agent,
  old_refresh_token_selector,
) {
  let refresh_token = generate_token()
  let session_token = generate_token()

  let sql =
    "
      WITH new_refresh AS (
          INSERT INTO refresh_tokens (selector, validator, user_agent, link_token_selector)
          VALUES ($1, $2, $3, $4)
      ), new_session AS (
          INSERT INTO session_tokens (selector, validator, refresh_token_selector)
          VALUES ($5, $6, $1)
      )
      DELETE FROM refresh_tokens
      WHERE selector = $7
      "
  let args = [
    pgo.text(refresh_token.selector),
    pgo.text(hash_string(refresh_token.secret)),
    pgo.text(user_agent),
    pgo.text(link_token_selector),
    pgo.text(session_token.selector),
    pgo.text(hash_string(session_token.secret)),
    pgo.nullable(old_refresh_token_selector, pgo.text),
  ]
  let mapper = fn(row) { row }
  try _ = run_sql.execute(sql, args, mapper)

  Ok(tuple(serialize_token(refresh_token), serialize_token(session_token)))
}

// So it's all very circular and needs a flow diagram
pub fn authenticate(link_token, refresh_token, user_agent) {
  try link_token = case link_token {
    Some(link_token) ->
      case parse_token(link_token) {
        Ok(link_token) -> Ok(Some(link_token))
      }
    None -> Ok(None)
  }
  try refresh_token = case refresh_token {
    Some(refresh_token) ->
      case parse_token(refresh_token) {
        Ok(refresh_token) -> Ok(Some(refresh_token))
      }
    None -> Ok(None)
  }
  try link_token_selector = case maybe_from_link_token(link_token) {
    Ok(link_token_selector) -> Ok(link_token_selector)
    Error(_) -> maybe_from_refresh_token(refresh_token, user_agent)
  }

  let old_refresh_token_selector =
    option.map(refresh_token, fn(t: Token) { t.selector })

  generate_client_tokens(
    link_token_selector,
    user_agent,
    old_refresh_token_selector,
  )
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
  Identifier(id: Int, email_address: EmailAddress, nickname: Option(String))
}

fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = validate_email(email_address)
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
pub fn identifier_from_email(email_address: EmailAddress) {
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
  let args = [pgo.text(email_address.value)]
  try [row] = run_sql.execute(sql, args, row_to_identifier)
  Ok(row)
}
pub fn lookup_identifier(email_address: EmailAddress) {
  let sql =
    "
    SELECT id, email_address, nickname FROM identifiers WHERE email_address = $1
    "
  // Could return True of False field for new user
  // Would enable Log or send email when new user is added
  let args = [pgo.text(email_address.value)]
  try rows = run_sql.execute(sql, args, row_to_identifier)
  case rows {
      [row] ->
      Ok(row)
      [] -> Error(error.Unprocessable(field: "email_address", failure: error.NotRecognised))
  }
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
