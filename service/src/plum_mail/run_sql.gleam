import gleam/atom
import gleam/dynamic.{Dynamic}
import gleam/float
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/pgo
import datetime

pub fn dynamic_option(raw, cast) {
  let null = dynamic.from(atom.create_from_string("null"))
  case null == raw {
    True -> Ok(None)
    False -> result.map(cast(raw), Some)
  }
}

// FIXME move to pgo lib
pub fn nullable(value: Option(a), mapper: fn(a) -> pgo.PgType) {
  case value {
    Some(term) -> mapper(term)
    None -> pgo.null()
  }
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
    |> result.map_error(fn(_) { todo("datetime erro") })
  Ok(dt)
}

pub fn execute(sql, args, mapper) {
  let conn = atom.create_from_string("default")
  try tuple(_, _, rows) =
    pgo.query(conn, sql, args)
    |> result.map_error(fn(err) {
      // TODO this should have a bug report and bug report id
      io.debug(err)
      // tuple(error.InternalServiceError, "Failed to query the database")
      todo("DB Error")
    })

  list.map(rows, mapper)
  |> Ok()
}

// TODO return error with a not found type that can use try
pub fn single(rows) {
  case rows {
    [] -> None
    [value] -> Some(value)
  }
}
