import type { Memo, Thread } from "../conversation"
import type { Identifier, Contact } from "../social"
import type { Block } from "../writing"
import { get, post } from "./client"
import type { Call, Failure } from "./client"

type Response<T> = { data: T } | { error: Failure }
function mapData<D, T>(response: Response<D>, mapper: (_: D) => T): Response<T> {
  if ('error' in response) {
    return response
  } else {
    return { data: mapper(response.data) }
  }
}

export type IdentifierDTO = {
  id: number,
  email_address: string,
  greeting: Block[] | null,
}

function identifierFromDTO(data: IdentifierDTO): Identifier {
  const { id, email_address: emailAddress, greeting, } = data
  return { emailAddress, greeting }
}

// Authentication

export async function authenticateByCode(code: string): Call<Identifier> {
  const path = "/authenticate/code"
  const params = { code }
  let response: Response<IdentifierDTO> = await post(path, params)
  return mapData(response, identifierFromDTO)
}

export async function authenticateBySession(): Call<Identifier | null> {
  const path = "/authenticate/session"
  let response: Response<IdentifierDTO> = await get(path)
  return mapData(response, identifierFromDTO)
}

export async function authenticateByEmail(emailAddress: string) {
  const path = "/authenticate/email"
  const params = { email_address: emailAddress }
  let response: Response<IdentifierDTO> = await post(path, params);
  return mapData(response, identifierFromDTO)
}

export async function authenticateByPassword(emailAddress: string, password: string): Call<Identifier> {
  const path = "/authenticate/password"
  const params = { email_address: emailAddress, password }
  let response: Response<IdentifierDTO> = await post(path, params);
  return mapData(response, identifierFromDTO)
}


// User Accont calls

export function saveGreeting(identifier_id: number, content: Block[] | null): Call<unknown> {
  const path = "/identifiers/" + identifier_id + "/greeting"
  const params = { content }
  return post(path, params)
}

// identifier discovery

export type MemoDTO = {
  author: string,
  content: Block[]
  // NOTE string is human string
  posted_at: string,
  position: number,
}

function memoFromDTO(data: MemoDTO): Memo {
  let { author, content, posted_at: postedAt, position } = data
  return { author, content, posted_at: new Date(postedAt), position }
}
export type ThreadDTO = {
  acknowledged: number,
  latest: MemoDTO | null
}
function threadFromDTO(data: ThreadDTO): Thread {
  let { latest, acknowledged } = data
  return { latest: latest && memoFromDTO(latest), acknowledged }
}

// export function fetchProfile(emailAddress: string): Call<IdentifierDTO | null> {
//   const path = "/identifiers/" + emailAddress
//   return get(path)
// }

// export function fetchContact(emailAddress: string): Call<{ identifier: IdentifierDTO | undefined, thread: Thread | undefined }> {
//   const path = "/relationship/" + emailAddress
//   return get(path)
// }

export type ContactDTO = {
  identifier: IdentifierDTO,
  thread: {
    acknowledged: number
    latest: MemoDTO | null
  }
}
function contactFromDTO(data: ContactDTO): Contact {
  const { identifier, thread } = data
  return { identifier: identifierFromDTO(identifier), thread: threadFromDTO(thread) }
}
function contactsFromDTO(data: ContactDTO[]): Contact[] {
  return data.map(contactFromDTO)
}
export async function fetchContacts(): Call<Contact[]> {
  const path = "/contacts"
  let response: Response<ContactDTO[]> = await get(path)
  return mapData(response, contactsFromDTO)
}

export function startRelationship(emailAddress: string, content: Block[]): Call<Contact> {
  const path = "/relationship/start"
  const params = { email_address: emailAddress, content }
  return post(path, params)
}

export function postMemo(threadId: number, position: number, content: Block[]): Call<{ latest: MemoDTO }> {
  const path = "/threads/" + threadId + "/post"
  const params = { position, content }
  return post(path, params)
}

export function acknowledge(threadId: number, position: number): Call<{}> {
  const path = "/threads/" + threadId + "/acknowledge"
  const params = { position }
  return post(path, params)

}