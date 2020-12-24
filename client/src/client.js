import { OK, Fail } from "./result.js";

export async function authenticate(linkToken) {
  return await post("/authenticate", { link_token: linkToken });
}

export async function fetchInbox() {
  return await get("/inbox")
}

export async function fetchConversation(id) {
  return await get("/c/" + id)
}

export async function addParticipant(id, emailAddress) {
  const path = "/c/" + id + "/participant"
  return await post(path, { email_address: emailAddress });
}

export async function writeMessage(id, content, conclusion) {
  const response = await fetch("__API_ORIGIN__/c/" + id + "/message", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ content, conclusion })
  });
  return {};
}
export async function readMessage(id, counter) {
  const path = "/c/" + id + "/read"
  return await post(path, { counter });
}

export async function markAsDone(id, counter) {
  const path = "/c/" + id + "/mark_done"
  return await post(path, { counter });
}

export async function addPin(id, counter, content) {
  const path = "/c/" + id + "/pin"
  return await post(path, { counter, content });
}

export async function setNotification(id, notify) {
  const path = "/c/" + id + "/notify"
  return await post(path, { notify });
}



export async function deletePin(conversationId, pinId) {
  return await post("/c/" + conversationId + "/delete_pin", { pin_id: pinId });
}

async function get(path) {
  let options = {
    credentials: "include",
    headers: {
      accept: "application/json",
    },
  };
  return myFetch(path, options)
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
  return myFetch(path, options)
}

async function myFetch(path, options) {
  let url = "__API_ORIGIN__" + path;
  let r = await doFetch(url, options);
  return r.asyncFlatMap(async function (response) {
    let status = response.status;
    if (status === 200) {
      return await parseJSON(response)
      // 400 is an error client shouldn't see
    } else if (status === 201) {
      return OK({})
    } else if (status === 422) {
      // TODO need to create a client error type with all the same fields
      let error = (await parseJSON(response)).unwrapOr({ detail: "Bad response from server" })
      error.status = 422
      return Fail(error)
    } else if (status === 403) {
      let error = (await parseJSON(response)).unwrapOr({ detail: "Forbidden reponse from server" })
      error.status = 403
      return Fail(error)
    } else {
      // TODO this should alert
      return Fail({ detail: "Bad response from server", meta: { url, status } });
    }
  });
}

async function doFetch(url, options) {
  let { method } = options
  console.log(`${method} ${url}`);
  try {
    const response = await fetch(url, options);
    return OK(response);
  } catch (e) {
    if (e instanceof TypeError) {
      return Fail({
        detail: "Failed to connect to server",
        meta: { url }
      });
    } else {
      throw e;
    }
  }
}

async function parseJSON(response) {
  try {
    const data = await response.json();
    return OK(data);
  } catch (e) {
    if (e instanceof SyntaxError) {
      return Fail({
        detail: e.message,
        meta: { url: response.url }
      });
    } else {
      throw e;
    }
  }
}
