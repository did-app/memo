import gleam/map
import gleam/os
import gleam_sentry
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

  assert Ok(origin) = map.get(env, "ORIGIN")
  assert Ok(client_origin) = map.get(env, "CLIENT_ORIGIN")
  assert Ok(postmark_api_token) = map.get(env, "POSTMARK_API_TOKEN")
  assert Ok(secret) = map.get(env, "SECRET")
  assert Ok(environment) = map.get(env, "ENVIRONMENT")
  assert Ok(sentry_dsn) = map.get(env, "SENTRY_DSN")
  assert Ok(sentry_client) = gleam_sentry.init(sentry_dsn, environment)

  assert Ok(google_client_id) = map.get(env, "GOOGLE_CLIENT_ID")
  assert Ok(google_client_secret) = map.get(env, "GOOGLE_CLIENT_SECRET")
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
}
