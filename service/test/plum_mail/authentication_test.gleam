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
  authentication.authenticate(None, None)
  |> should.equal(Error(Nil))
}

// TODO fails to authenticate with expired link token
// fn generate_token(identifier_id) {
// }
//
// // Fails to authenticate with invalid selector format or validator
pub fn authenticate_with_link_token_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  assert Ok(link_token) =
    authentication.generate_token()
    |> authentication.save_link_token(identifier.id)

  assert Ok(tuple(r1, s1)) = authentication.authenticate(Some(link_token), None)

  assert Ok(tuple(r2, s2)) = authentication.authenticate(None, Some(r1))
  todo("deleted")
  // |> should.equal(Ok(refresh_token2))
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
