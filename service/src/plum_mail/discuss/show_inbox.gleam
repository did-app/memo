import gleam/dynamic
import gleam/json
import gleam/pgo
import plum_mail/run_sql

pub fn execute(identifier_id) {
  let sql =
    "
    SELECT c.id, c.topic
    FROM conversations AS c
    JOIN participants AS me ON me.conversation_id = c.id
    WHERE me.identifier_id = $1
    "
  let args = [pgo.int(identifier_id)]
  try jsons =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(id) = dynamic.element(row, 0)
        assert Ok(id) = dynamic.int(id)
        assert Ok(topic) = dynamic.element(row, 1)
        assert Ok(topic) = dynamic.string(topic)
        json.object([
          tuple("id", json.int(id)),
          tuple("topic", json.string(topic)),
        ])
      },
    )
  json.list(jsons)
  |> Ok
}
