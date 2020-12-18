// this could have a constructor that is passed at the app level
import * as Client from "../client.js";

console.log("sync")
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

export let installPrompt = new Promise(function(resolve, reject) {
  window.addEventListener('beforeinstallprompt', (e) => {
    console.log("installPrompt");
    resolve(e);
  });
});

async function loadState(resolve, reject) {
  let response = await Client.fetchInbox();
  response.match({ok: function ({conversations, identifier}) {
    identifier = {hasAccount: identifier.has_account, emailAddress: identifier.email_address}

    conversations = conversations.map(function (c) {
      let participants = c.participants.map(function (p) {
        return p.email_address
      }).join(", ")
      return Object.assign({}, c, {participants})
    })
    resolve({conversations, identifier})
  },
  fail: function (e) {
    if (e.code == "forbidden") {
      reject({reason: "unauthenticated"})
    } else {
      reject({reason: "unknown"})
    }
  }})
}

// TODO remove any
export let loading: any = undefined;
// this is essentially init
export function handleAuthCode() {
  let fragment = window.location.hash.substring(1);
  let params = new URLSearchParams(fragment);
  let code = params.get("code");
  loading = new Promise(function(resolve, reject) {
    if (code) {
      window.location.hash = "#";
      let resp = Client.authenticate(code);
      // TODO handle the response
      loadState(resolve, reject);
    } else {
      loadState(resolve, reject);
    }

  });
}

// Pull from state or lookup
export async function fetchContact(identifier){
  // TODO extract client code, if TS good enough dont use Result
  const url = "__API_ORIGIN__/relationship/" + identifier;
  const response = await fetch(url, {
    credentials: "include",
    headers: {accept: "application/json"}
  })
  console.log(response)
  if (response.status === 200) {
    let raw = await response.json();
    return {data: {threadId: raw.thread_id, emailAddress: identifier}}
  }
}
