export type { Inbox, State } from "./state"
import type { Memo } from "../conversation"
import type { Inbox, State } from "./state"
export {
  initial,
  startTask,
  resolveTask,
  removeTask,
  reportFailure,
  selectedInbox,
  selectedConversation
} from "./state"
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

