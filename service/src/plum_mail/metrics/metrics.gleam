import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None}
import gleam/string
import gleam/pgo
import plum_mail/run_sql
import plum_mail/discuss/discuss
import plum_mail/discuss/write_message

pub fn load(metric_id) {
  let sql =
    "
    SELECT c.topic, COUNT(m.counter)
    FROM conversations AS c
    LEFT JOIN messages AS m ON m.conversation_id = c.id
    WHERE c.inserted_at > NOW() - INTERVAL '1 HOURS'
    OR m.inserted_at > NOW() - INTERVAL '1 HOURS'
    AND c.id <> $1
    GROUP BY c.id
    "
  let args = [pgo.int(metric_id)]
  let mapper = fn(row) {
    assert Ok(topic) = dynamic.element(row, 0)
    assert Ok(topic) = dynamic.string(topic)
    assert Ok(count) = dynamic.element(row, 1)
    assert Ok(count) = dynamic.int(count)
    tuple(topic, count)
  }
  run_sql.execute(sql, args, mapper)
}

fn list_item(row) {
  let tuple(topic, count) = row
  ["- `", topic, "` sent **", int.to_string(count), "** messages"]
  |> string.join("")
}

pub fn message(rows) {
  [
    "Automated update for the last hour.

The following conversations were active:

",
    string.join(list.map(rows, list_item), "\r\n"),
  ]
  |> string.join("")
}

pub fn execute(conversation_id, identifier_id) {
  assert Ok(conversation_id) = dynamic.string(conversation_id)
  assert Ok(conversation_id) = int.parse(conversation_id)
  assert Ok(identifier_id) = dynamic.string(identifier_id)
  assert Ok(identifier_id) = int.parse(identifier_id)
  assert Ok(participation) =
    discuss.load_participation(conversation_id, identifier_id)
  assert Ok(rows) = load(conversation_id)
  case rows {
    [] -> Nil
    _ -> {
      let content = message(rows)
      let params = write_message.Params(content, None, False)
      assert Ok(_) = write_message.execute(participation, params)
      Nil
    }
  }
}
