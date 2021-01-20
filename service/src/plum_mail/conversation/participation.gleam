import gleam/io
import gleam/pgo
import plum_mail/run_sql

// Have a view for participants based on participation etc
// WITH conversaions where conversations becomes the view
pub fn participation(identifier_id) {
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
  SELECT my_conversations.thread_id, latest.inserted_at, latest.content, latest.position 
  FROM my_conversations
  LEFT JOIN latest ON latest.thread_id = my_conversations.thread_id
  "
  let args = [pgo.int(identifier_id)]
  run_sql.execute(sql, args, io.debug)
}
