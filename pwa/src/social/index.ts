
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



export function contactForEmailAddress(emailAddress: string): Contact {
  throw "TODO contact"
}

export function emailAddressToPath(emailAddress: string) {
  let [username, domain] = emailAddress.split("@");
  if (domain === "plummail.co") {
    return "/" + username;
  } else {
    return "/" + domain + "/" + username;
  }
}