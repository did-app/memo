function onLoad({ addEventListener }: Window): Promise<null> {
  return new Promise(function (resolve) {
    addEventListener('load', function () {
      resolve(null)
    })
  })
}

async function registerServiceWorker({ navigator }: Window): Promise<null> {
  if ('serviceWorker' in navigator) {
    await navigator.serviceWorker.register('/sw.js')
  }
  return null
}

export type InstallPrompt = () => Promise<{ outcome: "accepted" | "dismissed", platform: string }>
async function installPrompt({ addEventListener }: Window): Promise<InstallPrompt> {
  return new Promise(function (resolve) {
    // https://stackoverflow.com/questions/51503754/typescript-type-beforeinstallpromptevent
    addEventListener('beforeinstallprompt', (event: any) => {
      // "Failed to execute 'prompt' on 'BeforeInstallPromptEvent': Illegal invocation"
      // if prompt is not called on the event object, hence the wrapping function
      let prompt: InstallPrompt = function () {
        return event.prompt()
      };
      resolve(prompt);
    });
  });
}

export default async function startInstall(window: Window) {
  // load doesn't fire multiple times, need a smarter wait for load function
  // console.log("waiting to start install");
  // await onLoad(window);
  console.log("starting install");
  await registerServiceWorker(window);
  console.log("Service worker registered");
  return await installPrompt(window)
}
