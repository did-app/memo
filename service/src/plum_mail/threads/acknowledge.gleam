import gleam/dynamic.{Dynamic}
import gleam/int
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql

pub type Params {
  Params(thread_id: Int, position: Int)
}

pub fn params(raw: Dynamic, thread_id: String) {
  assert Ok(thread_id) = int.parse(thread_id)
  try position = acl.required(raw, "position", dynamic.int)
  Params(thread_id, position)
  |> Ok()
}

pub fn execute(params, identifier_id) {
  let Params(thread_id, position) = params
  let sql =
    "
    WITH lower AS (
      UPDATE pairs
      SET lower_identifier_ack = $3
      WHERE lower_identifier_id = $2
      AND thread_id = $1
    ), upper AS (
      UPDATE pairs
      SET upper_identifier_ack = $3
      WHERE upper_identifier_id = $2
      AND thread_id = $1
    )
    SELECT 42
    "
  let args = [pgo.int(thread_id), pgo.int(identifier_id), pgo.int(position)]
  try [_] = run_sql.execute(sql, args, fn(x) { x })
  Ok(Nil)
}
