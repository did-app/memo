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
import gleam/http.{Response}
import gleam/json
import gleam_uuid.{UUID}
import midas/signed_message
import plum_mail/config.{Config}
import plum_mail/error

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

pub fn auth_token(identifier_id, user_agent, secret) {
  let now = os.system_time(os.Second)
  let term = tuple("cookie_token", identifier_id, now, now, user_agent)
  let data = beam.term_to_binary(term)
  signed_message.encode(data, secret)
}

fn do_identify_client(request, config, now) -> Result(Option(UUID), Nil) {
  let Config(client_origin: client_origin, secret: secret, ..) = config
  try Nil = case http.get_req_origin(request) {
    Some(from) if from == client_origin -> Ok(Nil)
    _ -> Error(Nil)
  }
  let cookies = http.get_req_cookies(request)
  case list.key_find(cookies, "token") {
    Ok(token) -> {
      try data = signed_message.decode(token, secret)
      assert Ok(term) = beam.binary_to_term(data)
      // security flaw if you issue tokens for other purpose
      let tuple(
        "cookie_token",
        identifier_id,
        identified_at,
        active_at,
        user_agent,
      ) = dynamic.unsafe_coerce(term)
      try _ = check_timestamp(identified_at, Days(30), now)
      try _ = check_timestamp(active_at, Days(3), now)
      try _ = case http.get_req_header(request, "user-agent") {
        Ok(ua) if ua == user_agent -> Ok(Nil)
        _ -> // we're not currently checking user agents match
          // NOTE putting a mobile view on chrome inspector tools changes the user agent.
          Ok(Nil)
      }
      Ok(Some(identifier_id))
    }
    Error(Nil) -> Ok(None)
  }
}

pub fn identify_client(request, config) {
  let now = os.system_time(os.Second)
  do_identify_client(request, config, now)
  |> result.map_error(fn(_) { error.Forbidden })
}

pub fn require_authenticated(client_state) {
  client_state
  |> option.to_result(error.Unauthenticated)
}
