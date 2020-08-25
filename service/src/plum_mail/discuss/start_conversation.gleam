import gleam/dynamic
import gleam/result
import gleam/pgo
import plum_mail/run_sql

pub fn execute(topic, owner_id) {
  let sql =
    "
    WITH new_conversation AS (
        INSERT INTO conversations (topic)
        VALUES ($1)
        RETURNING *
    ), new_participant AS (
        INSERT INTO participants (conversation_id, identifier_id)
        VALUES ((SELECT id FROM new_conversation), $2)
    )
    SELECT id FROM new_conversation
    "
  let args = [pgo.text(topic), pgo.int(owner_id)]
  try [id] =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(id) = dynamic.element(row, 0)
        assert Ok(id) = dynamic.int(id)
        id
      },
    )
  Ok(id)
}
