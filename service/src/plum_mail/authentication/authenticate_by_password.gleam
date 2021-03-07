import gleam/bit_string
import gleam/dynamic.{Dynamic}
import gleam/list
import gleam/map
import gleam/result
import gleam/crypto
import perimeter/input
import perimeter/scrub.{Report, Unprocessable}
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier

pub type Params {
  Params(email_address: EmailAddress, password: String)
}

// Note params is never used
pub fn params(raw: Dynamic) {
  try email_address = input.required(raw, "email_address", input.as_email)
  try password = input.required(raw, "password", input.as_string)
  Params(email_address, password)
  |> Ok
}

// Hardcoded because we don't want password word field on db model yet.
const accounts = [
  tuple("peter@sendmemo.app", "OnionLightningSea"),
  tuple("richard@sendmemo.app", "SproutGlitterWednesday"),
]

const denied = Report(
  Unprocessable,
  "Invalid credentials",
  "Could not sign in with provided email and password.",
)

pub fn run(params) {
  let Params(email_address, password) = params
  try correct =
    list.key_find(accounts, email_address.value)
    |> result.map_error(fn(_) { denied })
  try Nil = case crypto.secure_compare(
    bit_string.from_string(password),
    bit_string.from_string(correct),
  ) {
    True -> Ok(Nil)
    False -> Error(denied)
  }
  identifier.find_or_create(email_address)
}
