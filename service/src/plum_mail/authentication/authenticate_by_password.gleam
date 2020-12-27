import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier

pub fn run(username, password) {
  // Hardcoded because we don't want password word field on db model yet.
  // looking at alternative (OAuth) solutions
  // This doesn't work properly, but we want to down grade the complexity of authentication for a bit.
  assert Ok(email_address) = case username {
    "peter" -> {
      let True = password == "onion"
      assert Ok(email_address) = email_address.validate("peter@plummail.co")
      Ok(email_address)
    }
    "richard" -> {
      let True = password == "sprout"
      assert Ok(email_address) = email_address.validate("richard@plummail.co")
      Ok(email_address)
    }
  }
  identifier.find_or_create(email_address)
}
