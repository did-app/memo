import gleam/bit_builder
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/result
import gleam/string
import gleam/http
import postmark/client
import plum_mail/acl
import plum_mail/config.{Config}
import plum_mail/email_address.{EmailAddress}
import plum_mail/authentication
import plum_mail/identifier.{Personal}

pub fn handle(params, config) {
  io.debug(params)
  let Config(
    postmark_api_token: postmark_api_token,
    client_origin: client_origin,
    ..,
  ) = config

  try to_full = acl.required(params, "ToFull", Ok)
  assert Ok([to_full]) = dynamic.list(to_full)
  try to_hash = acl.required(to_full, "MailboxHash", acl.as_string)
  try to_email_address = acl.required(to_full, "Email", acl.as_email)

  try from_email_address = acl.required(params, "From", acl.as_email)

  try Personal(identifier_id, ..) =
    identifier.find_or_create(from_email_address)
  assert Ok(code) = authentication.generate_link_token(identifier_id)
  let link =
    [client_origin, email_address.to_path(to_email_address), "#code=", code]
    |> string.concat()

  // If domain is in supported domain, 
  case tuple(to_email_address.value, to_hash) {
    tuple("peter@sendmemo.app", _) | tuple("peter@sendmemo.app", _) | tuple("team@sendmemo.app", _) -> {
      // We just send back, assuming it is set up properly
      // look up profile/account/contact
      let from = to_email_address
      let to = from_email_address
      let subject = "Please add some context"
      let body =
        [
          "Hi\r\n",
          "\r\n",
          to_email_address.value,
          " doesn't accept direct emails, instead they have set up a quick message that will help you start productive conversation.\r\n",
          "Follow the link below to get started\r\n",
          "\r\n",
          link,
        ]
        |> string.concat()
      try _ =
        client.send_email(
          from.value,
          to.value,
          subject,
          body,
          postmark_api_token,
        )
        |> result.map_error(fn(_) { todo("postmark error not handled") })
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
  }
}
