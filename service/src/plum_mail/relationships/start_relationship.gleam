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
import plum_mail/authentication.{validate_email}

pub type Params {
  Params(
    email_address: String,
    // message or memo
    blocks: json.Json,
  )
}

pub fn params(raw: Dynamic) {
  try email_address = acl.required(raw, "email_address", acl.as_string)
  assert Ok(blocks) = dynamic.field(raw, dynamic.from("blocks"))
  let blocks = dynamic.unsafe_coerce(blocks)
  Params(email_address, blocks)
  |> Ok()
}

// TODO collect in some grouping
fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(email_address) = validate_email(email_address)
  assert Ok(greeting) = dynamic.element(row, 2)
  assert Ok(greeting): Result(Option(Json), Nil) =
    run_sql.dynamic_option(greeting, fn(x) { Ok(dynamic.unsafe_coerce(x)) })
  tuple(id, email_address, greeting)
}

fn find_or_create_identifer(email_address) {
  // TODO drop refered_by
  let sql =
    "
  WITH new_identifier AS (
    INSERT INTO identifiers (email_address, referred_by)
    VALUES ($1, currval('identifiers_id_seq'))
    ON CONFLICT (email_address) DO NOTHING
    RETURNING id, email_address, greeting
  )
  SELECT id, email_address, greeting FROM new_identifier
  UNION ALL
  SELECT id, email_address, greeting FROM identifiers WHERE email_address = $1
  "
  let args = [pgo.text(email_address)]
  try db_result = run_sql.execute(sql, args, row_to_identifier)
  assert [identifier] = db_result
  Ok(identifier)
}

pub fn execute(params, user_id) {
  let Params(email_address, blocks) = params
  try tuple(contact_id, _, greeting) = find_or_create_identifer(email_address)

  let notes: List(tuple(Int, Int, Json)) = case greeting {
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
