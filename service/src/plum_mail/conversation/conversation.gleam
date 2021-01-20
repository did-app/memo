import gleam/dynamic
import gleam/io
import gleam/option.{None, Option, Some}
import datetime.{DateTime}
import gleam/json.{Json}
import gleam/pgo
import plum_mail/email_address.{EmailAddress}
import plum_mail/run_sql

pub type Memo {
  Memo(posted_at: DateTime, content: Json, position: Int)
}

fn memo_to_json(memo) {
  let Memo(posted_at, content, position) = memo
  json.object([
    tuple("posted_at", json.string(datetime.to_iso8601(posted_at))),
    tuple("content", content),
    tuple("position", json.int(position)),
  ])
}

pub type Thread {
  Thread(id: Int, acknowledged: Int, latest: Option(Memo))
}

fn thread_to_json(thread) {
  let Thread(id, acknowledged, latest) = thread
  let latest_json = case latest {
    None -> json.null()
    Some(memo) -> memo_to_json(memo)
  }
  json.object([
    tuple("id", json.int(id)),
    tuple("acknowledged", json.int(acknowledged)),
    tuple("latest", latest_json),
  ])
}

// type Conversation {
//   Conversation(thread: Thread)
//   participation (ack)
//   thread (id, latest, participants)
// }
pub type Participation {
  Participation(
    // direct or group
    thread: Thread,
  )
}

// TODO add uniqueness on identifier
pub type Identifier {
  Individual(id: Int, email_address: String, greeting: Option(Json))
}

// There's no invited by on direct messages just who ever spoke first
pub fn start_direct(identifier: Identifier, email_address) {
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
      SELECT id FROM new_identifier
    UNION ALL
      SELECT id FROM identifiers 
      WHERE email_address = $2
  ), passive_participant AS (
    INSERT INTO participations (identifier_id, thread_id, acknowledged)
    VALUES ((SELECT id FROM invited), (SELECT id FROM new_thread), 0)
  )
  INSERT INTO pairs (lower_identifier_id, upper_identifier_id, thread_id)
  VALUES (LEAST($1, (SELECT id FROM new_identifier)), GREATEST($1, (SELECT id FROM new_identifier)), (SELECT id FROM new_thread))
  RETURNING thread_id
  "
  let args = [pgo.int(identifier.id), pgo.text(email_address)]
  try [participation] =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(thread_id) = dynamic.element(row, 0)
        assert Ok(thread_id) = dynamic.int(thread_id)

        let thread = Thread(thread_id, 0, None)
        Participation(thread: thread)
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
    SELECT thread_id, 'DIRECT'
    FROM my_contacts
    
    UNION ALL

    SELECT thread_id, 'GROUP'
    FROM my_groups
  )
  SELECT my_conversations.thread_id, COALESCE(participations.acknowledged, 0), latest.inserted_at, latest.content, latest.position 
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
      assert Ok(thread_id) = dynamic.element(row, 0)
      assert Ok(thread_id) = dynamic.int(thread_id)
      assert Ok(acknowledged) = dynamic.element(row, 1)
      assert Ok(acknowledged) = dynamic.int(acknowledged)
      assert Ok(inserted_at) = dynamic.element(row, 3)
      assert Ok(inserted_at) =
        run_sql.dynamic_option(inserted_at, run_sql.cast_datetime)
      assert Ok(content) = dynamic.element(row, 4)
      let content: json.Json = dynamic.unsafe_coerce(content)
      assert Ok(position) = dynamic.element(row, 5)
      assert Ok(position) = run_sql.dynamic_option(position, dynamic.int)
      let latest = case inserted_at, position {
        Some(posted_at), Some(position) ->
          Some(Memo(posted_at, content, position))
        None, None -> None
      }
      let thread = Thread(thread_id, acknowledged, latest)
      Participation(thread)
    },
  )
}
