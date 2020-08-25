import {domify} from "../utils.js"
const $topic = document.getElementById('topic')

export function setTopic(topic) {
  $topic.innerText = topic
}

const $participants = document.getElementById("participants");

export function renderParticipant(name, emailAddress) {
  const html = `<li class="m-1 whitespace-no-wrap truncate">${name} <small>&lt;${emailAddress}&gt;</small></li>`
  $participants.append(domify(html));
}
