import gleam/dynamic
import gleam/int
import gleam/string
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/authentication.{Identifier}
import plum_mail/discuss/conversation.{Conversation}
// Session is more than a web thing, anywhere you can be a session.
import plum_mail/web/session

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
    _ -> Error(Nil)
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

pub fn build_participation(conversation, identifier) {
  Participation(conversation, True, 0, All, identifier)
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

    let conversation = Conversation(id, topic, resolved, [], [])

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
pub fn invite_link(participation) {
  let Participation(
    conversation: Conversation(id: conversation_id, ..),
    identifier: Identifier(id: identifier_id, ..),
    ..,
  ) = participation
  string.join(
    ["", "i", int.to_string(conversation_id), int.to_string(identifier_id)],
    "/",
  )
}
