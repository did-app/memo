import { default as conversation } from "./conversation/boot.js";
import { default as search } from "./search/boot.js";
import { default as signIn } from "./sign_in/boot.js";

import Begin from "./Begin.svelte";
import Home from "./Home.svelte";

function handleLinkClick(event) {
  const el = event.target.closest("a");
  const href = el && el.getAttribute("href");

  if (
    event.ctrlKey ||
    event.metaKey ||
    event.altKey ||
    event.shiftKey ||
    event.button ||
    event.defaultPrevented
  )
    return;
  if (!href || el.target || el.host !== location.host) return;

  event.preventDefault();
  history.pushState({}, "", href);
  route(window.location.pathname)
}

window.addEventListener("click", handleLinkClick);

function begin() {
  const navLinks = [
    {
      url: "/",
      display: "Back to search"
    }
  ];

  const target = document.body;
  const props = { navLinks, inner: Begin };
  new Home({ target, props });
}

function route(path) {
  if (path === "/") {
    // searching
    // search();
  } else if (path === "/begin") {
    begin();
    // conversation()
    // } else if (boot === "sign_in") {
    //   signIn()
    // } else if (boot === "begin") {
    // load initial route
    // No problem in loading if local slash js only that is cached
    // rich urls and caching
    window.addEventListener("pushstate", function(e) {
      console.log("--");
    });
    window.onpushstate = function(event) {
      console.log(event);
      event.preventDefault();
    };
    // throw out state on redirect
    if (path == "/begin") {
    } else {
      throw "beginning";
    }

    // console.log(Begin.render());
    // setTimeout(function () {
    //   const page = new Begin({ target: document.body, hydrate: true });
    // }, 2000);
  } else {
    throw "Unknown page: " + path;
  }
}

route(window.location.pathname)
