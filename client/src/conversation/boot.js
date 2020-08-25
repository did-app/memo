import {fetchConversation, addParticipant} from "../client.js"
import {setTopic, renderParticipant} from "./view.js"
import {formValues} from "../utils.js"

(async function () {
  const conversationId = parseInt(window.location.pathname.substr(3))
  const conversation = await fetchConversation(conversationId);
  setTopic(conversation.topic);

  conversation.participants.forEach(function (participant) {
    const {email_address: emailAddress} = participant
    const [name] = emailAddress.split("@")
    renderParticipant(name, emailAddress)
  });

  document.addEventListener('submit', async function (event) {
    event.preventDefault()
    const action = event.target.dataset.action
    console.log(action);
    if (action === "addParticipant") {
      let form = formValues(event.target)
      console.log(form);
      let {emailAddress} = form

      let response = await addParticipant(conversationId, emailAddress)
      window.location.reload()
    }
  })
})()
