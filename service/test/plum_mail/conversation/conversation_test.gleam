import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/json
import gleam/pgo
import plum_mail/identifier.{Personal}
import plum_mail/support
import plum_mail/conversation/conversation.{DirectConversation}
import plum_mail/threads/dispatch_notifications
import gleam/should

pub fn talking_to_a_unknown_identifier_test() {
  let alice = support.generate_personal_identifier("alice.test")
  assert Personal(id: alice_id, ..) = alice
  let bob_email = support.generate_email_address("bob.test")

  let memo =
    json.list([
      json.object([
        tuple("type", json.string("paragraph")),
        tuple("spans", json.list([])),
      ]),
    ])
  assert Ok(new_conversation) =
    conversation.start_direct(alice_id, alice_id, bob_email, memo)

  assert Ok([conversation]) = conversation.all_participating(alice_id)
  conversation
  |> should.equal(new_conversation)
  assert DirectConversation(alice_contact, alice_participation) = conversation
  assert Personal(id: bob_id, email_address: contact_email, ..) = alice_contact

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

  let loaded = dispatch_notifications.load()
  assert Ok(latest) =
    loaded
    |> list.at(list.length(loaded) - 1)

  latest.0
  |> should.equal(bob_id)
  latest.5
  |> should.equal(1)

  let thread_id = alice_participation.thread_id
  let content = json.list([])

  assert Ok(_) = conversation.post_memo(thread_id, 2, bob_id, bob_id, content)
  assert Ok([_, _]) = conversation.load_memos(thread_id, bob_id, bob_id)

  let eve = support.generate_personal_identifier("eve.test")
  let eve_id = identifier.id(eve)

  conversation.post_memo(thread_id, 3, eve_id, eve_id, content)
  // TODO make sure these return reports with Unprocessable
  // |> should.equal(Error(Forbidden))
  conversation.load_memos(thread_id, eve_id, eve_id)

  // TODO make sure these return reports with Unprocessable
  // |> should.equal(Error(Forbidden))
  let loaded = dispatch_notifications.load()
  assert Ok(latest) =
    loaded
    |> list.at(list.length(loaded) - 1)

  latest.0
  |> should.equal(alice_id)
  latest.5
  |> should.equal(2)
}

pub fn answering_an_identifier_greeting_test() {
  let alice = support.generate_personal_identifier("alice.test")
  assert Personal(id: alice_id, ..) = alice
  let clive = support.generate_personal_identifier("clive.test")
  assert Personal(id: clive_id, email_address: clive_email, ..) = clive

  let greeting =
    json.list([
      json.object([
        tuple("type", json.string("paragraph")),
        tuple("spans", json.list([])),
      ]),
    ])
  let greeting: json.Json = dynamic.unsafe_coerce(dynamic.from(greeting))
  assert Ok(Some(_)) = identifier.update_greeting(clive_id, greeting)

  let memo =
    json.list([
      json.object([
        tuple("type", json.string("paragraph")),
        tuple("spans", json.list([])),
      ]),
    ])
  assert Ok(new_conversation) =
    conversation.start_direct(alice_id, alice_id, clive_email, memo)

  assert Ok([conversation]) = conversation.all_participating(alice_id)
  conversation
  |> should.equal(new_conversation)
  assert DirectConversation(alice_contact, alice_participation) = conversation
  assert Personal(id: clive_id, email_address: contact_email, ..) =
    alice_contact

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

  let loaded = dispatch_notifications.load()
  assert Ok(latest) =
    loaded
    |> list.at(list.length(loaded) - 1)

  latest.0
  |> should.equal(clive_id)
  latest.5
  |> should.equal(2)
}
