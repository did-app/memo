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
import plum_mail/run_sql
import plum_mail/authentication
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

fn error_response(_) {
  // todo("implement error response")
  http.response(401)
  |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
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

fn json_params(request: http.Request(BitString)) {
  try body = bit_string.to_string(request.body)
  try data =
    json.decode(body)
    |> result.map_error(fn(_) { todo })
  dynamic.from(data)
  |> Ok
}

fn can_view(c, user_session) {
  try identifier_id = session.require_authentication(user_session)
  let conversation.Conversation(participants: participants, ..) = c
  list.find_map(
    participants,
    fn(participant) {
      let tuple(participant_id, _) = participant
      case participant_id == identifier_id {
        True -> Ok(identifier_id)
        False -> Error(Nil)
      }
    },
  )
}

pub fn route(
  request,
  config: config.Config,
) -> Result(Response(BitBuilder), Nil) {
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
    [] -> // http.response(200)
      // |> http.set_resp_body(<<>>)
      // |> Ok()
      // |> result.map_error(fn(x) { todo("mapping show inbox") })
      // Ok(http.set_resp_body(http.response(200), <<>>))
      todo("index")
    ["c", "create"] -> {
      try topic = create_conversation_params(request)
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
      try params = json_params(request)
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
      try params = json_params(request)
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
  case route(request, config) {
    Ok(response) -> response
    Error(reason) -> error_response(reason)
  }
  |> http.prepend_resp_header(
    "access-control-allow-origin",
    config.client_origin,
  )
  |> http.prepend_resp_header("access-control-allow-credentials", "true")
}
