import gleam/dynamic
import gleam/option.{None}
import gleam/io
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/start_conversation
import plum_mail/discuss/add_participant
import plum_mail/discuss/write_message
import plum_mail/discuss/show_inbox
import plum_mail/web/session
import plum_mail/support
import gleam/should

pub fn unread_messages_in_conversation_test() {
  // Can left join on messages that were created before X pm
  // Ordered by most recent
  let email_address = support.generate_email_address("me.test")
  assert Ok(me) = authentication.identifier_from_email(email_address)

  let email_address = support.generate_email_address("alice.test")
  assert Ok(alice) = authentication.identifier_from_email(email_address)

  let me_session = session.authenticated(me.id)
  assert Ok(c1) = start_conversation.execute("First", me.id)
  assert Ok(participation) = discuss.load_participation(c1.id, me_session)
  assert Ok(_) =
    add_participant.execute(
      participation,
      add_participant.Params(email_address),
    )
  assert Ok(_) =
    write_message.execute(
      participation,
      write_message.Params("My Message", None, False),
    )

  assert Ok(c2) = start_conversation.execute("Second", me.id)
  assert Ok(participation) = discuss.load_participation(c2.id, me_session)
  assert Ok(_) =
    add_participant.execute(
      participation,
      add_participant.Params(email_address),
    )

  let alice_session = session.authenticated(alice.id)
  assert Ok(participation) = discuss.load_participation(c2.id, alice_session)
  assert Ok(_) =
    write_message.execute(
      participation,
      write_message.Params("New message", None, False),
    )
  assert Ok(_) =
    write_message.execute(
      participation,
      write_message.Params("Next message", None, False),
    )

  assert Ok(inbox) = show_inbox.execute(me.id)
  assert Ok([r1, r2]) = dynamic.list(dynamic.from(inbox))

  dynamic.field(r1, "topic")
  |> should.equal(Ok(dynamic.from("Second")))
  dynamic.field(r1, "resolved")
  |> should.equal(Ok(dynamic.from(False)))
  dynamic.field(r1, "unread")
  |> should.equal(Ok(dynamic.from(True)))

  dynamic.field(r2, "topic")
  |> should.equal(Ok(dynamic.from("First")))
  dynamic.field(r2, "resolved")
  |> should.equal(Ok(dynamic.from(False)))
  dynamic.field(r2, "unread")
  |> should.equal(Ok(dynamic.from(False)))
}

// pub fn unread_messages_in_concluded_conversation_test() {
//   todo
// }
