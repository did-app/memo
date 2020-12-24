import { get, post } from "./client"
import type { Call } from "./client"
import type { Block } from "../note/elements"

export type Identifier = {
  id: number,
  email_address: string,
  greeting: Block[]
}

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

export function saveGreeting(identifier_id: number, blocks: Block[]): Call<{ data: unknown }> {
  const path = "/identifiers/" + identifier_id + "/greeting"
  const params = { blocks }
  return post(path, params)
}