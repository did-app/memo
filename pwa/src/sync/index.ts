import type { Call } from "./client"
import * as API from "./api"
import type { Identifier } from "./api"

export async function startSync(): Call<Identifier> {
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('/sw.js').then(function (registration) {
        // Registration was successful
        console.log('ServiceWorker registration successful with scope: ', registration.scope);
      }, function (err) {
        // registration failed :(
        console.log('ServiceWorker registration failed: ', err);
      });
    });
  }

  let installPrompt = new Promise(function (resolve, reject) {
    window.addEventListener('beforeinstallprompt', (e) => {
      console.log("installPrompt");
      resolve(e);
    });
  });

  const fragment = window.location.hash.substring(1);
  const params = new URLSearchParams(fragment);
  const code = params.get("code");
  let authenticationProcess: Call<{ data: Identifier }>;
  if (code !== null) {
    window.location.hash = "#";
    authenticationProcess = API.authenticateWithCode(code)
  } else {
    // if code should always fail even if user session exists because trying to change.
    authenticationProcess = API.authenticateWithSession()
  }

  const result = await authenticationProcess;
  if ('data' in result) {
    return result.data
  } else {
    return result
  }

}

export const authenticationProcess = startSync();