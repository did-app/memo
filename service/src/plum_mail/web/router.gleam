import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/map
import gleam/option.{Some}
import gleam/string
import gleam/result
import gleam/uri
import gleam/http/cowboy
import gleam/http.{Request, Response}
import gleam/json
import gleam/pgo
// Web/utils let session = utils.extractsession
import plum_mail/config
import plum_mail/error.{Reason}
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication.{Identifier}
import plum_mail/web/session
import plum_mail/web/helpers as web
import plum_mail/discuss/conversation
import plum_mail/discuss/start_conversation
import plum_mail/discuss/show_inbox
import plum_mail/discuss/add_participant
import plum_mail/discuss/write_message

pub fn redirect(uri: String) -> Response(BitBuilder) {
  let body =
    string.append("You are being redirected to ", uri)
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  http.Response(status: 303, headers: [tuple("location", uri)], body: body)
}

fn can_view(c, user_session) {
  try identifier_id = session.require_authentication(user_session)
  let conversation.Conversation(participants: participants, ..) = c
  list.find_map(
    participants,
    fn(participant: Identifier) {
      case participant.id == identifier_id {
        True -> Ok(identifier_id)
        False -> Error(Nil)
      }
    },
  )
  |> result.map_error(fn(_: Nil) { error.Forbidden })
}

pub fn route(
  request,
  config: config.Config,
) -> Result(Response(BitBuilder), Reason) {
  case http.path_segments(request) {
    ["inbox"] -> {
      try identifier_id =
        session.require_authentication(session.extract(request))
      try conversations = show_inbox.execute(identifier_id)
      // |> result.map_error(fn(x) { todo("mapping show inbox") })
      http.response(200)
      |> web.set_resp_json(json.object([tuple("conversations", conversations)]))
      |> Ok()
    }
    [] ->
      // Ok(http.set_resp_body(http.response(200), <<>>))
      todo("index")
    ["c", "create"] -> {
      try params = acl.parse_form(request)
      try topic = start_conversation.params(params)
      try identifier_id =
        session.require_authentication(session.extract(request))
      try conversation = start_conversation.execute(topic, identifier_id)
      redirect(string.append(
        string.append(config.client_origin, "/c/"),
        int.to_string(conversation.id),
      ))
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
    // This could be participant_id
    ["i", conversation_id, identifier_id] -> {
      let cookie_defaults = http.cookie_defaults(request.scheme)
      // TODO this needs to be a proper token
      let url = string.join([config.client_origin, "/c/", conversation_id], "")
      redirect(url)
      |> http.set_resp_cookie(
        "session",
        identifier_id,
        // http.CookieAttributes(..cookie_defaults, same_site: Some(http.None)),
        cookie_defaults,
      )
      |> Ok
    }
    // TODO AND corresponding delete
    ["c", id, "participant"] -> {
      assert Ok(id) = int.parse(id)
      try conversation = conversation.fetch_by_id(id)
      try author_id = can_view(conversation, session.extract(request))
      try params = acl.parse_json(request)
      try params = add_participant.params(params)
      try conversation = add_participant.execute(conversation, params)
      // FIXME do we need to update http
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    // FIXME should add concurrency control
    ["c", id, "message"] -> {
      assert Ok(id) = int.parse(id)
      try conversation = conversation.fetch_by_id(id)
      try author_id = can_view(conversation, session.extract(request))
      try params = acl.parse_json(request)
      io.debug(params)
      try params = write_message.params(params)
      try _ = write_message.execute(tuple(conversation.id, author_id), params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    ["c", id, "pin"] -> todo("Post pint")
  }
}

pub fn handle(
  request: Request(BitString),
  config: config.Config,
) -> Response(BitBuilder) {
  // Would be helpful if stdlib had an unwrap_or(route, error_response)
  // io.debug(request)
  case route(request, config) {
    Ok(response) -> response
    Error(reason) -> acl.error_response(reason)
  }
  |> http.prepend_resp_header(
    "access-control-allow-origin",
    config.client_origin,
  )
  |> http.prepend_resp_header("access-control-allow-credentials", "true")
  // |> io.debug()
}
