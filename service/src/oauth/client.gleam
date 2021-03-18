import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string
import gleam/uri.{Uri}
import gleam/http.{Response}
import perimeter/input
import perimeter/input/http_response
import perimeter/input/json
import perimeter/scrub.{Report}

pub type AbsoluteUri {
  AbsoluteUri(scheme: String, host: String, path: String)
}

// A client is always a client of a provider, the client_id and secret are unique
// Therefore don't create a separate Provider/AuthorizationServer struct
pub type Client {
  Client(
    client_id: String,
    client_secret: String,
    authorization_endpoint: AbsoluteUri,
    token_endpoint: AbsoluteUri,
    extra_authorization: List(tuple(String, String)),
  )
}

pub fn authorization_request(client, redirect_uri, scopes) {
  let Client(
    client_id: client_id,
    authorization_endpoint: endpoint,
    extra_authorization: extra,
    ..,
  ) = client
  let AbsoluteUri(scheme, host, path) = endpoint
  let query = // Adding id_token here automatically turns response mode to hash
  // tuple("access_type", "offline"),
  [
    tuple("client_id", client_id),
    tuple("response_type", "code"),
    tuple("redirect_uri", redirect_uri),
    tuple("scope", string.join(scopes, " ")),
    ..extra
  ]
  let uri =
    uri.Uri(
      Some(scheme),
      None,
      Some(host),
      None,
      path,
      Some(uri.query_to_string(query)),
      None,
    )
  uri.to_string(uri)
}

pub fn cast_authorization_response(raw) {
  let code = dynamic.field(raw, "code")
  let state = dynamic.field(raw, "state")
  let error = dynamic.field(raw, "error")

  case code, error {
    // Double depth result
    Ok(code), Error(_) -> Ok(code)
  }
}

// Probably putting all this under oauth2point1/client/code_grant
// response is a request
pub fn token_request(client, code, redirect_uri) {
  let Client(
    client_id: client_id,
    client_secret: client_secret,
    token_endpoint: endpoint,
    ..,
  ) = client
  let AbsoluteUri(scheme, host, path) = endpoint

  let query = [
    tuple("client_id", client_id),
    tuple("client_secret", client_secret),
    tuple("code", code),
    tuple("grant_type", "authorization_code"),
    tuple("redirect_uri", redirect_uri),
  ]

  http.default_req()
  |> http.set_method(http.Post)
  |> http.set_scheme(http.Https)
  |> http.set_host(host)
  |> http.set_path(path)
  |> http.prepend_req_header(
    "content-type",
    "application/x-www-form-urlencoded",
  )
  |> http.set_req_body(uri.query_to_string(query))
}

pub fn cast_token_response(http_response) {
  try raw = http_response.get_json(http_response)
  token_response_parameters(raw)
  |> result.map_error(input.to_service_report(_, "Data"))
}

pub type TokenResponse {
  TokenResponse(
    access_token: String,
    token_type: String,
    expires_in: Option(Int),
    refresh_token: Option(String),
    scope: Option(String),
  )
}

pub fn token_response_parameters(raw) {
  try error = json.optional(raw, "error", json.as_string)
  case error {
    Some(error) -> {
      try error_description =
        json.optional(raw, "error_description", json.as_string)
      Ok(Error(tuple(error, error_description)))
    }
    None -> {
      try access_token = json.required(raw, "access_token", json.as_string)
      try token_type = json.required(raw, "token_type", json.as_string)
      try expires_in = json.optional(raw, "expires_in", json.as_int)
      try refresh_token = json.optional(raw, "refresh_token", json.as_string)
      try scope = json.optional(raw, "scope", json.as_string)
      Ok(Ok(TokenResponse(
        access_token,
        token_type,
        expires_in,
        refresh_token,
        scope,
      )))
    }
  }
}
