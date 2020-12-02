import gleam/beam
import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/http
import gleam/json
import midas/signed_message
import plum_mail/config.{Config}

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

pub fn identify_client(request, config, now) {
  let Config(client_origin: client_origin, secret: secret, ..) = config
  try Nil = case http.get_req_origin(request) {
    Some(from) if from == client_origin -> Ok(Nil)
    _ -> Error(Nil)
  }
  let cookies = http.get_req_cookies(request)
  try token = list.key_find(cookies, "token")

  try data = signed_message.decode(token, secret)
  assert Ok(term) = beam.binary_to_term(data)
  // security flaw if you issue tokens for other purpose
  let tuple("cookie_token", identifier_id, identified_at, active_at, user_agent) =
    dynamic.unsafe_coerce(term)

  try _ = check_timestamp(identified_at, Days(30), now)
  try _ = check_timestamp(active_at, Days(3), now)
  try _ = case http.get_req_header(request, "user-agent") {
    Ok(ua) if ua == user_agent -> Ok(Nil)
  }
  Ok(identifier_id)
}
