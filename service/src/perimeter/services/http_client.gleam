import gleam/atom
import gleam/bit_string
import gleam/dynamic.{Dynamic}
import gleam/io
import gleam/result
import gleam/http.{Request}
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

pub fn send(request: Request(String)) {
  // let Request(body: body, ..) = request
  // let r2 = Request(..request, body: bit_string.from_string(body))
  let Request(a, b, c, d, e, f, g, h) = request
  Request(a, b, bit_string.from_string(c), d, e, f, g, h)
  |> httpc.send_bits()
  |> result.map_error(cast_reason)
}

pub fn send_bits(request) {
  httpc.send_bits(request)
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
