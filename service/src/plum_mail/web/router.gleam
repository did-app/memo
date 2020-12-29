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
import gleam/pgo
// Web/utils let session = utils.extractsession
import datetime
import plum_mail
import plum_mail/config
import plum_mail/error.{Reason}
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication
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
import plum_mail/discuss/mark_done
import plum_mail/discuss/write_message
import plum_mail/discuss/read_message
import plum_mail/threads/thread
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
  http.CookieAttributes(..defaults, max_age: Some(604800))
}

pub fn route(
  request,
  config: config.Config,
) -> Result(Response(BitBuilder), Reason) {
  case http.path_segments(request) {
    ["authenticate", username, password] -> {
      assert Ok(identifier) = authenticate_by_password.run(username, password)
      assert Ok(user_agent) = http.get_req_header(request, "user-agent")
      let token = web.auth_token(identifier.id, user_agent, config.secret)
      web.redirect(string.append(config.client_origin, "/"))
      |> http.set_resp_cookie("token", token, token_cookie_settings(request))
      |> Ok
    }
    ["authenticate"] -> {
      // link tokens last for ever so might as well be a signed message as well
      // delete and use purpose link token
      try params = acl.parse_json(request)
      try link_token = acl.required(params, "link_token", acl.as_string)
      try identifier =
        authentication.validate_link_token(link_token)
        |> result.map_error(fn(_: Nil) { error.Forbidden })
      assert Ok(user_agent) = http.get_req_header(request, "user-agent")
      let Identifier(id: identifier_id, ..) = identifier
      let token = web.auth_token(identifier_id, user_agent, config.secret)
      http.response(200)
      |> web.set_resp_json(identifier.to_json(identifier))
      |> http.set_resp_cookie("token", token, token_cookie_settings(request))
      |> Ok
    }
    // TODO rename above as "code"
    ["authenticate", "session"] -> {
      try identifier_id = web.identify_client(request, config)
      try identifier = identifier.fetch_by_id(identifier_id)
      assert Some(identifier) = identifier
      http.response(200)
      |> web.set_resp_json(identifier.to_json(identifier))
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
    ["sign_out"] ->
      web.redirect(string.append(config.client_origin, "/"))
      |> http.expire_resp_cookie("token", token_cookie_settings(request))
      |> Ok
    // ["inbox"] -> {
    //   try identifier_id = web.identify_client(request, config)
    //   try conversations = show_inbox.execute(identifier_id)
    //   // can only show conversations if there is an identifier
    //   assert Ok(Some(tuple(identifier, _greeting))) =
    //     authentication.fetch_identifier(identifier_id)
    //   // If this conversations is the same as the top level conversation object for a page,
    //   // it can be the start value when switching pages
    //   http.response(200)
    //   |> web.set_resp_json(json.object([
    //     tuple("conversations", conversations),
    //     // TODO remove
    //     tuple("identifier", identifier_data(identifier)),
    //   ]))
    //   |> Ok()
    // }
    [] ->
      // Ok(http.set_resp_body(http.response(200), <<>>))
      todo("index")
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
        SELECT lower_identifier_id
        FROM pairs
        WHERE pairs.upper_identifier_id = $1
        UNION ALL
        SELECT upper_identifier_id
        FROM pairs
        WHERE pairs.lower_identifier_id = $1
      )
      SELECT id, email_address, greeting
      FROM identifiers
      WHERE id IN (SELECT id FROM contacts)
      AND id <> $1
      "
      let args = [pgo.int(user_id)]
      try contacts = run_sql.execute(sql, args, identifier.row_to_identifier)
      // db.run(sql, args, io.debug)
      http.response(200)
      |> web.set_resp_json(json.list(list.map(contacts, identifier.to_json)))
      |> Ok()
    }
    ["relationship", "start"] -> {
      try params = acl.parse_json(request)
      try params = start_relationship.params(params)
      try user_id = web.identify_client(request, config)
      try thread_id = start_relationship.execute(params, user_id)
      http.response(200)
      |> web.set_resp_json(json.object([tuple("thread_id", json.int(thread_id))]))
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
      try notes = thread.write_note(thread_id, counter, author_id, blocks)
      http.response(200)
      |> web.set_resp_json(json.null())
      |> Ok
    }

    // ["welcome"] -> {
    //   io.debug(request)
    //   try params = acl.parse_form(request)
    //   assert Ok(topic) = map.get(params, "topic")
    //   assert Ok(topic) = discuss.validate_topic(topic)
    //   assert Ok(author_id) = map.get(params, "author_id")
    //   assert Ok(author_id) = int.parse(author_id)
    //   // TODO email lib should have comma separated parser
    //   assert Ok(cc) = map.get(params, "cc")
    //   assert Ok(cc) = authentication.validate_email(cc)
    //   assert Ok(message) = map.get(params, "message")
    //   assert Ok(email_address) = map.get(params, "email")
    //   assert Ok(email_address) = authentication.validate_email(email_address)
    //   io.debug(email_address)
    //   try conversation = start_conversation.execute(topic, author_id)
    //   assert Ok(author_participation) =
    //     discuss.load_participation(conversation.id, author_id)
    //   let params = write_message.Params(content: message, conclusion: False)
    //   try _ = write_message.execute(author_participation, params)
    //   // let identifier = case authentication.lookup_identifier(email_address) {
    //   //   Ok(identifier) -> identifier
    //   //   Error(_) -> {
    //   //     assert Ok(identifier) =
    //   //       plum_mail.identifier_from_email(dynamic.from(email_address.value))
    //   //     identifier
    //   //   }
    //   // }
    //   let params = add_participant.Params(cc)
    //   assert Ok(_) = add_participant.execute(author_participation, params)
    //   let params = add_participant.Params(email_address)
    //   assert Ok(_) = add_participant.execute(author_participation, params)
    //   Nil
    //   io.debug("here")
    //   http.response(200)
    //   |> http.set_resp_body(bit_builder.from_bit_string(<<"message sent":utf8>>))
    //   |> Ok
    // }
    // This might not be a good name as we want a to introduce b
    // this might be reach out or something. connect(verb) contact(verb noun the same word)
    // ["introduction", label] -> {
    //   try params = acl.parse_form(request)
    //   assert Ok(topic) = map.get(params, "subject")
    //   assert Ok(topic) = discuss.validate_topic(topic)
    //   assert Ok(message) = map.get(params, "message")
    //   assert Ok(from) = map.get(params, "from")
    //   assert Ok(from) = authentication.validate_email(from)
    //   let identifier = case authentication.lookup_identifier(from) {
    //     Ok(identifier) -> identifier
    //     Error(_) -> {
    //       assert Ok(identifier) =
    //         plum_mail.identifier_from_email(dynamic.from(from.value))
    //       identifier
    //     }
    //   }
    //   try conversation = start_conversation.execute(topic, identifier.id)
    //   assert Ok(starter_participation) =
    //     discuss.load_participation(conversation.id, identifier.id)
    //   let params = write_message.Params(content: message, conclusion: False)
    //   try _ = write_message.execute(starter_participation, params)
    //   let email_address = string.concat([label, "@plummail.co"])
    //   let addresses = case email_address == "team@plummail.co" {
    //     True -> ["peter@plummail.co", "richard@plummail.co"]
    //     False -> [email_address]
    //   }
    //   // TODO need a load participation function that takes integers
    //   list.each(
    //     addresses,
    //     fn(email_address) {
    //       assert Ok(email_address) =
    //         authentication.validate_email(email_address)
    //       let params = add_participant.Params(email_address)
    //       // TODO note why does this not return participation
    //       assert Ok(tuple(identifier_id, conversation_id)) =
    //         add_participant.execute(starter_participation, params)
    //       Nil
    //     },
    //   )
    //   http.response(201)
    //   |> http.set_resp_body(bit_builder.from_bit_string(<<"message sent":utf8>>))
    //   |> Ok
    // }
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
    ["c", id, "mark_done"] -> {
      try params = acl.parse_json(request)
      try params = mark_done.params(params)
      try participation = load_participation(id, request, config)
      try _ = mark_done.execute(participation, params)
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
        "content-type",
      )
  }
  // |> io.debug()
}
