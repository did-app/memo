import gleam/io
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/http
import gleam/json
import plum_mail/authentication
import plum_mail/discuss/discuss
import plum_mail/discuss/start_conversation
import plum_mail/discuss/add_participant
import plum_mail/discuss/dispatch_email
import plum_mail/web/helpers
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

fn write_message(user_session, conversation_id, content, conclusion) {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation_id), "/message"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", user_session),
    )
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> helpers.set_req_json(json.object([
      tuple("content", json.string(content)),
      tuple("conclusion", json.bool(conclusion)),
    ]))

  handle(request, support.test_config())
}

pub fn write_test() {
  assert Ok(identifier) = support.generate_identifier("example.test")
  assert Ok(link_token) = authentication.generate_link_token(identifier.id)
  assert Ok(tuple(_, session_token)) =
    authentication.authenticate(Some(link_token), None, "ua")

  assert Ok(topic) = discuss.validate_topic("Test topic")
  assert Ok(conversation) = start_conversation.execute(topic, identifier.id)
  assert Ok(participation) =
    discuss.load_participation(conversation.id, identifier.id)

  let invited_email_address = support.generate_email_address("other.test")
  assert Ok(invited) =
    invited_email_address
    |> add_participant.Params
    |> add_participant.execute(participation, _)
  // assert Ok(tuple(_, other_session)) =
  //   authentication.generate_client_tokens(invited.0, "ua", None)
  assert Ok(link_token) = authentication.generate_link_token(invited.0)
  assert Ok(tuple(_, other_session)) =
    authentication.authenticate(Some(link_token), None, "ua")

  let response =
    write_message(session_token, conversation.id, "My first message", False)
  should.equal(response.status, 201)

  assert Ok([message]) = discuss.load_messages(conversation.id)
  message.counter
  |> should.equal(1)
  message.content
  |> should.equal("My first message")
  message.author
  |> should.equal(participation.identifier)

  assert Ok(participation) =
    discuss.load_participation(conversation.id, identifier.id)

  participation.cursor
  |> should.equal(1)

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
  case list.reverse(dispatches)
  |> list.head() {
    Ok(other) -> {
      other.id
      |> should.not_equal(message.id)
      Nil
    }
    _ -> Nil
  }

  assert Ok(participation) =
    discuss.load_participation(conversation.id, invited.0)

  participation.cursor
  |> should.equal(0)

  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation.id), "/read"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", other_session),
    )
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> helpers.set_req_json(json.object([tuple("counter", json.int(1))]))

  let response = handle(request, support.test_config())
  should.equal(response.status, 201)
  assert Ok(participation) =
    discuss.load_participation(conversation.id, invited.0)

  participation.cursor
  |> should.equal(1)
}
