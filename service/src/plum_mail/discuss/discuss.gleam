import gleam/dynamic
import gleam/int
import gleam/list
import gleam/string
import gleam/json
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication.{Identifier}
// Session is more than a web thing, anywhere you can be a session.
// FIXME date_time or Datetime
import datetime.{DateTime}
import plum_mail/web/session

pub type Conversation {
  Conversation(
    id: Int,
    topic: String,
    resolved: Bool,
    participants: List(Identifier),
  )
}

pub fn conversation_to_json(conversation: Conversation) {
  let Conversation(id, topic, resolved, participants) = conversation

  json.object([
    tuple("id", json.int(id)),
    tuple("topic", json.string(topic)),
    tuple("resolved", json.bool(resolved)),
    tuple(
      "participants",
      json.list(list.map(
        participants,
        fn(participant) {
          let Identifier(id: id, email_address: email_address, ..) = participant
          json.object([
            tuple("id", json.int(id)),
            tuple("email_address", json.string(email_address)),
          ])
        },
      )),
    ),
  ])
}

pub fn load_participants(conversation_id) {
  let sql =
    "
      SELECT i.id, i.email_address, i.nickname
      FROM participants AS p
      JOIN identifiers AS i ON i.id = p.identifier_id
      WHERE conversation_id = $1
      "
  let args = [pgo.int(conversation_id)]
  run_sql.execute(
    sql,
    args,
    fn(row) {
      assert Ok(id) = dynamic.element(row, 0)
      assert Ok(id) = dynamic.int(id)
      assert Ok(email_address) = dynamic.element(row, 1)
      assert Ok(email_address) = dynamic.string(email_address)
      assert Ok(nickname) = dynamic.element(row, 2)
      assert Ok(nickname) = run_sql.dynamic_option(nickname, dynamic.string)
      Identifier(id: id, email_address: email_address, nickname: nickname)
    },
  )
}

pub type Message {
  Message(
    counter: Int,
    content: String,
    inserted_at: DateTime,
    author: Identifier,
  )
}

pub fn load_messages(conversation_id) {
  let sql =
    "
        SELECT m.content, m.counter, m.inserted_at, i.id, i.email_address, i.nickname
        FROM messages AS m
        JOIN identifiers AS i ON i.id = m.author_id
        WHERE conversation_id = $1
        "
  let args = [pgo.int(conversation_id)]
  run_sql.execute(
    sql,
    args,
    fn(row) {
      assert Ok(content) = dynamic.element(row, 0)
      assert Ok(content) = dynamic.string(content)
      assert Ok(counter) = dynamic.element(row, 1)
      assert Ok(counter) = dynamic.int(counter)
      assert Ok(inserted_at) = dynamic.element(row, 2)
      assert Ok(inserted_at) = run_sql.cast_datetime(inserted_at)
      assert Ok(author_id) = dynamic.element(row, 3)
      assert Ok(author_id) = dynamic.int(author_id)
      assert Ok(author_email_address) = dynamic.element(row, 4)
      assert Ok(author_email_address) = dynamic.string(author_email_address)
      assert Ok(author_nickname) = dynamic.element(row, 5)
      assert Ok(author_nickname) =
        run_sql.dynamic_option(author_nickname, dynamic.string)

      let author =
        Identifier(
          id: author_id,
          email_address: author_email_address,
          nickname: author_nickname,
        )
      Message(counter, content, inserted_at, author)
    },
  )
}

pub fn load_pins(conversation_id) {
  let sql =
    "
        SELECT p.content
        FROM pins AS p
        WHERE conversation_id = $1
        "
  let args = [pgo.int(conversation_id)]
  run_sql.execute(
    sql,
    args,
    fn(row) {
      assert Ok(content) = dynamic.element(row, 0)
      assert Ok(content) = dynamic.string(content)
      content
    },
  )
}

//
pub type Preference {
  None
  All
  Concluded
}

// participant.notify way more sensible than preference
pub fn as_preference(raw) {
  try level_string = acl.as_string(raw)
  case level_string {
    "all" -> Ok(All)
    "none" -> Ok(None)
    "concluded" -> Ok(Concluded)
    _ -> Error("Not an acceptable notify preference")
  }
}

pub fn notify_to_string(notify) {
  case notify {
    None -> "none"
    All -> "all"
    Concluded -> "concluded"
  }
}

// TODO would like to be opaque,
pub type Participation {
  Participation(
    conversation: Conversation,
    active: Bool,
    cursor: Int,
    notify: Preference,
    identifier: Identifier,
  )
}

// Can call user session authentication?
pub fn load_participation(conversation_id: Int, user_session: session.Session) {
  // BECOMES a LEFT JOIN for open conversation
  try identifier_id = session.require_authentication(user_session)
  let sql =
    "
    SELECT c.id, c.topic, c.resolved, p.cursor, p.notify, i.id, i.email_address, i.nickname
    FROM conversations AS c
    JOIN participants AS p ON p.conversation_id = c.id
    JOIN identifiers AS i ON i.id = p.identifier_id
    WHERE c.id = $1
    AND i.id = $2
    "
  let args = [pgo.int(conversation_id), pgo.int(identifier_id)]
  let mapper = fn(row) {
    assert Ok(id) = dynamic.element(row, 0)
    assert Ok(id) = dynamic.int(id)
    assert Ok(topic) = dynamic.element(row, 1)
    assert Ok(topic) = dynamic.string(topic)
    assert Ok(resolved) = dynamic.element(row, 2)
    assert Ok(resolved) = dynamic.bool(resolved)

    let conversation = Conversation(id, topic, resolved, [])

    assert Ok(cursor) = dynamic.element(row, 3)
    assert Ok(cursor) = dynamic.int(cursor)
    assert Ok(notify) = dynamic.element(row, 4)
    // assert Ok(notify) = dynamic.string(notify)
    assert Ok(notify) = as_preference(notify)

    assert Ok(id) = dynamic.element(row, 5)
    assert Ok(id) = dynamic.int(id)
    assert Ok(email_address) = dynamic.element(row, 6)
    assert Ok(email_address) = dynamic.string(email_address)
    assert Ok(nickname) = dynamic.element(row, 7)
    assert Ok(nickname) = run_sql.dynamic_option(nickname, dynamic.string)

    let identifier = Identifier(id, email_address, nickname)

    Participation(
      conversation: conversation,
      active: True,
      cursor: cursor,
      notify: notify,
      identifier: identifier,
    )
  }

  try [participation] = run_sql.execute(sql, args, mapper)
  Ok(participation)
}

// Note doesn't need to always load identifier if we are making json returns because identifier information already fetched.
pub fn can_view(participation) -> Conversation {
  todo
}

pub fn can_edit(participation) {
  let Participation(conversation: conversation, ..) = participation

  Ok(conversation)
}

// Share is a functionality
pub fn invite_link(identifier_id, conversation_id) {
  string.join(
    ["", "i", int.to_string(conversation_id), int.to_string(identifier_id)],
    "/",
  )
}
