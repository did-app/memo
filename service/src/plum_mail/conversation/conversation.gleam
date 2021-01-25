import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import datetime.{DateTime}
import gleam/json.{Json}
import gleam/pgo
import gleam_uuid.{UUID}
import plum_mail/error
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Identifier, Personal, Shared}
import plum_mail/threads/thread.{Memo}
import plum_mail/run_sql
import plum_mail/conversation/group.{Group}

pub fn create_group(name, identifier_id, invitees) {
  try group = group.create_group(name, identifier_id)
  // should assert on return from invite member, even upgrade to transaction
  list.each(invitees, invite_member(group.id, _, identifier_id))
  Ok(GroupConversation(
    group,
    Participation(thread_id: group.thread_id, acknowledged: 0, latest: None),
  ))
}

pub fn invite_member(group_id, invited_id, inviting_id) {
  group.invite_member(group_id, invited_id, inviting_id)
}

pub fn post_memo(thread_id, position, author_id, content) {
  try _ = check_permission(thread_id, author_id)
  thread.post_memo(thread_id, position, author_id, content)
}

pub fn load_memos(thread_id, identifier_id) {
  try _ = check_permission(thread_id, identifier_id)
  thread.load_memos(thread_id)
}

pub fn memo_to_json(memo) {
  thread.memo_to_json(memo)
}

type Permission {
  Direct
  Invited
}

fn check_permission(thread_id, identifier_id) {
  let sql =
    "
  SELECT 'invited' 
  FROM invitations
  JOIN groups ON groups.id = invitations.group_id
  WHERE groups.thread_id = $1
  AND invitations.identifier_id = $2

  UNION ALL

  SELECT 'direct'
  FROM pairs
  WHERE pairs.thread_id = $1
  AND pairs.lower_identifier_id = $2

  UNION ALL
  
  SELECT 'direct'
  FROM pairs
  WHERE pairs.thread_id = $1
  AND pairs.upper_identifier_id = $2
  "
  let args = [run_sql.uuid(thread_id), run_sql.uuid(identifier_id)]
  try db_response = run_sql.execute(sql, args, fn(x) { x })
  case db_response {
    [_] -> Ok(Nil)
    [] -> Error(error.Forbidden)
  }
}

pub type Participation {
  Participation(thread_id: UUID, acknowledged: Int, latest: Option(Memo))
}

fn participation_to_json(participation) {
  let Participation(thread_id, acknowledged, latest) = participation

  let latest_json = case latest {
    None -> json.null()
    Some(memo) -> thread.memo_to_json(memo)
  }

  json.object([
    tuple("thread_id", json.string(gleam_uuid.to_string(thread_id))),
    tuple("acknowledged", json.int(acknowledged)),
    tuple("latest", latest_json),
  ])
}

// Conversation = Connection + Thread
// Connection can be Direct or Group
pub type Conversation {
  DirectConversation(contact: Identifier, participation: Participation)
  // This is just a name to avoid a GroupConversation being amonst a group
  GroupConversation(group: Group, participation: Participation)
}

pub fn to_json(conversation) {
  case conversation {
    DirectConversation(contact, participation) ->
      json.object([
        tuple("contact", identifier.to_json(contact)),
        tuple("participation", participation_to_json(participation)),
      ])
    GroupConversation(group, participation) ->
      json.object([
        tuple("contact", group.to_json(group)),
        tuple("participation", participation_to_json(participation)),
      ])
  }
}

pub fn start_direct(identifier_id, email_address, content) {
  try DirectConversation(contact, participation) =
    new_direct_contact(identifier_id, email_address)

  // load up greeting, write ack but the recipient won't have already accepted.
  // write message requires a participation object
  // This is greeting for the other person, it needs writing in the thread
  let tuple(recipient_id, greeting) = case contact {
    Personal(id: id, greeting: greeting, ..) -> tuple(id, greeting)
    Shared(id: id, greeting: greeting, ..) -> tuple(id, greeting)
  }

  try next_position = case greeting {
    Some(greeting) -> {
      assert Ok(_) =
        thread.post_memo(participation.thread_id, 1, recipient_id, greeting)
      Ok(2)
    }
    None -> Ok(1)
  }
  try memo =
    thread.post_memo(
      participation.thread_id,
      next_position,
      identifier_id,
      content,
    )
  DirectConversation(
    contact,
    Participation(
      ..participation,
      latest: Some(memo),
      acknowledged: next_position,
    ),
  )
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
  let args = [run_sql.uuid(identifier_id), pgo.text(email_address)]
  try [participation] =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(thread_id) = dynamic.element(row, 0)
        assert Ok(thread_id) = dynamic.bit_string(thread_id)
        assert thread_id = run_sql.binary_to_uuid4(thread_id)

        let contact = identifier.row_to_identifier(row, 1)
        let participation = Participation(thread_id, 0, None)
        DirectConversation(contact, participation)
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
  ), participant_lists AS (
    -- Could be a view
    SELECT invitations.group_id, json_agg(json_build_object(
      'identifier_id', invitations.identifier_id,
      'email_address', identifiers.email_address
    )) as participants
    FROM invitations
    JOIN identifiers ON identifiers.id = invitations.identifier_id
    GROUP BY (invitations.group_id)
  ), my_groups AS (
    SELECT groups.* FROM groups
    JOIN invitations ON invitations.group_id = groups.id
    WHERE identifier_id = $1
  ), my_conversations AS (
    SELECT thread_id, 'DIRECT', contact_id, i.email_address, i.greeting, i.group_id, NULL as participating_group_id, NULL as name, NULL as participants
    FROM my_contacts
    JOIN identifiers AS i ON i.id = my_contacts.contact_id
    
    UNION ALL

    SELECT thread_id, 'GROUP', NULL, NULL, NULL, NULL, my_groups.id as participating_group_id, my_groups.name, participants
    FROM my_groups
    JOIN participant_lists ON participant_lists.group_id = my_groups.id
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
    my_conversations.group_id,
    my_conversations.participating_group_id,
    my_conversations.name,
    my_conversations.thread_id,
    my_conversations.participants
  FROM my_conversations
  LEFT JOIN latest ON latest.thread_id = my_conversations.thread_id
  LEFT JOIN participations ON participations.thread_id = my_conversations.thread_id
  WHERE participations.identifier_id = $1
  OR participations.identifier_id IS NULL
  ORDER BY latest.inserted_at DESC
  "
  let args = [run_sql.uuid(identifier_id)]
  run_sql.execute(
    sql,
    args,
    fn(row) {
      assert Ok(thread_id) = dynamic.element(row, 0)
      assert Ok(thread_id) = dynamic.bit_string(thread_id)
      assert thread_id = run_sql.binary_to_uuid4(thread_id)
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
      let participation = Participation(thread_id, acknowledged, latest)
      let null_atom = dynamic.from(pgo.null())
      case dynamic.element(row, 5) {
        Ok(null) if null == null_atom -> {
          let group = group.from_row(row, 9, None)
          GroupConversation(group: group, participation: participation)
        }
        _ -> {
          let contact = identifier.row_to_identifier(row, 5)
          DirectConversation(contact, participation)
        }
      }
    },
  )
}
