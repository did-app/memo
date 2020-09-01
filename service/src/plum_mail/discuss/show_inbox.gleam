import gleam/dynamic
import gleam/io
import gleam/json
import gleam/pgo
import plum_mail/run_sql

pub fn execute(identifier_id) {
  let sql =
    "
    SELECT c.id, c.topic, c.resolved, pl.participants
    FROM conversations AS c
    JOIN participants AS me ON me.conversation_id = c.id
    JOIN participant_lists AS pl ON pl.conversation_id = c.id
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
        assert Ok(resolved) = dynamic.element(row, 2)
        assert Ok(resolved) = dynamic.bool(resolved)
        assert Ok(participants) = dynamic.element(row, 3)
        assert Ok(participants) = dynamic.string(participants)
        assert Ok(participants) = json.decode(participants)
        let participants = dynamic.from(participants)
        assert Ok(participants) =
          dynamic.typed_list(
            participants,
            fn(item) {
              assert Ok(email_address) = dynamic.field(item, "email_address")
              assert Ok(email_address) = dynamic.string(email_address)
              json.object([tuple("email_address", json.string(email_address))])
              |> Ok
            },
          )
        json.object([
          tuple("id", json.int(id)),
          tuple("topic", json.string(topic)),
          tuple("resolved", json.bool(resolved)),
          tuple("participants", json.list(participants)),
        ])
      },
    )
  json.list(jsons)
  |> Ok
}
