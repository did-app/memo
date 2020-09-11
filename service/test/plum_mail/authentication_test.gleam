import gleam/base
import gleam/bit_string
import gleam/dynamic
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import gleam/crypto
import gleam/pgo
import plum_mail/authentication.{EmailAddress}
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
  |> should.equal(Ok(EmailAddress("me@example.com")))
  authentication.validate_email("   me@example.com ")
  |> should.equal(Ok(EmailAddress("me@example.com")))
}

pub fn fails_to_authenticate_without_any_tokens_test() {
  authentication.authenticate(None, None, "random")
  |> should.equal(Error(Nil))
}

// Fails to authenticate with invalid selector format or validator
pub fn authenticate_with_link_token_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)

  assert Ok(link_token) = authentication.generate_link_token(identifier.id)

  // let sql =
  let user_agent = "Agent-123"
  assert Ok(tuple(r1, s1)) =
    authentication.authenticate(Some(link_token), None, user_agent)
  authentication.load_session(s1)
  |> should.equal(Ok(identifier.id))

  // Use the refresh token
  assert Ok(tuple(r2, s2)) =
    authentication.authenticate(None, Some(r1), user_agent)
  authentication.load_session(s2)
  |> should.equal(Ok(identifier.id))

  // Original refresh and sessions are invalidated
  assert Error(Nil) = authentication.authenticate(None, Some(r1), user_agent)
  authentication.load_session(s1)
  |> should.equal(Error(Nil))

  // link token remains valid
  assert Ok(tuple(r3, s3)) =
    authentication.authenticate(Some(link_token), None, user_agent)
  authentication.load_session(s3)
  |> should.equal(Ok(identifier.id))
}

pub fn refresh_token_tied_to_user_agent_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)

  assert Ok(link_token) = authentication.generate_link_token(identifier.id)

  let user_agent = "Agent-123"
  assert Ok(tuple(r1, s1)) =
    authentication.authenticate(Some(link_token), None, user_agent)
  authentication.authenticate(None, Some(r1), "Other-fire")
  |> should.equal(Error(Nil))
}

pub fn link_token_should_not_be_valid_after_seven_days_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
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

  authentication.authenticate(Some(link_token), None, "user_agent")
  |> should.equal(Error(Nil))
}

pub fn refresh_token_should_not_be_valid_after_seven_days_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)
  assert Ok(tuple(refresh_token, _)) =
    authentication.authenticate(Some(link_token), None, "ua")

  assert Ok(tuple(selector, _)) = string.split_once(refresh_token, ":")
  let sql =
    "
    UPDATE refresh_tokens
    SET inserted_at = NOW() - INTERVAL '2 DAYS'
    WHERE selector = $1
    "
  let args = [pgo.text(selector)]
  assert Ok(_) = run_sql.execute(sql, args, fn(_) { Nil })

  authentication.authenticate(None, Some(refresh_token), "ua")
  |> should.equal(Error(Nil))
}

pub fn refresh_token_not_valid_after_30_days_from_link_token_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)
  assert Ok(tuple(refresh_token, _)) =
    authentication.authenticate(Some(link_token), None, "ua")

  assert Ok(tuple(selector, _)) = string.split_once(link_token, ":")
  let sql =
    "
      UPDATE link_tokens
      SET inserted_at = NOW() - INTERVAL '30 DAYS'
      WHERE selector = $1
      "
  let args = [pgo.text(selector)]
  assert Ok(_) = run_sql.execute(sql, args, fn(_) { Nil })

  authentication.authenticate(None, Some(refresh_token), "ua")
  |> should.equal(Error(Nil))
}

pub fn session_token_expires_after_one_day_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)
  assert Ok(tuple(_, session_token)) =
    authentication.authenticate(Some(link_token), None, "ua")

  assert Ok(tuple(selector, _)) = string.split_once(session_token, ":")
  let sql =
    "
      UPDATE session_tokens
      SET inserted_at = NOW() - INTERVAL '1 DAYS'
      WHERE selector = $1
      "
  let args = [pgo.text(selector)]
  assert Ok(_) = run_sql.execute(sql, args, fn(_) { Nil })

  authentication.load_session(session_token)
  |> should.equal(Error(Nil))
}
