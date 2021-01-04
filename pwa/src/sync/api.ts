import { get, post } from "./client"
import type { Call } from "./client"
import type { Block } from "../note/elements"

export type Identifier = {
  id: number,
  email_address: string,
  greeting: Block[] | null,
}

// Authentication

export function authenticateByCode(code: string): Call<Identifier> {
  const path = "/authenticate/code"
  const params = { code }
  return post(path, params)
}

export function authenticateBySession(): Call<Identifier | null> {
  const path = "/authenticate/session"
  return get(path)
}

export function authenticateByEmail(emailAddress: string) {
  const path = "/authenticate/email"
  const params = { email_address: emailAddress }
  return post(path, params);
}

export function authenticateByPassword(emailAddress: string, password: string): Call<Identifier> {
  const path = "/authenticate/password"
  const params = { email_address: emailAddress, password }
  return post(path, params);
}


// User Accont calls

export function saveGreeting(identifier_id: number, blocks: Block[] | null): Call<unknown> {
  const path = "/identifiers/" + identifier_id + "/greeting"
  const params = { blocks }
  return post(path, params)
}

// identifier discovery

// TODO memo is note plus author
export type Note = {
  author: string,
  blocks: Block[]
  // NOTE string is human string
  inserted_at: string,
  counter: number,
}
export type Thread = {
  id: number,
  ack: number,
  notes: Note[]
}

export function fetchProfile(emailAddress: string): Call<Identifier | null> {
  const path = "/identifiers/" + emailAddress
  return get(path)
}

export function fetchContact(emailAddress: string): Call<{ identifier: Identifier | undefined, thread: Thread | undefined }> {
  const path = "/relationship/" + emailAddress
  return get(path)
}

export type Contact = {
  identifier: Identifier,
  ack: number
  latest: { inserted_at: string, content: Block[], counter: number } | undefined
}
export function fetchContacts(): Call<Contact[]> {
  const path = "/contacts"
  return get(path)
}

export function startRelationship(emailAddress: string, blocks: Block[]): Call<Contact> {
  const path = "/relationship/start"
  const params = { email_address: emailAddress, blocks }
  return post(path, params)
}

// TODO postMemo
// memo has contents and an index
export function writeNote(threadId: number, counter: number, blocks: Block[]): Call<{ latest: { inserted_at: string, content: Block[], counter: number } }> {
  const path = "/threads/" + threadId + "/post"
  const params = { counter, blocks }
  return post(path, params)
}

export function acknowledge(threadId: number, counter: number): Call<{}> {
  const path = "/threads/" + threadId + "/acknowledge"
  const params = { counter }
  return post(path, params)

}