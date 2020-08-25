import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/int
import gleam/map
import gleam/string
import gleam/uri
import gleam/http/cowboy
import gleam/http.{Request, Response}
import gleam/json
// Web/utils let session = utils.extractsession
import plum_mail/authentication
import plum_mail/web/session
import plum_mail/discuss/conversation
import plum_mail/discuss/start_conversation
import plum_mail/discuss/add_participant

pub fn redirect(uri: String) -> Response(BitBuilder) {
  let body =
    string.append("You are being redirected to ", uri)
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  http.Response(status: 303, headers: [tuple("location", uri)], body: body)
}

fn error_response(_) {
  todo("implement error response")
}

fn parse_form(request: Request(_)) {
  case request.method {
    http.Post -> {
      try body = bit_string.to_string(request.body)
      case uri.parse_query(body) {
        Ok(params) -> Ok(map.from_list(params))
        _ -> todo("bad quert")
      }
    }
    _ -> todo("incorrect method")
  }
}

fn create_conversation_params(request) {
  try form = parse_form(request)
  map.get(form, "topic")
}

fn add_participant_params(request) {
  try form = parse_form(request)
  map.get(form, "email_address")
}

fn can_view(conversation, session) {
  let identifier_id = 1
  Ok(identifier_id)
}

pub fn route(request) {
  case http.path_segments(request) {
    [] -> {
      let body =
        "Hello, world!"
        |> bit_string.from_string
        |> bit_builder.from_bit_string
      http.response(200)
      |> http.set_resp_body(body)
      |> Ok
    }
    ["sign_in"] -> {
      try form = parse_form(request)
      try email_address = map.get(form, "email_address")
      let Ok(identifier_id) =
        authentication.identifier_from_email(email_address)
      redirect("/")
      |> http.set_resp_cookie(
        "session",
        int.to_string(identifier_id),
        http.cookie_defaults(request.scheme),
      )
      |> Ok
    }
    ["c", "create"] -> {
      try topic = create_conversation_params(request)
      try identifier_id =
        session.require_authentication(session.extract(request))
      try conversation = start_conversation.execute(topic, identifier_id)
      redirect(string.append("/c/", int.to_string(conversation.id)))
      |> Ok
    }
    ["c", id] -> {
      assert Ok(id) = int.parse(id)
      try c = conversation.fetch_by_id(id)
      try author_id = can_view(c, session.extract(request))
      let body = conversation.to_json(c)
      http.response(200)
      |> http.set_resp_body(body)
      |> Ok
    }
    // AND corresponding delete
    ["c", id, "participant"] -> {
      assert Ok(id) = int.parse(id)
      try conversation = conversation.fetch_by_id(id)
      try author_id = can_view(conversation, session.extract(request))
      try email_address = add_participant_params(request)
      try conversation = add_participant.execute(conversation, email_address)
      // FIXME do we need to update http
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    // FIXME should add concurrency control
    ["c", id, "message"] -> todo("Post message")
    ["c", id, "pin"] -> todo("Post pint")
  }
}

pub fn handle(request: Request(BitString)) -> Response(BitBuilder) {
  // Would be helpful if stdlib had an unwrap_or(route, error_response)
  case route(request) {
    Ok(response) -> response
    Error(reason) -> error_response(reason)
  }
}
