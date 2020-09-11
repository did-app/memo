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
// Web/utils let session = utils.extractsession
import datetime
import plum_mail/config
import plum_mail/error.{Reason}
import plum_mail/acl
import plum_mail/authentication.{Identifier}
import plum_mail/web/helpers as web
import plum_mail/discuss/discuss.{Message}
import plum_mail/discuss/start_conversation
import plum_mail/discuss/show_inbox
import plum_mail/discuss/set_notification
import plum_mail/discuss/add_participant
import plum_mail/discuss/add_pin
import plum_mail/discuss/write_message
import plum_mail/discuss/read_message

pub fn redirect(uri: String) -> Response(BitBuilder) {
  let body =
    string.append("You are being redirected to ", uri)
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  http.Response(status: 303, headers: [tuple("location", uri)], body: body)
}

fn load_session(request) {
  let cookies = http.get_req_cookies(request)
  try session =
    list.key_find(cookies, "session")
    |> result.map_error(fn(_: Nil) { error.Unauthenticated })
  authentication.load_session(session)
  |> result.map_error(fn(_: Nil) { error.Unauthenticated })
}

fn load_participation(conversation_id, request) {
  try conversation_id =
    int.parse(conversation_id)
    |> result.map_error(fn(_: Nil) {
      error.BadRequest("Invalid conversation id")
    })
  try identifier_id = load_session(request)
  discuss.load_participation(conversation_id, identifier_id)
}

pub fn route(
  request,
  config: config.Config,
) -> Result(Response(BitBuilder), Reason) {
  case http.path_segments(request) {
    ["authenticate"] -> {
      io.debug(request)
      try params = acl.parse_json(request)
      try link_token = acl.optional(params, "link_token", acl.as_string)
      let cookies = http.get_req_cookies(request)
      let refresh_token =
        list.key_find(cookies, "refresh")
        |> option.from_result()
      assert tuple("user_agent", Ok(user_agent)) = tuple(
        "user_agent",
        http.get_req_header(request, "user-agent"),
      )
      io.debug(refresh_token)
      try tuple(refresh_token, session_token) =
        authentication.authenticate(link_token, refresh_token, user_agent)
        |> result.map_error(fn(e) { todo("map auth error") })
      let cookie_defaults = http.cookie_defaults(request.scheme)
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> http.set_resp_cookie("session", session_token, cookie_defaults)
      |> http.set_resp_cookie(
        "refresh",
        refresh_token,
        http.CookieAttributes(..cookie_defaults, max_age: Some(604800)),
      )
      |> Ok
    }
    ["inbox"] -> {
      try identifier_id = load_session(request)
      try conversations = show_inbox.execute(identifier_id)
      // |> result.map_error(fn(x) { todo("mapping show inbox") })
      // If this conversations is the same as the top level conversation object for a page,
      // it can be the start value when switching pages
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
      try identifier_id = load_session(request)
      try conversation = start_conversation.execute(topic, identifier_id)
      redirect(string.append(
        string.append(config.client_origin, "/c/"),
        int.to_string(conversation.id),
      ))
      |> Ok
    }
    // This will need participation for cursor
    ["c", id] -> {
      try participation = load_participation(id, request)
      try participants =
        discuss.load_participants(participation.conversation.id)
      try messages = discuss.load_messages(participation.conversation.id)
      try pins = discuss.load_pins(participation.conversation.id)
      let c = participation.conversation
      let c = discuss.Conversation(..c, participants: participants)
      // TODO fix the conversation updates.
      let body =
        json.object([
          tuple("conversation", discuss.conversation_to_json(c)),
          tuple(
            "messages",
            json.list(list.map(
              messages,
              fn(message) {
                let Message(counter, content, inserted_at, identifier) = message
                let Identifier(email_address: email_address, ..) = identifier
                json.object([
                  tuple("content", json.string(content)),
                  tuple("author", json.string(email_address)),
                  tuple(
                    "inserted_at",
                    json.string(datetime.to_human(inserted_at)),
                  ),
                ])
              },
            )),
          ),
          tuple("pins", json.list(list.map(pins, fn(p) { json.string(p) }))),
          tuple(
            "participation",
            json.object([
              tuple(
                "email_address",
                json.string(participation.identifier.email_address),
              ),
              tuple(
                "nickname",
                json.nullable(participation.identifier.nickname, json.string),
              ),
              tuple(
                "notify",
                json.string(discuss.notify_to_string(participation.notify)),
              ),
            ]),
          ),
        ])
        |> json.encode()
        |> bit_string.from_string
        |> bit_builder.from_bit_string
      http.response(200)
      |> http.set_resp_body(body)
      |> Ok
    }

    ["c", id, "participant"] -> {
      try params = acl.parse_json(request)
      try params = add_participant.params(params)
      try participation = load_participation(id, request)
      try _ = add_participant.execute(participation, params)
      // FIXME do we need to update http
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    ["c", id, "notify"] -> {
      try params = acl.parse_json(request)
      try params = set_notification.params(params)
      try participation = load_participation(id, request)
      try _ = set_notification.execute(participation, params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    // FIXME should add concurrency control
    // Could be named write
    ["c", id, "message"] -> {
      try params = acl.parse_json(request)
      try params = write_message.params(params)
      try participation = load_participation(id, request)
      try _ = write_message.execute(participation, params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    ["c", id, "read"] -> {
      try params = acl.parse_json(request)
      try params = read_message.params(params)
      try participation = load_participation(id, request)
      try _ = read_message.execute(participation, params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    ["c", id, "pin"] -> {
      try params = acl.parse_json(request)
      try params = add_pin.params(params)
      try participation = load_participation(id, request)
      try _ = add_pin.execute(participation, params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
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
