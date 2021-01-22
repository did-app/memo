import gleam/dynamic
import gleam/io
import gleam/option.{None, Some}
import gleam/json
import gleam/pgo
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Personal}
import plum_mail/support
import plum_mail/conversation/group
import plum_mail/conversation/conversation.{
  DirectConversation, GroupConversation,
}
import plum_mail/threads/thread.{Memo}
import plum_mail/run_sql
import gleam/should

pub fn talking_to_a_unknown_identifier_test() {
  let alice = support.generate_personal_identifier("alice.test")
  assert Personal(id: alice_id, ..) = alice
  let bob_email = support.generate_email_address("bob.test")

  let memo = json.list([json.object([tuple("type", json.string("paragraph"))])])
  assert Ok(new_conversation) =
    conversation.start_direct(alice_id, bob_email, memo)

  assert Ok([DirectConversation(alice_contact, alice_participation)]) =
    conversation.all_participating(alice_id)
  assert Personal(id: bob_id, email_address: contact_email, ..) = alice_contact
  assert Ok(bob) = identifier.fetch_by_id(bob_id)

  contact_email
  |> should.equal(bob_email)
  alice_participation.acknowledged
  |> should.equal(1)
  assert Some(latest) = alice_participation.latest
  latest.content
  |> should.equal(memo)
  latest.position
  |> should.equal(1)
  assert Ok([DirectConversation(bob_contact, bob_participation)]) =
    conversation.all_participating(bob_id)
  bob_participation.acknowledged
  |> should.equal(0)
  bob_contact
  |> should.equal(alice)
  bob_participation.latest
  |> should.equal(alice_participation.latest)
}

pub fn answering_an_identifier_greeting_test() {
  let alice = support.generate_personal_identifier("alice.test")
  assert Personal(id: alice_id, ..) = alice
  let clive = support.generate_personal_identifier("clive.test")
  assert Personal(id: clive_id, email_address: clive_email, ..) = clive

  let greeting =
    json.list([json.object([tuple("dummy", json.string("greeting "))])])
  let greeting: pgo.PgType = dynamic.unsafe_coerce(dynamic.from(greeting))
  assert Ok(Some(_)) = identifier.update_greeting(clive_id, greeting)

  let memo = json.list([json.object([tuple("type", json.string("paragraph"))])])
  assert Ok(new_conversation) =
    conversation.start_direct(alice_id, clive_email, memo)

  assert Ok([DirectConversation(alice_contact, alice_participation)]) =
    conversation.all_participating(alice_id)
  assert Personal(id: clive_id, email_address: contact_email, ..) =
    alice_contact
  assert Ok(clive) = identifier.fetch_by_id(clive_id)

  contact_email
  |> should.equal(clive_email)
  alice_participation.acknowledged
  |> should.equal(2)
  assert Some(latest) = alice_participation.latest
  latest.content
  |> should.equal(memo)
  latest.position
  |> should.equal(2)
  assert Ok([DirectConversation(clive_contact, clive_participation)]) =
    conversation.all_participating(clive_id)
  clive_participation.acknowledged
  |> should.equal(1)
  clive_contact
  |> should.equal(alice)
  clive_participation.latest
  |> should.equal(alice_participation.latest)
}

pub fn create_a_group_test() {
  // Every identifier start off as a Personal identifier
  assert Personal(identifier_id, ..) =
    support.generate_personal_identifier("sendmemo.test")

  let name = Some("Memo Team")
  let first_member = support.generate_email_address("example.test")

  assert Ok(first_membership) =
    group.create_visible_group(name, identifier_id, first_member)

  let second_member = support.generate_email_address("example.test")
  assert Ok(second_membership) =
    group.add_member(first_membership.group_id, second_member)

  second_membership.group_id
  |> should.equal(first_membership.group_id)

  assert Ok([GroupConversation(group, participation)]) =
    conversation.all_participating(second_membership.identifier_id)

  participation.acknowledged
  |> should.equal(0)
  participation.latest
  |> should.equal(None)
}
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
