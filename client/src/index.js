import { default as conversation } from './conversation/boot.js';
import { default as search } from './search/boot.js';

const boot = document.currentScript.dataset.boot;

if (boot === "conversation") {
  conversation()
} else if (boot === "search") {
  search()
} else {
  throw "Unknown page: " + boot
}
