export type { Memo } from "./memo"
import type { Memo } from "./memo"
export type { Reference } from "./reference";

export type { Thread } from "./thread";
export { followReference, makeSuggestions, gatherPrompts } from "./thread"

export type { Pin } from "./pin";
export { findPinnable } from "./pin"
import type { Block } from "../writing"

// export { getReference } from "../writing/view"

export type Participation = {
  threadId: number,
  acknowledged: number,
  latest: Memo | null
}
export type Shared = {
  type: "shared"
  id: number,
  emailAddress: string,
  greeting: Block[] | null
}
export type Personal = {
  type: "personal",
  id: number,
  emailAddress: string,
  greeting: Block[] | null
}
export type Identifier = Personal | Shared

export type Group = {
  type: 'group',
  id: number,
  name: string,
  participants: string[]
}

// Contact is Group | Direct(Identifier)


// Social was a good name for the contact bit but no outstanding pin finding etc
export type Conversation = {
  contact: Group | Identifier,
  participation: Participation
}

export function isOutstanding(participation: Participation): boolean {
  if (participation.latest) {
    return participation.latest.position > participation.acknowledged
  } else {
    return false
  }
}

export function subject(contact: Group | Identifier): [string, string] {
  if ('name' in contact) {
    return [contact.name, contact.participants.join(", ")]
  } else {
    return [contact.emailAddress, ""]
  }
}

export function url(contact: Group | Identifier): string {
  if ('name' in contact) {
    return "/groups/" + contact.id
  } else {
    return emailAddressToPath(contact.emailAddress)
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