import gleam/atom
import gleam/dynamic.{Dynamic}
import gleam/io
import gleam/result
import gleam/httpc
import perimeter/scrub.{Report, Unprocessable}

// Could just use report when no further context to be given
pub type Failure {
  ConnectionFailure(List(Dynamic))
}

pub fn to_report(failure) {
  Report(
    Unprocessable,
    "Connection failure",
    "Connection to HTTP service failed",
  )
}

pub fn send(request) {
  httpc.send(request)
  |> result.map_error(cast_reason)
}

pub fn cast_reason(reason) {
  let failed_connect = dynamic.from(atom.create_from_string("failed_connect"))
  case dynamic.element(reason, 0) {
    Ok(tag) if tag == failed_connect ->
      dynamic.element(reason, 1)
      |> result.then(dynamic.list)
      |> result.unwrap([])
      |> ConnectionFailure()
  }
}
