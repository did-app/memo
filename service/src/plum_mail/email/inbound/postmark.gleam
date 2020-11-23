import gleam/bit_builder
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/http
import postmark/client
import plum_mail/acl
import plum_mail/config.{Config}
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/write_message

pub fn handle(params, config) {
  io.debug(params)
  let Config(postmark_api_token: postmark_api_token, ..) = config

  try to_full = acl.required(params, "ToFull", Ok)
  assert Ok([to_full]) = dynamic.list(to_full)
  try to_hash = acl.required(to_full, "MailboxHash", acl.as_string)
  try to_email_address = acl.required(to_full, "Email", acl.as_email)
  try to_name = acl.required(to_full, "Name", acl.as_string)

  try from_email_address = acl.required(params, "From", acl.as_email)

  case tuple(to_email_address.value, to_hash) {
    tuple("peter@plummail.co", "") -> {
      // We just send back, assuming it is set up properly
      // TODO look up profile/account/contact
      let from = to_email_address
      let to = from_email_address
      let subject = "Please and some context"
      let body =
        "
        Hi

        Please can you visit https://plummail.co/peter
        "
      try _ = client.send_email(from, to, subject, body, postmark_api_token)
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    // Note this address has the full email address including the hash
    tuple(<<c:utf8_codepoint, _>>, conversation_id) -> {
      assert Ok(conversation_id) = int.parse(conversation_id)
      try reply = acl.required(params, "StrippedTextReply", acl.as_string)
      let params = write_message.Params(reply, False)
      assert Ok(identifier) =
        authentication.lookup_identifier(from_email_address)
      assert Ok(participation) =
        discuss.load_participation(conversation_id, identifier.id)
      try _ = write_message.execute(participation, params)
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
  }
}
