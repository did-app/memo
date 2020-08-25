import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/string
import gleam/http
import gleam/json
import plum_mail/authentication
import plum_mail/discuss/start_conversation
import plum_mail/web/session
import plum_mail/web/router.{handle}
import plum_mail/support
import gleam/should

fn get_conversation(id, session) {
  let request =
    http.default_req()
    |> http.set_path(string.append("/c/", int.to_string(id)))
    |> http.prepend_req_header("cookie", string.append("session=", session))
    |> http.set_req_body(<<>>)
  handle(request)
}

pub fn add_participant_test() {
  let email_address = support.generate_email_address("example.test")
  assert Ok(identifier_id) = authentication.identifier_from_email(email_address)
  let user_session = session.authenticated(identifier_id)
  let topic = "Test topic"
  // conversation, could be domain and entity is thread/topic
  assert Ok(conversation_id) = start_conversation.execute(topic, identifier_id)

  io.debug(conversation_id)
  let http.Response(body: body, ..) =
    get_conversation(conversation_id, session.to_string(user_session))
  let body = bit_builder.to_bit_string(body)
  try body = bit_string.to_string(body)
  assert Ok(data) = json.decode(body)
  let data = dynamic.from(data)
  assert Ok(data) = dynamic.field(data, "conversation")
  assert Ok(participants) = dynamic.field(data, "participants")
  assert Ok(participants) = dynamic.typed_list(participants, dynamic.string)

  let invited = support.generate_email_address("example.test")
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path(string.join(
      ["/c/", int.to_string(conversation_id), "/participant"],
      "",
    ))
    |> http.prepend_req_header(
      "cookie",
      string.append("session=", session.to_string(user_session)),
    )
    |> http.set_req_body(bit_string.append(
      <<"email_address+":utf8>>,
      bit_string.from_string(invited),
    ))

  let response = handle(request)
  should.equal(response.status, 200)
  participants
  |> io.debug()
  todo
}
// TODO validate invalid email address etc
