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
  // TODO switch this over to select on lower upper and return ack.
  // Can pull in gleam land last message for thread summary
  let sql =
    "
    SELECT thread_id, lower_identifier_ack AS ack FROM pairs
    WHERE pairs.lower_identifier_id = $1
    AND pairs.upper_identifier_id = $2
    UNION ALL
    SELECT thread_id, upper_identifier_ack AS ack FROM pairs
    WHERE pairs.upper_identifier_id = $1
    AND pairs.lower_identifier_id = $2
    "
  let args = [pgo.int(identifier_id), pgo.int(contact_id)]
  let mapper = fn(row) {
    assert Ok(thread_id) = dynamic.element(row, 0)
    assert Ok(thread_id) = dynamic.int(thread_id)
    assert Ok(ack) = dynamic.element(row, 1)
    assert Ok(ack) = dynamic.int(ack)

    tuple(thread_id, ack)
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
          fn(thread) {
            let tuple(thread_id, ack) = thread
            assert Ok(notes) = thread.load_notes(thread_id)
            tuple(thread_id, ack, notes)
          },
        )
      Ok(tuple(Some(contact), thread))
    }
  }
}
