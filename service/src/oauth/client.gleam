import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri.{Uri}
import gleam/http

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
  let code = list.key_find(raw, "code")
  let state = list.key_find(raw, "state")
  let error = list.key_find(raw, "error")

  case code, error {
    // Double depth result
    Ok(code), Error(Nil) -> Ok(code)
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

  // let request_uri = http.req_to_uri(authorization_response)
  // let redirect_uri = Uri(..request_uri, query: None)
  // try query =
  //   http.get_query(authorization_response)
  //   |> result.map_error(fn(_) { todo("could not parse query") })
  // try code = cast_authorization_response(raw)
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
  |> Ok
}
// // TODO this is dynamic
// pub fn cast_token_response(raw) {
//   let access_token = list.key_find(raw, "access_token")
//   let token_type = list.key_find(raw, "token_type")
//   let expires_in = list.key_find(raw, "expires_in")
//   let refresh_token = list.key_find(raw, "refresh_token")
// }
