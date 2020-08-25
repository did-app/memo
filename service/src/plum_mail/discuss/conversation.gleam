import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/list
import gleam/json
import gleam/pgo
import plum_mail/run_sql

pub type Conversation {
  Conversation(
    id: Int,
    topic: String,
    participants: List(tuple(Int, String)),
    messages: List(String),
  )
}

pub fn to_json(conversation: Conversation) {
  let Conversation(id, topic, participants, messages) = conversation
  json.object([
    tuple(
      "conversation",
      json.object([
        tuple("id", json.int(id)),
        tuple("topic", json.string(topic)),
        tuple(
          "participants",
          json.list(list.map(
            participants,
            fn(participant) {
              let tuple(id, email_address) = participant
              json.object([
                tuple("id", json.int(id)),
                tuple("email_address", json.string(email_address)),
              ])
            },
          )),
        ),
        tuple(
          "messages",
          json.list(list.map(
            messages,
            fn(message) {
              json.object([tuple("content", json.string(message))])
            },
          )),
        ),
      ]),
    ),
  ])
  |> json.encode()
  |> bit_string.from_string
  |> bit_builder.from_bit_string
}

pub fn fetch_by_id(id) {
  let sql =
    "
    SELECT id, topic
    FROM conversations
    WHERE id = $1
    "
  let args = [pgo.int(id)]
  let Ok([c]) =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(id) = dynamic.element(row, 0)
        assert Ok(id) = dynamic.int(id)
        assert Ok(topic) = dynamic.element(row, 1)
        assert Ok(topic) = dynamic.string(topic)

        Conversation(id, topic, [], [])
      },
    )

  let sql =
    "
    SELECT p.id, i.email_address
    FROM participants AS p
    JOIN identifiers AS i ON i.id = p.identifier_id
    WHERE conversation_id = $1
    "
  let args = [pgo.int(c.id)]
  try participants =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(id) = dynamic.element(row, 0)
        assert Ok(id) = dynamic.int(id)
        assert Ok(email_address) = dynamic.element(row, 1)
        assert Ok(email_address) = dynamic.string(email_address)
        tuple(id, email_address)
      },
    )
  let sql =
    "
    SELECT m.content
    FROM messages AS m
    WHERE conversation_id = $1
    "
  let args = [pgo.int(c.id)]
  try messages =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(content) = dynamic.element(row, 0)
        assert Ok(content) = dynamic.string(content)
        content
      },
    )

  Ok(Conversation(..c, participants: participants, messages: messages))
}
