import gleam/base
import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/option.{None, Option, Some}
import gleam/string
import gleam/crypto
import gleam/http
import gleam/json.{Json}
import gleam/pgo
import plum_mail/config
import plum_mail/run_sql
import plum_mail/email_address.{EmailAddress}
import plum_mail/conversation/conversation.{Individual}
import plum_mail/identifier
import plum_mail/web/helpers as web
import plum_mail/web/router.{handle}

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

// TODO remove
pub fn generate_identifier(domain) {
  generate_email_address(domain)
  |> identifier.find_or_create()
}

pub fn generate_individual(domain) {
  let email_address = generate_email_address(domain)
  let sql =
    "
  -- WITH new_individual AS (
  --  INSERT INTO individuals DEFAULT VALUES
  --  RETURNING id
  -- )
  
  INSERT INTO identifiers (email_address)
  VALUES ($1)
  RETURNING id, email_address, greeting, group_id
  "
  let args = [pgo.text(email_address.value)]
  assert Ok([identifier]) = run_sql.execute(sql, args, row_to_identifier)
  identifier
}

fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(greeting) = dynamic.element(row, 2)
  assert Ok(greeting): Result(Option(Json), Nil) =
    run_sql.dynamic_option(greeting, fn(x) { Ok(dynamic.unsafe_coerce(x)) })
  // assert Ok(individual_id) = dynamic.element(row, )
  // assert Ok(individual_id) = run_sql.dynamic_option(individual_id, dynamic.int)
  assert Ok(group_id) = dynamic.element(row, 3)
  assert Ok(group_id) = run_sql.dynamic_option(group_id, dynamic.int)
  case group_id {
    None -> Individual(id, email_address, greeting)
  }
}
