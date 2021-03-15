import gleam/beam
import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/order
import gleam/os
import gleam/result
import gleam/string
import gleam/http.{Request, Response}
import gleam/json
import gleam_uuid.{UUID}
import midas/signed_message
import perimeter/scrub.{BadInput, Report, Unprocessable}
import plum_mail/config.{Config}
import plum_mail/identifier.{Personal}

pub fn redirect(uri: String) -> Response(BitBuilder) {
  let body =
    string.append("You are being redirected to ", uri)
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  http.Response(status: 303, headers: [tuple("location", uri)], body: body)
}

pub fn set_req_json(request, data) {
  let body =
    data
    |> json.encode
    |> bit_string.from_string

  request
  |> http.prepend_req_header("content-type", "application/json")
  |> http.set_req_body(body)
}

pub fn set_resp_json(response, data) {
  let body =
    data
    |> json.encode
    |> bit_string.from_string
    |> bit_builder.from_bit_string

  response
  |> http.prepend_resp_header("content-type", "application/json")
  |> http.set_resp_body(body)
}

type Duration {
  Days(Int)
}

fn check_timestamp(issued, duration, now) {
  let Days(days) = duration
  let seconds = days * 24 * 60 * 60
  let expires = issued + seconds
  case int.compare(expires, now) {
    order.Gt -> Ok(Nil)
    order.Eq | order.Lt -> Error(Nil)
  }
}

const email_authentication = "email_authentication"

const one_month = 2_592_000

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
    max_age: Some(one_month),
    same_site: same_site_policy,
    secure: secure,
  )
}

pub fn set_email_authentication_cookie(response, identifier, request, config) {
  let Personal(id: identifier_id, ..) = identifier
  let Config(secret: secret, ..) = config
  let cookie =
    tuple(email_authentication, identifier_id)
    |> beam.term_to_binary()
    |> signed_message.encode(secret)

  http.set_resp_cookie(
    response,
    email_authentication,
    cookie,
    token_cookie_settings(request),
  )
}

fn check_request_origin(request, client_origin) {
  case http.get_req_origin(request) {
    Ok(from) if from == client_origin -> Ok(Nil)
    _ ->
      Error(Report(
        // TODO RejectedInput
        BadInput,
        "Unacceptable origin",
        "Unable to complete action due to invalid origin",
      ))
  }
}

pub fn get_email_authentication(request, config) {
  let Config(client_origin: client_origin, secret: secret, ..) = config
  try Nil = check_request_origin(request, client_origin)
  let cookies = http.get_req_cookies(request)

  case list.key_find(cookies, email_authentication) {
    Ok(cookie) -> {
      try data =
        signed_message.decode(cookie, secret)
        |> result.map_error(fn(_: Nil) {
          Report(
            BadInput,
            "Invalid cookie",
            "Unable to complete action due to invalid cookie",
          )
        })
      // Use because signed binary
      assert Ok(term) = beam.binary_to_term(data)
      let term: tuple(String, UUID) = dynamic.unsafe_coerce(term)
      case term {
        tuple(key, identifier_id) if key == email_authentication ->
          Ok(Some(identifier_id))
      }
    }
    Error(Nil) -> Ok(None)
  }
}

pub fn expire_email_authentication_cookie(response, request) {
  http.expire_resp_cookie(
    response,
    email_authentication,
    token_cookie_settings(request),
  )
}

pub fn require_authenticated(client_state) {
  client_state
  |> option.to_result(Report(
    BadInput,
    "Unauthenticated",
    "Unable to complete action due to missing authentication",
  ))
}
