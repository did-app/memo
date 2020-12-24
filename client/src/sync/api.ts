import type { Block } from "../note/elements"
import { get, post } from "./client"
import type { Call } from "./client"


export type Identifier = { id: number, emailAddress: string, hasAccount: boolean, greeting: Block[] }
// typescript type for anything, so it needs checking
// unknown is the type we need

function toIdentifier({ identifier: raw, greeting }) {
  const identifier = {
    id: raw.id,
    emailAddress: raw.email_address,
    hasAccount: raw.has_account,
    greeting
  }
  return identifier
}
export async function authenticateWithSession(): Call<Identifier> {
  const path = "/authenticate/session"
  const response = await get(path)
  return mapData(response, toIdentifier)
}

export async function authenticateWithCode(code): Call<Identifier> {
  const path = "/authenticate/code"
  const params = { code }
  const response = await post(path, params)
  return mapData(response, toIdentifier)
}

export type Block = { type: "paragraph" }

export type Contact = {
  id: number,
  emailAddress: string,
  introduction: Block[],
  threadId: number | null
}

export async function fetchProfile(id): Call<{ greeting: Block[] }> {
  const path = "/identifiers/" + id;
  const response = await get(path)
  return mapData(response, function (raw) {
    return {
      greeting: raw.greeting
    }
  })
}

export async function fetchContact(identifier): Call<Contact> {
  const path = "/relationship/" + identifier;
  const response = await get(path)
  return mapData(response, function (raw) {
    return {
      id: raw.contact_id,
      emailAddress: raw.email_address,
      // introduction: raw.introduction,
      introduction: [],
      // above might be an identifier and below a thread
      threadId: raw.thread_id
      // notes: []
    }
  })
}

export type OK = { ok: true }
function ok(): OK { return { ok: true } }

export async function saveGreeting(identifier_id: number, blocks: Block[]): Call<OK> {
  const path = "/identifiers/" + identifier_id + "/greeting"
  const params = { blocks }
  const response = await post(path, params)
  return mapData(response, function (_) {
    return ok();
  })
}

export async function startRelationship(id: number, counter: number, blocks: Block[]) {
  const path = "/relationships/start"
  const params = { id, counter, blocks }
  const response = await post(path, params)
  return mapData(response, function (_) {
    return null
  })
}

export async function writeNote(threadId: number, counter: number, blocks: Block[]): Call<null> {
  const path = "/threads/" + threadId + "/write"
  const params = { counter, blocks }
  const response = await post(path, params)
  return mapData(response, function (_) {
    return null
  })
}

function mapData<T>(response, mapper: (unknown) => T): T {
  if ("data" in response) {
    return mapper(response.data)
  } else {
    return response
  }
}