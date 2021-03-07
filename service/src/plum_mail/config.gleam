import gleam/map
import gleam/os
import gleam/result
import gleam_sentry
import perimeter/input.{CastFailure, NotProvided}
import oauth/client as oauth

pub type Config {
  Config(
    origin: String,
    // Needs to be a single origin otherwise a lot of tracking for dispatch notification etc
    client_origin: String,
    postmark_api_token: String,
    secret: BitString,
    google_client: oauth.Client,
    sentry_client: gleam_sentry.Client,
  )
}

pub fn from_env() {
  let env = os.get_env()

  try origin = required(env, "ORIGIN")
  try client_origin = required(env, "CLIENT_ORIGIN")
  try postmark_api_token = required(env, "POSTMARK_API_TOKEN")
  try secret = required(env, "SECRET")
  try environment = required(env, "ENVIRONMENT")
  try sentry_dsn = required(env, "SENTRY_DSN")
  try sentry_client =
    gleam_sentry.init(sentry_dsn, environment)
    |> result.map_error(fn(_: Nil) { CastFailure("SENTRY_DSN", "dsn") })

  try google_client_id = required(env, "GOOGLE_CLIENT_ID")
  try google_client_secret = required(env, "GOOGLE_CLIENT_SECRET")
  let google_client =
    oauth.Client(
      google_client_id,
      google_client_secret,
      oauth.AbsoluteUri("https", "accounts.google.com", "/o/oauth2/auth"),
      oauth.AbsoluteUri("https", "oauth2.googleapis.com", "/token"),
      [tuple("access_type", "offline")],
    )

  Config(
    origin,
    client_origin,
    postmark_api_token,
    <<secret:utf8>>,
    google_client,
    sentry_client,
  )
  |> Ok
}

fn required(raw, key) {
  case map.get(raw, key) {
    Ok(value) -> Ok(value)
    Error(_) -> Error(NotProvided(key))
  }
}
