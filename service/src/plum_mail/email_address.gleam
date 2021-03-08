import gleam/string

// regex match from mdn form validation
// split into hash user and domain
// https://en.wikipedia.org/wiki/Email_address#Local-part
// wiki doesn't have hash as a real definition, but postmark does
// username + hash = local
// display name <email address> is part of  RFC 822 sill called an email address
// https://github.com/Porges/email-validate-hs
// has domain part and local part
pub type EmailAddress {
  EmailAddress(value: String)
}

pub fn validate(email_address) {
  let email_address = string.trim(email_address)
  try parts = string.split_once(string.reverse(email_address), "@")
  case parts {
    tuple("", _) -> Error(Nil)
    tuple(_, "") -> Error(Nil)
    _ -> Ok(EmailAddress(email_address))
  }
}

pub fn to_path(email_address) {
  let EmailAddress(value) = email_address
  // Valid because using value from email address, we should have a function to get parts or save in record deconstructed
  assert [username, domain] = string.split(value, "@")
  string.join(["/", domain, "/", username], "")
}
