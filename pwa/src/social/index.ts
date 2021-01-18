
import type { Thread, Memo } from "../conversation";
import type { Call } from "../sync"
import type { Block } from "../writing"
import * as API from "../sync/api"

export type Identifier = {
  emailAddress: string
  greeting: Block[] | null
}

// define thread identifier profile types
export type Contact = {
  identifier: Identifier,
  // A contact will always have a thread
  thread: Thread
}
export type Stranger = {
  identifier: Identifier
  thread: { latest: null, acknowledged: 0 }
}


export async function contactForEmailAddress(contacts: Contact[], emailAddress: string): Call<Contact | Stranger> {
  let result = contacts.find(function (contact) { return contact.identifier.emailAddress === emailAddress })
  if (result) {
    return { data: result }
  } else {
    let response = await API.fetchProfile(emailAddress)
    if ('data' in response && response.data !== null) {
      let greeting = response.data.greeting
      let thread: Thread | { latest: null; acknowledged: 0; };
      thread = { latest: null, acknowledged: 0 }
      // if (greeting === null) {
      // } else {
      //   let latest: Memo = { author: emailAddress, content: greeting, posted_at: new Date(), position: 0 }
      //   thread = { latest, acknowledged: 1 }
      // }
      let identifier = { emailAddress, greeting }

      return { data: { identifier, thread } }
    } else {

      throw "failed to look up public info"
    }
  }
}

export function emailAddressToPath(emailAddress: string) {
  let [username, domain] = emailAddress.split("@");
  if (domain === "plummail.co") {
    return "/" + username;
  } else {
    return "/" + domain + "/" + username;
  }
}