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
import plum_mail/conversation/group
import plum_mail/conversation/conversation
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Personal, Shared}
import plum_mail/web/helpers as web
import plum_mail/threads/thread
import plum_mail/threads/acknowledge
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

fn successful_authentication(identifier, request, config) {
  let token = authentication_token(identifier, request, config)
  try shared = identifier.shared_identifiers(identifier)
  http.response(200)
  |> web.set_resp_json(json.object([
    tuple("identifier", identifier.to_json(identifier)),
    tuple("shared", json.list(list.map(shared, identifier.to_json))),
  ]))
  |> http.set_resp_cookie("token", token, token_cookie_settings(request))
  |> Ok
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
      successful_authentication(identifier, request, config)
    }
    // Note cookies wont get set on the ajax auth step
    ["sign_in"] -> {
      try raw = acl.parse_form(request)
      try params = authenticate_by_password.from_form(raw)
      try identifier = authenticate_by_password.run(params)
      let token = authentication_token(identifier, request, config)
      web.redirect(string.append(config.client_origin, "/"))
      |> http.set_resp_cookie("token", token, token_cookie_settings(request))
      |> Ok
    }
    ["authenticate", "code"] -> {
      try raw = acl.parse_json(request)
      try params = authenticate_by_code.params(raw)
      try identifier = authenticate_by_code.run(params)
      successful_authentication(identifier, request, config)
    }
    ["authenticate", "session"] -> {
      try client = web.identify_client(request, config)
      case client {
        Some(identifier_id) -> {
          try Some(identifier) = identifier.fetch_by_id(identifier_id)
          // This one doesn't set a session as it already has one
          try shared = identifier.shared_identifiers(identifier)
          http.response(200)
          |> web.set_resp_json(json.object([
            tuple("identifier", identifier.to_json(identifier)),
            tuple("shared", json.list(list.map(shared, identifier.to_json))),
          ]))
          |> Ok
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
    // TODO this should become identifiers identifiers_id greeting
    ["me", "greeting"] -> {
      try client_state = web.identify_client(request, config)
      try user_id = web.require_authenticated(client_state)
      try raw = acl.parse_json(request)
      assert Ok(blocks) = dynamic.field(raw, dynamic.from("blocks"))
      // casts from json to pg type
      let blocks = dynamic.unsafe_coerce(blocks)
      let identifier = identifier.update_greeting(user_id, blocks)
      let identifier = todo("finis mapping")
      http.response(200)
      |> web.set_resp_json(identifier.to_json(identifier))
      |> Ok
    }
    // connect | start_direct
    // should return conversation
    // rest would be POST identifiers/id/conversations but is conversations really nested under?
    ["identifiers", identifier_id, "start_direct"] -> {
      try params = acl.parse_json(request)
      try email_address = acl.required(params, "email_address", acl.as_email)
      assert Ok(content) = dynamic.field(params, dynamic.from("content"))
      try client_state = web.identify_client(request, config)
      try session = web.require_authenticated(client_state)
      assert Ok(identifier_id) = int.parse(identifier_id)
      assert True = session == identifier_id
      let content: Json = dynamic.unsafe_coerce(content)
      try conversation =
        conversation.start_direct(identifier_id, email_address, content)
      http.response(200)
      |> web.set_resp_json(conversation.to_json(conversation))
      |> Ok
    }
    ["identifiers", identifier_id, "conversations"] -> {
      try client_state = web.identify_client(request, config)
      try session = web.require_authenticated(client_state)
      assert Ok(identifier_id) = int.parse(identifier_id)
      // TODO instate this check against groups
      // assert True = session == identifier_id
      try conversations = conversation.all_participating(identifier_id)
      let data = json.list(list.map(conversations, conversation.to_json))
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["threads", thread_id, "memos"] -> {
      assert Ok(thread_id) = int.parse(thread_id)
      try memos = thread.load_memos(thread_id)
      let data = json.list(memos)
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["threads", thread_id, "post"] -> {
      assert Ok(thread_id) = int.parse(thread_id)
      try raw = acl.parse_json(request)
      try position = acl.required(raw, "position", acl.as_int)
      assert Ok(blocks) = dynamic.field(raw, dynamic.from("content"))
      // We can pass validity
      let blocks: json.Json = dynamic.unsafe_coerce(blocks)
      try client_state = web.identify_client(request, config)
      try author_id = web.require_authenticated(client_state)
      // // Needs a participation thing again
      try latest = thread.post_memo(thread_id, position, author_id, blocks)
      let data = thread.memo_to_json(latest)
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["threads", thread_id, "acknowledge"] -> {
      try raw = acl.parse_json(request)
      try params = acknowledge.params(raw, thread_id)
      try client_state = web.identify_client(request, config)
      try identifier_id = web.require_authenticated(client_state)
      try _ = acknowledge.execute(params, identifier_id)
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
  // |> io.debug()
}
