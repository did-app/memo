import gleam/dynamic.{Dynamic}
import gleam/io
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string
import gleam/json
import gleam/http
import gleam/httpc
import postmark/client as postmark
import plum_mail/config
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Personal}

pub type Params {
  Params(email_address: EmailAddress, target: Option(String))
}

pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_email)
  try target = acl.optional(raw, "target", acl.as_string)
  Params(email_address, target)
  |> Ok
}

// some profiles e.g. founders@sendmemo.app have no authentication information
// some accounts have more than one authentication id
pub fn execute(params, config) {
  let Params(email_address: email_address, target: target) = params
  try Personal(identifier_id, ..) = identifier.find_or_create(email_address)
  assert Ok(token) = authentication.generate_link_token(identifier_id)
  let config.Config(
    postmark_api_token: postmark_api_token,
    client_origin: client_origin,
    ..,
  ) = config

  assert Ok(from) = email_address.validate("memo@sendmemo.app")
  let to = email_address
  let subject = "Welcome back to memo"
  let target = option.unwrap(target, "/")
  let authentication_url =
    [client_origin, target, "#code=", token]
    |> string.join("")

  let tuple(template_alias, profile_email_address) = case string.split(
    target,
    "/",
  ) {
    ["", ""] -> tuple("sign-in", None)
    ["", username] -> tuple(
      "start-chatting",
      Some(string.concat([username, "@sendmemo.app"])),
    )
    ["", domain, username] -> tuple(
      "start-chatting",
      Some(string.concat([username, "@", domain])),
    )
  }

  let template_model =
    json.object([
      tuple("authentication_url", json.string(authentication_url)),
      tuple(
        "profile_email_address",
        json.nullable(profile_email_address, json.string),
      ),
    ])
  try _ =
    postmark.send_email_with_template(
      from.value,
      to.value,
      subject,
      template_alias,
      template_model,
      postmark_api_token,
    )
    |> io.debug()
    |> result.map_error(fn(_) { todo("what is the send error here") })
  Ok(Nil)
}
