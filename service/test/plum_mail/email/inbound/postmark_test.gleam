import gleam/io
import gleam/http
import plum_mail/support
import plum_mail/web/router.{handle}
import gleam/should

pub fn bouncing_email_test() {
  let request =
    http.default_req()
    |> http.set_method(http.Post)
    |> http.set_path("/inbound")
    |> http.prepend_req_header("content-type", "application/json")
    |> http.set_req_body(<<
      "{
  \"FromName\": \"Postmarkapp Support\",
  \"From\": \"support@postmarkapp.com\",
  \"FromFull\": {
    \"Email\": \"support@postmarkapp.com\",
    \"Name\": \"Postmarkapp Support\",
    \"MailboxHash\": \"\"
  },
  \"To\": \"\\\"Peter\\\" <peter@plummail.co>\",
  \"ToFull\": [
    {
      \"Email\": \"peter@plummail.co\",
      \"Name\": \"Peter\",
      \"MailboxHash\": \"\"
    }
  ],
  \"StrippedTextReply\": \"This is the reply text\"


}":utf8,
    >>)

  let response = handle(request, support.test_config())
  io.debug(response)

  should.equal(response.status, 200)
}
