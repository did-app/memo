import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/string
import gleam/result
import gleam/beam
import gleam/http.{Request}
import gleam/httpc
import gleam/json
import gleam/pgo
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

pub fn save_authorization(sub, email_address, refresh_token, access_token) {
  let sql =
    "
    WITH updated_authorization AS (
      UPDATE google_authorizations 
      SET email_address = $2, refresh_token = $3, access_token = $4 
      WHERE sub = $1
      RETURNING *
    ), new_authorization AS (
      INSERT INTO google_authorizations (sub, email_address, refresh_token, access_token)
      VALUES ($1, $2, $3, $4)
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
    pgo.text(access_token),
  ]

  let mapper = fn(row) {
    // Use assert because it's a code error to fail
    assert Ok(sub) = dynamic.element(row, 0)
    assert Ok(sub) = dynamic.string(sub)
    sub
  }
  try authorizations = run_sql.execute(sql, args, mapper)
  assert [authorization] = authorizations
  Ok(authorization)
}

pub fn authorize(code, client) {
  let auth_request = oauth.token_request(client, code, "http://localhost:8080")
  try auth_response =
    httpc.send(auth_request)
    |> result.map_error(fn(_) { todo("map error for authorize") })

  try raw =
    json.decode(auth_response.body)
    |> result.map_error(fn(_) { todo("map error for authorize") })

  try tuple(access_token, refresh_token) =
    oauth.cast_token_response(dynamic.from(raw))
    |> result.map_error(fn(_) { todo("map error for authorize") })

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
    |> httpc.send()
    |> result.map_error(fn(_) { todo("map error for authorize") })
    |> io.debug

  try raw =
    json.decode(user_response.body)
    |> result.map_error(fn(_) { todo("map error for authorize") })

  let raw = dynamic.from(raw)
  assert Ok(sub) = dynamic.field(raw, "sub")
  assert Ok(sub) = dynamic.string(sub)
  assert Ok(email_address) = dynamic.field(raw, "email")
  assert Ok(email_address) = dynamic.string(email_address)

  try _ = save_authorization(sub, email_address, refresh_token, access_token)

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
  run_sql.execute(sql, args, row_to_uploader)
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
  try uploaders = run_sql.execute(sql, args, row_to_uploader)
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
  try uploaders = run_sql.execute(sql, args, row_to_uploader)
  case uploaders {
    [uploader] -> Ok(uploader)
  }
}

fn row_to_uploader(row) {
  assert Ok(sub) = dynamic.element(row, 0)
  assert Ok(sub) = dynamic.string(sub)
  assert Ok(id) = dynamic.element(row, 1)
  assert Ok(id) = dynamic.string(id)
  assert Ok(name) = dynamic.element(row, 2)
  assert Ok(name) = dynamic.string(name)
  assert Ok(parent_id) = dynamic.element(row, 3)
  assert Ok(parent_id) = run_sql.dynamic_option(parent_id, dynamic.string)

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
}

pub fn edit_uploader() {
  todo
}

pub fn delete_uploader(id) {
  let sql = "
  DELETE FROM drive_uploaders
  WHERE id = $1
  "
  let args = [pgo.text(id)]
  try _ = run_sql.execute(sql, args, fn(_) { Nil })
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
    _ -> Error(Nil)
  }
  let cookies = http.get_req_cookies(request)
  case list.key_find(cookies, "google_authentication") {
    Ok(cookie) -> decode_cookie(cookie, secret)
  }
}

pub fn decode_cookie(cookie, secret) {
  try data = signed_message.decode(cookie, secret)
  assert Ok(term) = beam.binary_to_term(data)
  let tuple("google_authentication", sub) = dynamic.unsafe_coerce(term)
  Ok(sub)
}
