import { get, post } from "./client"
import type { Call } from "./client"
import type { Block } from "../writing/elements"

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

export function saveGreeting(identifier_id: number, content: Block[] | null): Call<unknown> {
  const path = "/identifiers/" + identifier_id + "/greeting"
  const params = { content }
  return post(path, params)
}

// identifier discovery

export type Memo = {
  author: string,
  content: Block[]
  // NOTE string is human string
  inserted_at: string,
  position: number,
}
export type Thread = {
  id: number,
  ack: number,
  memos: Memo[]
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
  latest: Memo | undefined
}
export function fetchContacts(): Call<Contact[]> {
  const path = "/contacts"
  return get(path)
}

export function startRelationship(emailAddress: string, content: Block[]): Call<Contact> {
  const path = "/relationship/start"
  const params = { email_address: emailAddress, content }
  return post(path, params)
}

export function postMemo(threadId: number, position: number, content: Block[]): Call<{ latest: Memo }> {
  const path = "/threads/" + threadId + "/post"
  const params = { position, content }
  return post(path, params)
}

export function acknowledge(threadId: number, position: number): Call<{}> {
  const path = "/threads/" + threadId + "/acknowledge"
  const params = { position }
  return post(path, params)

}