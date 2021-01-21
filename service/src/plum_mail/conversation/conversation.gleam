import gleam/dynamic
import gleam/io
import gleam/option.{None, Option, Some}
import datetime.{DateTime}
import gleam/json.{Json}
import gleam/pgo
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Identifier, Personal, Shared}
import plum_mail/threads/thread.{Memo}
import plum_mail/run_sql

pub type Thread {
  Thread(id: Int, acknowledged: Int, latest: Option(Memo))
}

fn thread_to_json(thread) {
  let Thread(id, acknowledged, latest) = thread
  let latest_json = case latest {
    None -> json.null()
    Some(memo) -> thread.memo_to_json(memo)
  }
  json.object([
    tuple("id", json.int(id)),
    tuple("acknowledged", json.int(acknowledged)),
    tuple("latest", latest_json),
  ])
}

pub type Contact {
  Contact(
    // direct or group
    identifier: Identifier,
    thread: Thread,
  )
}

pub fn to_json(conversation) {
  let Contact(thread: thread, identifier: identifier) = conversation
  json.object([
    tuple("identifier", identifier.to_json(identifier)),
    tuple("thread", thread_to_json(thread)),
  ])
}

pub fn start_direct(identifier_id, email_address, content) {
  try Contact(identifier, thread) =
    new_direct_contact(identifier_id, email_address)

  // load up greeting, write ack but the recipient won't have already accepted.
  // write message requires a participation object
  // This is greeting for the other person, it needs writing in the thread
  let tuple(recipient_id, greeting) = case identifier {
    Personal(id: id, greeting: greeting, ..) -> tuple(id, greeting)
    Shared(id: id, greeting: greeting, ..) -> tuple(id, greeting)
  }
  try position = case greeting {
    Some(greeting) -> {
      assert Ok(_) = thread.post_memo(thread.id, 1, recipient_id, greeting)
      Ok(0)
    }
    None -> Ok(1)
  }
  try memo = thread.post_memo(thread.id, position, identifier_id, content)
  Contact(identifier, thread: Thread(..thread, latest: Some(memo)))
  |> Ok
}

// There's no invited by on direct messages just who ever spoke first
fn new_direct_contact(identifier_id, email_address) {
  let EmailAddress(email_address) = email_address
  // Find or create contact id
  let sql =
    "
  WITH new_thread AS (
    INSERT INTO threads
    DEFAULT VALUES
    RETURNING *
  ), active_participant AS (
    INSERT INTO participations (identifier_id, thread_id, acknowledged)
    VALUES ($1, (SELECT id FROM new_thread), 0)
  ), new_identifier AS (
    INSERT INTO identifiers (email_address)
    VALUES ($2)
    ON CONFLICT DO NOTHING
    RETURNING *
  ), invited AS (
      SELECT * FROM new_identifier
    UNION ALL
      SELECT * FROM identifiers 
      WHERE email_address = $2
  ), passive_participant AS (
    INSERT INTO participations (identifier_id, thread_id, acknowledged)
    VALUES ((SELECT id FROM invited), (SELECT id FROM new_thread), 0)
  ), new_pair AS (
    INSERT INTO pairs (lower_identifier_id, upper_identifier_id, thread_id)
    VALUES (LEAST($1, (SELECT id FROM invited)), GREATEST($1, (SELECT id FROM invited)), (SELECT id FROM new_thread))
    RETURNING thread_id
  )
  SELECT (SELECT thread_id FROM new_pair), id, email_address, greeting, group_id FROM invited
  "
  let args = [pgo.int(identifier_id), pgo.text(email_address)]
  try [participation] =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(thread_id) = dynamic.element(row, 0)
        assert Ok(thread_id) = dynamic.int(thread_id)

        let contact = identifier.row_to_identifier(row, 1)
        let thread = Thread(thread_id, 0, None)
        Contact(thread: thread, identifier: contact)
      },
    )
  participation
  |> Ok
}

// thread_latest
// Have a view for participants based on participation etc
// WITH conversations where conversations becomes the view
pub fn all_participating(identifier_id) {
  let sql =
    "
  WITH latest AS (
    SELECT DISTINCT ON(thread_id) * FROM memos
    ORDER BY thread_id DESC, inserted_at DESC
  ), my_contacts AS (
    SELECT lower_identifier_id AS contact_id, thread_id
    FROM pairs
    WHERE pairs.upper_identifier_id = $1
    UNION ALL
    SELECT upper_identifier_id AS contact_id, thread_id
    FROM pairs
    WHERE pairs.lower_identifier_id = $1
  ), my_groups AS (
    SELECT * FROM groups
    JOIN invitations ON invitations.group_id = groups.id
    WHERE identifier_id = $1
  ), my_conversations AS (
    SELECT thread_id, 'DIRECT', contact_id, i.email_address, i.greeting, i.group_id
    FROM my_contacts
    JOIN identifiers AS i ON i.id = my_contacts.contact_id
    
    UNION ALL

    SELECT thread_id, 'GROUP', NULL, NULL, NULL, NULL
    FROM my_groups
  )
  SELECT 
    my_conversations.thread_id,
    COALESCE(participations.acknowledged, 0),
    latest.inserted_at,
    latest.content,
    latest.position, 
    my_conversations.contact_id,
    my_conversations.email_address,
    my_conversations.greeting,
    my_conversations.group_id
  FROM my_conversations
  LEFT JOIN latest ON latest.thread_id = my_conversations.thread_id
  LEFT JOIN participations ON participations.thread_id = my_conversations.thread_id
  WHERE participations.identifier_id = $1
  "
  let args = [pgo.int(identifier_id)]
  run_sql.execute(
    sql,
    args,
    fn(row) {
      io.debug(row)
      assert Ok(thread_id) = dynamic.element(row, 0)
      assert Ok(thread_id) = dynamic.int(thread_id)
      assert Ok(acknowledged) = dynamic.element(row, 1)
      assert Ok(acknowledged) = dynamic.int(acknowledged)
      assert Ok(inserted_at) = dynamic.element(row, 2)
      assert Ok(inserted_at) =
        run_sql.dynamic_option(inserted_at, run_sql.cast_datetime)
      assert Ok(content) = dynamic.element(row, 3)
      let content: json.Json = dynamic.unsafe_coerce(content)
      assert Ok(position) = dynamic.element(row, 4)
      assert Ok(position) = run_sql.dynamic_option(position, dynamic.int)
      let latest = case inserted_at, position {
        Some(posted_at), Some(position) ->
          Some(Memo(posted_at, content, position))
        None, None -> None
      }
      let thread = Thread(thread_id, acknowledged, latest)
      let identifier = identifier.row_to_identifier(row, 5)
      Contact(thread: thread, identifier: identifier)
    },
  )
}
