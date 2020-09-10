import gleam/bit_string
import gleam/base
import gleam/string
import gleam/crypto
import gleam/pgo

pub fn load_session(token) {
  try tuple(selector, secret) = string.split_once(token, ":")
  // Might as well copy PKCE
  try selector = base.url_decode64(selector)

  let sql =
    "
    SELECT identifier_id, validator
    FROM session_tokens
    JOIN remember_tokens ON remember_tokens.id = session_tokens.remember_token_id
    WHERE id = $1
    "
  let args = [pgo.int(0)]

  case todo {
    [] -> todo
    [tuple(validator, identifier_id)] -> {
      crypto.secure_compare(
        validator,
        crypto.hash(crypto.Sha256, bit_string.from_string(secret)),
      )
      todo
    }
  }
  todo
}
// If load session tracks HTTP web/authentication
// authentication.load_session -> Option(UserId) None is not the same as garbage in, although can just keep ignoring
// refresh
// First boot call from client should be to the "refresh" or "authenticate" endoint
// /authentication/refresh
// For testing I need the first sign in point
// Link token should be single use BUT if session already works then continue
// /c/id?t=encoded
// /i/token/redirect=path
// We should use the token first, because we want the link to work once functionality
// The email should have only one token
// Ideally follow up emails should invalidate the first token
// There could be 1 active token per email address, requires DB to know that token
// Token should be active for 24 hours.
// Need a token family
// pub fn generate_token() {
//
// }
