import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pgo
import plum_mail/authentication.{EmailAddress}
import plum_mail/run_sql

// contact is one end of a relationship
pub type Contact {
  Contact(
      thread_id: Option(Int),
      // what do we call the gatekeeper message
      introduction: Option(String)
  )
}

pub fn execute(identifier_id, email_address: EmailAddress) {
  let sql = "SELECT id, email_address FROM identifiers WHERE email_address = $1"
  let args = [pgo.text(email_address.value)]

  try db_result = run_sql.execute(sql, args, authentication.row_to_identifier)

  let introduction = lookup_introduction(email_address)

  case list.head(db_result) {
    Error(Nil) -> Ok(Contact(None, None))
    Ok(contact) -> {
      let sql =
        "
          SELECT thread_id FROM pairs
          WHERE pairs.lower_identifier_id IN ($1, $2)
          AND pairs.upper_identifier_id IN ($1, $2)
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
        Error(Nil) -> Ok(Contact(None, introduction))
        Ok(thread_id) -> Ok(Contact(Some(thread_id), introduction))
      }
    }
  }
}

pub fn lookup_introduction(email_address) {
  case email_address.value {
    "peter@plummail.co" ->
      Some("Hello

Thanks for reaching out

I'm currently trying to take control of my communication.
Please may I ask you consider the following in your message

- Be explicit about if you need a reply, and how quickly.
- If I don't know you, share a link to your website, bio or twitter
- Recruiters, I'm very happy building [Plum Mail](https://plummail.co) and not looking for new opportunities.

**Cheers, Peter**",
      )
    "richard@plummail.co" ->
      Some("Hi,

Thanks for emailing me. Have we met?

I don't yet have your email (or any idea you even sent one) because Plum Mail has it on ice until we establish who you are.
Honestly this is just the best way to deal with spam.

Please can you tell me something about you that we can relate over?
I would also love to know where you found me.

I'm pretty fussy about who gets into my inbox, don't hate me, it's just who I am.

Speak soon and thank you,

Richard",
      )
      _ -> None
  }
}
