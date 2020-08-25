import gleam/base
import gleam/string
import gleam/crypto
import gleam/http

pub fn generate_email_address(domain) {
  crypto.strong_random_bytes(8)
  |> base.url_encode64(False)
  |> string.append(domain)
}

pub fn get_resp_cookie(response) {
  try set_cookie_header = http.get_resp_header(response, "set-cookie")
  let [pair, .._attributes] = string.split(set_cookie_header, ";")
  // try tuple(key, value) =
  string.split_once(pair, "=")
}
