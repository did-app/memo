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

pub fn get_resp_cookie(response) {
  try set_cookie_header = http.get_resp_header(response, "set-cookie")
  let [pair, .._attributes] = string.split(set_cookie_header, ";")
  // try tuple(key, value) =
  string.split_once(pair, "=")
}

pub fn get_conversation(id, session) {
  let request =
    http.default_req()
    |> http.set_path(string.append("/c/", int.to_string(id)))
    |> http.prepend_req_header("cookie", string.append("session=", session))
    |> http.prepend_req_header("origin", test_config().client_origin)
    |> http.set_req_body(<<>>)

  let http.Response(body: body, ..) = handle(request, test_config())
  let body = bit_builder.to_bit_string(body)
  assert Ok(body) = bit_string.to_string(body)
  assert Ok(data) = json.decode(body)
  let data = dynamic.from(data)
  assert Ok(data) = dynamic.field(data, "conversation")
  assert Ok(topic) = dynamic.field(data, "topic")
  assert Ok(topic) = dynamic.string(topic)
  // assert Ok(messages) = dynamic.field(data, "messages")
  // assert Ok(messages) =
  //   dynamic.typed_list(
  //     messages,
  //     fn(message) { // try id_inner = dynamic.field(participant, "id")
  //       // try id_inner = dynamic.int(id_inner)
  //       try content = dynamic.field(message, "content")
  //       try content = dynamic.string(content)
  //       Ok(tuple(content)) },
  //   )
  tuple(id, topic, [])
}
