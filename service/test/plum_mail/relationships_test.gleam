import gleam/dynamic
import gleam/io
import gleam/pgo
import plum_mail/email_address.{EmailAddress}
import plum_mail/support
import plum_mail/conversation/group
import plum_mail/conversation/participation
import plum_mail/run_sql
import gleam/should

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
    participation.participation(second_membership.individual_id)
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
