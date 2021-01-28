import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/map
import gleam/option.{None, Option, Some}
import gleam/string
import gleam/result
import gleam/uri
import gleam/http/cowboy
import gleam/http.{Request, Response}
import gleam/httpc
import gleam/json.{Json}
import gleam/pgo
import gleam_uuid
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
import plum_mail/conversation/conversation
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Personal, Shared}
import plum_mail/web/helpers as web
import plum_mail/email/inbound/postmark

fn token_cookie_settings(request) {
  let Request(scheme: scheme, ..) = request
  let defaults = http.cookie_defaults(scheme)
  // The policy needs to be none because we call from memo.did.app to herokuapp
  // let same_site_policy = case defaults.secure {
  //   True -> http.None
  //   False -> http.Lax
  // }
  // NOTE need x-request
  // this breaks it if api call is made over http, need to handle redirect
  // motion removing from gleam_http
  let tuple(secure, same_site_policy) = case http.get_req_header(
    request,
    "x-forwarded-proto",
  ) {
    Ok("https") -> tuple(True, Some(http.None))
    _ -> tuple(False, Some(http.Lax))
  }
  http.CookieAttributes(
    ..defaults,
    max_age: Some(604800),
    same_site: same_site_policy,
    secure: secure,
  )
}

fn authentication_token(identifier, request, config) {
  let Personal(id: identifier_id, ..) = identifier
  let Config(secret: secret, ..) = config
  assert Ok(user_agent) = http.get_req_header(request, "user-agent")
  web.auth_token(identifier_id, user_agent, secret)
}

fn successful_authentication(identifier) {
  let identifier_id = identifier.id(identifier)
  assert Ok(inboxs) = conversation.all_inboxes(identifier_id)
  let inboxs_data =
    json.list(list.map(
      inboxs,
      fn(inbox) {
        let tuple(identifier, role, conversations) = inbox
        let role = case role {
          None -> json.object([tuple("type", json.string("personal"))])
          Some(author) ->
            json.object([
              tuple("type", json.string("member")),
              tuple("identifier", identifier.to_json(author)),
            ])
        }

        json.object([
          tuple("identifier", identifier.to_json(identifier)),
          tuple(
            "conversations",
            json.list(list.map(conversations, conversation.to_json)),
          ),
          tuple("role", role),
        ])
      },
    ))
  http.response(200)
  |> web.set_resp_json(json.object([tuple("inboxes", inboxs_data)]))
}

fn no_content() {
  http.response(204)
  |> http.set_resp_body(bit_builder.from_bit_string(<<"":utf8>>))
  |> Ok
}

