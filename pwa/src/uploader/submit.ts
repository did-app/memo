import Submit from "./Submit.svelte";

var app = new Submit({
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
