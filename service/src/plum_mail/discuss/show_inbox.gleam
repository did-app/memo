import gleam/dynamic
import gleam/int
import gleam/io
import gleam/option
import gleam/json
import gleam/pgo
import datetime
import plum_mail/run_sql
import plum_mail/discuss/discuss

pub fn execute(identifier_id) {
  let sql =
    "
    WITH search AS (
        SELECT DISTINCT ON (c.id)
            c.id,
            c.topic,
            COALESCE(m.conclusion, FALSE) as closed,
            pl.participants,
            me.cursor,
            me.notify,
            COALESCE(m.inserted_at, c.inserted_at) as inserted_at,
            m.counter,
            m.authored_by <> me.identifier_id AND m.counter > me.done as to_reply
        FROM conversations AS c
        JOIN participants AS me ON me.conversation_id = c.id
        JOIN participant_lists AS pl ON pl.conversation_id = c.id
        LEFT JOIN messages AS m ON m.conversation_id = c.id
        WHERE me.identifier_id = $1
        ORDER BY c.id DESC, m.inserted_at DESC
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
        assert Ok(closed) = dynamic.element(row, 2)
        assert Ok(closed) = dynamic.bool(closed)
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
        assert Ok(notify) = dynamic.element(row, 5)
        assert Ok(notify) = discuss.as_preference(notify)
        assert Ok(inserted_at) = dynamic.element(row, 6)
        assert Ok(inserted_at) = run_sql.cast_datetime(inserted_at)
        assert Ok(latest) = dynamic.element(row, 7)
        assert Ok(latest) = run_sql.dynamic_option(latest, dynamic.int)
        assert Ok(to_reply) = dynamic.element(row, 8)
        assert Ok(to_reply) = dynamic.bool(to_reply)

        json.object([
          tuple("id", json.int(id)),
          tuple("topic", json.string(topic)),
          tuple("closed", json.bool(closed)),
          tuple("participants", json.list(participants)),
          tuple("updated_at", json.string(datetime.to_human(inserted_at))),
          tuple(
            "unread",
            json.bool(
              option.unwrap(latest, 0) > cursor && {
                notify == discuss.All || notify == discuss.Concluded && closed
              },
            ),
          ),
          tuple("next", json.int(int.min(cursor + 1, option.unwrap(latest, 0)))),
          tuple("to_reply", json.bool(to_reply)),
        ])
      },
    )
  json.list(jsons)
  |> Ok
}
