
import type { Thread, Memo } from "../conversation";
import type { Call } from "../sync"
import type { Block } from "../writing"
import * as API from "../sync/api"

export function foo() {
  6
}
// TODO removbe
// export type Identifier = {
//   type: "personal" | "shared"
//   id: number,
//   emailAddress: string
//   greeting: Block[] | null
// }

// export type Contact = {
//   identifier: Identifier,
//   thread: Thread
// }
// export type Stranger = {
//   identifier: {
//     type: "unknown",
//     emailAddress: string,
//     greeting: Block[] | null
//   }
//   thread: null
// }

// export type Relationship = Contact | Stranger

// export async function contactForEmailAddress(contacts: Contact[], emailAddress: string): Call<Relationship> {
//   let result = contacts.find(function (contact) { return contact.identifier.emailAddress === emailAddress })
//   if (result) {
//     return { data: result }
//   } else {
//     let response = await API.fetchProfile(emailAddress)
//     if ('data' in response && response.data !== null) {
//       let greeting = response.data.greeting
//       let stranger: Stranger = { identifier: { type: "unknown", emailAddress, greeting }, thread: null }

//       return { data: stranger }
//     } else {

//       throw "failed to look up public info"
//     }
//   }
// }
