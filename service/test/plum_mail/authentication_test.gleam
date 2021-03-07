import gleam/base
import gleam/bit_string
import gleam/dynamic
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import gleam/crypto
import gleam/pgo
import plum_mail/authentication
import plum_mail/identifier.{Personal}
import plum_mail/run_sql
import plum_mail/support
import gleam/should

// Fails to authenticate with invalid selector format or validator
pub fn authenticate_with_link_token_test() {
  let identifier = support.generate_personal_identifier("example.test")
  let Personal(identifier_id, ..) = identifier
  assert Ok(link_token) = authentication.generate_link_token(identifier_id)

  authentication.validate_link_token(link_token)
  |> should.equal(Ok(identifier))
}

pub fn link_token_should_not_be_valid_after_seven_days_test() {
  let Personal(identifier_id, ..) =
    support.generate_personal_identifier("example.test")
  assert Ok(link_token) = authentication.generate_link_token(identifier_id)
  assert Ok(tuple(selector, _)) = string.split_once(link_token, ":")
  let sql =
    "
    UPDATE link_tokens
    SET inserted_at = NOW() - INTERVAL '7 DAYS'
    WHERE selector = $1
    "
  let args = [pgo.text(selector)]
  assert Ok(_) = run_sql.execute(sql, args)

  assert Error(_) = authentication.validate_link_token(link_token)
  Nil
}
