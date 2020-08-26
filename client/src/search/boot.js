import Page from "./Page.svelte";
import * as Client from "../client.js";

export default async function() {
  const page = new Page({ target: document.body });
  let response = await Client.fetchInbox();
  if (response.status != 200) {
    window.location.pathname = "/sign_in"
  }
}
