import gleam/dynamic
import gleam/io
import gleam/pgo
import plum_mail/email_address.{EmailAddress}
import plum_mail/support
import plum_mail/run_sql
import gleam/should

pub type Membership {
  Membership(group_id: Int, individual_id: Int)
}

pub fn create_visible_group(name, identifier_id, first_member) {
  let EmailAddress(first_member) = first_member
  // log in as individual will see unconfirmed memberships and be able to cancel as need be
  // So to create a visible group you need to be logged in as the address
  // create group, attach profile
  let sql =
    "
    WITH new_group AS (
      INSERT INTO groups (name)
      VALUES ($1)
      RETURNING id, name
    ), group_identifier AS (
      UPDATE identifiers
      SET group_id = (SELECT id FROM new_group)
      WHERE id = $2
      AND group_id IS NULL
    ), new_individual AS (
      INSERT INTO identifiers (email_address)
      VALUES ($3)
      ON CONFLICT DO NOTHING
      RETURNING *
    ), invited AS (
        SELECT id FROM new_individual
      UNION ALL
        SELECT id FROM identifiers 
        WHERE email_address = $3
    )

    INSERT INTO invitations(group_id, individual_id)
    VALUES ((SELECT id FROM new_group), (SELECT id FROM invited))
    RETURNING group_id, individual_id;
    "
  // let args = [pgo.nullable(name, pgo.text)]
  let args = [pgo.text(name), pgo.int(identifier_id), pgo.text(first_member)]
  try [membership] = run_sql.execute(sql, args, row_to_membership)
  membership
  |> Ok
}

fn row_to_membership(row) {
  assert Ok(group_id) = dynamic.element(row, 0)
  assert Ok(group_id) = dynamic.int(group_id)
  assert Ok(individual_id) = dynamic.element(row, 1)
  assert Ok(individual_id) = dynamic.int(individual_id)
  Membership(group_id, individual_id)
}

pub fn add_member(group_id, new_member) {
  let EmailAddress(new_member) = new_member

  let sql =
    "
    WITH new_individual AS (
      INSERT INTO identifiers (email_address)
      VALUES ($2)
      ON CONFLICT DO NOTHING
      RETURNING *
    ), invited AS (
        SELECT id FROM new_individual
      UNION ALL
        SELECT id FROM identifiers 
        WHERE email_address = $2
    )
    INSERT INTO invitations(group_id, individual_id)
    VALUES ($1, (SELECT id FROM invited))
    RETURNING group_id, individual_id;
    "
  let args = [pgo.int(group_id), pgo.text(new_member)]
  try [membership] = run_sql.execute(sql, args, row_to_membership)
  membership
  |> Ok
}

pub fn create_a_group_test() {
  assert Ok(identifier) = support.generate_identifier("sendmemo.test")
  let name = "Memo Team"
  let first_member = support.generate_email_address("example.test")
  assert Ok(first_membership) =
    create_visible_group(name, identifier.id, first_member)
  // If your logged in as the team address then it should be unaccepted on the first member
  let second_member = support.generate_email_address("example.test")
  assert Ok(second_membership) =
    add_member(first_membership.group_id, second_member)
  second_membership.group_id
  |> should.equal(first_membership.group_id)

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
