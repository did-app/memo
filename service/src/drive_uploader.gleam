import gleam/dynamic
import gleam/pgo
import plum_mail/authentication
import plum_mail/run_sql

pub type Uploader {
  Uploader(id: String, name: String)
}

pub fn save_authorization(sub, email_address, refresh_token, access_token) {
  let sql =
    "
    WITH updated_authorization AS (
      UPDATE google_authorizations 
      SET email_address = $2, refresh_token = $3, access_token = $4 
      WHERE sub = $1
      RETURNING *
    ), new_authorization AS (
      INSERT INTO google_authorizations (sub, email_address, refresh_token, access_token)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (email_address) DO NOTHING
      RETURNING *
    )
    SELECT sub FROM updated_authorization
    UNION ALL
    SELECT sub FROM new_authorization
    "
  let args = [
    pgo.text(sub),
    pgo.text(email_address),
    pgo.text(refresh_token),
    pgo.text(access_token),
  ]

  let mapper = fn(row) {
    // Use assert because it's a code error to fail
    assert Ok(sub) = dynamic.element(row, 0)
    assert Ok(sub) = dynamic.string(sub)
    sub
  }
  try authorizations = run_sql.execute(sql, args, mapper)
  assert [authorization] = authorizations
  Ok(authorization)
}

pub fn list_for_authorization(sub) {
  let sql =
    "
  SELECT authorization_sub, id, name
  FROM drive_uploaders
  WHERE authorization_sub = $1
  "
  let args = [pgo.text(sub)]
  run_sql.execute(sql, args, row_to_uploader)
}

pub fn authorize(code, client) {
  // exchange code
  todo
}

// Call them links?
pub fn create_uploader(sub, name) {
  let id = authentication.random_string(8)
  let sql =
    "
  INSERT INTO drive_uploaders (authorization_sub, id, name)
  VALUES ($1, $2, $3)
  RETURNING authorization_sub, id, name
  "
  let args = [pgo.text(sub), pgo.text(id), pgo.text(name)]
  try uploaders = run_sql.execute(sql, args, row_to_uploader)
  assert [uploader] = uploaders
  Ok(uploader)
}

fn row_to_uploader(row) {
  assert Ok(sub) = dynamic.element(row, 0)
  assert Ok(sub) = dynamic.string(sub)
  assert Ok(id) = dynamic.element(row, 1)
  assert Ok(id) = dynamic.string(id)
  assert Ok(name) = dynamic.element(row, 2)
  assert Ok(name) = dynamic.string(name)
  Uploader(id, name)
}

pub fn edit_uploader() {
  todo
}

pub fn delete_uploader() {
  todo
}
