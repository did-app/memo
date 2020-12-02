import gleam/base
import gleam/bit_string
import gleam/string
import gleam/crypto

fn generate_digest(data, secret) {
  data
  |> crypto.hmac(crypto.Sha256, secret)
  // can use url_encode because uses `--` for join
  |> base.encode64(False)
}

pub fn encode(data: BitString, secret: BitString) {
  string.concat([
    base.encode64(data, False),
    "--",
    generate_digest(data, secret),
  ])
}

pub fn decode(cookie: String, secret: BitString) {
  case string.split(cookie, "--") {
    [base64_string, digest] -> {
      try data = base.decode64(base64_string)
      case crypto.secure_compare(
        bit_string.from_string(digest),
        bit_string.from_string(generate_digest(data, secret)),
      ) {
        True -> Ok(data)
        False -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}
