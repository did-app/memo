import { writable } from "svelte/store"
import type { Writable } from "svelte/store"
import type { Block } from "../note/elements"
import type { Call, Failure } from "./client"
import * as API from "./api"
import type { Identifier } from "./api"

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

export type Contact = { identifier: Identifier, outstanding: boolean, latest: { inserted_at: string, content: Block[]; } | undefined }
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
(async function start() {
  let loading: Call<{ data: Identifier }>;
  if (code !== null) {
    window.location.hash = "#";
    loading = API.authenticateByCode(code)
  } else {
    // if code should always fail even if user session exists because trying to change.
    loading = API.authenticateBySession()
  }
  let authResponse = await loading
  console.log("starting", authResponse);

  if ("error" in authResponse && authResponse.error.code === "forbidden") {
    set({ loading: false, me: undefined, error: undefined })
  } else if ("error" in authResponse) {
    console.log("here");

    set({ loading: false, me: undefined, error: authResponse.error })

    // pop error in state
  } else {
    let me = authResponse.data
    let inboxResponse = await API.fetchContacts();
    if ("error" in inboxResponse) {
      throw "TODO error";
    }
    set({ loading: false, me, contacts: inboxResponse.data })
  }
}())
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
        threadId: undefined,
        ack: 0,
        notes: [],
        contactEmailAddress,
      };
    }
    if (thread) {
      let threadId = thread.id;
      let notes = thread.notes.map(function ({
        inserted_at: iso8601,
        ...rest
      }) {
        let inserted_at = new Date(iso8601);
        return { inserted_at, ...rest };
      });
      return {
        threadId,
        ack: thread.ack,
        notes: notes,
        contactEmailAddress,
      };
    } else {
      let greeting = identifier.greeting;

      let notes = greeting
        ? [
          {
            blocks: greeting,
            author: contactEmailAddress,
            inserted_at: new Date(),
            counter: 1,
          },
        ]
        : [];
      return {
        threadId: undefined,
        // It's not outstand to have not yet answered a greeting
        ack: 1,
        notes,
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
    //     let notes = greeting
    //       ? [
    //           {
    //             blocks: greeting,
    //             author: contactEmailAddress,
    //             inserted_at: new Date(),
    //             // TODO make counter index
    //             counter: 1,
    //           },
    //         ]
    //       : [];
    //     return {
    //       threadId: undefined,
    //       ack: 0,
    //       notes,
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

