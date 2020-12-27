import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pgo
import gleam/json.{Json}
import plum_mail/authentication.{EmailAddress, Identifier}
import plum_mail/run_sql

// contact is one end of a relationship
pub type Contact {
  Contact(// id: Option(Int),
    // thread_id: Option(Int),
    // what do we call the gatekeeper message
    // Note Json is nullable
    greeting: Json)
}

pub fn execute(identifier_id, email_address: EmailAddress) {
  let sql =
    "SELECT id, email_address, greeting FROM identifiers WHERE email_address = $1"
  let args = [pgo.text(email_address.value)]

  try db_result =
    run_sql.execute(
      sql,
      args,
      fn(row) {
        assert Ok(id) = dynamic.element(row, 0)
        assert Ok(id) = dynamic.int(id)
        // assert Ok(email_address) = dynamic.element(row, 1)
        // assert Ok(email_address) = dynamic.string(email_address)
        // assert Ok(email_address) = validate_email(email_address)
        assert Ok(greeting) = dynamic.element(row, 2)
        let greeting: Json = dynamic.unsafe_coerce(greeting)
        tuple(id, greeting)
      },
    )

  case list.head(db_result) {
    Error(Nil) -> Ok(Contact(json.null()))
    Ok(tuple(contact_id, _greeting)) if contact_id == identifier_id ->
      todo("talking about self")
    Ok(tuple(contact_id, greeting)) -> {
      let sql =
        "
          SELECT thread_id FROM pairs
          WHERE pairs.lower_identifier_id IN ($1, $2)
          AND pairs.upper_identifier_id IN ($1, $2)
          "
      let args = [pgo.int(identifier_id), pgo.int(contact_id)]
      try db_result =
        run_sql.execute(
          sql,
          args,
          fn(row) {
            assert Ok(thread_id) = dynamic.element(row, 0)
            assert Ok(thread_id) = dynamic.int(thread_id)
            thread_id
          },
        )
      case list.head(db_result) {
        Error(Nil) -> Ok(Contact(greeting))
        Ok(thread_id) -> Ok(Contact(greeting))
      }
    }
  }
}
