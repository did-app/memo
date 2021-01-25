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
    WITH maybe_new AS (
      INSERT INTO participations (thread_id, identifier_id, acknowledged)
      VALUES ($1, $2, $3)
      ON CONFLICT DO NOTHING
    )
    UPDATE participations 
    SET acknowledged = $3
    WHERE thread_id = $1
    AND identifier_id = $2
    RETURNING *
    "
  let args = [
    pgo.int(thread_id),
    run_sql.uuid(identifier_id),
    pgo.int(position),
  ]
  try [_] = run_sql.execute(sql, args, fn(x) { x })
  Ok(Nil)
}
