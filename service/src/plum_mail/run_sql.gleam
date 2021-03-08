import gleam/atom
import gleam/dynamic.{Dynamic}
import gleam/float
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/pgo
import gleam_uuid.{UUID}
import perimeter/scrub.{Report, UnknownError}
import datetime

pub fn dynamic_option(raw, cast) {
  let null = dynamic.from(atom.create_from_string("null"))
  case null == raw {
    True -> Ok(None)
    False -> result.map(cast(raw), Some)
  }
}

pub fn uuid(uuid: UUID) -> pgo.PgType {
  // Could be done by unsafe coerce to tuple, in reality need to bits on the uuid module
  assert Ok(bits) =
    uuid
    |> dynamic.from
    |> dynamic.element(1)
  dynamic.unsafe_coerce(bits)
}

pub fn binary_to_uuid4(bits: BitString) -> UUID {
  dynamic.unsafe_coerce(dynamic.from(tuple(
    atom.create_from_string("uuid"),
    bits,
  )))
}

pub fn cast_datetime(raw: Dynamic) {
  try date = dynamic.element(raw, 0)
  try time = dynamic.element(raw, 1)
  try year = dynamic.element(date, 0)
  try year = dynamic.int(year)
  try month = dynamic.element(date, 1)
  try month = dynamic.int(month)
  try day = dynamic.element(date, 2)
  try day = dynamic.int(day)
  try hour = dynamic.element(time, 0)
  try hour = dynamic.int(hour)
  try minute = dynamic.element(time, 1)
  try minute = dynamic.int(minute)
  try second = dynamic.element(time, 2)
  try second = dynamic.float(second)
  // Note this looses milliseconds
  let second = float.round(float.floor(second))
  try dt =
    datetime.from_erl(tuple(
      tuple(year, month, day),
      tuple(hour, minute, second),
    ))
    |> result.map_error(fn(_) { "Datetime could not be cast from values" })
  Ok(dt)
}

pub fn execute(sql, args) {
  let conn = atom.create_from_string("default")
  try tuple(_, _, rows) =
    pgo.query(conn, sql, args)
    |> result.map_error(fn(reason) {
      // this should have a bug report and bug report id, but we can see it in the heroku SQL view perhaps
      io.debug(reason)
      Report(UnknownError, "Database Error", "Database query failed")
    })
  Ok(rows)
}
