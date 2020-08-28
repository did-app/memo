import plum_mail/discuss/conversation.{Conversation}

pub type Identifier {
  Identifier(id: Int, email_address: String)
}

pub opaque type Participation {
  Participation(conversation: Conversation, active: Bool)
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
