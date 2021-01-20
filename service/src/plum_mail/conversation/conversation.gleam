import gleam/dynamic
import gleam/io
import gleam/pgo
import plum_mail/run_sql

type Memo {
  Memo
}

type Thread {
  Thread(latest: Memo)
}

// type Conversation {
//   Conversation(thread: Thread)
//   participation (ack)
//   thread (id, latest, participants)
// }
pub type Participation {
  Participation(
    // direct or group
    thread_id: Int,
    acknowledged: Int,
  )
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
    SELECT lower_identifier_id AS contact_id, upper_identifier_ack AS ack, thread_id
    FROM pairs
    WHERE pairs.upper_identifier_id = $1
    UNION ALL
    SELECT upper_identifier_id AS contact_id, lower_identifier_ack AS ack, thread_id
    FROM pairs
    WHERE pairs.lower_identifier_id = $1
  ), my_groups AS (
    SELECT * FROM groups
    JOIN invitations ON invitations.group_id = groups.id
    WHERE individual_id = $1
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

      Participation(thread_id: thread_id, acknowledged: acknowledged)
    },
  )
}
