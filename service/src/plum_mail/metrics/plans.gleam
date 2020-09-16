import gleam/dynamic
import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/string
import plum_mail/run_sql
import plum_mail/discuss/discuss
import plum_mail/discuss/write_message

// Users
// Have received a message this week
// Have sent a message this week
// Have logged in this week
// When they started
// users in conversations
pub fn load() {
  let sql =
    "
    WITH owners AS (
        SELECT DISTINCT ON (c.id) c.id, i.email_address
        FROM participants AS p
        JOIN conversations AS c ON c.id = p.conversation_id
        JOIN identifiers AS i on i.id = p.identifier_id
        ORDER BY c.id, p.inserted_at ASC
    )
    SELECT email_address, COUNT(id)
    FROM owners
    GROUP BY email_address
    ORDER BY COUNT(id) DESC
    "
  let mapper = fn(row) {
    assert Ok(email_address) = dynamic.element(row, 0)
    assert Ok(email_address) = dynamic.string(email_address)
    assert Ok(count) = dynamic.element(row, 1)
    assert Ok(count) = dynamic.int(count)
    tuple(email_address, count)
  }
  run_sql.execute(sql, [], mapper)
}

fn display_row(row) {
  let tuple(email_address, active_conversations) = row
  [
    "- `",
    email_address,
    "` has started **",
    int.to_string(active_conversations),
    "** conversations",
  ]
  |> string.join("")
}

pub fn message(rows) {
  [
    "These are the most active users by number of conversations started:\r\n\r\n",
    string.join(list.map(rows, display_row), "\r\n"),
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
  assert Ok(rows) = load()
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