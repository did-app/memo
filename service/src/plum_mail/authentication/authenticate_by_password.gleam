import gleam/dynamic.{Dynamic}
import gleam/map
import plum_mail/acl
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier

pub type Params {
  Params(email_address: EmailAddress, password: String)
}

// Note params is never used
pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_email)
  try password = acl.required(raw, "password", acl.as_string)
  Params(email_address, password)
  |> Ok
}

pub fn from_form(raw) {
  assert Ok(email_address) = map.get(raw, "email_address")
  assert Ok(email_address) = email_address.validate(email_address)
  assert Ok(password) = map.get(raw, "password")
  Params(email_address, password)
  |> Ok
}

pub fn run(params) {
  // Hardcoded because we don't want password word field on db model yet.
  // looking at alternative (OAuth) solutions
  // This doesn't work properly, but we want to down grade the complexity of authentication for a bit.
  let Params(email_address, password) = params
  assert Ok(email_address) = case email_address.value {
    "peter@plummail.co" -> {
      let True = password == "onion"
      assert Ok(email_address) = email_address.validate("peter@plummail.co")
      Ok(email_address)
    }
    "richard@plummail.co" -> {
      let True = password == "sprout"
      assert Ok(email_address) = email_address.validate("richard@plummail.co")
      Ok(email_address)
    }
  }
  identifier.find_or_create(email_address)
}
