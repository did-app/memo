import plum_mail/email_address.{EmailAddress}
import gleam/should

pub fn validate_email_test() {
  email_address.validate("")
  |> should.equal(Error(Nil))

  email_address.validate("@")
  |> should.equal(Error(Nil))

  email_address.validate("    @ ")
  |> should.equal(Error(Nil))

  email_address.validate("me@")
  |> should.equal(Error(Nil))

  email_address.validate("@nothing")
  |> should.equal(Error(Nil))

  email_address.validate("me@example.com")
  |> should.equal(Ok(EmailAddress("me@example.com")))
  email_address.validate("   me@example.com ")
  |> should.equal(Ok(EmailAddress("me@example.com")))
}
