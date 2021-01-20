import gleam/dynamic
import gleam/io
import gleam/pgo
import gleam/json
import datetime
import plum_mail/run_sql

pub fn post_memo(thread_id, position, author_id, content: json.Json) {
  let sql =
    "
    WITH memo AS (
      INSERT INTO memos (thread_id, position, authored_by, content)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    ), lower AS (
      UPDATE pairs
      SET lower_identifier_ack = $2
      WHERE lower_identifier_id = $3
      AND thread_id = $1
    ), upper AS (
      UPDATE pairs
      SET upper_identifier_ack = $2
      WHERE upper_identifier_id = $3
      AND thread_id = $1
    )
    SELECT content, inserted_at, position 
    FROM memo
    "
  let args = [
    pgo.int(thread_id),
    pgo.int(position),
    pgo.int(author_id),
    dynamic.unsafe_coerce(dynamic.from(content)),
  ]
  try db_response =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(content) = dynamic.element(row, 0)
        let content: json.Json = dynamic.unsafe_coerce(content)
        assert Ok(inserted_at) = dynamic.element(row, 1)
        assert Ok(inserted_at) = run_sql.cast_datetime(inserted_at)
        assert Ok(position) = dynamic.element(row, 2)
        assert Ok(position) = dynamic.int(position)

        tuple(inserted_at, content, position)
      },
    )
  run_sql.single(db_response)
  |> Ok
}

pub fn load_memos(thread_id) {
  let sql =
    "
    SELECT n.position, n.content, a.email_address, n.inserted_at
    FROM memos AS n
    JOIN identifiers AS a ON a.id = n.authored_by
    WHERE n.thread_id = $1
    ORDER BY n.position ASC
    "
  let args = [pgo.int(thread_id)]
  let mapper = fn(row) {
    assert Ok(position) = dynamic.element(row, 0)
    assert Ok(position) = dynamic.int(position)
    assert Ok(content) = dynamic.element(row, 1)
    // assert Ok(blocks) = dynamic.field(content, "blocks")
    assert Ok(author) = dynamic.element(row, 2)
    assert Ok(author) = dynamic.string(author)
    assert Ok(inserted_at) = dynamic.element(row, 3)
    assert Ok(inserted_at) = run_sql.cast_datetime(inserted_at)
    json.object([
      tuple("position", json.int(position)),
      tuple("content", dynamic.unsafe_coerce(content)),
      tuple("author", json.string(author)),
      tuple("posted_at", json.string(datetime.to_iso8601(inserted_at))),
    ])
  }
  run_sql.execute(sql, args, mapper)
  |> io.debug()
}

pub fn to_json(thread) {
  let tuple(thread_id, ack, memos) = thread
  json.object([
    tuple("id", json.int(thread_id)),
    tuple("ack", json.int(ack)),
    tuple("memos", json.list(memos)),
  ])
}
