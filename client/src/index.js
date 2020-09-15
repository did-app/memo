import { default as conversation } from './conversation/boot.js';
import { default as search } from './search/boot.js';
import { default as signIn } from './sign_in/boot.js';

const boot = document.currentScript.dataset.boot;

if (boot === "conversation") {
  conversation()
} else if (boot === "search") {
  search()
} else if (boot === "sign_in") {
  signIn()
} else {
  throw "Unknown page: " + boot
}
