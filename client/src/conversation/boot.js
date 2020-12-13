import DOMPurify from "dompurify";
import Page from "./Page.svelte";
import authenticate from "../authenticate.js"
import * as Client from "../client.js";
import { formValues } from "../dom";
import {extractQuestions} from '../content.js'

export default async function() {
  document.addEventListener("submit", async function(event) {
    event.preventDefault();

    const action = event.target.dataset.action;

    const form = formValues(event.target);

    if (action === "addParticipant") {
      let { emailAddress } = form;

      // Could be 204 for idempotent? although not quite idempotent
      // Could have a map with key as participant id which is merged and displated in participant order?
      if (participants.find(p => p.emailAddress === emailAddress)) {
        event.target.reset();
      } else {
        let response = await Client.addParticipant(
          conversationId,
          emailAddress
        );
        response.match({
          ok: function(_) {
            const [name] = emailAddress.split("@");
            const participant = { name, emailAddress };
            participants = participants.concat(participant);
            page.$set({ participants });
            event.target.reset();
          },
          fail: function({ status }) {
            if (status === 422) {
              page.$set({
                failure: "Unable to add participant because email is invalid"
              });
            } else {
              page.$set({ failure: "Failed to add participant" });
            }
          }
        });
      }
    } else if (action == "writeMessage") {
      let { content, resolve } = form;
      let buffer = ""
      for (const [key, value] of Object.entries(form)) {
        if (key.slice(0, 2) === "Q:" && value.trim().length) {
          buffer += `<answer data-question="${key.slice(2)}">

${value}
</answer>

`
        }
      }

      let response = await Client.writeMessage(
        conversationId,
        buffer + content,
        resolve
      );
      window.location.reload();
    } else if (action === "deletePin") {
      const pinId = parseInt(form.id);
      const response = await Client.deletePin(conversationId, pinId);
      response.match({
        ok: function(_) {
          pins = pins.filter(function(p) {
            return p.id != pinId;
          });
          page.$set({ pins });
        },
        fail: function(_) {
          page.$set({ failure: "Failed to delete pin" });
        }
      });
    } else if (action === "markAsDone") {
      const counter = messages.length
      const response = await Client.markAsDone(conversationId, counter);
      response.match({
        ok: function(_) {
          page.$set({ done: counter });
        },
        fail: function(_) {
          page.$set({ failure: "Failed to mark as done" });
        }
      });

    } else {
      throw "Unknown action " + action
    }
  });

  // Could also be fixed with a div overlay
  let delayClick;
  let selectionContent;
  let selectionMessageCounter;
  document.addEventListener("selectionchange", function(event) {
    const selection = window.getSelection();
    const range = selection.getRangeAt(0);
    if (!range || range.collapsed) {
      // Don't hide because gets messed with clicks
      // page.$set({left: null, bottom: null})
      return true;
    }

    const common = range.commonAncestorContainer;
    const isText = common.nodeName === "#text";
    const container = isText ? common.parentElement : common;
    const message = container.closest(".markdown-body");
    if (!message) {
      page.$set({ left: null, bottom: null });
      return true;
    }
    selectionContent = range.toString();
    selectionMessageCounter = message.closest("article").id;
    const {
      top: selTop,
      left: selLeft,
      width: selWidth
    } = range.getBoundingClientRect();
    const tipEl = document.querySelector(".texttip");
    const tipWidth = tipEl.offsetWidth;

    // Middle of selection width
    let newTipLeft = selLeft + selWidth / 2 - window.scrollX;

    // Right above selection
    let newTipBottom = window.innerHeight - selTop - window.scrollY;

    // Stop tooltip bleeding off of left or right edge of screen
    // Use a buffer of 20px so we don't bump right against the edge
    // The tooltip transforms itself left minus 50% of it's width in css
    // so this will need to be taken into account

    const buffer = 20;
    const tipHalfWidth = this.tipWidth / 2;
    // console.log(selection);
    // "real" means after taking the css transform into account
    const realTipLeft = newTipLeft - tipHalfWidth;
    const realTipRight = realTipLeft + this.tipWidth;

    if (realTipLeft < buffer) {
      // Correct for left edge overlap
      newTipLeft = buffer + tipHalfWidth;
    } else if (realTipRight > window.innerWidth - buffer) {
      // Correct for right edge overlap
      newTipLeft = window.innerWidth - buffer - tipHalfWidth;
    }

    delayClick = true;
    page.$set({ left: newTipLeft, bottom: newTipBottom });
  });

  document.addEventListener("click", async function(event) {
    let button = event.target.closest("[role=button]");
    if (button && selectionContent) {
      // perhaops only select within one paragraph for pins replies.
      const action = button.dataset.action;
      if (action === "quoteInReply") {
        const snippet = selectionContent.replace(/\r?\n/g, "\r\n> ");
        const $composeContent = document.querySelector("textarea[name='content']")
        const written = $composeContent.value.trimEnd()
        const prePadding = written ? "\r\n\r\n> " : "> "
        $composeContent.value = written + prePadding + snippet + "\r\n\r\n";
        $composeContent.focus()
      } else if (action === "pinSelection") {
        const content = selectionContent;
        const counter = parseInt(selectionMessageCounter);
        let response = await Client.addPin(conversationId, counter, content);
        response.match({
          ok: function({ id }) {
            const pin = { id, counter, content };
            pins = pins.concat(pin);
            page.$set({ pins });
          },
          fail: function(_) {
            page.$set({ failure: "Failed to pin content" });
          }
        });
      }
    }
    if (delayClick) {
      delayClick = false;
    } else {
      page.$set({ left: null, bottom: null });
    }
  });
}
