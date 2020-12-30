import { get, post } from "./client"
import type { Call } from "./client"
import type { Block } from "../note/elements"

export type Identifier = {
  id: number,
  email_address: string,
  greeting: Block[] | null,
}

// Authentication

export function authenticateByCode(code: string): Call<{ data: Identifier }> {
  const path = "/authenticate/code"
  const params = { code }
  return post(path, params)
}

export function authenticateBySession(): Call<{ data: Identifier }> {
  const path = "/authenticate/session"
  return get(path)
}

export function authenticateByEmail(emailAddress: string) {
  const path = "/authenticate/email"
  const params = { email_address: emailAddress }
  return post(path, params);
}

export function authenticateByPassword(emailAddress: string, password: string): Call<{ data: Identifier }> {
  const path = "/authenticate/password"
  const params = { email_address: emailAddress, password }
  return post(path, params);
}


// User Accont calls

export function saveGreeting(identifier_id: number, blocks: Block[] | null): Call<{ data: unknown }> {
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
  notes: Note[]
}

export function fetchProfile(emailAddress: string): Call<{ data: Identifier | null }> {
  const path = "/identifiers/" + emailAddress
  return get(path)
}

export function fetchContact(emailAddress: string): Call<{ data: { identifier: Identifier | undefined, thread: Thread | undefined } }> {
  const path = "/relationship/" + emailAddress
  return get(path)
}

export function fetchContacts(): Call<{ data: { identifier: Identifier }[] }> {
  const path = "/contacts"
  return get(path)
}

export function startRelationship(emailAddress: string, blocks: Block[]) {
  const path = "/relationship/start"
  const params = { email_address: emailAddress, blocks }
  return post(path, params)
}

// TODO postMemo
// memo has contents and an index
export function writeNote(threadId: number, counter: number, blocks: Block[]): Call<{ data: null }> {
  const path = "/threads/" + threadId + "/post"
  const params = { counter, blocks }
  return post(path, params)
}