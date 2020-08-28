import gleam/dynamic
import gleam/option.{Option}
import gleam/result
import gleam/pgo
import plum_mail/run_sql

pub type Identifier {
  Identifier(id: Int, email_address: String, nickname: Option(String))
}

fn row_to_identifier(row) {
  assert Ok(id) = dynamic.element(row, 0)
  assert Ok(id) = dynamic.int(id)
  assert Ok(email_address) = dynamic.element(row, 1)
  assert Ok(email_address) = dynamic.string(email_address)
  assert Ok(nickname) = dynamic.element(row, 2)
  assert Ok(nickname) = run_sql.dynamic_option(nickname, dynamic.string)
  Identifier(id, email_address, nickname)
}

pub fn fetch_identifier(id) {
  let sql =
    "
    SELECT id, email_address, nickname
    FROM identifiers
    WHERE id = $1"
  let args = [pgo.int(id)]
  try db_result = run_sql.execute(sql, args, row_to_identifier)
  run_sql.single(db_result)
  |> Ok
}

// https://www.postgresql.org/message-id/CAHiCE4VBFg7Zp75x8h8QoHf3qpH_GqoQEDUd6QWC0bLGb6ZhVg%40mail.gmail.com
pub fn identifier_from_email(email_address) {
  let sql =
    "
    WITH new_identifier AS (
        INSERT INTO identifiers (email_address)
        VALUES ($1)
        ON CONFLICT DO NOTHING
        RETURNING *
    )
    SELECT id, email_address, nickname FROM new_identifier
    UNION ALL
    SELECT id, email_address, nickname FROM identifiers WHERE email_address = $1
    "
  // Could return True of False field for new user
  // Would enable Log or send email when new user is added
  let args = [pgo.text(email_address)]
  try [row] = run_sql.execute(sql, args, row_to_identifier)
  Ok(row)
}

pub fn update_nickname(identifier_id, nickname) {
  let sql =
    "
    UPDATE identifiers
    SET nickname = $2
    WHERE id = $1
    RETURNING id, email_address, nickname
    "
  let args = [pgo.int(identifier_id), pgo.text(nickname)]
  run_sql.execute(sql, args, row_to_identifier)
}
