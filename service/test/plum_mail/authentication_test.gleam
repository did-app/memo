import gleam/base
import gleam/bit_string
import gleam/dynamic
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import gleam/crypto
import gleam/pgo
import plum_mail/authentication.{Token}
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

pub fn fails_to_authenticate_without_any_tokens_test() {
  authentication.authenticate(None, None, "random")
  |> should.equal(Error(Nil))
}

pub fn fails_to_authenticate_with_expired_link_token_test() {
  // NOTE link can be valid forever, currently set to 7 days
  Nil
}

// Fails to authenticate with invalid selector format or validator
pub fn authenticate_with_link_token_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)

  assert Ok(link_token) =
    authentication.generate_token()
    |> authentication.save_link_token(identifier.id)

  let user_agent = "Agent-123"
  assert Ok(tuple(r1, s1)) =
    authentication.authenticate(Some(link_token), None, user_agent)
  authentication.load_session(authentication.serialize_token(s1))
  |> should.equal(Ok(identifier.id))

  // Use the refresh token
  assert Ok(tuple(r2, s2)) =
    authentication.authenticate(None, Some(r1), user_agent)
  authentication.load_session(authentication.serialize_token(s2))
  |> should.equal(Ok(identifier.id))

  // Original refresh and sessions are invalidated
  assert Error(Nil) = authentication.authenticate(None, Some(r1), user_agent)
  authentication.load_session(authentication.serialize_token(s1))
  |> should.equal(Error(Nil))
  io.debug("ballon2")

  // link token remains valid
  assert Ok(tuple(r3, s3)) =
    authentication.authenticate(Some(link_token), None, user_agent)
  authentication.load_session(authentication.serialize_token(s3))
  |> should.equal(Ok(identifier.id))
}

pub fn refresh_token_tied_to_user_agent_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)

  assert Ok(link_token) =
    authentication.generate_token()
    |> authentication.save_link_token(identifier.id)

  let user_agent = "Agent-123"
  assert Ok(tuple(r1, s1)) =
    authentication.authenticate(Some(link_token), None, user_agent)
  authentication.authenticate(None, Some(r1), "Other-fire")
  |> should.equal(Error(Nil))
}
