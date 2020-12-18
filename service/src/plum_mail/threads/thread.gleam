import gleam/dynamic
import gleam/io
import gleam/pgo
import gleam/json
import datetime
import plum_mail/run_sql

// identificatation - discovery
//
// // client/identifier
// // if authed
// // if not its look up profile as well.
// web/pair/identifier
//     lookup_pair
//
// // if not authed profile and if doesn't exist default profile
//
// api/identifier
//  finds pair if exists and returns thread id
pub fn load_notes(thread_id) {
    io.debug(thread_id)
    run_sql.execute("SELECT * FROM notes", [], io.debug)
    |> io.debug()
  let sql =
    "
    SELECT n.counter, n.blocks, a.email_address, n.inserted_at
    FROM notes AS n
    JOIN identifiers AS a ON a.id = n.authored_by
    WHERE n.thread_id = $1
    "
  let args = [pgo.int(thread_id)]
  let mapper = fn(row) {
    assert Ok(counter) = dynamic.element(row, 0)
    assert Ok(counter) = dynamic.int(counter)
    assert Ok(contents) = dynamic.element(row, 1)
    // assert Ok(counter) = dynamic.int(counter)
    assert Ok(author) = dynamic.element(row, 2)
    assert Ok(author) = dynamic.string(author)
    assert Ok(inserted_at) = dynamic.element(row, 3)
    assert Ok(inserted_at) = run_sql.cast_datetime(inserted_at)
    json.object([
      tuple("counter", json.int(counter)),
      tuple("contents", dynamic.unsafe_coerce(contents)),
      tuple("author", json.string(author)),
      tuple("inserted_at", json.string(datetime.to_human(inserted_at))),
    ])
  }
  run_sql.execute(sql, args, mapper)
}
