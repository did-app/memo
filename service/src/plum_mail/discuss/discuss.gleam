import gleam/int
import gleam/string
import plum_mail/authentication.{Identifier}
import plum_mail/discuss/conversation.{Conversation}

pub opaque type Participation {
  Participation(
    conversation: Conversation,
    active: Bool,
    identifier: Identifier,
  )
}

pub fn build_participation(conversation, identifier) {
  Participation(conversation, True, identifier)
}

pub fn load_participation(conversation_id: Int, identifier_id: Int) {
  todo
}

// Note doesn't need to always load identifier if we are making json returns because identifier information already fetched.
pub fn can_view(participation) -> Conversation {
  todo
}

pub fn can_edit(participation) -> tuple(Conversation, Int) {
  todo
}
// Share is a functionality
pub fn invite_link(participation) {
  let Participation(
    conversation: Conversation(id: conversation_id, ..),
    identifier: Identifier(id: identifier_id, ..),
    ..,
  ) = participation
  string.join(
    ["", "i", int.to_string(conversation_id), int.to_string(identifier_id)],
    "/",
  )
}
