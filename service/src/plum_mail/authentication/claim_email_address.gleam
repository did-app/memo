import gleam/dynamic.{Dynamic}
import gleam/io
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
  Params(email_address: EmailAddress)
}

pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_email)
  Params(email_address)
  |> Ok
}

// some profiles e.g. founders@sendmemo.app have no authentication information
// some accounts have more than one authentication id
pub fn execute(params, config) {
  let Params(email_address: email_address) = params
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
  let body =
    [
      "Sign in to memo using the link below\r\n\r\n",
      client_origin,
      "/#code=",
      token,
    ]
    |> string.join("")

  case postmark_api_token {
    "POSTMARK_DUMMY_TOKEN" -> {
      io.debug(body)
      Ok(Nil)
    }
    _ -> {
      try _ =
        postmark.send_email(
          from.value,
          to.value,
          subject,
          body,
          postmark_api_token,
        )
      Ok(Nil)
    }
  }

  Ok(Nil)
}
