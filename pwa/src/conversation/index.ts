export type { Memo } from "./memo"
import type { IdentifierDTO } from "src/sync/api";
import type { Memo } from "./memo"
export type { Reference } from "./reference";

export type { Thread } from "./thread";
export { currentPosition, followReference, makeSuggestions, gatherPrompts } from "./thread"

export type { Pin } from "./pin";
export { findPinnable } from "./pin"

// export { getReference } from "../writing/view"

export type Participation = {
  threadId: number,
  acknowledged: number,
  latest: Memo | null
}
export type Shared = {
  id: number,
  emailAddress: string,
  greeting: Block[] | null
}
export type Personal = {
  id: number,
  emailAddress: string,
  greeting: Block[] | null
}
export type Identifier = Personal | Shared

export type Group = {
  id: number,
  name: string,
}


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

export function subject(contact: Group | Identifier): string {
  if ('name' in contact) {
    return contact.name
  } else {
    return contact.emailAddress
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