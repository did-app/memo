import { get, post } from "./client"
import type { Call } from "./client"

export type Identifier = {
  id: number,
  email_address: string,
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