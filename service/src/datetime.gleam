import gleam/atom
import gleam/dynamic.{Dynamic}
import gleam/int
import gleam/string

external type Naive

pub external type DateTime

external fn naive_from_erl(
  tuple(tuple(Int, Int, Int), tuple(Int, Int, Int)),
) -> Result(Naive, Dynamic) =
  "Elixir.NaiveDateTime" "from_erl"

external fn from_naive(Naive, String) -> Result(DateTime, Dynamic) =
  "Elixir.DateTime" "from_naive"

pub fn from_erl(erl) {
  try naive = naive_from_erl(erl)
  try dt = from_naive(naive, "Etc/UTC")
  Ok(dt)
}

pub external fn to_iso8601(DateTime) -> String =
  "Elixir.DateTime" "to_iso8601"

pub fn to_human(dt) {
  let dt = dynamic.from(dt)
  assert Ok(day) = dynamic.field(dt, atom.create_from_string("day"))
  assert Ok(day) = dynamic.int(day)
  assert Ok(month) = dynamic.field(dt, atom.create_from_string("month"))
  assert Ok(month) = dynamic.int(month)
  let month = case month {
    1 -> "January"
    2 -> "February"
    3 -> "March"
    4 -> "April"
    5 -> "May"
    6 -> "June"
    7 -> "July"
    8 -> "August"
    9 -> "September"
    10 -> "October"
    11 -> "November"
    12 -> "December"
  }

  string.join([int.to_string(day), month], " ")
}
