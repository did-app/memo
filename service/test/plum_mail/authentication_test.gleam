import gleam/base
import gleam/bit_string
import gleam/dynamic
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import gleam/crypto
import gleam/pgo
import plum_mail/authentication
import plum_mail/run_sql
import plum_mail/support
import gleam/should

pub fn validate_email_test() {
  authentication.validate_email("")
  |> should.equal(Error(Nil))

  authentication.validate_email("@")
  |> should.equal(Error(Nil))

  authentication.validate_email("    @ ")
  |> should.equal(Error(Nil))

  authentication.validate_email("me@")
  |> should.equal(Error(Nil))

  authentication.validate_email("@nothing")
  |> should.equal(Error(Nil))

  authentication.validate_email("me@example.com")
  |> should.equal(Ok("me@example.com"))
  authentication.validate_email("   me@example.com ")
  |> should.equal(Ok("me@example.com"))
}

fn by_refresh_token(refresh_token) {
  case refresh_token {
    Some(_) -> todo
    None -> Error(Nil)
  }
}

pub type Token {
  Token(String, String)
}

fn authenticate(link_token, refresh_token) {
  case link_token {
    Some(Token(selector, secret)) -> {
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
            crypto.hash(crypto.Sha256, bit_string.from_string(secret)),
          ) {
            True -> Ok(3)
          }
      }
    }
    None -> by_refresh_token(refresh_token)
  }
}

pub fn fails_to_authenticate_without_refresh_test() {
  authenticate(None, None)
  |> should.equal(Error(Nil))
}

fn generate_token(identifier_id) {
  let selector =
    crypto.strong_random_bytes(4)
    |> base.url_encode64(False)

  let secret =
    crypto.strong_random_bytes(8)
    |> base.url_encode64(False)

  let validator =
    secret
    |> bit_string.from_string()
    |> crypto.hash(crypto.Sha256, _)
    |> base.url_encode64(False)

  // Insert with target
  // Identifier and conversation becomes participation
  // Do we need a signed redirect
  let sql =
    "
      INSERT INTO link_tokens (selector, validator, identifier_id)
      VALUES ($1, $2, $3)
      RETURNING *
      "
  let args = [pgo.text(selector), pgo.text(validator), pgo.int(identifier_id)]
  let mapper = fn(row) { Nil }
  try [Nil] = run_sql.execute(sql, args, mapper)
  Token(selector, secret)
  |> Ok()
}

// Fails to authenticate with invalid selector format or validator
pub fn authenticate_with_link_token_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  assert Ok(link_token) = generate_token(identifier.id)

  authenticate(Some(link_token), None)
  |> should.equal(Error(Nil))
}
// If we bounce need to query referrer for refresh or session good,
// also to show sign in or link expired
// pub fn generate_token_test() {
//
//   // /i/token/c/id
//   // app.plummail.co/c/id#code=code&target=5
//   // /authenticate
//   authenticate(Some(token), None)
//   // client wont know if token works so don't want to call token and then refresh
//   //
//   todo
// }
