import { writable } from "svelte/store"
import type { Writable } from "svelte/store"
import type { Memo } from "../writing"
import type { Block } from "../writing/elements"
import type { Call, Failure } from "./client"
import * as API from "./api"
import type { Identifier, Contact } from "./api"

if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('/sw.js').then(function (registration) {
      // Registration was successful
      console.log('ServiceWorker registration successful with scope: ', registration.scope);
    }, function (err) {
      // registration failed :(
      console.log('ServiceWorker registration failed: ', err);
    });
  });
}
let installPrompt = new Promise(function (resolve, reject) {
  window.addEventListener('beforeinstallprompt', (e) => {
    console.log("installPrompt");
    resolve(e);
  });
});

export type Loading = { loading: true }
export type Unauthenticated = { loading: false, me: undefined, error: Failure | undefined }
export type Authenticated = { loading: false, me: Identifier, contacts: Contact[] }
export type State = Loading | Unauthenticated | Authenticated

const initial: State = { loading: true }
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
      return { loading: false, me: undefined, error: authResponse.error }
    }
    me = authResponse.data
  } else {
    let authResponse = await API.authenticateBySession()
    if ('data' in authResponse) {
      let data = authResponse.data
      if (data === null) {
        return { loading: false, me: undefined, error: undefined }
      } else {
        me = data
      }
    } else {
      return { loading: false, me: undefined, error: authResponse.error }
    }
  }

  let inboxResponse = await API.fetchContacts();
  if ("error" in inboxResponse) {
    return { loading: false, me: undefined, error: inboxResponse.error }
  }
  return { loading: false, me, contacts: inboxResponse.data }
}
start().then(set)
// TODO single function to handle auth response and fetch contacts
// fetch contacts is separate so it can be updated periodically

export const sync = {
  subscribe
}

export async function authenticateByPassword(emailAddress: string, password: string) {
  let authResponse = await API.authenticateByPassword(emailAddress, password);
  if ("error" in authResponse) {
    return authResponse.error
  }
  let me = authResponse.data
  let inboxResponse = await API.fetchContacts();
  if ("error" in inboxResponse) {
    throw "TODO error";
  }
  set({ loading: false, me, contacts: inboxResponse.data })
  return authResponse
}

export function updateContact(contact: Contact) {
  update(function (state: State) {
    if ('me' in state && state.me) {
      const index = state.contacts.findIndex(({ identifier: { email_address } }) => contact.identifier.email_address)
      const contacts = index === -1 ? state.contacts : [...state.contacts.slice(0, index), contact, ...state.contacts.slice(index + 1)]

      state.contacts = contacts
    }
    return state
  })
}
export async function loadContact(state: Unauthenticated | Authenticated, contactEmailAddress: string) {
  if (state.me) {
    console.log(state.contacts);
    let contactResponse = await API.fetchContact(contactEmailAddress);
    if ("error" in contactResponse) {
      throw "error";
    }
    let { thread, identifier } = contactResponse.data;

    if (!identifier) {
      return {
        threadId: null,
        ack: 0,
        memos: [],
        contactEmailAddress,
      };
    }
    if (thread) {
      let threadId = thread.id;
      let memos = thread.memos.map(function ({
        inserted_at: iso8601,
        ...rest
      }) {
        let inserted_at = new Date(iso8601);
        return { inserted_at, ...rest };
      });
      return {
        threadId,
        ack: thread.ack,
        memos: memos,
        contactEmailAddress,
      };
    } else {
      let greeting = identifier.greeting;

      let memos = greeting
        ? [
          {
            content: greeting,
            author: contactEmailAddress,
            inserted_at: new Date(),
            position: 1,
          },
        ]
        : [];
      return {
        threadId: null,
        // It's not outstand to have not yet answered a greeting
        ack: 1,
        memos,
        contactEmailAddress,
      };
    }
  } else {
    // async function load(handle: string): Promise<Data | { error: Failure }> {
    //   let contactEmailAddress = handle;

    //   if ("error" in authResponse && authResponse.error.code === "forbidden") {
    //     // There is no 404 as will always try sending
    //     let profileResponse = await API.fetchProfile(contactEmailAddress);
    //     if ("error" in profileResponse) {
    //       throw "todo error";
    //     }
    //     let myEmailAddress = "";
    //     let greeting = profileResponse.data && profileResponse.data.greeting;
    //     let memos = greeting
    //       ? [
    //           {
    //             content: greeting,
    //             author: contactEmailAddress,
    //             inserted_at: new Date(),
    //             position: 1,
    //           },
    //         ]
    //       : [];
    //     return {
    //       threadId: null,
    //       ack: 0,
    //       memos,
    //       contactEmailAddress,
    //       myEmailAddress,
    //     };
    //   } else if ("error" in authResponse) {
    //     throw "error fetching self";
    //   } else {
    //     const myEmailAddress = authResponse.data.email_address;
    //     if (myEmailAddress === contactEmailAddress) {
    //       page.redirect("/profile");
    //       // throw after redirect results in unhandled promise logged in sentry
    //       return {
    //         error: {
    //           code: "forbidden",
    //           detail: "Cannot view contact page for self",
    //         },
    //       };
    //     } else {
    //       let contactResponse = await API.fetchContact(contactEmailAddress);
    //
    //     }
    //   }
    // }
  }
}

// export async function findContactByEmail(state: Authenticated): Call<Contact> {
// }

export async function postMemo(threadId: number | null, memos: Memo[], blocks: Block[]): Call<null> {
  let response: { data: Contact } | { error: Failure };
  // safe as there is no thread 0
  if (threadId) {
    response = await API.postMemo(threadId, memos.length + 1, blocks).then(
      function (response) {
        if ("error" in response) {
          return response;
        } else {
          let { latest } = response.data;
          let data = {
            latest,
            ack: latest.position,
            identifier: {
              // TODO remove this dummy id, contacts have a different set of things i.e. you don't see there id
              id: 99999999,
              email_address: contactEmailAddress,
              greeting: null,
            },
          };
          return { data };
        }
      }
    );
  } else {
    // TODO define thread identifier profile types
    // {thread, identifier} | {emailaddress, maybeGreeting}
    response = await API.startRelationship(contactEmailAddress, blocks);
  }
}
