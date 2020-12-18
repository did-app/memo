// if contact has no hello message start talking directly
// WHAT to do if contact is a group like founders
// user might want to view their contact page but they can't send
// could put a code in below when adding your email address, but we don't like that security.
pub fn between(identifier_id, contact) {
  let sql =
    "
    WITH ids AS (
        SELECT id FROM identifiers
        WHERE id = $1
        OR email_address = $2
    )
    SELECT * FROM pairs
    WHERE pairs.lower_identifier_id IN ids
    AND pairs.upper_identifier_id IN ids
    "
  // Need contact information even if pair doesn't
  // if looking at your own address then show account page
  todo
}
