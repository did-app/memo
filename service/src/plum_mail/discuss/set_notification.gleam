import gleam/dynamic.{Dynamic}
import gleam/pgo
import plum_mail/acl
import plum_mail/run_sql
import plum_mail/discuss/discuss.{All, Concluded, None, Preference}

pub type Params {
  Params(preference: Preference)
}

pub fn params(raw: Dynamic) {
  try preference = acl.required(raw, "notify", discuss.as_preference)
  Params(preference)
  |> Ok
}

pub fn execute(participation, params) {
  let discuss.Participation(
    conversation: conversation,
    identifier: identifier,
    notify: notify,
    ..,
  ) = participation

  let Params(preference: new) = params
  case new == notify {
    True -> Ok(Nil)
    False -> {
      let sql =
        "
            UPDATE participants
            SET notify = $1
            WHERE identifier_id = $2
            AND conversation_id = $3
            RETURNING *
            "
      let args = [
        pgo.text(discuss.notify_to_string(new)),
        pgo.int(identifier.id),
        pgo.int(conversation.id),
      ]
      let mapper = fn(_) { Nil }
      assert Ok([_]) = run_sql.execute(sql, args, mapper)
      Ok(Nil)
    }
  }
}
