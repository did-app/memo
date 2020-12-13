import DOMPurify from "dompurify";
import Page from "./Page.svelte";
import authenticate from "../authenticate.js"
import * as Client from "../client.js";

export default async function() {
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
  });


}
