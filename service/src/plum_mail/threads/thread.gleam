import gleam/dynamic
import gleam/io
import gleam/pgo
import gleam/json.{Json}
import datetime.{DateTime}
import plum_mail/run_sql

pub type Memo {
  Memo(posted_at: DateTime, content: Json, position: Int)
}

pub fn memo_to_json(memo) {
  let Memo(posted_at, content, position) = memo
  json.object([
    tuple("posted_at", json.string(datetime.to_iso8601(posted_at))),
    tuple("content", content),
    tuple("position", json.int(position)),
  ])
}

pub fn post_memo(thread_id, position, author_id, content: json.Json) {
  let sql =
    "
    WITH new_memo AS (
      INSERT INTO memos (thread_id, position, authored_by, content)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    ), participation AS (
      UPDATE participations
      SET acknowledged = $2
      WHERE thread_id = $1
      AND identifier_id = $3
    )
    SELECT content, inserted_at, position 
    FROM new_memo
    "
  let args = [
    run_sql.uuid(thread_id),
    pgo.int(position),
    run_sql.uuid(author_id),
    dynamic.unsafe_coerce(dynamic.from(content)),
  ]
  try [memo] =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(content) = dynamic.element(row, 0)
        let content: json.Json = dynamic.unsafe_coerce(content)
        assert Ok(posted_at) = dynamic.element(row, 1)
        assert Ok(posted_at) = run_sql.cast_datetime(posted_at)
        assert Ok(position) = dynamic.element(row, 2)
        assert Ok(position) = dynamic.int(position)

        Memo(posted_at, content, position)
      },
    )
  memo
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
  let args = [run_sql.uuid(thread_id)]
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
}
