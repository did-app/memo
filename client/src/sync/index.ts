import * as API from "./api"
import type {Call, Identifier} from "./api"

export function startSync(): Call<Identifier> {
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
      navigator.serviceWorker.register('/sw.js').then(function(registration) {
        // Registration was successful
        console.log('ServiceWorker registration successful with scope: ', registration.scope);
      }, function(err) {
        // registration failed :(
        console.log('ServiceWorker registration failed: ', err);
      });
    });
  }

  let installPrompt = new Promise(function(resolve, reject) {
    window.addEventListener('beforeinstallprompt', (e) => {
      console.log("installPrompt");
      resolve(e);
    });
  });

  const fragment = window.location.hash.substring(1);
  const params = new URLSearchParams(fragment);
  const code = params.get("code");
  let authenticationProcess;
  if (code !== null) {
    window.location.hash = "#";
    authenticationProcess = API.authenticateWithCode(code)
  } else {
    // if code should always fail even if user session exists because trying to change.
    authenticationProcess = API.authenticateWithSession()
  }

  return authenticationProcess
}

export const authenticationProcess = startSync();

async function loadState(resolve, reject) {
  // let response = await Client.fetchInbox();
  // response.match({ok: function ({conversations, identifier}) {
  //   identifier = {hasAccount: identifier.has_account, emailAddress: identifier.email_address}
  //
  //   conversations = conversations.map(function (c) {
  //     let participants = c.participants.map(function (p) {
  //       return p.email_address
  //     }).join(", ")
  //     return Object.assign({}, c, {participants})
  //   })
  //   resolve({conversations, identifier})
  // },
  // fail: function (e) {
  //   if (e.code == "forbidden") {
  //     reject({reason: "unauthenticated"})
  //   } else {
  //     reject({reason: "unknown"})
  //   }
  // }})
}

// TODO remove any
export let loading: any = undefined;
// this is essentially init
export function handleAuthCode() {
  // loading = new Promise(function(resolve, reject) {
  //   if (code) {
  //     let resp = Client.authenticate(code);
  //     // TODO handle the response
  //     loadState(resolve, reject);
  //   } else {
  //     loadState(resolve, reject);
  //   }
  //
  // });
}

// Pull from state or lookup

type block = {type: "paragraph"}
type note = {counter: number, author: string, blocks: block[]};


// // TODO this is to be part of fetch contact
// export async function fetchThread(threadId): Call<{notes: note[]}> {
//   const path = "/threads/" + threadId
//   const result = await get(path)
//   if ("data" in result) {
//     const notes = result.data.notes.map(function({counter, blocks, author}){
//       return {counter, blocks, author}
//     })
//     return {notes}
//   } else {
//     return result
//   }
// }
//
