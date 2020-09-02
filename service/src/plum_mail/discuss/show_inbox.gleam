import gleam/dynamic
import gleam/io
import gleam/option
import gleam/json
import gleam/pgo
import plum_mail/run_sql

pub fn execute(identifier_id) {
  // TO can in memory see if cursor > latest
  // Can in memory see if resolved
  let sql =
    "
    WITH search AS (
        SELECT DISTINCT ON (c.id) c.id, c.topic, c.resolved, pl.participants, me.cursor, me.notify, m.inserted_at, m.counter
        FROM conversations AS c
        JOIN participants AS me ON me.conversation_id = c.id
        JOIN participant_lists AS pl ON pl.conversation_id = c.id
        LEFT JOIN messages AS m ON m.conversation_id = c.id
        WHERE me.identifier_id = $1
        ORDER BY c.id DESC
    )
    SELECT * FROM search
    ORDER BY inserted_at DESC
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

        assert Ok(cursor) = dynamic.element(row, 4)
        assert Ok(cursor) = dynamic.int(cursor)
        // assert Ok(notify) = dynamic.element(row, 5)
        // assert Ok(notify) = dynamic.int(notify)
        // assert Ok(inserted_at) = dynamic.element(row, 6)
        // NOTE this is an optional value maybe there is no message, unwrap with created at
        // assert Ok(inserted_at) = dynamic.int(inserted_at)
        assert Ok(latest) = dynamic.element(row, 7)
        assert Ok(latest) = run_sql.dynamic_option(latest, dynamic.int)
        json.object([
          tuple("id", json.int(id)),
          tuple("topic", json.string(topic)),
          tuple("resolved", json.bool(resolved)),
          tuple("participants", json.list(participants)),
          tuple("unread", json.bool(option.unwrap(latest, 0) > cursor)),
        ])
      },
    )
  json.list(jsons)
  |> Ok
}
