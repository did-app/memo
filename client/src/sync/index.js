// this could have a constructor that is passed at the app level
import * as Client from "../client.js";

console.log("sync")

export const user = 5;

export let loading = undefined;
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
    }

    setTimeout(function () {
      reject({reason: "unauthenticated"})
    }, 1000);
  });
}
