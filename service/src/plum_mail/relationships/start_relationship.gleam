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
import plum_mail/identifier.{Identifier}

pub type Params {
  Params(
    email_address: EmailAddress,
    // message or memo
    blocks: json.Json,
  )
}

pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_email)
  assert Ok(blocks) = dynamic.field(raw, dynamic.from("blocks"))
  let blocks = dynamic.unsafe_coerce(blocks)
  Params(email_address, blocks)
  |> Ok()
}

pub fn execute(params, user_id) {
  let Params(email_address, blocks) = params
  try identifier = identifier.find_or_create(email_address)
  let Identifier(contact_id, _, greeting) = identifier
  let tuple(first, current) = case greeting {
    None -> tuple(None, tuple(1, user_id, blocks))
    Some(greeting) -> tuple(
      Some(tuple(1, contact_id, greeting)),
      tuple(2, user_id, blocks),
    )
  }
  // TODO set first index to one
  let sql =
    "
  WITH new_thread AS (
    INSERT INTO threads
    DEFAULT VALUES
    RETURNING *
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
    Some(tuple(counter, author_id, content)) -> {
      let content: Json = content
      // TODO it's just a map you pass in
      assert Ok(note) =
        thread.write_note(thread_id, counter, author_id, content)
      Nil
    }
  }
  let tuple(counter, author_id, content) = current
  assert Ok(Some(tuple(inserted_at, content))) =
    thread.write_note(thread_id, counter, author_id, content)
  Ok(tuple(identifier, False, Some(inserted_at), content))
}
