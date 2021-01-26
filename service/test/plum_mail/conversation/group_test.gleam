import gleam/io
import gleam/json
import plum_mail/error.{Forbidden}
import plum_mail/conversation/conversation.{GroupConversation}
import plum_mail/identifier
import gleam/should
import plum_mail/support

pub fn participating_in_a_group_conversation_test() {
  let alice = support.generate_personal_identifier("alice.test")
  let alice_id = identifier.id(alice)
  let bob = support.generate_personal_identifier("bob.test")
  let bob_id = identifier.id(bob)
  let eve = support.generate_personal_identifier("eve.test")
  let eve_id = identifier.id(eve)

  assert Ok(conversation) =
    conversation.create_group("My Group", alice_id, [bob_id])
  assert GroupConversation(group: group, ..) = conversation
  let thread_id = group.thread_id

  // Eve can't view the thread or add_members
  assert Error(error) = conversation.invite_member(group.id, bob_id, eve_id)
  assert Error(Forbidden) =
    conversation.post_memo(thread_id, 1, eve_id, eve_id, json.list([]))
  assert Error(Forbidden) = conversation.load_memos(thread_id, eve_id, eve_id)
  assert Error(Forbidden) = conversation.load_memos(thread_id, bob_id, eve_id)

  // assert Ok(_) = conversation.invite_member(group.id, bob_id, alice_id)
  assert Ok(_) =
    conversation.post_memo(thread_id, 1, alice_id, alice_id, json.list([]))

  // This memo might helpfully be the same as latest later in the test
  // Alice sees an up to date conversation
  assert Ok([conversation]) = conversation.all_participating(alice_id)
  assert GroupConversation(group: g, participation: p) = conversation
  g.name
  |> should.equal("My Group")
  p.acknowledged
  |> should.equal(1)

  // Bob sees an outstanding conversation
  assert Ok([conversation]) = conversation.all_participating(bob_id)
  assert GroupConversation(group: g, participation: p) = conversation
  g.name
  |> should.equal("My Group")
  p.acknowledged
  |> should.equal(0)
}
// pub fn create_a_group_test() {
//   // Every identifier start off as a Personal identifier
//   assert Personal(identifier_id, ..) =
//     support.generate_personal_identifier("sendmemo.test")
//   let name = Some("Memo Team")
//   let first_member = support.generate_email_address("example.test")
//   assert Ok(first_membership) =
//     group.create_visible_group(name, identifier_id, first_member)
//   let second_member = support.generate_email_address("example.test")
//   assert Ok(second_membership) =
//     group.add_member(first_membership.group_id, second_member)
//   second_membership.group_id
//   |> should.equal(first_membership.group_id)
//   assert Ok([GroupConversation(group, participation)]) =
//     conversation.all_participating(second_membership.identifier_id)
//   participation.acknowledged
//   |> should.equal(0)
//   participation.latest
//   |> should.equal(None)
// }
// invite someone peter@sendmemo.app
// Create a group then link it to a public address
// post memo to accept membership
// contacts should no longer show the 
// 
// Write an invitation event in the pair message stream which will trigger the pending accepted rejected
// The invidation is not active until a message has been sent.
// Can lookup all the people you have invided, who you haven't sent a message too, or who you arent in a pair with
// contacts can load all invided by, 
// needs an invited_by field
// So first member is in a group and they have accepted
// Both in a group start talking to someone
// a pending pair, can show shared conversations
// Use case of writing a group message.
// Invitation = membership where accepted != true
// pending | accepted | rejected
// pairs can also be in status accepted | pending. 
// if you start replying you should discover this.
