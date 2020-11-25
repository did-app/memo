import { default as conversation } from "./conversation/boot.js";
import Inbox from "./Inbox.svelte";
import Introduction from "./Introduction.svelte";

// pane, panel, console, controls

function route(path) {
  if (path === "/") {
    const target = document.body;
    new Inbox({ target });
  } else if (path.substring(0, 3) === "/c/") {
    conversation()
  } else if (path === "/peter") {
    const target = document.body;
    new Introduction({ target, props: {label: "peter"} });
  } else if (path === "/richard") {
    const target = document.body;
    new Introduction({ target, props: {label: "richard"} });
  } else if (path === "/team") {
    const target = document.body;
    new Introduction({ target, props: {label: "team"} });
  } else {
    throw "Unknown page: " + path;
  }
}

route(window.location.pathname)
