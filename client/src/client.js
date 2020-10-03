import { OK, Fail } from "./result.js";

export async function authenticate(linkToken) {
  const response = await fetch("__API_ORIGIN__/authenticate", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ link_token: linkToken })
  });
  return response;
}

export async function fetchInbox() {
  const response = await fetch("__API_ORIGIN__/inbox", {
    credentials: "include"
  });
  return response;
}
export async function fetchConversation(id) {
  const response = await fetch("__API_ORIGIN__/c/" + id, {
    credentials: "include"
  });
  return response;
}
export async function addParticipant(id, emailAddress) {
  const path = "/c/" + id + "/participant"
  return await post(path, {email_address: emailAddress});
}

export async function writeMessage(id, content, conclusion) {
  const response = await fetch("__API_ORIGIN__/c/" + id + "/message", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ content, conclusion })
  });
  console.log(response);
  return {};
}
export async function readMessage(id, counter) {
  const response = await fetch("__API_ORIGIN__/c/" + id + "/read", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ counter })
  });
  return response;
}

export async function addPin(id, counter, content) {
  const path = "/c/" + id + "/pin"
  return await post(path, { counter, content });
}

export async function setNotification(id, notify) {
  const path = "/c/" + id + "/notify"
  return await post(path, { notify });
}

export async function requestEmailAuthentication(emailAddress) {
  return await post("/authenticate/email", {email_address: emailAddress});
}

export async function deletePin(conversationId, pinId) {
  return await post("/c/" + conversationId + "/delete_pin", {pin_id: pinId});
}

async function post(path, params) {
  let url = "__API_ORIGIN__" + path;
  let options = {
    method: "POST",
    credentials: "include",
    headers: {
      accept: "application/json",
      "content-type": "application/json"
    },
    body: JSON.stringify(params)
  };

  let r = await doFetch(url, options);
  return r.asyncFlatMap(async function(response) {
    let status = response.status;
    if (status === 200) {
      return await parseJSON(response)
      // 400 is an error client shouldn't see
    } else if (status === 422) {
      // TODO need to create a client error type with all the same fields
      let error = (await parseJSON(response)).unwrapOr({detail: "Bad response from server"})
      error.status = 422
      return Fail(error)
    } else {
      // TODO this should alert
      return Fail({ detail: "Bad response from server", meta: { url, status } });
    }
  });
}

async function doFetch(url, options) {
  let {method} = options
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
