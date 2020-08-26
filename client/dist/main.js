(function (factory) {
  typeof define === 'function' && define.amd ? define(factory) :
  factory();
}((function () { 'use strict';

  const API_ROOT = "http://localhost:8000";

  async function fetchConversation(id) {
    const response = await fetch(API_ROOT + "/c/" + id, {});
    return (await response.json()).conversation
  }
  async function addParticipant(id, emailAddress) {
    const response = await fetch(API_ROOT + "/c/" + id + "/participant", {
      method: "POST",
      body: JSON.stringify({email_address: emailAddress})
    });
    console.log(response);
    return ({})
  }
  async function writeMessage(id, content) {
    const response = await fetch(API_ROOT + "/c/" + id + "/message", {
      method: "POST",
      body: JSON.stringify({content: content})
    });
    console.log(response);
    return ({})
  }

  // TODO this is not safe
  function domify(string) {
    var htmlObject = document.createElement("div");
    htmlObject.innerHTML = string;
    return htmlObject.children[0];
  }

  function formValues($form) {
    // https://codepen.io/ntpumartin/pen/MWYmypq
    var obj = {};
    var elements = $form.querySelectorAll("input, select, textarea");
    for (var i = 0; i < elements.length; ++i) {
      var element = elements[i];
      var name = element.name;
      var value = element.value;
      var type = element.type;

      if (type === "checkbox") {
        obj[name] = element.checked;
      } else {
        if (name) {
          obj[name] = value;
        }

      }

    }
    return obj;
  }

  const $topic = document.getElementById('topic');

  function setTopic(topic) {
    $topic.innerText = topic;
  }

  const $participants = document.getElementById("participants");

  function renderParticipant(name, emailAddress) {
    const html = `<li class="m-1 whitespace-no-wrap truncate">${name} <small>&lt;${emailAddress}&gt;</small></li>`;
    $participants.append(domify(html));
  }

  const $messages = document.getElementById("messages");
  var messageIndex = 0;

  function renderMessage({ author, date, checked, content }) {
    messageIndex += 1;

    checked = checked ? "checked" : "";
    const [intro] = content.trim().split(/\r?\n/);
    const html = marked(content);
    var message = `
  <article class="relative rounded-2xl my-shadow bg-white">
    <input id="message-${messageIndex}" class="message-checkbox hidden" type="checkbox" ${checked}>
    <label for="message-${messageIndex}">
      <header class="pt-4 pb-4 flex">
        <span class="font-bold ml-20">${author}</span>
        <span class="ml-auto mr-8">${date}</span>
      </header>
      <div class="message-overlay absolute bottom-0 top-0 right-0 left-0 ">
      </div>
    </label>
    <div class="content-intro px-20 truncate">${intro}</div>
    <div class="markdown-body px-20">${html}</div>
    <footer class="h-12 mb-2 mt-4">

    </footer>
  </article>
  `;
    $messages.append(domify(message));
  }

  async function conversation () {
    const conversationId = parseInt(window.location.pathname.substr(3));
    const conversation = await fetchConversation(conversationId);
    setTopic(conversation.topic);

    conversation.participants.forEach(function (participant) {
      const {email_address: emailAddress} = participant;
      const [name] = emailAddress.split("@");
      renderParticipant(name, emailAddress);
    });
    conversation.messages.forEach(function (message) {
      const {content} = message;
      renderMessage({content});
    });

    document.addEventListener('submit', async function (event) {
      event.preventDefault();
      const action = event.target.dataset.action;
      const form = formValues(event.target);
      console.log(form);
      if (action === "addParticipant") {
        let {emailAddress} = form;

        let response = await addParticipant(conversationId, emailAddress);
        window.location.reload();
      } else if (action == "writeMessage") {
        let {content} = form;

        let response = await writeMessage(conversationId, content);
        window.location.reload();
      }
    });
  }

  const boot = document.currentScript.dataset.boot;
  if (boot === "conversation") {
    conversation();
  } else {
    throw "Unknown page"
  }

})));
