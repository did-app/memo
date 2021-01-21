import gleam/dynamic.{Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/map
import gleam/option.{None, Option, Some}
import gleam/order
import gleam/json.{Json}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/threads/thread
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Personal}

pub type Params {
  Params(
    email_address: EmailAddress,
    // message or memo
    content: json.Json,
  )
}

pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_email)
  assert Ok(content) = dynamic.field(raw, dynamic.from("content"))
  let content = dynamic.unsafe_coerce(content)
  Params(email_address, content)
  |> Ok()
}

pub fn execute(params, user_id) {
  let Params(email_address, content) = params
  try identifier = identifier.find_or_create(email_address)
  let Personal(contact_id, _, greeting) = identifier
  let tuple(first, current) = case greeting {
    None -> tuple(None, tuple(1, user_id, content))
    Some(greeting) -> tuple(
      Some(tuple(1, contact_id, greeting)),
      tuple(2, user_id, content),
    )
  }
  let sql =
    "
  WITH new_thread AS (
    INSERT INTO threads
    DEFAULT VALUES
    RETURNING *
  ), lower_participation AS(
    INSERT INTO participations (thread_id, identifi)
    VALUES ()
  )
  INSERT INTO pairs (lower_identifier_id, lower_identifier_ack, upper_identifier_id, upper_identifier_ack, thread_id)
  VALUES ($1, 0, $2, 0, (SELECT id FROM new_thread))
  RETURNING thread_id
  "
  let [lower, upper] = case int.compare(user_id, contact_id) {
    order.Lt -> [user_id, contact_id]
    order.Gt -> [contact_id, user_id]
  }
  let args = [pgo.int(lower), pgo.int(upper)]
  // rename db.run
  let mapper = fn(row) {
    assert Ok(thread_id) = dynamic.element(row, 0)
    assert Ok(thread_id) = dynamic.int(thread_id)
    thread_id
  }

  try [thread_id] = run_sql.execute(sql, args, mapper)
  case first {
    None -> Nil
    Some(tuple(position, author_id, content)) -> {
      let content: Json = content
      // it's just a map you pass in
      assert Ok(note) =
        thread.post_memo(thread_id, position, author_id, content)
      Nil
    }
  }
  let tuple(position, author_id, content) = current
  assert Ok(Some(tuple(inserted_at, content, position))) =
    thread.post_memo(thread_id, position, author_id, content)
  Ok(tuple(
    identifier,
    position,
    Some(inserted_at),
    content,
    position,
    thread_id,
  ))
}
