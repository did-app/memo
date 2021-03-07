import gleam/result
import perimeter/input
import perimeter/scrub.{Report, Unprocessable}
import plum_mail/authentication

pub type Params {
  Params(code: String)
}

pub fn params(raw) {
  try code = input.required(raw, "code", input.as_string)
  Params(code)
  |> Ok
}

pub fn run(params) {
  let Params(code) = params
  // link tokens last for ever so might as well be a signed message as well
  // delete and use purpose link token
  authentication.validate_link_token(code)
}
