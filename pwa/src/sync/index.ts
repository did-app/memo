export type { Inbox, State } from "./state"
import type { Memo } from "../conversation"
import type { Inbox, State } from "./state"
export { initial, startTask, resolveTask } from "./state"
export { startInstall } from "./install"

function sleep(milliseconds: number) {
  return new Promise(function (resolve) {
    setTimeout(() => {
      resolve(true)
    }, milliseconds);
  })
}

// There is a process without the Flask/Task messaging that happens
export async function authenticateBySession() {
  // update((s) => return addTask(s, ))
  await sleep(200)
  let inboxes: Inbox[] = [
    {
      identifier: {
        id: 1,
        emailAddress: "peter@sendmemo.app",
        greeting: null,
      },
      conversations: [
        {
          contact: {
            id: 2,
            emailAddress: "richard@plummail.co",
            greeting: null,
          },
          participation: {
            threadId: 1,
            acknowledged: 1,
            latest: {
              position: 2,
              author: "TODO",
              content: [],
              postedAt: new Date()
            },
          },
        },
        {
          contact: {
            id: 2,
            emailAddress: "team@superservice.co",
            greeting: null,
          },
          participation: {
            threadId: 1,
            acknowledged: 2,
            latest: {
              position: 2,
              author: "TODO",
              content: [],
              postedAt: new Date()
            },
          },
        },
        {
          contact: {
            id: 32,
            name: "Ski Buddies"
          },
          participation: {
            threadId: 1,
            acknowledged: 1,
            latest: {
              position: 2,
              author: "TODO",
              content: [],
              postedAt: new Date()
            },
          },
        },
      ],
    },
    {
      identifier: {
        id: 3,
        emailAddress: "team@sendmemo.app",
        greeting: null,
      },
      conversations: [
        {
          contact: {
            id: 2,
            emailAddress: "richard@plummail.co",
            greeting: null,
          },
          participation: {
            threadId: 1,
            acknowledged: 1,
            latest: {
              position: 2,
              author: "TODO",
              content: [],
              postedAt: new Date()
            },
          },
        },
      ],
    },
  ];
  return inboxes
}

export async function fetchMemos(): Promise<Memo[]> {
  await sleep(1000)
  return [
    {
      author: "Jimmy",
      postedAt: new Date,
      position: 1,
      content: [{ type: 'paragraph', spans: [{ type: 'text', text: "Hello" }] }]
    },
    {
      author: "Bobby",
      postedAt: new Date,
      position: 2,
      content: [{ type: 'paragraph', spans: [{ type: 'text', text: "And back" }] }]
    }

  ]
}

// import type { Memo, Thread } from "../conversation"
// import type { Block } from "../writing"
// import type { Call, Failure } from "./client"
// import * as API from "./api"
// import type { Contact, Relationship, Identifier } from "../social"

// import type { InstallPrompt } from "./install"
// import startInstall from "./install"

// export type { Response, Call } from "./client"


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
export async function authenticate(): Promise<Inbox[]> {
  const code = popAuthenticationCode()
  if (code) {
    return await API.authenticateByCode(code)
  } else {
    return await authenticateBySession()
  }
}

// start().then(set).then(function () {
//   startInstall(window).then(function (installPrompt) {
//     update(function ({ flash, ...unchanged }) {
//       async function prompt() {
//         let result = await installPrompt()
//         console.log(result);
//         update(function ({ flash, ...unchanged }) {
//           flash = flash.filter(function (each) {
//             return each.type !== 'install_available'
//           })
//           return { flash, ...unchanged }
//         })
//         return result
//       }

//       flash = [{ type: "install_available", prompt }, ...flash]
//       return { flash, ...unchanged }
//     })
//   })
// })
// // Needs single function to handle auth response and fetch contacts
// // fetch contacts is separate so it can be updated periodically


// export async function authenticateByPassword(emailAddress: string, password: string) {
//   let authResponse = await API.authenticateByPassword(emailAddress, password);
//   if ("error" in authResponse) {
//     return authResponse.error
//   }
//   let me = authResponse.data.identifier
//   let inboxResponse = await API.fetchContacts(me.id);
//   if ("error" in inboxResponse) {
//     throw "some error we aint fixed yet";
//   }
//   let sharedInboxes = authResponse.data.shared
//   let shared = sharedInboxes.map(function (identifier) {
//     // TODO fetch contacts
//     const contacts: Contact[] = [];
//     return { identifier, contacts }
//   })
//   set({ loading: false, flash: [], tasks: [], me, contacts: inboxResponse.data, shared, error: undefined })
//   return authResponse
// }

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