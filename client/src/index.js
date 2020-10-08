import { default as conversation } from "./conversation/boot.js";

import Inbox from "./Inbox.svelte";
import Loading from "./Loading.svelte";
import Search from "./Search.svelte";
import Begin from "./Begin.svelte";

// function handleLinkClick(event) {
//   const el = event.target.closest("a");
//   const href = el && el.getAttribute("href");
//
//   if (
//     event.ctrlKey ||
//     event.metaKey ||
//     event.altKey ||
//     event.shiftKey ||
//     event.button ||
//     event.defaultPrevented
//   )
//     return;
//   if (!href || el.target || el.host !== location.host) return;
//
//   event.preventDefault();
//   history.pushState({}, "", href);
//   route(window.location.pathname)
// }

// window.addEventListener("click", handleLinkClick);

// function begin() {
//   const navLinks = [
//     backToSearchLink()
//   ];
//
//   const target = document.body;
//   const props = { navLinks, inner: Begin };
//   new Inbox({ target, props });
// }

// TODO think about this being async
// pane, panel, console, controls

function route(path) {
  if (path === "/") {

    const target = document.body;
    new Inbox({ target });

    // const authenticated = await authenticate()
    // authenticated.match({
    //   ok: function({identifier}) {
    //     console.log(identifier);
    //   },
    //   fail: function(e) {
    //     document.body.innerHTML = ""
    //     signIn()
    //   }
    // });
  } else if (path === "/begin") {
    begin();
  } else if (path === "/archive") {
    const navLinks = [
      backToSearchLink,
      signOutLink
    ];
    //   signIn()
    // } else if (boot === "begin") {
    // load initial route
    // No problem in loading if local slash js only that is cached
    // rich urls and caching
    // window.onpushstate = function(event) {
    //   console.log(event);
    //   event.preventDefault();
    // };
    // throw out state on redirect

    // console.log(Begin.render());
    // setTimeout(function () {
    //   const page = new Begin({ target: document.body, hydrate: true });
    // }, 2000);
  } else {
    throw "Unknown page: " + path;
  }
}

route(window.location.pathname)
