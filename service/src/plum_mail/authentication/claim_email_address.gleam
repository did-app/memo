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
import plum_mail/identifier

pub type Params {
  Params(email_address: EmailAddress)
}

pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_email)
  Params(email_address)
  |> Ok
}

// TODO some profiles e.g. yesplease@plummail.co have no authentication information
// some accounts have more than one authentication id
pub fn execute(params, config) {
  let Params(email_address: email_address) = params
  try identifier = identifier.find_or_create(email_address)
  assert Ok(token) = authentication.generate_link_token(identifier.id)
  let config.Config(
    postmark_api_token: postmark_api_token,
    origin: origin,
    ..,
  ) = config

  assert Ok(from) = email_address.validate("updates@plummail.co")
  let to = email_address
  let subject = "Welcome back to plum mail"
  let body =
    [
      "Sign in to your plum mail account with the authentication link below\r\n\r\n",
      origin,
      "/memo/#code=",
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
