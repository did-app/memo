import { get, post } from "./client"
import type { Call } from "./client"
import type { Block } from "../note/elements"

export type Identifier = {
  greeting: Block[],
  identifier: {
    id: number,
    email_address: string,
  }
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

export function fetchProfile(email_address: string): Call<{ data: { greeting: Block[] } }> {
  const path = "/identifiers/" + email_address
  return get(path)
}

export function fetchContact(email_address: string): Call<{ data: { greeting: Block[] } }> {
  const path = "/relationship/" + email_address
  return get(path)
}