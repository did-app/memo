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
import gleam/httpc
import gleam/json
// Web/utils let session = utils.extractsession
import datetime
import plum_mail/config
import plum_mail/error.{Reason}
import plum_mail/acl
import plum_mail/authentication.{Identifier}
import plum_mail/web/helpers as web
import plum_mail/discuss/discuss.{Message, Pin}
import plum_mail/discuss/start_conversation
import plum_mail/discuss/show_inbox
import plum_mail/discuss/set_notification
import plum_mail/discuss/add_participant
import plum_mail/discuss/add_pin
import plum_mail/discuss/delete_pin
import plum_mail/discuss/write_message
import plum_mail/discuss/read_message

pub fn redirect(uri: String) -> Response(BitBuilder) {
  let body =
    string.append("You are being redirected to ", uri)
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  http.Response(status: 303, headers: [tuple("location", uri)], body: body)
}

fn load_cookies(request, client_origin) {
  let origin =
    http.get_req_header(request, "origin")
    |> option.from_result()
  let referrer =
    http.get_req_header(request, "referer`")
    |> option.from_result()
    |> option.map(fn(referrer) {
      assert Ok(referrer) = uri.parse(referrer)
      assert Ok(origin) = uri.origin(referrer)
      origin
    })

  // Test in router test, return 403 if cookies are set.
  // Would it be easier to return a single result/option
  assert Some(client_origin) = option.or(origin, referrer)

  let cookies = http.get_req_cookies(request)
  let refresh_token =
    list.key_find(cookies, "refresh")
    |> option.from_result()
  let session_token =
    list.key_find(cookies, "session")
    |> option.from_result()
  tuple(refresh_token, session_token)
}

fn load_session(request, client_origin) {
  let tuple(_, session_token) = load_cookies(request, client_origin)
  try session = option.to_result(session_token, error.Unauthenticated)
  authentication.load_session(session)
  |> result.map_error(fn(_: Nil) { error.Unauthenticated })
}

fn load_participation(conversation_id, request, client_origin) {
  try conversation_id =
    int.parse(conversation_id)
    |> result.map_error(fn(_: Nil) {
      error.BadRequest("Invalid conversation id")
    })
  try identifier_id = load_session(request, client_origin)
  discuss.load_participation(conversation_id, identifier_id)
}

