import gleam/dynamic
import gleam/io
import gleam/http
import gleam/httpc
import gleam/json
import plum_mail/email_address.{EmailAddress}

pub type Failure {
  Failure(retry: Bool)
}

// let's make all email bodies work with ,markdown
// TODO content type that is always text but has HTML as optional
pub fn send_email(from, to, subject, text_body, api_token) {
  case api_token {
    "POSTMARK_DUMMY_TOKEN" -> {
      io.debug(from)
      io.debug(to)
      io.debug(subject)
      io.debug(text_body)
      Ok(Nil)
    }
    _ -> {
      // let EmailAddress(from_string) = from
      // let EmailAddress(to_string) = to
      // This needs to be a email string with detail, i.e. a name
      let from_string = from
      let to_string = to
      let data =
        json.object([
          tuple("From", json.string(from_string)),
          tuple("To", json.string(to_string)),
          tuple("Subject", json.string(subject)),
          tuple("TextBody", json.string(text_body)),
        ])
      let request =
        http.default_req()
        |> http.set_method(http.Post)
        |> http.set_host("api.postmarkapp.com")
        |> http.set_path("/email")
        |> http.prepend_req_header("content-type", "application/json")
        |> http.prepend_req_header("accept", "application/json")
        |> http.prepend_req_header("x-postmark-server-token", api_token)
        |> http.set_req_body(json.encode(data))
      io.debug(request)
      assert Ok(response) = httpc.send(request)
      case response {
        http.Response(status: 200, ..) -> Ok(Nil)
        http.Response(status: 422, body: body, ..) -> {
          assert Ok(data) = json.decode(body)
          let data = dynamic.from(data)
          assert Ok(error_code) = dynamic.field(data, "ErrorCode")
          assert Ok(error_code) = dynamic.int(error_code)
          case error_code {
            406 ->
              Failure(retry: False)
              |> Error
            // Other error code retry
            _ ->
              Failure(retry: True)
              |> Error
          }
        }
      }
    }
  }
}
