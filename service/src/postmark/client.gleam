import gleam/dynamic
import gleam/io
import gleam/result
import gleam/http
import gleam/json
import perimeter/input
import perimeter/input/json as json_input
import perimeter/input/http_response
import perimeter/scrub.{Report, ServiceError}
import perimeter/services/http_client
import perimeter/email_address.{EmailAddress}

pub type Failure {
  Failure(retry: Bool)
}

// let's make all email bodies work with ,markdown
// Could make a content type Type that always has text but has HTML as optional
pub fn send_email(from, to, subject, text_body, api_token) {
  case api_token {
    "POSTMARK_DUMMY_TOKEN" -> {
      io.debug(from)
      io.debug(to)
      io.debug(subject)
      io.debug(text_body)
      Ok(Ok(Nil))
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
      let request = api_post("/email", api_token, data)
      dispatch(request)
    }
  }
}

pub fn send_email_with_template(
  from,
  to,
  template_alias,
  template_model,
  api_token,
) {
  case api_token {
    "POSTMARK_DUMMY_TOKEN" -> {
      io.debug(from)
      io.debug(to)
      io.debug(template_alias)
      io.debug(template_model)
      Ok(Ok(Nil))
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
          tuple("TemplateAlias", json.string(template_alias)),
          tuple("TemplateModel", template_model),
        ])
      let request = api_post("/email/withTemplate", api_token, data)
      dispatch(request)
    }
  }
}

pub fn api_post(path, api_token, data) {
  http.default_req()
  |> http.set_method(http.Post)
  |> http.set_host("api.postmarkapp.com")
  |> http.set_path(path)
  |> http.prepend_req_header("content-type", "application/json")
  |> http.prepend_req_header("accept", "application/json")
  |> http.prepend_req_header("x-postmark-server-token", api_token)
  |> http.set_req_body(json.encode(data))
}

pub fn dispatch(request) {
  try response =
    http_client.send(request)
    |> result.map_error(http_client.to_report)
  case response {
    http.Response(status: 200, ..) -> Ok(Ok(Nil))
    http.Response(status: 422, body: body, ..) -> {
      // Can't use input parse json because that's all on responses
      try raw = http_response.get_json(response)
      try error_code =
        json_input.required(raw, "ErrorCode", json_input.as_int)
        |> result.map_error(input.to_service_report(_, "Data"))
      case error_code {
        406 ->
          Failure(retry: False)
          |> Error
          |> Ok
        // Other error code retry
        _ ->
          Failure(retry: True)
          |> Error
          |> Ok
      }
    }
  }
}
