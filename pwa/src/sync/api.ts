import type { Group, Memo, Participation } from "../conversation"
import type { Conversation, Identifier } from "../conversation"
import type { Block } from "../writing"
import { get, post } from "./client"
import type { Call, Response } from "./client"
import type { Inbox } from "./state"


function mapData<D, T>(response: Response<D>, mapper: (_: D) => T): Response<T> {
  if ('error' in response) {
    return response
  } else {
    return { data: mapper(response.data) }
  }
}

function identifierFromDTO(data: IdentifierDTO): Identifier {
  const { id, type, email_address: emailAddress, greeting, } = data
  return { id, type, emailAddress, greeting }
}

export type SharedDTO = {
  type: "shared"
  id: number,
  email_address: string,
  greeting: Block[] | null
}
export type PersonalDTO = {
  type: "personal",
  id: number,
  email_address: string,
  greeting: Block[] | null
}
type IdentifierDTO = PersonalDTO | SharedDTO

type GroupDTO = {
  type: 'group',
  id: number,
  name: string,
}

function contactFromDTO(contact: IdentifierDTO | GroupDTO): Identifier | Group {
  if (contact.type === 'group') {
    return contact
  } else {
    return identifierFromDTO(contact)
  }
}

export type MemoDTO = {
  author: string,
  content: Block[]
  // NOTE string is human string
  posted_at: string,
  position: number,
}

function memoFromDTO(data: MemoDTO): Memo {
  let { author, content, posted_at: postedAt, position } = data
  return { author, content, postedAt: new Date(postedAt), position }
}


type ParticipationDTO = {
  thread_id: number,
  acknowledged: number,
  latest: MemoDTO | null
}

function participationFromDTO(data: ParticipationDTO): Participation {
  let { thread_id: threadId, latest, acknowledged } = data
  return { threadId, latest: latest && memoFromDTO(latest), acknowledged }
}

type ConversationDTO = {
  contact: IdentifierDTO | GroupDTO,
  participation: ParticipationDTO
}

function conversationFromDTO({ contact, participation }: ConversationDTO): Conversation {
  return {
    contact: contactFromDTO(contact),
    participation: participationFromDTO(participation)
  }
}

type roleDTO = { type: 'personal' } | { type: 'member', identifier: IdentifierDTO }
type InboxDTO = {
  conversations: ConversationDTO[],
  identifier: IdentifierDTO,
  role: roleDTO
}

function roleFromDTO(role: roleDTO): { type: 'personal' } | { type: 'member', identifier: Identifier } {
  if ('type' in role && role.type === 'personal') {
    return { type: 'personal' }
  } else {
    return { type: 'member', identifier: identifierFromDTO(role.identifier) }
  }
}

function inboxFromDTO(data: InboxDTO): Inbox {
  const { conversations, identifier, role } = data

  return {
    conversations: conversations.map(conversationFromDTO),
    identifier: identifierFromDTO(identifier),
    role: roleFromDTO(role)
  }
}

// Authentication

export async function authenticateByCode(code: string): Call<Inbox[]> {
  const path = "/authenticate/code"
  const params = { code }
  let response: Response<{ inboxes: InboxDTO[] }> = await post(path, params)
  return mapData(response, function ({ inboxes }) {
    return inboxes.map(inboxFromDTO)
  })
}

export async function authenticateBySession(): Call<Inbox[] | null> {
  const path = "/authenticate/session"
  let response: Response<{ inboxes: InboxDTO[] } | null> = await get(path)
  return mapData(response, function (data) {
    return data?.inboxes.map(inboxFromDTO) || null
  })
}


export async function authenticateByEmail(emailAddress: string) {
  const path = "/authenticate/email"
  const params = { email_address: emailAddress }
  let response: Response<null> = await post(path, params);
  return response
}

export async function authenticateByPassword(emailAddress: string, password: string): Call<{ identifier: Identifier, shared: Identifier[] }> {
  const path = "/authenticate/password"
  const params = { email_address: emailAddress, password }
  let response: Response<{ identifier: IdentifierDTO, shared: IdentifierDTO[] }> = await post(path, params);
  return mapData(response, function ({ identifier, shared }) {
    return { identifier: identifierFromDTO(identifier), shared: shared.map(identifierFromDTO) }
  })
}


// User Accont calls

export function saveGreeting(blocks: Block[] | null): Call<unknown> {
  const path = "/me/greeting"
  const params = { blocks }
  return post(path, params)
}

// identifier discovery

// export async function fetchProfile(emailAddress: string): Call<Identifier | null> {
//   const path = "/identifiers/" + emailAddress
//   let response: Response<IdentifierDTO> = await get(path);
//   return mapData(response, identifierFromDTO)
// }

export async function startDirectConversation(identifierId: number, emailAddress: string, content: Block[]): Call<Conversation> {
  const path = "/identifiers/" + identifierId + "/start_direct"
  const params = { email_address: emailAddress, content }
  let response: Response<ConversationDTO> = await post(path, params)
  return mapData(response, conversationFromDTO)
}

export async function createGroup(groupName: string, invitees: number[]): Call<Conversation> {
  const path = "/groups/create"
  const params = { name: groupName, invitees }
  let response: Response<ConversationDTO> = await post(path, params)
  return mapData(response, conversationFromDTO)
}

// Thread API endpoints

export async function pullMemos(threadId: number): Call<Memo[]> {
  const path = "/threads/" + threadId + "/memos"
  let response: Response<MemoDTO[]> = await get(path);
  return mapData(response, (dto) => { return dto.map(memoFromDTO) })
}

export async function postMemo(threadId: number, position: number, content: Block[]): Call<Memo> {
  const path = "/threads/" + threadId + "/post"
  const params = { position, content }
  let response: Response<MemoDTO> = await post(path, params);
  return mapData(response, memoFromDTO)
}

export async function acknowledge(threadId: number, position: number): Call<null> {
  const path = "/threads/" + threadId + "/acknowledge"
  const params = { position }
  let response: Response<null> = await post(path, params);
  return response
}