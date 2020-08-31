import gleam/io
import gleam/int
import gleam/list
import gleam/string
import gleam/http
import gleam/json
import plum_mail/authentication.{Identifier}
import plum_mail/discuss/start_conversation
import plum_mail/discuss/add_participant
import plum_mail/discuss/dispatch_email
import plum_mail/web/helpers
import plum_mail/web/session
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

pub fn write_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier) = authentication.identifier_from_email(email_address)
  let user_session = session.authenticated(identifier.id)
  let topic = "Test topic"

  assert Ok(conversation) = start_conversation.execute(topic, identifier.id)

  let invited_email_address = support.generate_email_address("other.test")
  assert Ok(invited) =
    invited_email_address
    |> add_participant.Params
    |> add_participant.execute(conversation, _)
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation.id), "/message"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", session.to_string(user_session)),
    )
    |> helpers.set_req_json(json.object([
      tuple("content", json.string("My first message")),
      tuple("resolve", json.bool(False)),
    ]))

  let response = handle(request, support.test_config())
  should.equal(response.status, 201)

  let tuple(_id, topic, participants, messages) =
    support.get_conversation(conversation.id, session.to_string(user_session))

  messages
  |> should.equal([tuple("My first message")])

  assert Ok(dispatches) = dispatch_email.load()
  assert Ok(message) =
    list.reverse(dispatches)
    |> list.head()

  should.equal(message.to.email_address, invited_email_address)
  // should.equal(message.from, "")
  should.equal(message.conversation, tuple(conversation.id, topic))
  should.equal(message.content, "My first message")

  assert Ok(_) = dispatch_email.record_sent(message)

  assert Ok(dispatches) = dispatch_email.load()
  assert Ok(other) =
    list.reverse(dispatches)
    |> list.head()
  other.id
  |> should.not_equal(message.id)
}