pub fn route(
  request,
  config: config.Config,
) -> Result(Response(BitBuilder), Reason) {
  case http.path_segments(request) {
    [] -> no_content()
    // Note this endpoint is never used 
    ["authenticate", "password"] -> {
      try raw = acl.parse_json(request)
      try params = authenticate_by_password.params(raw)
      try identifier = authenticate_by_password.run(params)
      let token = authentication_token(identifier, request, config)
      successful_authentication(identifier)
      |> http.set_resp_cookie("authentication", token, token_cookie_settings(request))
      |> Ok
    }
    // Note cookies wont get set on the ajax auth step
    ["sign_in"] -> {
      try raw = acl.parse_form(request)
      try params = authenticate_by_password.from_form(raw)
      try identifier = authenticate_by_password.run(params)
      let token = authentication_token(identifier, request, config)
      web.redirect(string.append(config.client_origin, "/"))
      |> http.set_resp_cookie("authentication", token, token_cookie_settings(request))
      |> Ok
    }
    ["authenticate", "code"] -> {
      try raw = acl.parse_json(request)
      try params = authenticate_by_code.params(raw)
      try identifier = authenticate_by_code.run(params)
      let token = authentication_token(identifier, request, config)
      successful_authentication(identifier)
      |> http.set_resp_cookie("authentication", token, token_cookie_settings(request))
      |> Ok
    }
    ["authenticate", "session"] -> {
      try client = web.identify_client(request, config)
      case client {
        Some(identifier_id) -> {
          try lookup = identifier.fetch_by_id(identifier_id)
          case lookup {
            Some(identifier) ->
              // This one doesn't set a session as it already has one
              successful_authentication(identifier)
              |> Ok
            None -> no_content()
          }
        }
        None -> no_content()
      }
    }
    ["authenticate", "email"] -> {
      try params = acl.parse_json(request)
      try params = claim_email_address.params(params)
      try _ = claim_email_address.execute(params, config)
      no_content()
    }
    ["sign_out"] ->
      web.redirect(string.append(config.client_origin, "/"))
      |> http.expire_resp_cookie("authentication", token_cookie_settings(request))
      |> Ok
    ["identifiers", email_address] -> {
      let sql = "SELECT greeting FROM identifiers WHERE email_address = $1"
      let args = [pgo.text(email_address)]
      let mapper = fn(row) -> Json {
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
    ["identifiers", identifier_id, "greeting"] -> {
      try client_state = web.identify_client(request, config)
      try session = web.require_authenticated(client_state)
      // TODO act on behalf of the group
      assert Ok(identifier_id) = gleam_uuid.from_string(identifier_id)
      assert True = session == identifier_id
      try raw = acl.parse_json(request)
      assert Ok(blocks) = dynamic.field(raw, dynamic.from("blocks"))
      let blocks: json.Json = dynamic.unsafe_coerce(blocks)
      let _ = identifier.update_greeting(identifier_id, blocks)
      no_content()
    }
    // connect | start_direct
    // should return conversation
    // rest would be POST identifiers/id/conversations but is conversations really nested under?
    ["identifiers", identifier_id, "start_direct"] -> {
      try params = acl.parse_json(request)
      try email_address = acl.required(params, "email_address", acl.as_email)
      assert Ok(content) = dynamic.field(params, dynamic.from("content"))
      try client_state = web.identify_client(request, config)
      try author_id = web.require_authenticated(client_state)
      assert Ok(identifier_id) = gleam_uuid.from_string(identifier_id)
      let content: Json = dynamic.unsafe_coerce(content)
      try conversation =
        conversation.start_direct(
          identifier_id,
          author_id,
          email_address,
          content,
        )
      http.response(200)
      |> web.set_resp_json(conversation.to_json(conversation))
      |> Ok
    }
    ["groups", "create"] -> {
      try params = acl.parse_json(request)
      try name = acl.required(params, "name", acl.as_string)
      try invitees =
        acl.required(params, "invitees", acl.as_list(_, acl.as_uuid))
      try client_state = web.identify_client(request, config)
      try identifier_id = web.require_authenticated(client_state)
      assert Ok(conversation) =
        conversation.create_group(name, identifier_id, invitees)
      http.response(200)
      |> web.set_resp_json(conversation.to_json(conversation))
      |> Ok
    }
    // Don't just look up if user is member of group. this allows an individual to talk to group. If ever needed. maybe integrations
    ["identifiers", identifier_id, "threads", thread_id, "memos"] -> {
      assert Ok(identifier_id) = gleam_uuid.from_string(identifier_id)
      assert Ok(thread_id) = gleam_uuid.from_string(thread_id)
      try client_state = web.identify_client(request, config)
      try user_id = web.require_authenticated(client_state)
      try memos = conversation.load_memos(thread_id, identifier_id, user_id)
      let data = json.list(memos)
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["identifiers", identifier_id, "threads", thread_id, "post"] -> {
      assert Ok(identifier_id) = gleam_uuid.from_string(identifier_id)
      assert Ok(thread_id) = gleam_uuid.from_string(thread_id)
      try raw = acl.parse_json(request)
      try position = acl.required(raw, "position", acl.as_int)
      assert Ok(blocks) = dynamic.field(raw, dynamic.from("content"))
      // We can pass validity
      let blocks: json.Json = dynamic.unsafe_coerce(blocks)
      try client_state = web.identify_client(request, config)
      try author_id = web.require_authenticated(client_state)
      // // Needs a participation thing again
      try latest =
        conversation.post_memo(
          thread_id,
          position,
          identifier_id,
          author_id,
          blocks,
        )
      let data = conversation.memo_to_json(latest)
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["identifiers", identifier_id, "threads", thread_id, "acknowledge"] -> {
      assert Ok(identifier_id) = gleam_uuid.from_string(identifier_id)
      assert Ok(thread_id) = gleam_uuid.from_string(thread_id)
      try raw = acl.parse_json(request)
      try position = acl.required(raw, "position", acl.as_int)
      try client_state = web.identify_client(request, config)
      try user_id = web.require_authenticated(client_state)
      // TODO this needs to be on the conversation level
      try _ =
        conversation.acknowledge(identifier_id, user_id, thread_id, position)
      no_content()
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
      // Could put everthing under /api /client thought I think I prefer a Halt solution
      |> http.prepend_resp_header(
        "access-control-allow-origin",
        // does this need limiting to just the client origin
        // can't be wild card with credentials included
        config.client_origin,
      )
      |> http.prepend_resp_header("access-control-allow-credentials", "true")
      |> http.prepend_resp_header(
        "access-control-allow-headers",
        // decide if we want to keep sentry trace header
        "content-type, sentry-trace",
      )
  }
}
