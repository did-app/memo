import gleam/dynamic
import gleam/io
import gleam/result
import gleam/pgo
import plum_mail/run_sql
import plum_mail/discuss/conversation.{Conversation}

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
    SELECT id, topic FROM new_conversation
    "
  let args = [pgo.text(topic), pgo.int(owner_id)]
  try [c] =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        io.debug(row)
        assert Ok(id) = dynamic.element(row, 0)
        assert Ok(id) = dynamic.int(id)
        assert Ok(topic) = dynamic.element(row, 1)
        assert Ok(topic) = dynamic.string(topic)

        Conversation(id, topic, [], [])
      },
    )
  Ok(c)
}
