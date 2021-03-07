import gleam/dynamic.{Dynamic}
import gleam/map
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

pub fn run(params) {
  // Hardcoded because we don't want password word field on db model yet.
  // looking at alternative (OAuth) solutions
  // This doesn't work properly, but we want to down grade the complexity of authentication for a bit.
  let Params(email_address, password) = params
  try email_address = case email_address.value {
    "peter@sendmemo.app" ->
      // TODO secure compare
      case password == "OnionLightningSea" {
        True -> Ok(email_address)
        False ->
          Error(Report(
            Unprocessable,
            "Invalid credentials",
            "Could not sign in with provided email and password.",
          ))
      }
    "richard@sendmemo.app" ->
      case password == "SproutGlitterWednesday" {
        True -> Ok(email_address)
        False ->
          Error(Report(
            Unprocessable,
            "Invalid credentials",
            "Could not sign in with provided email and password.",
          ))
      }
    _ ->
      Error(Report(
        Unprocessable,
        "Invalid credentials",
        "Could not sign in with provided email and password.",
      ))
  }
  identifier.find_or_create(email_address)
}
