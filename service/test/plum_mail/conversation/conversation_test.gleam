import gleam/dynamic
import gleam/io
import gleam/option.{Some}
import gleam/json
import gleam/pgo
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Personal}
import plum_mail/support
import plum_mail/conversation/group
import plum_mail/conversation/conversation
import plum_mail/threads/thread.{Memo}
import plum_mail/run_sql
import gleam/should

pub fn talking_to_a_unknown_identifier_test() {
  let alice = support.generate_personal_identifier("alice.test")
  assert Personal(id: alice_id, ..) = alice
  let bob_email = support.generate_email_address("bob.test")

  let memo = json.list([json.object([tuple("type", json.string("paragraph"))])])
  assert Ok(contact) = conversation.start_direct(alice_id, bob_email, memo)

  assert Ok([alice_contact]) = conversation.all_participating(alice_id)
  assert Personal(id: bob_id, email_address: contact_email, ..) =
    alice_contact.identifier
  assert Ok(bob) = identifier.fetch_by_id(bob_id)

  contact_email
  |> should.equal(bob_email)

  alice_contact.thread.acknowledged
  |> should.equal(1)
  assert Some(latest) = alice_contact.thread.latest
  latest.content
  |> should.equal(memo)
  latest.position
  |> should.equal(1)

  assert Ok([bob_contact]) = conversation.all_participating(bob_id)
  bob_contact.thread.acknowledged
  |> should.equal(0)
  bob_contact.identifier
  |> should.equal(alice)
  bob_contact.thread.latest
  |> should.equal(alice_contact.thread.latest)
}

pub fn answering_an_identifier_greeting_test() {
  let alice = support.generate_personal_identifier("alice.test")
  assert Personal(id: alice_id, ..) = alice

  let clive = support.generate_personal_identifier("clive.test")
  assert Personal(id: clive_id, email_address: clive_email, ..) = clive

  let memo = json.list([json.object([tuple("type", json.string("paragraph"))])])
  assert Ok(contact) = conversation.start_direct(alice_id, clive_email, memo)

  assert Ok([alice_contact]) = conversation.all_participating(alice_id)
  assert Personal(id: clive_id, email_address: contact_email, ..) =
    alice_contact.identifier
  assert Ok(clive) = identifier.fetch_by_id(clive_id)

  contact_email
  |> should.equal(clive_email)

  alice_contact.thread.acknowledged
  |> should.equal(1)
  assert Some(latest) = alice_contact.thread.latest
  latest.content
  |> should.equal(memo)
  latest.position
  |> should.equal(1)

  assert Ok([clive_contact]) = conversation.all_participating(clive_id)
  clive_contact.thread.acknowledged
  |> should.equal(0)
  clive_contact.identifier
  |> should.equal(alice)
  clive_contact.thread.latest
  |> should.equal(alice_contact.thread.latest)
}

pub fn create_a_group_test() {
  // Every identifier start off as a Personal identifier
  assert Personal(identifier_id, ..) =
    support.generate_personal_identifier("sendmemo.test")

  let name = "Memo Team"
  let first_member = support.generate_email_address("example.test")

  assert Ok(first_membership) =
    group.create_visible_group(name, identifier_id, first_member)
  // If your logged in as the team address then it should be unaccepted on the first member
  let second_member = support.generate_email_address("example.test")
  assert Ok(second_membership) =
    group.add_member(first_membership.group_id, second_member)
  second_membership.group_id
  |> should.equal(first_membership.group_id)
  assert Ok(groups) = group.load_all(second_membership.identifier_id)
  io.debug(groups)
  assert Ok(threads) =
    conversation.all_participating(second_membership.identifier_id)
  // After accepting invitation to a group you need all the groups you are a member of
  // Separate permission from participation, participation is the accepted blah blah
  todo("create visible group with first member")
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
