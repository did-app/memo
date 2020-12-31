import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/map
import gleam/option.{None, Some}
import gleam/string
import gleam/result
import gleam/uri
import gleam/http/cowboy
import gleam/http.{Request, Response}
import gleam/httpc
import gleam/json
import gleam/pgo
// Web/utils let session = utils.extractsession
import datetime
import plum_mail
import plum_mail/config.{Config}
import plum_mail/error.{Reason}
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/authentication/authenticate_by_code
import plum_mail/authentication/authenticate_by_password
import plum_mail/authentication/claim_email_address
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Identifier}
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
import plum_mail/threads/thread
import plum_mail/threads/acknowledge
import plum_mail/relationships/lookup_relationship
import plum_mail/relationships/start_relationship
import plum_mail/email/inbound/postmark

fn load_participation(conversation_id, request, config) {
  try conversation_id =
    int.parse(conversation_id)
    |> result.map_error(fn(_: Nil) {
      error.BadRequest("Invalid conversation id")
    })
  try identifier_id = web.identify_client(request, config)
  discuss.load_participation(conversation_id, identifier_id)
}

fn token_cookie_settings(request) {
  let Request(scheme: scheme, ..) = request
  let defaults = http.cookie_defaults(scheme)
  // The policy needs to be none because we call from memo.did.app to herokuapp
  let same_site_policy = case defaults.secure {
    True -> http.None
    False -> http.Lax
  }
  http.CookieAttributes(..defaults, max_age: Some(604800), same_site: Some(http.None), secure: True)
}

fn successful_authentication(identifier, request, config) {
  let Identifier(id: identifier_id, ..) = identifier
  let Config(secret: secret, ..) = config
  assert Ok(user_agent) = http.get_req_header(request, "user-agent")
  let token = web.auth_token(identifier_id, user_agent, secret)
  http.response(200)
  |> web.set_resp_json(identifier.to_json(identifier))
  |> http.set_resp_cookie("token", token, token_cookie_settings(request))
  |> Ok
}

// Responds with 200 and valid JSON object to make life easier in Client
fn no_content() {
  http.response(200)
  |> http.set_resp_body(bit_builder.from_bit_string(<<"{}":utf8>>))
  |> Ok
}

fn latest_to_json(latest) {
  let tuple(inserted_at, content) = latest
  json.object([
    tuple("inserted_at", json.string(datetime.to_iso8601(inserted_at))),
    tuple("content", content),
  ])
}

fn contact_to_json(contact) {
  let tuple(identifier, outstanding, inserted_at, content) = contact
  let latest_json = case inserted_at {
    None -> json.null()
    Some(inserted_at) -> latest_to_json(tuple(inserted_at, content))
  }
  json.object([
    tuple("identifier", identifier.to_json(identifier)),
    tuple("outstanding", json.bool(outstanding)),
    tuple("latest", latest_json),
  ])
}

