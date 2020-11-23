import gleam/bit_builder
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/http
import plum_mail/acl
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/write_message

// TODO rename email/postmark/router at [inbound/postmark]
pub fn handle(params, config) {
  try to_full = acl.required(params, "ToFull", Ok)
  assert Ok([to_full]) = dynamic.list(to_full)
  try to_hash = acl.required(to_full, "MailboxHash", acl.as_string)
  try to_email_address = acl.required(to_full, "Email", acl.as_email)
  try to_name = acl.required(to_full, "Name", acl.as_email)

  try from_email_address = acl.required(params, "From", acl.as_email)

  case tuple(to_email_address.value, to_hash) {
    tuple("c@reply.plummail.co", conversation_id) -> {
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
    tuple("peter@plummail.co", _) -> {
      io.debug("let's bounce this")
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
  }
}
