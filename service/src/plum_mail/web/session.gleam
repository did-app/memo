import gleam/int
import gleam/list
import gleam/option.{Option, Some}
import gleam/http
import plum_mail/error

pub opaque type Session {
  Session(identifier_id: Option(Int))
}

pub fn authenticated(identifier_id) {
  Session(Some(identifier_id))
}

pub fn to_string(session) {
  let Session(Some(identifier_id)) = session
  int.to_string(identifier_id)
}

fn extract_user_id(request) {
  let cookies = http.get_req_cookies(request)
  try session_string = list.key_find(cookies, "session")
  int.parse(session_string)
}

pub fn extract(request) -> Session {
  Session(option.from_result(extract_user_id(request)))
}

pub fn require_authentication(session: Session) {
  option.to_result(session.identifier_id, error.Unauthenticated)
}
