import * as Sentry from "@sentry/browser";
import { Integrations } from "@sentry/tracing";

const environment = (window.location.hostname === "localhost") ? "local" : "production"
Sentry.init({
  dsn: 'https://e3b301fb356a4e61bebf8edb110af5b3@o351506.ingest.sentry.io/5574979',
  integrations: [
    new Integrations.BrowserTracing(),
  ],
  environment,
  tracesSampleRate: 1.0,
});
import App from "./App.svelte";


var app = new App({
  target: document.body,
  props: { gapi: (window as any).gapi }
});

export default app;

// Hot Module Replacement (HMR) - Remove this snippet to remove HMR.
// Learn more: https://www.snowpack.dev/concepts/hot-module-replacement
if ('hot' in import.meta) {
  let meta = import.meta as any
  if (meta.hot) {
    meta.hot.accept();
    meta.hot.dispose(() => {
      app.$destroy();
    });
  }
}
