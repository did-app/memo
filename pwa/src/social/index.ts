
import type { Thread } from "../conversation";
import type { Block } from "../writing"

export type Identifier = {
  emailAddress: string
  greeting: Block[] | null
}

// TODO define thread identifier profile types
export type Contact = {
  identifier: Identifier,
  // A contact will always have a thread
  thread: Thread
}
export type Stranger = {
  emailAddress: string
}


export function contactForEmailAddress(contacts: Contact[], emailAddress: string): Contact | Stranger {
  let result = contacts.find(function (contact) { return contact.identifier.emailAddress === emailAddress })
  if (result) {
    return result
  } else {
    return { emailAddress }
  }
}

export function emailAddressToPath(emailAddress: string) {
  let [username, domain] = emailAddress.split("@");
  if (domain === "plummail.co") {
    return "/" + username;
  } else {
    return "/" + domain + "/" + username;
  }
}