import gleam/int
import gleam/list
import gleam/option.{Option}
import gleam/http

pub opaque type Session {
  Session(identifier_id: Option(Int))
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
  option.to_result(session.identifier_id, Nil)
}
