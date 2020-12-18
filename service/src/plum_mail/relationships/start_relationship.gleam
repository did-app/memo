import gleam/dynamic.{Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/map
import gleam/order
import gleam/json
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql

pub type Params {
  // contact_id is just the identifier id
  Params(
    contact_id: Int,
    // TODO make JSON
    content: Dynamic,
    counter: Int,
  )
}

pub fn params(raw: Dynamic) {
  try counter = acl.required(raw, "counter", acl.as_int)
  try contact_id = acl.required(raw, "contact_id", acl.as_int)
  assert Ok(content) = dynamic.field(raw, dynamic.from("content"))
  Params(contact_id, content, counter)
  |> Ok()
}

pub fn execute(params, user_id) {
  let Params(contact_id, content, counter) = params

  let notes = case counter {
    0 -> [tuple(0, user_id, content)]
    // TODO message content
    1 -> [tuple(0, contact_id, dynamic.from(map.from_list([tuple("blocks", [])]))), tuple(1, user_id, content)]
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
  try [thread_id] =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(thread_id) = dynamic.element(row, 0)
        assert Ok(thread_id) = dynamic.int(thread_id)
        thread_id
      },
    )

  let sql =
    "
  INSERT INTO notes (thread_id, counter, authored_by, content)
  VALUES ($1, $2, $3, $4)
  RETURNING *
  "
  list.each(
    notes,
    fn(note) {
      let tuple(counter, author_id, content) = note
      // TODO it's just a map you pass in
      let args = [
        pgo.int(thread_id),
        pgo.int(counter),
        pgo.int(author_id),
        dynamic.unsafe_coerce(content),
      ]
      assert Ok(_) = run_sql.execute(sql, args, fn(x) { x })
      Nil
    },
  )
  Ok(thread_id)
}
