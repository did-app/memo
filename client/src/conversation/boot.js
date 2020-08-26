import {fetchConversation, addParticipant, writeMessage} from "../client.js"
import {setTopic, renderParticipant, renderMessage} from "./view.js"
import {formValues} from "../utils.js"

export default async function () {
  const conversationId = parseInt(window.location.pathname.substr(3))
  const conversation = await fetchConversation(conversationId);
  setTopic(conversation.topic);

  conversation.participants.forEach(function (participant) {
    const {email_address: emailAddress} = participant
    const [name] = emailAddress.split("@")
    renderParticipant(name, emailAddress)
  });
  conversation.messages.forEach(function (message) {
    const {content} = message
    renderMessage({content})
  });

  document.addEventListener('submit', async function (event) {
    event.preventDefault()
    const action = event.target.dataset.action
    const form = formValues(event.target)
    console.log(form);
    if (action === "addParticipant") {
      let {emailAddress} = form

      let response = await addParticipant(conversationId, emailAddress)
      window.location.reload()
    } else if (action == "writeMessage") {
      let {content} = form

      let response = await writeMessage(conversationId, content)
      window.location.reload()
    }
  })
}
