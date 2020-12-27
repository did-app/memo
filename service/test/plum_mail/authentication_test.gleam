import gleam/base
import gleam/bit_string
import gleam/dynamic
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import gleam/crypto
import gleam/pgo
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
import plum_mail/run_sql
import plum_mail/support
import gleam/should

pub fn validate_email_test() {
  email_address.validate("")
  |> should.equal(Error(Nil))

  email_address.validate("@")
  |> should.equal(Error(Nil))

  email_address.validate("    @ ")
  |> should.equal(Error(Nil))

  email_address.validate("me@")
  |> should.equal(Error(Nil))

  email_address.validate("@nothing")
  |> should.equal(Error(Nil))

  email_address.validate("me@example.com")
  |> should.equal(Ok(EmailAddress("me@example.com")))
  email_address.validate("   me@example.com ")
  |> should.equal(Ok(EmailAddress("me@example.com")))
}

// Fails to authenticate with invalid selector format or validator
pub fn authenticate_with_link_token_test() {
  assert Ok(identifier) = support.generate_identifier("example.test")
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)

  authentication.validate_link_token(link_token)
  |> should.equal(Ok(identifier))
}

pub fn link_token_should_not_be_valid_after_seven_days_test() {
  assert Ok(identifier) = support.generate_identifier("example.test")
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)
  assert Ok(tuple(selector, _)) = string.split_once(link_token, ":")
  let sql =
    "
    UPDATE link_tokens
    SET inserted_at = NOW() - INTERVAL '7 DAYS'
    WHERE selector = $1
    "
  let args = [pgo.text(selector)]
  assert Ok(_) = run_sql.execute(sql, args, fn(_) { Nil })

  authentication.validate_link_token(link_token)
  |> should.equal(Error(Nil))
}
