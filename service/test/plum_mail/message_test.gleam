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
import plum_mail/web/helpers as web
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

fn write_message(identifier_id, conversation_id, content, conclusion) {
  let config = support.test_config()
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation_id), "/message"],
      "",
    ))
    |> http.set_req_cookie(
      "token",
      web.auth_token(identifier_id, "ua-test", config.secret),
    )
    |> http.prepend_req_header("user-agent", "ua-test")
    |> http.prepend_req_header("origin", config.client_origin)
    |> web.set_req_json(json.object([
      tuple("content", json.string(content)),
      tuple("conclusion", json.bool(conclusion)),
    ]))

  handle(request, support.test_config())
}

pub fn write_test() {
  assert Ok(identifier) = support.generate_identifier("example.test")

  assert Ok(topic) = discuss.validate_topic("Test topic")
  assert Ok(conversation) = start_conversation.execute(topic, identifier.id)
  assert Ok(participation) =
    discuss.load_participation(conversation.id, identifier.id)

  let invited_email_address = support.generate_email_address("other.test")
  assert Ok(invited) =
    invited_email_address
    |> add_participant.Params
    |> add_participant.execute(participation, _)

  let response =
    write_message(identifier.id, conversation.id, "My first message", False)
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
    |> http.set_req_cookie(
      "token",
      web.auth_token(invited.0, "ua-test", support.test_config().secret),
    )
    |> http.prepend_req_header("origin", support.test_config().client_origin)
    |> http.prepend_req_header("user-agent", "ua-test")
    |> web.set_req_json(json.object([tuple("counter", json.int(1))]))

  let response = handle(request, support.test_config())
  should.equal(response.status, 201)
  assert Ok(participation) =
    discuss.load_participation(conversation.id, invited.0)

  participation.cursor
  |> should.equal(1)
}
