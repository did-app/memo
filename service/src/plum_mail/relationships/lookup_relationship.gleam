import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pgo
import plum_mail/authentication.{EmailAddress}
import plum_mail/run_sql

// contact is one end of a relationship
pub type Contact {
  Contact(thread_id: Option(Int))
}

pub fn execute(identifier_id, email_address: EmailAddress) {
  let sql = "SELECT id, email_address FROM identifiers WHERE email_address = $1"
  let args = [pgo.text(email_address.value)]

  try db_result = run_sql.execute(sql, args, authentication.row_to_identifier)

  case list.head(db_result) {
    Error(Nil) -> Ok(Contact(None))
    Ok(contact) -> {
      let sql =
        "
          SELECT thread_id FROM pairs
          WHERE pairs.lower_identifier_id IN [$1, $2]
          AND pairs.upper_identifier_id IN [$1, $2]
          "
      let args = [pgo.int(identifier_id), pgo.int(contact.id)]
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
        Error(Nil) -> Ok(Contact(None))
        Ok(thread_id) -> Ok(Contact(Some(thread_id)))
      }
    }
  }
}
