import Page from "./Page.svelte";
import * as Client from "../client.js";
import {formValues} from "../utils"

export default async function() {
  const conversationId = parseInt(window.location.pathname.substr(3));

  const page = new Page({ target: document.body });
  let {conversation, participation} = await Client.fetchConversation(conversationId);
  console.log(participation);
  let nickname = participation["nickname"];
  let emailAddress = participation["email_address"];
  let displayName = nickname || emailAddress.split("@")[0];
  let topic = conversation.topic;
  let resolved = conversation.resolved;
  let notify = participation.notify;
  let participants = conversation.participants.map(function({
    email_address: emailAddress
  }) {
    const [name] = emailAddress.split("@");
    return { name, emailAddress };
  });
  let messages = conversation.messages.map(function ({content}) {
    const [intro] = content.trim().split(/\r?\n/)
    const html = marked(content)
    const checked = true
    const date ="12 Aug"
    const author = "vov"
    return {checked, author, date, intro, html}
  })
  if (messages[messages.length - 1]) {
    messages[messages.length - 1].checked = false
  }
  console.log(messages);
  page.$set({nickname, displayName, topic, notify, resolved, participants, messages})

  document.addEventListener('submit', async function (event) {
    event.preventDefault()

    const action = event.target.dataset.action

    const form = formValues(event.target)
    console.log(form);

    if (action === "addParticipant") {
      let {emailAddress} = form

      let response = await Client.addParticipant(conversationId, emailAddress)
      window.location.reload()
    } else if (action == "writeMessage") {
      let {content, from, resolve} = form
      from = from === "" ? null : from

      let response = await Client.writeMessage(conversationId, content, from, resolve)
      window.location.reload()
    }
  })
}
