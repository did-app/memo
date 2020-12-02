import * as Client from "./client.js";

export default async function authenticate() {
  let fragment = window.location.hash.substring(1);
  let params = new URLSearchParams(fragment);
  let code = params.get("code");
  if (code) {
    let resp = await Client.authenticate(code);
    console.log(resp, "RSP");
    window.location.hash = "#";
    // Bring this back but store in localhost
    // return resp.map(function({ identifier }) {
    //   return {
    //     id: identifier.id,
    //     emailAddress: identifier.email_address,
    //     hasAccount: identifier.has_account
    //   };
    // });
  }

}
