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
  try Identifier(contact_id, _, greeting) =
    identifier.find_or_create(email_address)

  let notes = case greeting {
    None -> [tuple(0, user_id, blocks)]
    Some(greeting) -> [
      tuple(0, contact_id, greeting),
      tuple(1, user_id, blocks),
    ]
  }
  let sql =
    "
  WITH new_thread AS (
    INSERT INTO threads
    DEFAULT VALUES
    RETURNING *
  )
  INSERT INTO pairs (lower_identifier_id, upper_identifier_id, thread_id)
  VALUES ($1, $2, (SELECT id FROM new_thread))
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
  list.each(
    notes,
    fn(note: tuple(Int, Int, Json)) {
      let tuple(counter, author_id, content) = note
      let content: Json = content
      // TODO it's just a map you pass in
      assert Ok(_) = thread.write_note(thread_id, counter, author_id, content)
      Nil
    },
  )
  Ok(thread_id)
}
