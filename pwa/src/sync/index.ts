import { writable } from "svelte/store"
import type { Writable } from "svelte/store"
import type { Memo, Thread } from "../conversation"
import type { Block } from "../writing"
import type { Call, Failure } from "./client"
import * as API from "./api"
import type { Contact, Relationship, Identifier } from "../social"

import type { InstallPrompt } from "./install"
import startInstall from "./install"

export type { Response, Call } from "./client"

export type MemoAcknowledged = { type: "acknowledged", contact: Contact }
export type InstallAvailable = { type: "install_available", prompt: InstallPrompt }
export type ProfileSaved = { type: 'profile_saved' }
export type Flash = MemoAcknowledged | InstallAvailable | ProfileSaved

export type Task = { message: "" }

export type Loading = { loading: true, flash: Flash[], tasks: Task[], me: undefined, error: Failure | undefined }
export type Unauthenticated = { loading: false, flash: Flash[], tasks: Task[], me: undefined, error: Failure | undefined }
export type Authenticated = { loading: false, flash: Flash[], tasks: Task[], me: Identifier, contacts: Contact[], error: Failure | undefined }
export type State = Loading | Unauthenticated | Authenticated

const initial: State = { loading: true, flash: [], tasks: [], me: undefined, error: undefined }
const store: Writable<State> = writable(initial);
const { subscribe, set, update } = store

const fragment = window.location.hash.substring(1);
const params = new URLSearchParams(fragment);
const code = params.get("code");
// Put the promise on the loading key
async function start(): Promise<State> {
  let me: Identifier
  if (code !== null) {
    window.location.hash = "#";
    let authResponse = await API.authenticateByCode(code)
    if ("error" in authResponse) {
      return { ...initial, loading: false, error: authResponse.error }
    }
    me = authResponse.data.identifier
  } else {
    let authResponse = await API.authenticateBySession()
    if ('data' in authResponse) {
      let data = authResponse.data
      if (data === null) {
        return { ...initial, loading: false }
      } else {
        me = data.identifier

      }
    } else {
      return { ...initial, loading: false, error: authResponse.error }
    }
  }

  let inboxResponse = await API.fetchContacts();
  if ("error" in inboxResponse) {
    return { ...initial, loading: false, error: inboxResponse.error }
  }
  return { loading: false, flash: [], tasks: [], me, contacts: inboxResponse.data, error: undefined }
}
start().then(set).then(function () {
  startInstall(window).then(function (installPrompt) {
    update(function ({ flash, ...unchanged }) {
      async function prompt() {
        let result = await installPrompt()
        console.log(result);
        update(function ({ flash, ...unchanged }) {
          flash = flash.filter(function (each) {
            return each.type !== 'install_available'
          })
          return { flash, ...unchanged }
        })
        return result
      }

      flash = [{ type: "install_available", prompt }, ...flash]
      return { flash, ...unchanged }
    })
  })
})
// Needs single function to handle auth response and fetch contacts
// fetch contacts is separate so it can be updated periodically

export const sync = {
  subscribe
}

export async function authenticateByPassword(emailAddress: string, password: string) {
  let authResponse = await API.authenticateByPassword(emailAddress, password);
  if ("error" in authResponse) {
    return authResponse.error
  }
  let me = authResponse.data.identifier
  let inboxResponse = await API.fetchContacts();
  if ("error" in inboxResponse) {
    throw "some error we aint fixed yet";
  }
  set({ loading: false, flash: [], tasks: [], me, contacts: inboxResponse.data, error: undefined })
  return authResponse
}

export function updateContact(contact: Contact) {
  update(function (state: State) {
    if ('me' in state && state.me) {
      const index = state.contacts.findIndex(({ identifier: { emailAddress } }) => contact.identifier.emailAddress === emailAddress)
      const contacts = index === -1 ? [...state.contacts, contact] : [...state.contacts.slice(0, index), contact, ...state.contacts.slice(index + 1)]

      state.contacts = contacts
    }
    return state
  })
}

export async function saveGreeting(blocks: Block[]): Call<null> {
  let task = await API.saveGreeting(blocks)
  if ('error' in task) {
    throw "Failed to save greeting"
  }
  update(function (state) {
    if ('me' in state && state.me !== undefined) {
      let me = { ...state.me, greeting: blocks }
      let flash: Flash[] = [{ type: 'profile_saved' }]
      state = { ...state, me, flash }
    }
    return state
  })
  return { data: null }
}

export { loadMemos } from "./api"

export async function postMemo(me: number, contact: Relationship, blocks: Block[], position: number): Call<null> {
  let task: Call<Contact>
  if (contact.thread) {
    let thread: Thread = contact.thread;
    task = API.postMemo(thread.id, position, blocks).then(function (response) {
      if ('data' in response) {
        let latest = response.data
        thread = { ...thread, latest, acknowledged: latest.position }
        return { data: { identifier: contact.identifier, thread } }
      } else {
        return response
      }
    })
  } else {
    task = API.startDirectConversation(me, contact.identifier.emailAddress, blocks);

  }
  let response = await task

  if ('data' in response) {
    updateContact(response.data)
  } else {

  }
  return { data: null }
}

export async function acknowledge(contact: Contact, position: number): Call<null> {
  update(function (state) {
    if ('contacts' in state) {
      let { flash, contacts, ...unchanged } = state
      contacts = contacts.map(function (each: Contact) {
        if (each.thread.id === contact.thread.id) {
          let acknowledged = Math.max(position, each.thread.acknowledged)
          let thread = { ...each.thread, acknowledged }
          return { ...each, thread }
        } else {
          return each
        }
      })
      flash = [{ type: 'acknowledged', contact }]
      return { flash, contacts, ...unchanged }
    } else {
      return state
    }
  })
  return await API.acknowledge(contact.thread.id, position)
}