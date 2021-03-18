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
import gleam/beam
import gleam/http/cowboy
import gleam/http.{Request, Response}
import gleam/json.{Json}
import gleam/pgo
import gleam_uuid
// Web/utils let session = utils.extractsession
import midas/signed_message
import datetime
import oauth/client as oauth
import drive_uploader
import perimeter/email_address.{EmailAddress}
import perimeter/input
import perimeter/input/http_request
import perimeter/input/json as json_input
import perimeter/scrub
import perimeter/services/http_client
import plum_mail
import plum_mail/config.{Config}
import plum_mail/run_sql
import plum_mail/authentication
import plum_mail/authentication/authenticate_by_code
import plum_mail/authentication/authenticate_by_password
import plum_mail/authentication/claim_email_address
import plum_mail/conversation/conversation
import plum_mail/identifier
import plum_mail/web/helpers as web
import plum_mail/email/inbound/postmark

fn successful_authentication(identifier) {
  let identifier_id = identifier.id(identifier)
  try inboxes = conversation.all_inboxes(identifier_id)
  let inboxes_data =
    json.list(list.map(
      inboxes,
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
  |> web.set_resp_json(json.object([tuple("inboxes", inboxes_data)]))
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
) -> Result(Response(BitBuilder), scrub.Report(scrub.Code)) {
  case http.path_segments(request) {
    [] -> no_content()
    // Note cookies wont get set on the ajax auth step so we use a form submission
    ["sign_in"] -> {
      try raw = http_request.get_form(request)
      try params =
        authenticate_by_password.params(raw)
        |> result.map_error(input.to_report(_, "Form field"))
      try identifier = authenticate_by_password.run(params)
      web.redirect(string.append(config.client_origin, "/"))
      |> web.set_email_authentication_cookie(identifier, request, config)
      |> Ok
    }
    ["authenticate", "code"] -> {
      try raw = http_request.get_json(request)
      try params =
        authenticate_by_code.params(raw)
        |> result.map_error(input.to_report(_, "Parameter"))
      try identifier = authenticate_by_code.run(params)
      successful_authentication(identifier)
      |> result.map(web.set_email_authentication_cookie(
        _,
        identifier,
        request,
        config,
      ))
    }
    ["authenticate", "session"] -> {
      try client = web.get_email_authentication(request, config)
      // Could require_authentication but with a handle
      case client {
        Some(identifier_id) -> {
          try lookup = identifier.fetch_by_id(identifier_id)
          case lookup {
            Some(identifier) ->
              // This one doesn't set a cookie as it already has one
              successful_authentication(identifier)
            None -> no_content()
          }
        }
        None -> no_content()
      }
    }
    ["authenticate", "email"] -> {
      try params = claim_email_address.cast(request)
      try _ = claim_email_address.execute(params, config)
      no_content()
    }
    ["sign_out"] ->
      web.redirect(string.append(config.client_origin, "/"))
      |> web.expire_email_authentication_cookie(request)
      |> Ok
    ["identifiers", email_address] -> {
      let sql = "SELECT greeting FROM identifiers WHERE email_address = $1"
      let args = [pgo.text(email_address)]
      try rows = run_sql.execute(sql, args)
      assert Ok(greetings) =
        list.try_map(
          rows,
          fn(row) {
            try greeting = dynamic.element(row, 0)
            let greeting: Json = dynamic.unsafe_coerce(greeting)
            Ok(greeting)
          },
        )
      let greeting = case greetings {
        [greeting] -> greeting
        [] -> json.null()
      }
      let data = json.object([tuple("greeting", greeting)])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok()
    }
    ["identifiers", identifier_id, "name"] -> {
      try client_state = web.get_email_authentication(request, config)
      try user_id = web.require_authenticated(client_state)
      try identifier_id =
        json_input.as_uuid(dynamic.from(identifier_id))
        |> result.map_error(input.CastFailure("identifier_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
      try raw = http_request.get_json(request)
      try name =
        json_input.required(raw, "name", json_input.as_string)
        |> result.map_error(input.to_report(_, "Parameter"))
      let _ = conversation.update_name(identifier_id, user_id, name)
      no_content()
    }

    ["identifiers", identifier_id, "greeting"] -> {
      try client_state = web.get_email_authentication(request, config)
      try user_id = web.require_authenticated(client_state)
      try identifier_id =
        json_input.as_uuid(dynamic.from(identifier_id))
        |> result.map_error(input.CastFailure("identifier_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
      try raw = http_request.get_json(request)
      try blocks =
        json_input.required(raw, "blocks", Ok)
        |> result.map_error(input.to_report(_, "Parameter"))
      let blocks: json.Json = dynamic.unsafe_coerce(blocks)
      let _ = conversation.update_greeting(identifier_id, user_id, blocks)
      no_content()
    }
    // connect | start_direct
    // should return conversation
    // rest would be POST identifiers/id/conversations but is conversations really nested under?
    ["identifiers", identifier_id, "start_direct"] -> {
      try raw = http_request.get_json(request)
      try email_address =
        json_input.required(raw, "email_address", json_input.as_email)
        |> result.map_error(input.to_report(_, "Parameter"))
      try content =
        json_input.required(raw, "content", Ok)
        |> result.map_error(input.to_report(_, "Parameter"))
      try client_state = web.get_email_authentication(request, config)
      try author_id = web.require_authenticated(client_state)
      try identifier_id =
        json_input.as_uuid(dynamic.from(identifier_id))
        |> result.map_error(input.CastFailure("identifier_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
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
      try params = http_request.get_json(request)
      try name =
        json_input.required(params, "name", json_input.as_string)
        |> result.map_error(input.to_report(_, "Parameter"))
      try invitees =
        json_input.required(
          params,
          "invitees",
          json_input.as_list(_, json_input.as_uuid),
        )
        |> result.map_error(input.to_report(_, "Parameter"))
      try client_state = web.get_email_authentication(request, config)
      try identifier_id = web.require_authenticated(client_state)
      try conversation =
        conversation.create_group(name, identifier_id, invitees)
      http.response(200)
      |> web.set_resp_json(conversation.to_json(conversation))
      |> Ok
    }
    // Don't just look up if user is member of group. this allows an individual to talk to group. If ever needed. maybe integrations
    ["identifiers", identifier_id, "threads", thread_id, "memos"] -> {
      try identifier_id =
        json_input.as_uuid(dynamic.from(identifier_id))
        |> result.map_error(input.CastFailure("identifier_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
      try thread_id =
        json_input.as_uuid(dynamic.from(thread_id))
        |> result.map_error(input.CastFailure("thread_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
      try client_state = web.get_email_authentication(request, config)
      try user_id = web.require_authenticated(client_state)
      try memos = conversation.load_memos(thread_id, identifier_id, user_id)
      let data = json.list(memos)
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok
    }
    ["identifiers", identifier_id, "threads", thread_id, "post"] -> {
      try identifier_id =
        json_input.as_uuid(dynamic.from(identifier_id))
        |> result.map_error(input.CastFailure("identifier_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
      try thread_id =
        json_input.as_uuid(dynamic.from(thread_id))
        |> result.map_error(input.CastFailure("thread_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
      try raw = http_request.get_json(request)
      try position =
        json_input.required(raw, "position", json_input.as_int)
        |> result.map_error(input.to_report(_, "Parameter"))
      try blocks =
        json_input.required(raw, "content", Ok)
        |> result.map_error(input.to_report(_, "Parameter"))
      // We can pass validity
      let blocks: json.Json = dynamic.unsafe_coerce(blocks)
      try client_state = web.get_email_authentication(request, config)
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
      try identifier_id =
        json_input.as_uuid(dynamic.from(identifier_id))
        |> result.map_error(input.CastFailure("identifier_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
      try thread_id =
        json_input.as_uuid(dynamic.from(thread_id))
        |> result.map_error(input.CastFailure("thread_id", _))
        |> result.map_error(input.to_report(_, "Url Parameter"))
      try raw = http_request.get_json(request)
      try position =
        json_input.required(raw, "position", json_input.as_int)
        |> result.map_error(input.to_report(_, "Parameter"))
      try client_state = web.get_email_authentication(request, config)
      try user_id = web.require_authenticated(client_state)
      try _ =
        conversation.acknowledge(identifier_id, user_id, thread_id, position)
      no_content()
    }

    ["inbound"] -> {
      try params = http_request.get_json(request)
      postmark.handle(params, config)
    }

    ["drive_uploaders", "authorize"] -> {
      try raw = http_request.get_json(request)
      try code =
        json_input.required(raw, "code", json_input.as_string)
        |> result.map_error(input.to_report(_, "Parameter"))
      try sub = drive_uploader.authorize(code, config.google_client, config)
      uploaders_response(sub, request, config)
    }

    ["drive_uploaders", "create"] -> {
      try sub = drive_uploader.client_authentication(request, config)
      try raw = http_request.get_json(request)
      try name =
        json_input.required(raw, "name", json_input.as_string)
        |> result.map_error(input.to_report(_, "Parameter"))
      try parent_id =
        json_input.optional(raw, "parent_id", json_input.as_string)
        |> result.map_error(input.to_report(_, "Parameter"))
      try parent_name =
        json_input.optional(raw, "parent_name", json_input.as_string)
        |> result.map_error(input.to_report(_, "Parameter"))
      try _ = drive_uploader.create_uploader(sub, name, parent_id, parent_name)
      uploaders_response(sub, request, config)
    }
    ["drive_uploaders", id, "delete"] -> {
      try sub = drive_uploader.client_authentication(request, config)
      try _ = drive_uploader.delete_uploader(id)
      uploaders_response(sub, request, config)
    }

    ["drive_uploaders", id] -> {
      try uploader = drive_uploader.uploader_by_id(id)
      let data =
        json.object([
          tuple("uploader", drive_uploader.uploader_to_json(uploader)),
        ])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok()
    }
    ["drive_uploaders", id, "start"] -> {
      try uploader = drive_uploader.uploader_by_id(id)
      try raw = http_request.get_json(request)
      try name =
        json_input.required(raw, "name", json_input.as_string)
        |> result.map_error(input.to_report(_, "Parameter"))
      try mime_type =
        json_input.required(raw, "mime_type", json_input.as_string)
        |> result.map_error(input.to_report(_, "Parameter"))
      assert Ok(drive_uploader.Authorization(access_token: access_token, ..)) =
        uploader.authorization
      // https://developers.google.com/drive/api/v3/reference/files/create
      let parents = case uploader.parent_id {
        Some(parent_id) -> [json.string(parent_id)]
        None -> []
      }
      let data =
        json.object([
          tuple("mimeType", json.string(mime_type)),
          tuple("name", json.string(name)),
          tuple("parents", json.list(parents)),
        ])
      let start_request =
        http.default_req()
        |> http.set_scheme(http.Https)
        |> http.set_method(http.Post)
        |> http.set_host("www.googleapis.com")
        |> http.set_path("/upload/drive/v3/files")
        |> http.set_query([tuple("uploadType", "resumable")])
        |> http.prepend_req_header("content-type", "application/json")
        // https://stackoverflow.com/questions/27281825/google-storage-api-resumable-upload-ajax-cors-error
        |> http.prepend_req_header("origin", config.client_origin)
        |> http.prepend_req_header(
          "authorization",
          string.concat(["Bearer ", access_token]),
        )
        |> http.set_req_body(json.encode(data))
      try response =
        start_request
        |> http_client.send()
        |> result.map_error(http_client.to_report)
      try location =
        http.get_resp_header(response, "location")
        |> result.map_error(fn(_: Nil) {
          scrub.Report(
            scrub.ServiceError,
            "Missing location",
            "No upload target created",
          )
        })
      let data = json.object([tuple("location", json.string(location))])
      http.response(200)
      |> web.set_resp_json(data)
      |> Ok()
    }
    _ ->
      http.response(404)
      |> http.set_resp_body(bit_builder.from_bit_string(<<>>))
      |> Ok
  }
}

fn uploaders_response(sub, request, config) {
  let Config(client_origin: client_origin, secret: secret, ..) = config
  try uploaders = drive_uploader.list_for_authorization(sub)

  let uploaders_data = drive_uploader.uploaders_to_json(uploaders)
  let data = json.object([tuple("uploaders", uploaders_data)])

  let term = tuple("google_authentication", sub)
  let cookie = signed_message.encode(beam.term_to_binary(term), secret)
  http.response(200)
  |> http.set_resp_cookie(
    "google_authentication",
    cookie,
    google_cookie_settings(request),
  )
  |> web.set_resp_json(data)
  |> Ok()
}

fn google_cookie_settings(request) {
  let Request(scheme: scheme, ..) = request
  let defaults = http.cookie_defaults(scheme)
  let tuple(secure, same_site_policy) = case http.get_req_header(
    request,
    "x-forwarded-proto",
  ) {
    Ok("https") -> tuple(True, Some(http.None))
    _ -> tuple(False, Some(http.Lax))
  }
  http.CookieAttributes(..defaults, same_site: same_site_policy, secure: secure)
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
        Error(report) -> scrub.to_response(report)
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
