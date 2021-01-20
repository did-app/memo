import gleam/dynamic
import gleam/io
import gleam/json
import gleam/pgo
import plum_mail/email_address.{EmailAddress}
import plum_mail/support
import plum_mail/conversation/group
import plum_mail/conversation/conversation
import plum_mail/conversation/start_relationship
import plum_mail/threads/thread
import plum_mail/run_sql
import gleam/should

pub fn talking_to_a_new_individual_test() {
  // This needs to create an individual
  let alice = support.generate_individual("customer.test")

  // Start talking to bob who is not in the system
  let bob_email = support.generate_email_address("customer.test")

  // let params = start_relationship.Params(bob_email, json.list([]))
  // TODO return conversation view
  assert Ok(conversation) = conversation.start_direct(alice, bob_email)
  assert Ok(_) =
    thread.post_memo(conversation.thread_id, 1, alice.id, json.list([]))

  // This is alices view od the conversation
  assert Ok([alice_participation]) = conversation.all_participating(alice.id)

  alice_participation.acknowledged
  |> should.equal(1)
  // TODO test latest is the correct values
  // TODO fetch identifier id for bob
  // assert Ok([bob_participation]) = conversation.all_participating(bob.id)
  // bob_participation.acknowledged
  // |> should.equal(1)
  // Bobs view of the conversation will have a different ack level
}

pub fn create_a_group_test() {
  assert Ok(identifier) = support.generate_identifier("sendmemo.test")
  let name = "Memo Team"
  let first_member = support.generate_email_address("example.test")
  assert Ok(first_membership) =
    group.create_visible_group(name, identifier.id, first_member)
  // If your logged in as the team address then it should be unaccepted on the first member
  let second_member = support.generate_email_address("example.test")
  assert Ok(second_membership) =
    group.add_member(first_membership.group_id, second_member)
  second_membership.group_id
  |> should.equal(first_membership.group_id)

  assert Ok(groups) = group.load_all(second_membership.individual_id)
  io.debug(groups)
  assert Ok(threads) =
    conversation.all_participating(second_membership.individual_id)
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
