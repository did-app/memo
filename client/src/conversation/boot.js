import Page from "./Page.svelte";
import * as Client from "../client.js";
import {formValues} from "../utils"

export default async function() {
  const conversationId = parseInt(window.location.pathname.substr(3));

  const page = new Page({ target: document.body });
  let data = await Client.fetchConversation(conversationId);
  let topic = data.topic;
  let resolved = data.resolved;
  let participants = data.participants.map(function({
    email_address: emailAddress
  }) {
    const [name] = emailAddress.split("@");
    return { name, emailAddress };
  });
  let messages = data.messages.map(function ({content}) {
    const [intro] = content.trim().split(/\r?\n/)
    const html = marked(content)
    const checked = true
    const date ="12 Aug"
    const author = "vov"
    return {checked, author, date, intro, html}
  })
  messages[messages.length - 1].checked = false
  console.log(messages);
  page.$set({topic, resolved, participants, messages})

  document.addEventListener('submit', async function (event) {
    event.preventDefault()

    const action = event.target.dataset.action

    const form = formValues(event.target)
    console.log(form);

    if (action === "addParticipant") {
      let {emailAddress} = form

      let response = await Client.addParticipant(conversationId, emailAddress)
      console.log(response);
      // window.location.reload()
    } else if (action == "writeMessage") {
      let {content, resolve} = form

      let response = await Client.writeMessage(conversationId, content, resolve)
      window.location.reload()
    }
  })
}
