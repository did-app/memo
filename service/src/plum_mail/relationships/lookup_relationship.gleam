import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pgo
import gleam/json.{Json}
import plum_mail/authentication
import plum_mail/email_address.{EmailAddress}
import plum_mail/identifier.{Identifier}
import plum_mail/run_sql
import plum_mail/threads/thread

fn load_pairing(contact_id, identifier_id) {
  let sql =
    "
          SELECT thread_id FROM pairs
          WHERE pairs.lower_identifier_id IN ($1, $2)
          AND pairs.upper_identifier_id IN ($1, $2)
          "
  let args = [pgo.int(identifier_id), pgo.int(contact_id)]
  let mapper = fn(row) {
    assert Ok(thread_id) = dynamic.element(row, 0)
    assert Ok(thread_id) = dynamic.int(thread_id)
    thread_id
  }

  try db_result = run_sql.execute(sql, args, mapper)
  run_sql.single(db_result)
  |> Ok
}

pub fn execute(identifier_id, email_address: EmailAddress) {
  try maybe_contact = identifier.find(email_address)

  case maybe_contact {
    None -> Ok(tuple(None, None))
    Some(Identifier(id, ..)) if id == identifier_id ->
      todo("talking about self")
    Some(contact) -> {
      assert Ok(maybe_thread) = load_pairing(contact.id, identifier_id)
      let thread =
        option.map(
          maybe_thread,
          fn(thread_id) {
            assert Ok(notes) = thread.load_notes(thread_id)
            tuple(thread_id, notes)
          },
        )
      Ok(tuple(Some(contact), thread))
    }
  }
}
