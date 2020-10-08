import * as Client from "./client.js";

export default async function authenticate() {
  let fragment = window.location.hash.substring(1);
  let params = new URLSearchParams(fragment);
  let code = params.get("code");
  let resp = await Client.authenticate(code);
  if (code) {
    window.location.hash = "#";
  }

  // let self;
  // resp.match({
  //   ok: function({identifier}) {
  //     self = {id: identifier.id, emailAddress: identifier.email_address}
  //   },
  //   fail: function(e) {
  //     window.location.pathname = "/sign_in";
  //   }
  // });
  //
  // return self
  return resp.map(function ({identifier}) {
    return {id: identifier.id, emailAddress: identifier.email_address}
  })
}
