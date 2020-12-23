export async function get(path): Promise<unknown> {
  let options = {
    credentials: "include",
    headers: {
      accept: "application/json",
    },
  };
  return doFetch(path, options)
}

export async function post(path, params): Promise<unknown> {
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
    } else if (response.status === 403) {
      return {error: {status: 403}}
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
