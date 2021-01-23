export type Failure = {
  code: "forbidden" | "network failure" | "bad response",
  detail: string
}

export type Response<T> = { data: T, } | { error: Failure }
export type Call<T> = Promise<Response<T>>
const Call = Promise
// https://github.com/microsoft/TypeScript/issues/32574

export async function get(path: string): Call<any> {
  let options = {
    credentials: "include",
    headers: {
      accept: "application/json",
    },
  };
  return doFetch(path, options)
}

export async function post(path: string, params: object): Call<any> {
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

// use any because not a public function
async function doFetch(path: string, options: any): Call<any> {
  let meta = import.meta as any
  const url = meta.env.SNOWPACK_PUBLIC_API_ORIGIN + path;
  try {
    const response = await fetch(url, options);
    if (response.status === 200) {
      return parseJSON(response)
    } else if (response.status === 204) {
      return { data: null }
    } else if (response.status === 403) {
      return { error: { code: "forbidden", detail: "Action was forbidden" } }
    } else {
      throw "handle other responses" + response.status
    }
  } catch (e) {
    if (e instanceof TypeError) {
      return { error: { code: "network failure", detail: "Network Failure" } }
    } else {
      throw e;
    }
  }
}

async function parseJSON(response: globalThis.Response): Call<{ data: any }> {
  try {
    const data = await response.json();
    return { data };
  } catch (e) {
    if (e instanceof SyntaxError) {
      return { error: { code: "bad response", detail: "Invalid JSON response" } }
    } else {
      throw e;
    }
  }
}
