import Page from "./Page.svelte";
import * as Client from "../client.js";
import {formValues} from "../utils"

export default async function() {
  const conversationId = parseInt(window.location.pathname.substr(3));

  const page = new Page({ target: document.body });
  let {conversation, participation, messages, pins} = await Client.fetchConversation(conversationId);
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
  console.log(messages);
  messages = messages.map(function ({content, author, inserted_at}) {
    const [intro] = content.trim().split(/\r?\n/)
    const html = marked(content)
    const checked = true
    return {checked, author, date: inserted_at, intro, html}
  })
  if (messages[messages.length - 1]) {
    messages[messages.length - 1].checked = false
  }
  console.log(messages);
  page.$set({nickname, displayName, topic, notify, resolved, participants, messages, pins})

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

  document.addEventListener('change', async function (event) {
    if (event.target.name === 'notify') {
      let notify = event.target.value;
      await Client.setNotification(conversationId, notify)
      window.location.reload()
    }
  })

  // Could also be fixed with a div overlay
  let delayClick;
  let selectionContent;
  document.addEventListener('selectionchange', function (event) {
    const selection = window.getSelection();
    const range = selection.getRangeAt(0);
    if (!range || range.collapsed){
      // Don't hide because gets messed with clicks
      // page.$set({left: null, bottom: null})
      return true
    }

    const common = range.commonAncestorContainer;
    const isText = common.nodeName === "#text";
    const container = isText ? common.parentElement : common;
    const message = container.closest(".markdown-body")
    if (!message) {
      page.$set({left: null, bottom: null})
      return true
    }
    selectionContent = range.toString()
    const { top: selTop, left: selLeft, width: selWidth } = range.getBoundingClientRect();
    const tipEl = document.querySelector(".texttip")
    const tipWidth = tipEl.offsetWidth;



    // Middle of selection width
    let newTipLeft = selLeft + (selWidth / 2) - window.scrollX;

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
    page.$set({left: newTipLeft, bottom: newTipBottom})
  })

  document.addEventListener('click', async function (event) {
    let button = event.target.closest("[role=button]")
    if (button && selectionContent) {
      // perhaops only select within one paragraph for pins replies.
      const action = button.dataset.action
      if (action === "quoteInReply") {
        const snippet = "\r\n> " + selectionContent.replace(/\r?\n/g, "\r\n> ");
        document.querySelector('textarea').value += snippet
      } else if (action === "pinSelection") {
        page.$set({pins: pins.concat(selectionContent)})
        let response = await Client.addPin(conversationId, selectionContent)
        window.location.reload()
      }
    }
    if (delayClick) {
      delayClick = false;
    } else {
      page.$set({left: null, bottom: null})
    }
  })
}
