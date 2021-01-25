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
  DirectConversation,
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
