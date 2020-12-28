import gleam/dynamic
import gleam/io
import gleam/pgo
import gleam/json
import datetime
import plum_mail/run_sql

pub fn write_note(thread_id, counter, author_id, content: json.Json) {
  let sql =
    "
    INSERT INTO notes (thread_id, counter, authored_by, content)
    VALUES ($1, $2, $3, $4)
    RETURNING *
    "
  let args = [
    pgo.int(thread_id),
    pgo.int(counter),
    pgo.int(author_id),
    dynamic.unsafe_coerce(dynamic.from(content)),
  ]
  run_sql.execute(sql, args, fn(x) { x })
}

pub fn load_notes(thread_id) {
  let sql =
    "
    SELECT n.counter, n.content, a.email_address, n.inserted_at
    FROM notes AS n
    JOIN identifiers AS a ON a.id = n.authored_by
    WHERE n.thread_id = $1
    ORDER BY n.counter ASC
    "
  let args = [pgo.int(thread_id)]
  let mapper = fn(row) {
    assert Ok(counter) = dynamic.element(row, 0)
    assert Ok(counter) = dynamic.int(counter)
    assert Ok(contents) = dynamic.element(row, 1)
    // assert Ok(blocks) = dynamic.field(contents, "blocks")
    assert Ok(author) = dynamic.element(row, 2)
    assert Ok(author) = dynamic.string(author)
    assert Ok(inserted_at) = dynamic.element(row, 3)
    assert Ok(inserted_at) = run_sql.cast_datetime(inserted_at)
    json.object([
      tuple("counter", json.int(counter)),
      tuple("blocks", dynamic.unsafe_coerce(contents)),
      tuple("author", json.string(author)),
      tuple("inserted_at", json.string(datetime.to_iso8601(inserted_at))),
    ])
  }
  run_sql.execute(sql, args, mapper)
  |> io.debug()
}

pub fn to_json(thread) {
  let tuple(thread_id, notes) = thread
  json.object([
    tuple("id", json.int(thread_id)),
    tuple("notes", json.list(notes)),
  ])
}
