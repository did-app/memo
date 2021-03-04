import gleam/io
import gleam/string
import plum_mail/authentication
import drive_uploader
import gleam/should

pub fn db_test() {
  // TODO random string
  let sub = string.concat(["google_", authentication.random_string(8)])
  let email_address = "clive@example.com"
  let refresh_token = "refresh_2345"
  let access_token = "access_772"

  drive_uploader.save_authorization(
    sub,
    email_address,
    refresh_token,
    access_token,
  )
  |> should.equal(Ok(sub))

  io.debug("okss")

  drive_uploader.save_authorization(
    sub,
    email_address,
    "refrest_2323",
    "access_999",
  )
  |> should.equal(Ok(sub))

  assert Ok(uploader1) = drive_uploader.create_uploader(sub, "First Uploader")
  assert Ok(uploader2) = drive_uploader.create_uploader(sub, "Second Uploader")

  assert Ok(uploaders) = drive_uploader.list_for_authorization(sub)
  uploaders
  |> should.equal([uploader1, uploader2])
  todo("finish")
}