pub fn route(
  request,
  config: config.Config,
) -> Result(Response(BitBuilder), Reason) {
  case http.path_segments(request) {
    ["authenticate"] -> {
      try params = acl.parse_json(request)
      try link_token = acl.optional(params, "link_token", acl.as_string)
      let tuple(refresh_token, _) = load_cookies(request, config.client_origin)
      assert tuple("user_agent", Ok(user_agent)) = tuple(
        "user_agent",
        http.get_req_header(request, "user-agent"),
      )
      try tuple(identifier, refresh_token, session_token) =
        authentication.authenticate(link_token, refresh_token, user_agent)
        |> result.map_error(fn(e) { error.Unauthenticated })
      let cookie_defaults = http.cookie_defaults(request.scheme)
      let data =
        json.object([
          tuple(
            "identifier",
            json.object([
              tuple("id", json.int(identifier.id)),
              tuple(
                "email_address",
                json.string(identifier.email_address.value),
              ),
            ]),
          ),
        ])
      http.response(200)
      |> web.set_resp_json(data)
      |> http.set_resp_cookie("session", session_token, cookie_defaults)
      |> http.set_resp_cookie(
        "refresh",
        refresh_token,
        http.CookieAttributes(..cookie_defaults, max_age: Some(604800)),
      )
      |> Ok
    }
    ["authenticate", "email"] -> {
      try params = acl.parse_json(request)
      try email_address = acl.required(params, "email_address", acl.as_email)
      try identifier = authentication.lookup_identifier(email_address)
      assert Ok(token) = authentication.generate_link_token(identifier.id)
      let config.Config(
        postmark_api_token: postmark_api_token,
        client_origin: client_origin,
      ) = config
      let body =
        [
          "
          <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
          <html xmlns=\"http://www.w3.org/1999/xhtml\">
            <head>
              <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
              <meta name=\"x-apple-disable-message-reformatting\" />
              <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
              <title></title>
            </head>
            <body>
              <main>
              Sign in to your plum mail account with the authentication link below
              <br>
              <br>
          ",
          "<a href=\"",
          client_origin,
          "/#code=",
          token,
          "\">Click here to sign in</a>
          </main>
          ",
        ]
        |> string.join("")
      let data =
        json.object([
          tuple("From", json.string("updates@plummail.co")),
          tuple("To", json.string(email_address.value)),
          tuple("Subject", json.string("Welcome back to plum mail")),
          // tuple("TextBody", json.string(message.content)),
          tuple("HtmlBody", json.string(body)),
        ])
      let request =
        http.default_req()
        |> http.set_method(http.Post)
        |> http.set_host("api.postmarkapp.com")
        |> http.set_path("/email")
        |> http.prepend_req_header("content-type", "application/json")
        |> http.prepend_req_header("accept", "application/json")
        |> http.prepend_req_header(
          "x-postmark-server-token",
          postmark_api_token,
        )
        |> http.set_req_body(json.encode(data))
      assert Ok(http.Response(status: 200, ..)) = httpc.send(request)
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<"{}":utf8>>))
      |> Ok
    }
    ["sign_out"] -> {
      // TODO delete the refresh token
      let cookie_defaults = http.cookie_defaults(request.scheme)
      redirect(string.append(config.client_origin, "/"))
      |> http.expire_resp_cookie("session", cookie_defaults)
      |> http.expire_resp_cookie("refresh", cookie_defaults)
      |> Ok
    }
    ["inbox"] -> {
      try identifier_id = load_session(request, config.client_origin)
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
      try identifier_id = load_session(request, config.client_origin)
      try conversation = start_conversation.execute(topic, identifier_id)
      try _ = case map.get(params, "participant") {
        Error(Nil) -> Ok(Nil)
        Ok(email_address) -> {
          try participation =
            load_participation(
              int.to_string(conversation.id),
              request,
              config.client_origin,
            )
          let params =
            dynamic.from(map.from_list([tuple("email_address", email_address)]))
          try params = add_participant.params(params)
          try _ = add_participant.execute(participation, params)
          Ok(Nil)
        }
      }
      redirect(string.append(
        string.append(config.client_origin, "/c/"),
        int.to_string(conversation.id),
      ))
      |> Ok
    }
    // This will need participation for cursor
    ["c", id] -> {
      try participation = load_participation(id, request, config.client_origin)
      try participants =
        discuss.load_participants(participation.conversation.id)
      try messages = discuss.load_messages(participation.conversation.id)
      try pins = discuss.load_pins(participation.conversation.id)
      let data =
        json.object([
          tuple(
            "conversation",
            discuss.conversation_to_json(participation.conversation),
          ),
          tuple(
            "participants",
            json.list(list.map(
              participants,
              fn(participant) {
                let Identifier(id: id, email_address: email_address) =
                  participant
                json.object([
                  tuple("id", json.int(id)),
                  tuple("email_address", json.string(email_address.value)),
                ])
              },
            )),
          ),
          tuple(
            "messages",
            json.list(list.map(
              messages,
              fn(message) {
                let Message(counter, content, inserted_at, identifier) = message
                let Identifier(email_address: email_address, ..) = identifier
                json.object([
                  tuple("counter", json.int(counter)),
                  tuple("content", json.string(content)),
                  tuple("author", json.string(email_address.value)),
                  tuple(
                    "inserted_at",
                    json.string(datetime.to_human(inserted_at)),
                  ),
                ])
              },
            )),
          ),
          tuple(
            "pins",
            json.list(list.map(
              pins,
              fn(pin) {
                let Pin(id, counter, identifier_id, content) = pin
                json.object([
                  tuple("id", json.int(id)),
                  tuple("counter", json.int(counter)),
                  tuple("identifier_id", json.int(identifier_id)),
                  tuple("content", json.string(content)),
                ])
              },
            )),
          ),
          tuple(
            "participation",
            json.object([
              tuple(
                "email_address",
                json.string(participation.identifier.email_address.value),
              ),
              tuple(
                "notify",
                json.string(discuss.notify_to_string(participation.notify)),
              ),
              tuple("cursor", json.int(participation.cursor)),
            ]),
          ),
        ])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }

    ["c", id, "participant"] -> {
      try params = acl.parse_json(request)
      try params = add_participant.params(params)
      try participation = load_participation(id, request, config.client_origin)
      try _ = add_participant.execute(participation, params)
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<"{}":utf8>>))
      |> Ok
    }
    ["c", id, "notify"] -> {
      try params = acl.parse_json(request)
      try params = set_notification.params(params)
      try participation = load_participation(id, request, config.client_origin)
      try _ = set_notification.execute(participation, params)
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<"{}":utf8>>))
      |> Ok
    }
    // FIXME should add concurrency control
    // Could be named write
    ["c", id, "message"] -> {
      try params = acl.parse_json(request)
      try params = write_message.params(params)
      try participation = load_participation(id, request, config.client_origin)
      try _ = write_message.execute(participation, params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    ["c", id, "read"] -> {
      try params = acl.parse_json(request)
      try params = read_message.params(params)
      try participation = load_participation(id, request, config.client_origin)
      try _ = read_message.execute(participation, params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    ["c", id, "pin"] -> {
      try params = acl.parse_json(request)
      try params = add_pin.params(params)
      try participation = load_participation(id, request, config.client_origin)
      try pin_id = add_pin.execute(participation, params)
      let data = json.object([tuple("id", json.int(pin_id))])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["c", id, "delete_pin"] -> {
      try params = acl.parse_json(request)
      try params = delete_pin.params(params)
      try participation = load_participation(id, request, config.client_origin)
      try _ = delete_pin.execute(participation, params)
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<"{}":utf8>>))
      |> Ok
    }
    _ ->
      http.response(404)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
  }
}

pub fn handle(
  request: Request(BitString),
  config: config.Config,
) -> Response(BitBuilder) {
  // Would be helpful if stdlib had an unwrap_or(route, error_response)
  // io.debug(request)
  case request.method {
    http.Options ->
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
    _ ->
      case route(request, config) {
        Ok(response) -> response
        Error(reason) -> acl.error_response(reason)
      }
  }
  |> http.prepend_resp_header(
    "access-control-allow-origin",
    config.client_origin,
  )
  |> http.prepend_resp_header("access-control-allow-credentials", "true")
  |> http.prepend_resp_header("access-control-allow-headers", "content-type")
  // |> io.debug()
}
