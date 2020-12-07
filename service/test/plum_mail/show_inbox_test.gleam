import gleam/dynamic
import gleam/option.{None, Some}
import gleam/io
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/start_conversation
import plum_mail/discuss/add_participant
import plum_mail/discuss/write_message
import plum_mail/discuss/show_inbox
import plum_mail/support
import gleam/should

pub fn unread_messages_in_conversation_test() {
  // Can left join on messages that were created before X pm
  // Ordered by most recent
  assert Ok(me) = support.generate_identifier("me.test")

  assert Ok(alice) = support.generate_identifier("alice.test")

  assert Ok(first) = discuss.validate_topic("First")
  assert Ok(c1) = start_conversation.execute(first, me.id)
  assert Ok(participation) = discuss.load_participation(c1.id, me.id)
  participation.invited_by
  |> should.equal(None)
  assert Ok(_) =
    add_participant.execute(
      participation,
      add_participant.Params(alice.email_address),
    )
  assert Ok(_) =
    write_message.execute(
      participation,
      write_message.Params("My Message", False),
    )

  assert Ok(second) = discuss.validate_topic("Second")
  assert Ok(c2) = start_conversation.execute(second, me.id)
  assert Ok(participation) = discuss.load_participation(c2.id, me.id)
  participation.invited_by
  |> should.equal(None)
  assert Ok(_) =
    add_participant.execute(
      participation,
      add_participant.Params(alice.email_address),
    )

  assert Ok(participation) = discuss.load_participation(c2.id, alice.id)
  participation.invited_by
  |> should.equal(Some(me.id))
  assert Ok(_) =
    write_message.execute(
      participation,
      write_message.Params("New message", False),
    )
  assert Ok(_) =
    write_message.execute(
      participation,
      write_message.Params("Next message", False),
    )

  assert Ok(inbox) = show_inbox.execute(me.id)
  assert Ok([r1, r2]) = dynamic.list(dynamic.from(inbox))

  // This is conversation 2
  dynamic.field(r1, "id")
  |> should.equal(Ok(dynamic.from(c2.id)))
  dynamic.field(r1, "topic")
  |> should.equal(Ok(dynamic.from("Second")))
  dynamic.field(r1, "closed")
  |> should.equal(Ok(dynamic.from(False)))
  dynamic.field(r1, "unread")
  |> should.equal(Ok(dynamic.from(True)))

  // dynamic.field(r1, "to_reply")
  // |> should.equal(Ok(dynamic.from(True)))
  dynamic.field(r2, "id")
  |> should.equal(Ok(dynamic.from(c1.id)))
  dynamic.field(r2, "topic")
  |> should.equal(Ok(dynamic.from("First")))
  dynamic.field(r2, "closed")
  |> should.equal(Ok(dynamic.from(False)))
  dynamic.field(r2, "unread")
  |> should.equal(Ok(dynamic.from(False)))
  // dynamic.field(r1, "to_reply")
  // |> should.equal(Ok(dynamic.from(False)))
  //
  // todo("mark c2 as concluded")
}
// pub fn unread_messages_in_concluded_conversation_test() {
//   todo
// }
