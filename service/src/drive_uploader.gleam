import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/string
import gleam/result
import gleam/beam
import gleam/http.{Request}
import gleam/json
import gleam/pgo
import perimeter/input/http_response
import perimeter/input/json as json_input
import perimeter/scrub.{LogicError, RejectedInput, Report, ServiceError}
import perimeter/services/http_client
import midas/signed_message
import oauth/client as oauth
import plum_mail/config.{Config}
import plum_mail/authentication
import plum_mail/run_sql

pub type Authorization {
  Authorization(sub: String, access_token: String, refresh_token: String)
}

// google drive is an implementation of uploaders
pub type Uploader {
  Uploader(
    id: String,
    name: String,
    parent_id: Option(String),
    authorization: Result(Authorization, String),
  )
}

pub fn save_authorization(
  sub,
  email_address,
  refresh_token,
  expires_in,
  access_token,
) {
  let sql =
    "
    WITH updated_authorization AS (
      UPDATE google_authorizations 
      SET email_address = $2, refresh_token = $3, expires_in = $4, access_token = $5 
      WHERE sub = $1
      RETURNING *
    ), new_authorization AS (
      INSERT INTO google_authorizations (sub, email_address, refresh_token, expires_in, access_token)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (sub) DO NOTHING
      RETURNING *
    )
    SELECT sub FROM updated_authorization
    UNION ALL
    SELECT sub FROM new_authorization
    "
  let args = [
    pgo.text(sub),
    pgo.text(email_address),
    pgo.text(refresh_token),
    pgo.int(expires_in),
    pgo.text(access_token),
  ]

  try rows = run_sql.execute(sql, args)
  assert Ok(authorizations) =
    list.try_map(
      rows,
      fn(row) {
        try sub = dynamic.element(row, 0)
        dynamic.string(sub)
      },
    )
  assert [authorization] = authorizations
  Ok(authorization)
}

pub fn authorize(code, client, config: Config) {
  let auth_request = oauth.token_request(client, code, config.client_origin)
  try auth_response =
    http_client.send(auth_request)
    |> result.map_error(http_client.to_report)

  try oauth_response = oauth.cast_token_response(auth_response)
  try oauth_response =
    oauth_response
    |> result.map_error(fn(reason) {
      let tuple(code, description) = reason
      let description = option.unwrap(description, code)
      // Most of these errors are from the programming making the wrong call
      Report(LogicError, code, description)
    })

  let access_token = oauth_response.access_token
  try expires_in =
    option.to_result(
      oauth_response.expires_in,
      Report(ServiceError, "Missing Data", "expected value for 'expires_in'"),
    )
  try refresh_token =
    option.to_result(
      oauth_response.refresh_token,
      Report(ServiceError, "Missing Data", "expected value for 'refresh_token'"),
    )

  let user_request =
    http.default_req()
    |> http.set_scheme(http.Https)
    |> http.set_host("openidconnect.googleapis.com")
    |> http.set_path("/v1/userinfo")
    |> http.prepend_req_header(
      "authorization",
      string.concat(["Bearer ", access_token]),
    )
  try user_response =
    user_request
    |> http_client.send()
    |> result.map_error(http_client.to_report)

  try raw = http_response.get_json(user_response)

  assert Ok(sub) = json_input.required(raw, "sub", json_input.as_string)
  assert Ok(email_address) =
    json_input.required(raw, "email", json_input.as_string)

  try _ =
    save_authorization(
      sub,
      email_address,
      refresh_token,
      expires_in,
      access_token,
    )

  Ok(sub)
}

pub fn list_for_authorization(sub) {
  let sql =
    "
  SELECT authorization_sub, id, name, parent_id
  FROM drive_uploaders
  WHERE authorization_sub = $1
  "
  let args = [pgo.text(sub)]
  try rows = run_sql.execute(sql, args)
  assert Ok(uploaders) = list.try_map(rows, row_to_uploader)
  Ok(uploaders)
}

// Call them links?
pub fn create_uploader(sub, name, parent_id, parent_name) {
  let id = authentication.random_string(8)
  let sql =
    "
  INSERT INTO drive_uploaders (authorization_sub, id, name, parent_id, parent_name)
  VALUES ($1, $2, $3, $4, $5)
  RETURNING authorization_sub, id, name, parent_id
  "
  let args = [
    pgo.text(sub),
    pgo.text(id),
    pgo.text(name),
    pgo.nullable(parent_id, pgo.text),
    pgo.nullable(parent_name, pgo.text),
  ]
  try rows = run_sql.execute(sql, args)
  assert Ok(uploaders) = list.try_map(rows, row_to_uploader)
  assert [uploader] = uploaders
  Ok(uploader)
}

pub fn uploader_by_id(id) {
  let sql =
    "
  SELECT authorization_sub, id, name, parent_id, refresh_token, access_token
  FROM drive_uploaders
  JOIN google_authorizations ON google_authorizations.sub = drive_uploaders.authorization_sub
  WHERE id = $1
  "
  let args = [pgo.text(id)]
  try rows = run_sql.execute(sql, args)
  assert Ok(uploaders) = list.try_map(rows, row_to_uploader)
  assert [uploader] = uploaders
  Ok(uploader)
}

fn row_to_uploader(row) {
  try sub = dynamic.element(row, 0)
  try sub = dynamic.string(sub)
  try id = dynamic.element(row, 1)
  try id = dynamic.string(id)
  try name = dynamic.element(row, 2)
  try name = dynamic.string(name)
  try parent_id = dynamic.element(row, 3)
  try parent_id = run_sql.dynamic_option(parent_id, dynamic.string)

  let refresh_token =
    dynamic.element(row, 4)
    |> result.then(dynamic.string)
  let access_token =
    dynamic.element(row, 5)
    |> result.then(dynamic.string)

  case refresh_token, access_token {
    Ok(refresh_token), Ok(access_token) ->
      Uploader(
        id,
        name,
        parent_id,
        Ok(Authorization(sub, access_token, refresh_token)),
      )
    _, _ -> Uploader(id, name, parent_id, Error(sub))
  }
  |> Ok
}

pub fn delete_uploader(id) {
  let sql = "
  DELETE FROM drive_uploaders
  WHERE id = $1
  "
  let args = [pgo.text(id)]
  try _ = run_sql.execute(sql, args)
  Ok(Nil)
}

// surface slash representations?
pub fn uploader_to_json(u) {
  let Uploader(id, name, ..) = u
  json.object([tuple("id", json.string(id)), tuple("name", json.string(name))])
}

pub fn uploaders_to_json(uploaders) {
  json.list(list.map(uploaders, uploader_to_json))
}

// authentication
pub fn client_authentication(request, config) {
  let Config(client_origin: client_origin, secret: secret, ..) = config
  try Nil = case http.get_req_origin(request) {
    Ok(from) if from == client_origin -> Ok(Nil)
    _ -> Error(Report(RejectedInput, "Forbidden", "Origin not allowed"))
  }
  let cookies = http.get_req_cookies(request)
  case list.key_find(cookies, "google_authentication") {
    // TODO handle missin here
    Ok(cookie) -> decode_cookie(cookie, secret)
  }
}

pub fn decode_cookie(cookie, secret) {
  try data =
    signed_message.decode(cookie, secret)
    |> result.map_error(fn(_: Nil) {
      Report(RejectedInput, "Invalid Session", "Did not send valid cookie data")
    })
  // Used because by this point it's signed
  assert Ok(term) = beam.binary_to_term(data)
  let tuple("google_authentication", sub) = dynamic.unsafe_coerce(term)
  Ok(sub)
}