pub fn route(
  request,
  config: config.Config,
) -> Result(Response(BitBuilder), Reason) {
  case http.path_segments(request) {
    [] -> no_content()
    ["authenticate", "password"] -> {
      try raw = acl.parse_json(request)
      try params = authenticate_by_password.params(raw)
      try identifier = authenticate_by_password.run(params)
      successful_authentication(identifier, request, config)
    }
    ["authenticate", "code"] -> {
      try raw = acl.parse_json(request)
      try params = authenticate_by_code.params(raw)
      try identifier = authenticate_by_code.run(params)
      successful_authentication(identifier, request, config)
    }
    ["authenticate", "session"] -> {
      try identifier_id = web.identify_client(request, config)
      try Some(identifier) = identifier.fetch_by_id(identifier_id)
      // TODO this one doesn't set a session as it already has
      http.response(200)
      |> web.set_resp_json(identifier.to_json(identifier))
      |> Ok
    }
    ["authenticate", "email"] -> {
      try params = acl.parse_json(request)
      try params = claim_email_address.params(params)
      try _ = claim_email_address.execute(params, config)
      no_content()
    }
    ["sign_out"] ->
      web.redirect(string.append(config.client_origin, "/"))
      |> http.expire_resp_cookie("token", token_cookie_settings(request))
      |> Ok
    ["identifiers", email_address] -> {
      let sql = "SELECT greeting FROM identifiers WHERE email_address = $1"
      let args = [pgo.text(email_address)]
      let mapper = fn(row) {
        assert Ok(greeting) = dynamic.element(row, 0)
        dynamic.unsafe_coerce(greeting)
      }
      try db_response = run_sql.execute(sql, args, mapper)
      let greeting = case db_response {
        [greeting] -> greeting
        [] -> json.null()
      }
      let data = json.object([tuple("greeting", greeting)])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok()
    }
    ["identifiers", id, "greeting"] -> {
      try user_id = web.identify_client(request, config)
      assert Ok(id) = int.parse(id)
      assert true = user_id == id
      try raw = acl.parse_json(request)
      assert Ok(blocks) = dynamic.field(raw, dynamic.from("blocks"))
      let sql = "UPDATE identifiers SET greeting = $2 WHERE id = $1"
      let args = [pgo.int(user_id), dynamic.unsafe_coerce(blocks)]
      try [] = run_sql.execute(sql, args, fn(x) { x })
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<"{}":utf8>>))
      |> Ok
    }
    ["contacts"] -> {
      try user_id = web.identify_client(request, config)
      let sql =
        "
      WITH contacts AS (
        SELECT lower_identifier_id AS contact_id, upper_identifier_ack AS ack, thread_id
        FROM pairs
        WHERE pairs.upper_identifier_id = $1
        UNION ALL
        SELECT upper_identifier_id AS contact_id, lower_identifier_ack AS ack, thread_id
        FROM pairs
        WHERE pairs.lower_identifier_id = $1
      ), latest AS (
        SELECT DISTINCT ON(thread_id) * FROM notes
        ORDER BY thread_id DESC, inserted_at DESC
      )
      SELECT id, email_address, greeting, COALESCE(latest.counter, 0) > contacts.ack, latest.inserted_at, latest.content FROM contacts
      JOIN identifiers ON identifiers.id = contacts.contact_id
      LEFT JOIN latest ON latest.thread_id = contacts.thread_id
      "
      let args = [pgo.int(user_id)]
      try contacts =
        run_sql.execute(
          sql,
          args,
          fn(row) {
            let identifier = identifier.row_to_identifier(row)
            assert Ok(outstanding) = dynamic.element(row, 3)
            assert Ok(outstanding) = dynamic.bool(outstanding)
            assert Ok(inserted_at) = dynamic.element(row, 4)
            assert Ok(inserted_at) =
              run_sql.dynamic_option(inserted_at, run_sql.cast_datetime)
            assert Ok(content) = dynamic.element(row, 5)
            let content: json.Json = dynamic.unsafe_coerce(content)
            // TODO thread summary type
            tuple(identifier, outstanding, inserted_at, content)
          },
        )
      // db.run(sql, args, io.debug)
      http.response(200)
      |> web.set_resp_json(json.list(list.map(contacts, contact_to_json)))
      |> Ok()
    }
    ["relationship", "start"] -> {
      try params = acl.parse_json(request)
      try params = start_relationship.params(params)
      try user_id = web.identify_client(request, config)
      try contact = start_relationship.execute(params, user_id)
      http.response(200)
      |> web.set_resp_json(contact_to_json(contact))
      |> Ok()
    }
    // TODO don't bother with tim as short for tim@plummail.co
    // tim32@plummail.co might also want name tim
    ["relationship", contact] -> {
      try identifier_id = web.identify_client(request, config)
      try email_address =
        email_address.validate(contact)
        |> result.map_error(fn(e: Nil) {
          todo("proper error for email validation")
        })
      try tuple(identifier, thread) =
        lookup_relationship.execute(identifier_id, email_address)
      let data =
        json.object([
          tuple("identifier", json.nullable(identifier, identifier.to_json)),
          tuple("thread", json.nullable(thread, thread.to_json)),
        ])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["threads", thread_id, "post"] -> {
      assert Ok(thread_id) = int.parse(thread_id)
      try raw = acl.parse_json(request)
      try counter = acl.required(raw, "counter", acl.as_int)
      assert Ok(blocks) = dynamic.field(raw, dynamic.from("blocks"))
      let blocks: json.Json = dynamic.unsafe_coerce(blocks)
      try author_id = web.identify_client(request, config)
      // // TODO a participation thing again
      try Some(latest) =
        thread.write_note(thread_id, counter, author_id, blocks)
      let data = json.object([tuple("latest", latest_to_json(latest))])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["threads", thread_id, "acknowledge"] -> {
      try raw = acl.parse_json(request)
      try params = acknowledge.params(raw, thread_id)
      try author_id = web.identify_client(request, config)
      try _ = acknowledge.execute(params, author_id)
      no_content()
    }

    ["c", "create"] -> {
      try params = acl.parse_form(request)
      try topic = start_conversation.params(params)
      try identifier_id = web.identify_client(request, config)
      try conversation = start_conversation.execute(topic, identifier_id)
      try _ = case map.get(params, "participant") {
        Error(Nil) -> Ok(Nil)
        Ok(email_address) -> {
          try participation =
            load_participation(int.to_string(conversation.id), request, config)
          let params =
            dynamic.from(map.from_list([tuple("email_address", email_address)]))
          try params = add_participant.params(params)
          try _ = add_participant.execute(participation, params)
          Ok(Nil)
        }
      }
      web.redirect(string.append(
        string.append(config.client_origin, "/c/"),
        int.to_string(conversation.id),
      ))
      |> Ok
    }

    // This will need participation for cursor
    // ["c", id] -> {
    //   try participation = load_participation(id, request, config)
    //   try participants =
    //     discuss.load_participants(participation.conversation.id)
    //   try messages = discuss.load_messages(participation.conversation.id)
    //   try pins = discuss.load_pins(participation.conversation.id)
    //   let data =
    //     json.object([
    //       tuple(
    //         "conversation",
    //         discuss.conversation_to_json(participation.conversation),
    //       ),
    //       tuple(
    //         "participants",
    //         json.list(list.map(
    //           participants,
    //           fn(participant) {
    //             let Identifier(id: id, email_address: email_address) =
    //               participant
    //             json.object([
    //               tuple("id", json.int(id)),
    //               tuple("email_address", json.string(email_address.value)),
    //             ])
    //           },
    //         )),
    //       ),
    //       tuple(
    //         "messages",
    //         json.list(list.map(
    //           messages,
    //           fn(message) {
    //             let Message(counter, content, inserted_at, identifier) = message
    //             let Identifier(email_address: email_address, ..) = identifier
    //             json.object([
    //               tuple("counter", json.int(counter)),
    //               tuple("content", json.string(content)),
    //               tuple("author", json.string(email_address.value)),
    //               tuple(
    //                 "inserted_at",
    //                 json.string(datetime.to_human(inserted_at)),
    //               ),
    //             ])
    //           },
    //         )),
    //       ),
    //       tuple(
    //         "pins",
    //         json.list(list.map(
    //           pins,
    //           fn(pin) {
    //             let Pin(id, counter, identifier_id, content) = pin
    //             json.object([
    //               tuple("id", json.int(id)),
    //               tuple("counter", json.int(counter)),
    //               tuple("identifier_id", json.int(identifier_id)),
    //               tuple("content", json.string(content)),
    //             ])
    //           },
    //         )),
    //       ),
    //       tuple(
    //         "participation",
    //         json.object([
    //           tuple(
    //             "email_address",
    //             json.string(participation.identifier.email_address.value),
    //           ),
    //           tuple(
    //             "notify",
    //             json.string(discuss.notify_to_string(participation.notify)),
    //           ),
    //           tuple("cursor", json.int(participation.cursor)),
    //           tuple("done", json.int(participation.done)),
    //         ]),
    //       ),
    //     ])
    //   http.response(200)
    //   |> web.set_resp_json(data)
    //   |> Ok
    // }
    ["c", id, "participant"] -> {
      try params = acl.parse_json(request)
      try params = add_participant.params(params)
      try participation = load_participation(id, request, config)
      try _ = add_participant.execute(participation, params)
      http.response(200)
      |> http.set_resp_body(bit_builder.from_bit_string(<<"{}":utf8>>))
      |> Ok
    }
    ["c", id, "notify"] -> {
      try params = acl.parse_json(request)
      try params = set_notification.params(params)
      try participation = load_participation(id, request, config)
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
      try participation = load_participation(id, request, config)
      try _ = write_message.execute(participation, params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    ["c", id, "read"] -> {
      try params = acl.parse_json(request)
      try params = read_message.params(params)
      try participation = load_participation(id, request, config)
      try _ = read_message.execute(participation, params)
      http.response(201)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
    }
    ["c", id, "pin"] -> {
      try params = acl.parse_json(request)
      try params = add_pin.params(params)
      try participation = load_participation(id, request, config)
      try pin_id = add_pin.execute(participation, params)
      let data = json.object([tuple("id", json.int(pin_id))])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["c", id, "delete_pin"] -> {
      try params = acl.parse_json(request)
      try params = delete_pin.params(params)
      try participation = load_participation(id, request, config)
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
        // TODO decide if we want to keep sentry trace header
        "content-type, sentry-trace",
      )
  }
  // |> io.debug()
}
