import {fetchConversation} from "../client.js"
import {setTopic, renderParticipant} from "./view.js"

(async function () {
  const conversationId = parseInt(window.location.pathname.substr(3))
  const conversation = await fetchConversation(conversationId);
  setTopic(conversation.topic);


  conversation.participants.forEach(function (participant) {
    const {email_address: emailAddress} = participant
    const [name] = emailAddress.split("@")
    renderParticipant(name, emailAddress)
  });
})()
