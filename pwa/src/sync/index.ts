export type { Inbox, State } from "./state"
import type { Memo } from "../conversation"
import type { Inbox, State } from "./state"
export { initial, startTask, resolveTask, reportFailure } from "./state"
export { startInstall } from "./install"

import * as API from "./api"
import type { Call } from "./client"

function popAuthenticationCode(): string | null {
  const fragment = window.location.hash.substring(1);
  const params = new URLSearchParams(fragment);
  const code = params.get("code");
  if (code !== null) {
    window.location.hash = "#";
  }
  return code
}
// Put the promise on the loading key
// Type script doesn't have an error type Hmm
export async function authenticate(): Call<Inbox[] | null> {
  const code = popAuthenticationCode()
  if (code) {
    return await API.authenticateByCode(code)
  } else {
    return await API.authenticateBySession()
  }
}

export async function fetchMemos() {
  return []
}

// export function updateContact(contact: Contact) {
//   update(function (state: State) {
//     if ('me' in state && state.me) {
//       const index = state.contacts.findIndex(({ identifier: { emailAddress } }) => contact.identifier.emailAddress === emailAddress)
//       const contacts = index === -1 ? [...state.contacts, contact] : [...state.contacts.slice(0, index), contact, ...state.contacts.slice(index + 1)]

//       state.contacts = contacts
//     }
//     return state
//   })
// }

// export async function saveGreeting(blocks: Block[]): Call<null> {
//   let task = await API.saveGreeting(blocks)
//   if ('error' in task) {
//     throw "Failed to save greeting"
//   }
//   update(function (state) {
//     if ('me' in state && state.me !== undefined) {
//       let me = { ...state.me, greeting: blocks }
//       let flash: Flash[] = [{ type: 'profile_saved' }]
//       state = { ...state, me, flash }
//     }
//     return state
//   })
//   return { data: null }
// }

// export { loadMemos } from "./api"

// export async function postMemo(me: number, contact: Relationship, blocks: Block[], position: number): Call<null> {
//   let task: Call<Contact>
//   if (contact.thread) {
//     let thread: Thread = contact.thread;
//     task = API.postMemo(thread.id, position, blocks).then(function (response) {
//       if ('data' in response) {
//         let latest = response.data
//         thread = { ...thread, latest, acknowledged: latest.position }
//         return { data: { identifier: contact.identifier, thread } }
//       } else {
//         return response
//       }
//     })
//   } else {
//     task = API.startDirectConversation(me, contact.identifier.emailAddress, blocks);

//   }
//   let response = await task

//   if ('data' in response) {
//     updateContact(response.data)
//   } else {

//   }
//   return { data: null }
// }

// export async function acknowledge(contact: Contact, position: number): Call<null> {
//   update(function (state) {
//     if ('contacts' in state) {
//       let { flash, contacts, ...unchanged } = state
//       contacts = contacts.map(function (each: Contact) {
//         if (each.thread.id === contact.thread.id) {
//           let acknowledged = Math.max(position, each.thread.acknowledged)
//           let thread = { ...each.thread, acknowledged }
//           return { ...each, thread }
//         } else {
//           return each
//         }
//       })
//       flash = [{ type: 'acknowledged', contact }]
//       return { flash, contacts, ...unchanged }
//     } else {
//       return state
//     }
//   })
//   return await API.acknowledge(contact.thread.id, position)
// }