import gleam/map
import gleam/os

pub type Config {
  Config(client_origin: String)
}

pub fn from_env() {
  let env = os.get_env()

  assert Ok(client_origin) = map.get(env, "CLIENT_ORIGIN")
  Config(client_origin)
}
