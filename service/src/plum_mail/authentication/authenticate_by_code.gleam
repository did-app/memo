import gleam/dynamic.{Dynamic}
import gleam/result
import perimeter/input
import perimeter/scrub.{Report, Unprocessable}
import plum_mail/authentication
import plum_mail/error

pub type Params {
  Params(code: String)
}

pub fn params(raw: Dynamic) {
  try code = input.required(raw, "code", input.as_string)
  Params(code)
  |> Ok
}

pub fn run(params) {
  let Params(code) = params
  // link tokens last for ever so might as well be a signed message as well
  // delete and use purpose link token
  authentication.validate_link_token(code)
  |> result.map_error(fn(_: Nil) {
    Report(
      Unprocessable,
      "Forbidden",
      "Unable to complete action due to invalid link token",
    )
  })
}
