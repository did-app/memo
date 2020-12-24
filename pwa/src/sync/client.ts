export type Failure = {
  code: "forbidden" | "network failure" | "bad response",
  detail: string
}
export type Call<T> = Promise<T | { error: Failure }>
const Call = Promise
// https://github.com/microsoft/TypeScript/issues/32574
export type Response<T> = T | Failure

export async function get(path: string): Call<{ data: any }> {
  let options = {
    credentials: "include",
    headers: {
      accept: "application/json",
    },
  };
  return doFetch(path, options)
}

export async function post(path: string, params: any): Call<{ data: any }> {
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
async function doFetch(path: string, options: any): Call<{ data: any }> {
  const url = import.meta.env.SNOWPACK_PUBLIC_API_ORIGIN + path;
  try {
    const response = await fetch(url, options);
    if (response.status === 200) {
      return parseJSON(response)
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

async function parseJSON(response: Response<any>): Call<{ data: any }> {
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
