import gleam/dynamic
import gleam/io
import gleam/option.{None, Some}
import gleam/json
import gleam_uuid
import plum_mail
import plum_mail/identifier
import plum_mail/conversation/conversation
import gleam/should
import plum_mail/support

pub fn direct_conversation_from_shared_inbox_test() {
  let member = support.generate_personal_identifier("me.test")
  let member_id = identifier.id(member)
  let shared = support.generate_personal_identifier("memo.test")
  let shared_id = identifier.id(shared)
  let group =
    plum_mail.create_shared_inbox(
      dynamic.from("Memo Team"),
      dynamic.from(gleam_uuid.to_string(shared_id)),
      dynamic.from(gleam_uuid.to_string(member_id)),
    )

  let bob_email = support.generate_email_address("bob.test")

  let memo = json.list([json.object([tuple("type", json.string("paragraph"))])])
  assert Ok(new_conversation) =
    conversation.start_direct(shared_id, member_id, bob_email, memo)

  assert Ok([personal_inbox, shared_inbox]) =
    conversation.all_inboxes(member_id)
  personal_inbox.0
  |> should.equal(member)
  personal_inbox.1
  |> should.equal(None)

  identifier.fetch_by_id(shared_id)
  |> should.equal(Ok(Some(shared_inbox.0)))
  shared_inbox.1
  |> should.equal(Some(member))
  shared_inbox.2
  |> should.equal([new_conversation])

  todo("direct")
}
