import gleam/base
import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/string
import gleam/crypto
import gleam/http
import gleam/json
import gleam/pgo
import plum_mail/config
import plum_mail/run_sql
import plum_mail/authentication.{EmailAddress}
import plum_mail/web/helpers as web
import plum_mail/web/router.{handle}

pub fn test_config() {
  config.Config(
    client_origin: "https://app.plummail.test",
    postmark_api_token: "POSTMARK_TEST_TOKEN",
  )
}

pub fn generate_email_address(domain) {
  crypto.strong_random_bytes(8)
  |> base.url_encode64(False)
  |> string.append("@")
  |> string.append(domain)
  |> EmailAddress()
}

fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = authentication.validate_email(email_address)
  authentication.Identifier(id, email_address)
}

pub fn identifier_from_email(email_address: EmailAddress) {
  let sql =
    "
    INSERT INTO identifiers (email_address, referred_by)
    VALUES ($1, currval('identifiers_id_seq'))
    RETURNING id, email_address
    "
  // Could return True of False field for new user
  // Would enable Log or send email when new user is added
  let args = [pgo.text(email_address.value)]
  try [identifier] = run_sql.execute(sql, args, row_to_identifier)
  Ok(identifier)
}

pub fn generate_identifier(domain) {
  generate_email_address(domain)
  |> identifier_from_email()
}
