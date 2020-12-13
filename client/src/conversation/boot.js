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


}
