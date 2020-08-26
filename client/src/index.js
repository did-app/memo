import { default as conversation } from './conversation/boot.js';

const boot = document.currentScript.dataset.boot;
if (boot === "conversation") {
  conversation()
} else {
  throw "Unknown page"
}
