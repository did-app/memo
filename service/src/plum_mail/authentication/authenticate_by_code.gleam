import gleam/dynamic.{Dynamic}
import gleam/result
import plum_mail/acl
import plum_mail/authentication
import plum_mail/error

pub type Params {
  Params(code: String)
}

pub fn params(raw: Dynamic) {
  try code = acl.required(raw, "code", acl.as_string)
  Params(code)
  |> Ok
}

pub fn run(params) {
  let Params(code) = params
  // link tokens last for ever so might as well be a signed message as well
  // delete and use purpose link token
  authentication.validate_link_token(code)
  |> result.map_error(fn(_: Nil) { error.Forbidden })
}
