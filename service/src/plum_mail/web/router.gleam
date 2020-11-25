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
import plum_mail
import plum_mail/config
import plum_mail/error.{Reason}
import plum_mail/acl
import plum_mail/authentication.{Identifier}
import plum_mail/authentication/claim_email_address
import plum_mail/profile
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
import plum_mail/email/inbound/postmark

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
    // Hardcoded because we don't want password word field on db model yet.
    // looking at alternative (OAuth) solutions
    // This doesn't work properly, but we want to down grade the complexity of authentication for a bit.
    ["authenticate", name, password] -> {
      assert Ok(email_address) = case name {
        "peter" -> {
          let True = password == "onion"
          assert Ok(email_address) =
            authentication.validate_email("peter@plummail.co")
          Ok(email_address)
        }
      }
      assert Ok(identifier) = authentication.lookup_identifier(email_address)
      assert Ok(link_token) = authentication.generate_link_token(identifier.id)
      assert Ok(tuple(_, refresh_token, session_token)) =
        authentication.authenticate(Some(link_token), option.None, "ua TODO")
      let cookie_defaults = http.cookie_defaults(request.scheme)
      io.debug(refresh_token)
      redirect(string.append(config.client_origin, "/"))
      |> http.set_resp_cookie("session", session_token, cookie_defaults)
      |> http.set_resp_cookie(
        "refresh",
        refresh_token,
        http.CookieAttributes(..cookie_defaults, max_age: Some(604800)),
      )
      |> Ok
      |> io.debug()
    }
    ["authenticate"] -> {
      try params = acl.parse_json(request)
      io.debug(params)
      try link_token = acl.optional(params, "link_token", acl.as_string)
      let tuple(refresh_token, _) = load_cookies(request, config.client_origin)
      io.debug(refresh_token)
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
      try params = claim_email_address.params(params)
      try _ = claim_email_address.execute(params, config)
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
    ["contact", label] -> {
      try profile = profile.lookup(label)
      let data = json.object([tuple("greeting", json.string(profile.greeting))])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok()
    }
    ["welcome"] -> {
      io.debug(request)
      try params = acl.parse_form(request)
      assert Ok(topic) = map.get(params, "topic")
      assert Ok(topic) = discuss.validate_topic(topic)
      assert Ok(author_id) = map.get(params, "author_id")
      assert Ok(author_id) = int.parse(author_id)
      // TODO email lib should have comma separated parser
      assert Ok(cc) = map.get(params, "cc")
      assert Ok(cc) = authentication.validate_email(cc)
      assert Ok(message) = map.get(params, "message")
      assert Ok(email_address) = map.get(params, "email")
      assert Ok(email_address) = authentication.validate_email(email_address)
      try conversation = start_conversation.execute(topic, author_id)
      assert Ok(author_participation) =
        discuss.load_participation(conversation.id, author_id)
      let params = write_message.Params(content: message, conclusion: False)
      try _ = write_message.execute(author_participation, params)
      // let identifier = case authentication.lookup_identifier(email_address) {
      //   Ok(identifier) -> identifier
      //   Error(_) -> {
      //     assert Ok(identifier) =
      //       plum_mail.identifier_from_email(dynamic.from(email_address.value))
      //     identifier
      //   }
      // }
      let params = add_participant.Params(cc)
      assert Ok(_) = add_participant.execute(author_participation, params)
      let params = add_participant.Params(email_address)
      assert Ok(_) = add_participant.execute(author_participation, params)
      Nil
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<"message sent":utf8>>))
      |> Ok
    }
    // This might not be a good name as we want a to introduce b
    // this might be reach out or something.
    ["introduction", label] -> {
      try params = acl.parse_form(request)
      assert Ok(topic) = map.get(params, "subject")
      assert Ok(topic) = discuss.validate_topic(topic)
      assert Ok(message) = map.get(params, "message")
      assert Ok(from) = map.get(params, "from")
      assert Ok(from) = authentication.validate_email(from)
      let identifier = case authentication.lookup_identifier(from) {
        Ok(identifier) -> identifier
        Error(_) -> {
          assert Ok(identifier) =
            plum_mail.identifier_from_email(dynamic.from(from.value))
          identifier
        }
      }
      try conversation = start_conversation.execute(topic, identifier.id)
      assert Ok(starter_participation) =
        discuss.load_participation(conversation.id, identifier.id)
      let params = write_message.Params(content: message, conclusion: False)
      try _ = write_message.execute(starter_participation, params)
      let email_address = string.concat([label, "@plummail.co"])
      let addresses = case email_address == "team@plummail.co" {
        True -> ["peter@plummail.co", "richard@plummail.co"]
        False -> [email_address]
      }
      // TODO need a load participation function that takes integers
      list.each(
        addresses,
        fn(email_address) {
          assert Ok(email_address) =
            authentication.validate_email(email_address)
          let params = add_participant.Params(email_address)
          // TODO note why does this not return participation
          assert Ok(tuple(identifier_id, conversation_id)) =
            add_participant.execute(starter_participation, params)
          Nil
        },
      )
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<"message sent":utf8>>))
      |> Ok
    }
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
    ["inbound"] -> {
      try params = acl.parse_json(request)
      postmark.handle(params, config)
      |> io.debug
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
  let response = case request.method {
    http.Options ->
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
    _ ->
      case route(request, config) {
        Ok(response) -> response
        Error(reason) -> acl.error_response(reason)
      }
  }
  case request.path {
    "/welcome" ->
      response
      |> http.prepend_resp_header("access-control-allow-origin", "*")
    _ ->
      response
      // TODO put everthing under /api /client
      |> http.prepend_resp_header(
        "access-control-allow-origin",
        // TODO does this need limiting to just the client origin
        // can't be wild card with credentials included
        config.client_origin,
      )
      |> http.prepend_resp_header("access-control-allow-credentials", "true")
      |> http.prepend_resp_header(
        "access-control-allow-headers",
        "content-type",
      )
  }
  // |> io.debug()
}
