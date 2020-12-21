// could be called users or identity.
// something like yesplease is not an identity, is it a contact.
// maybe more contact information than "a contact"
import gleam/string

// TODO delete all
pub type Profile {
  Profile(greeting: String)
}

pub fn lookup(label) {
  let email_address = case string.contains(label, "@") {
    True -> label
    False -> string.concat([label, "@plummail.co"])
  }
  case email_address {
    "peter@plummail.co" ->
      Ok(Profile(
        greeting: "Hello

Thanks for reaching out

I'm currently trying to take control of my communication.
Please may I ask you consider the following in your message

- Be explicit about if you need a reply, and how quickly.
- If I don't know you, share a link to your website, bio or twitter
- Recruiters, I'm very happy building [Plum Mail](https://plummail.co) and not looking for new opportunities.

**Cheers, Peter**",
      ))
    "richard@plummail.co" ->
      Ok(Profile(
        greeting: "Hi,

Thanks for emailing me. Have we met?

I don't yet have your email (or any idea you even sent one) because Plum Mail has it on ice until we establish who you are.
Honestly this is just the best way to deal with spam.

Please can you tell me something about you that we can relate over?
I would also love to know where you found me.

I'm pretty fussy about who gets into my inbox, don't hate me, it's just who I am.

Speak soon and thank you,

Richard",
      ))
  }
}
