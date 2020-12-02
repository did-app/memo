import gleam/map
import gleam/os

pub type Config {
  Config(client_origin: String, postmark_api_token: String, secret: BitString)
}

pub fn from_env() {
  let env = os.get_env()

  assert Ok(client_origin) = map.get(env, "CLIENT_ORIGIN")
  assert Ok(postmark_api_token) = map.get(env, "POSTMARK_API_TOKEN")
  assert Ok(secret) = map.get(env, "SECRET")
  Config(client_origin, postmark_api_token, <<secret:utf8>>)
}
