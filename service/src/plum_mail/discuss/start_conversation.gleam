import gleam/dynamic
import gleam/io
import gleam/map
import gleam/result
import gleam/pgo
import plum_mail/error
import plum_mail/run_sql
import plum_mail/discuss/discuss.{Conversation}

pub fn params(form) {
  // Note doesn't use ACL because not JSON
  case map.get(form, "topic") {
    Ok(value) ->
      case discuss.validate_topic(value) {
        Ok(topic) -> Ok(topic)
        Error(Nil) ->
          Error(error.Unprocessable(
            "topic",
            error.CastFailure("contains invalid charachters"),
          ))
      }
    Error(Nil) -> Error(error.Unprocessable("topic", error.Missing))
  }
}

pub fn execute(topic, owner_id) {
  let sql =
    "
    WITH new_conversation AS (
        INSERT INTO conversations (topic)
        VALUES ($1)
        RETURNING *
    ), new_participant AS (
        INSERT INTO participants (identifier_id, conversation_id, cursor, notify)
        VALUES ($2, (SELECT id FROM new_conversation), 0, 'all')
    )
    SELECT id, topic, resolved FROM new_conversation
    "
  let args = [pgo.text(discuss.topic_to_string(topic)), pgo.int(owner_id)]
  try [c] =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(id) = dynamic.element(row, 0)
        assert Ok(id) = dynamic.int(id)
        assert Ok(topic) = dynamic.element(row, 1)
        assert Ok(topic) = dynamic.string(topic)
        assert Ok(topic) = discuss.validate_topic(topic)
        assert Ok(resolved) = dynamic.element(row, 2)
        assert Ok(resolved) = dynamic.bool(resolved)

        Conversation(id, topic, resolved, [])
      },
    )
  Ok(c)
}
