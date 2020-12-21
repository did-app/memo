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
    return {data: {
      threadId: raw.thread_id,
      emailAddress: identifier,
      introduction: raw.introduction,
      contactId: raw.contact_id
    }}
  }
}
type block = {type: "paragraph"}
type note = {counter: number, author: string, blocks: block[]};
type Call<T> = Promise<T | {error: {detail: string}}>
const Call = Promise
// https://github.com/microsoft/TypeScript/issues/32574

// TODO this is to be part of fetch contact
export async function fetchThread(threadId): Call<{notes: note[]}> {
  const path = "/threads/" + threadId
  const result = await get(path)
  if ("data" in result) {
    const notes = result.data.notes.map(function({counter, blocks, author}){
      return {counter, blocks, author}
    })
    return {notes}
  } else {
    return result
  }
}

export async function writeNote(threadId, counter, blocks) {
  const path = "/threads/" + threadId + "/write"
  const params = {counter, blocks}
  return post(path, params)
}

async function get(path) {
  let options = {
    credentials: "include",
    headers: {
      accept: "application/json",
    },
  };
  return doFetch(path, options)
}

async function post(path, params) {
  let options = {
    method: "POST",
    credentials: "include",
    headers: {
      accept: "application/json",
      "content-type": "application/json"
    },
    body: JSON.stringify(params)
  };
  return doFetch(path, options)
}

async function doFetch(path, options) {
  const url = "__API_ORIGIN__" + path;
  let {method} = options
  console.log(`${method} ${url}`);
  try {
    const response = await fetch(url, options);
    if (response.status === 200) {
      return parseJSON(response)
    } else {
      throw "handle other responses" + response.status
    }
  } catch (e) {
    if (e instanceof TypeError) {
      const error = {detail: "Network Failure"}
      return {error}
    } else {
      throw e;
    }
  }
}

async function parseJSON(response) {
  try {
    const data = await response.json();
    return {data};
  } catch (e) {
    if (e instanceof SyntaxError) {
      const error = {detail: "JSON SyntaxError"}
      return {error}
    } else {
      throw e;
    }
  }
}
