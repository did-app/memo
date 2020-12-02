import * as Client from "./client.js";

export default async function authenticate() {
  let fragment = window.location.hash.substring(1);
  let params = new URLSearchParams(fragment);
  let code = params.get("code");
  if (code) {
    let resp = await Client.authenticate(code);
    window.location.hash = "#";
  }
}
