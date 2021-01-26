import gleam/base
import gleam/bit_builder
import gleam/bit_string
import gleam/string
import gleam/crypto
import gleam/http
import gleam/pgo
import plum_mail/config
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier

pub fn test_config() {
  config.Config(
    origin: "https://memo.did.test",
    client_origin: "https://app.plummail.test",
    postmark_api_token: "POSTMARK_TEST_TOKEN",
    secret: <<"DUMMY_SECRET":utf8>>,
  )
}

pub fn generate_email_address(domain) {
  crypto.strong_random_bytes(8)
  |> base.url_encode64(False)
  |> string.append("@")
  |> string.append(domain)
  |> EmailAddress()
}

pub fn generate_personal_identifier(domain) {
  assert Ok(identifier) =
    identifier.find_or_create(generate_email_address(domain))
  identifier
}
