import { get, post } from "./client"
import type { Call } from "./client"
import type { Block } from "../note/elements"

export type Identifier = {
  id: number,
  email_address: string,
  greeting: Block[] | null,
}

// Authentication

export function authenticateWithCode(code: string): Call<{ data: Identifier }> {
  const path = "/authenticate/code"
  const params = { code }
  return post(path, params)
}

export function authenticateWithSession(): Call<{ data: Identifier }> {
  const path = "/authenticate/session"
  return get(path)
}

export function authenticateWithEmail(emailAddress: string) {
  const path = "/authenticate/email"
  const params = { email_address: emailAddress }
  return post(path, params);
}

// User Accont calls

export function saveGreeting(identifier_id: number, blocks: Block[]): Call<{ data: unknown }> {
  const path = "/identifiers/" + identifier_id + "/greeting"
  const params = { blocks }
  return post(path, params)
}

// identifier discovery

// TODO memo is note plus author
export type Note = {
  author: string,
  date: Date,
  blocks: Block[]
}
export type Thread = {
  id: number,
  notes: Note[]
}

export function fetchProfile(emailAddress: string): Call<{ data: { greeting: Block[] | null } }> {
  const path = "/identifiers/" + emailAddress
  return get(path)
}

export function fetchContact(emailAddress: string): Call<{ data: { identifier: Identifier, thread: Thread | undefined } }> {
  const path = "/relationship/" + emailAddress
  return get(path)
}

export function startRelationship(emailAddress: string, blocks: Block[]) {
  const path = "/relationship/start"
  const params = { email_address: emailAddress, blocks }
  return post(path, params)
}