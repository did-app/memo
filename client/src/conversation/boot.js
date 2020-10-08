import DOMPurify from "dompurify";
import Page from "./Page.svelte";
import authenticate from "../authenticate.js"
import * as Client from "../client.js";
import { formValues } from "../dom";

export default async function() {
  const conversationId = parseInt(window.location.pathname.substr(3));

  const page = new Page({ target: document.body });

  let identifier
  let authenticationRequired
  (await authenticate()).match({
    ok: function(i) {
      identifier = i
    },
    fail: function(e) {
      authenticationRequired = true;
    }
  })
  if (!identifier) {
    page.$set({authenticationRequired})
    return
  }
  // const identifier = await authenticate()

  let response = await Client.fetchConversation(conversationId);
  let {
    conversation,
    participation,
    messages,
    pins,
    participants
  } = response.match({ok: function (x) {
    return x
  }, fail: function (_) {
    throw "Could not find conversation";
  }});

  let emailAddress = participation["email_address"];
  let displayName = emailAddress.split("@")[0];
  let cursor = participation["cursor"];
  let topic = conversation.topic;
  let closed = conversation.closed;
  let notify = participation.notify;

  participants = participants.map(function({ email_address: emailAddress }) {
    const [name] = emailAddress.split("@");
    return { name, emailAddress };
  });

  var highest;

  let asked = []
  // If we follow the numerical id's all the way, just do it might be problems
  messages = messages.map(function({ counter, content, author, inserted_at }) {
    // marked doesn't like an html bumping up against markdown content
    content = content.replaceAll("</answer>", "\r\n</answer>\r\n")
    const html = marked(content)

    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");
    const firstElement = doc.body.children[0]
    // It's possible there are empty messges
    const intro = firstElement ? DOMPurify.sanitize(firstElement.innerHTML) : "";

    let $questionLinks = doc.querySelectorAll('a[href="#?"]')

    $questionLinks.forEach(function ($link) {
      const query = $link.innerHTML

      // Work off the questions array length
      const $details = document.createElement('details')
      $details.id = "Q:" + asked.length

      const $summary = document.createElement('summary')
      $summary.innerHTML = query

      const $answerTray = document.createElement('div')

      const $answerFallback = document.createElement('div')
      $answerFallback.classList.add('fallback')
      $answerFallback.innerHTML = "There are no answers to this question yet"
      $answerFallback.classList.add('border-l-4', 'border-gray-400', "px-2", "pt-1", "mb-2")

      $answerTray.append($answerFallback)
      $details.append($summary)
      $details.append($answerTray)

      $link.parentElement.replaceChild($details, $link)

      const awaiting = author != identifier.emailAddress
      asked = asked.concat({query, awaiting, $answerTray, id: asked.length})
    })

    let $answerElements = doc.querySelectorAll('answer')
    $answerElements.forEach(function ($answer) {
      let qid = parseInt($answer.dataset.question)
      let question = asked[qid]

      const $answerDropdownContainer = document.createElement('div')

      const $answerAuthor = document.createElement('div')
      $answerAuthor.innerHTML = `<a href="#${counter}" style="color:#434190">${author}</a>`
      $answerAuthor.classList.add('border-l-4', 'border-indigo-800', "px-2", "mt-2")
      $answerDropdownContainer.append($answerAuthor)

      const $answerContent = document.createElement('div')
      $answerContent.innerHTML = $answer.innerHTML
      $answerContent.classList.add('border-l-4', 'border-gray-400', "px-2", "pt-1", "mb-2")
      $answerDropdownContainer.append($answerContent)

      question.$answerTray.append($answerDropdownContainer)

      const $replyLink = document.createElement("a")
      $replyLink.href = "#Q:" + qid
      $replyLink.innerHTML = question.query

      const $quoteQuestion = document.createElement("blockquote")
      $quoteQuestion.append($replyLink)

      const $replyContent = document.createElement("div")
      $replyContent.classList.add("pl-4")
      $replyContent.innerHTML = $answer.innerHTML

      const $answerContainer = document.createElement("div")
      $answerContainer.append($quoteQuestion)
      $answerContainer.append($replyContent)
      $answerContainer.append(document.createElement("hr"))

      $answer.parentElement.replaceChild($answerContainer, $answer)

      const mine = author == identifier.emailAddress
      if (mine) {
        question.awaiting = false
      }
    })

    // checked = closed
    const checked = !(cursor < counter);
    highest = counter;
    return { counter, checked, author, date: inserted_at, intro, doc };
  }).map(function ({ counter, checked, author, date, intro, doc }) {
    const html = DOMPurify.sanitize(doc.body.innerHTML)
    return { counter, checked, author, date, intro, html }
  });

  const questions = asked.filter(function ({awaiting}) {
    return awaiting
  })

  // Always leave the last open
  if (messages[messages.length - 1]) {
    messages[messages.length - 1].checked = false;
  }
  document.title = topic;
  page.$set({
    conversationId,
    emailAddress,
    displayName,
    topic,
    notify,
    closed,
    participants,
    messages,
    pins,
    questions
  });

  requestAnimationFrame(function() {
    let id = window.location.hash.substr(1);
    let el = document.getElementById(id);
    if (el) {
      el.scrollIntoView();
    }
  });

  Client.readMessage(conversationId, highest);

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
    } else if (action === "deletePin") {
      const pinId = parseInt(form.id);
      const response = await Client.deletePin(conversationId, pinId);
      response.match({
        ok: function(_) {
          pins = pins.filter(function(p) {
            return p.id != pinId;
          });
          page.$set({ pins });
        },
        fail: function(_) {
          page.$set({ failure: "Failed to delete pin" });
        }
      });
    }
  });

  document.addEventListener("change", async function(event) {
    if (event.target.name === "notify") {
      let notify = event.target.value;
      const response = await Client.setNotification(conversationId, notify);
      response.match({
        ok: function(_) {
          undefined;
        },
        fail: function(_) {
          page.$set({ failure: "Failed to save notification preferences" });
        }
      });
    }
  });

  // Could also be fixed with a div overlay
  let delayClick;
  let selectionContent;
  let selectionMessageCounter;
  document.addEventListener("selectionchange", function(event) {
    const selection = window.getSelection();
    const range = selection.getRangeAt(0);
    if (!range || range.collapsed) {
      // Don't hide because gets messed with clicks
      // page.$set({left: null, bottom: null})
      return true;
    }

    const common = range.commonAncestorContainer;
    const isText = common.nodeName === "#text";
    const container = isText ? common.parentElement : common;
    const message = container.closest(".markdown-body");
    if (!message) {
      page.$set({ left: null, bottom: null });
      return true;
    }
    selectionContent = range.toString();
    selectionMessageCounter = message.closest("article").id;
    const {
      top: selTop,
      left: selLeft,
      width: selWidth
    } = range.getBoundingClientRect();
    const tipEl = document.querySelector(".texttip");
    const tipWidth = tipEl.offsetWidth;

    // Middle of selection width
    let newTipLeft = selLeft + selWidth / 2 - window.scrollX;

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
    page.$set({ left: newTipLeft, bottom: newTipBottom });
  });

  document.addEventListener("click", async function(event) {
    let button = event.target.closest("[role=button]");
    if (button && selectionContent) {
      // perhaops only select within one paragraph for pins replies.
      const action = button.dataset.action;
      if (action === "quoteInReply") {
        const snippet = selectionContent.replace(/\r?\n/g, "\r\n> ");
        const $composeContent = document.querySelector("textarea[name='content']")
        const written = $composeContent.value.trimEnd()
        const prePadding = written ? "\r\n\r\n> " : "> "
        $composeContent.value = written + prePadding + snippet + "\r\n\r\n";
        $composeContent.focus()
      } else if (action === "pinSelection") {
        const content = selectionContent;
        const counter = parseInt(selectionMessageCounter);
        let response = await Client.addPin(conversationId, counter, content);
        response.match({
          ok: function({ id }) {
            const pin = { id, counter, content };
            pins = pins.concat(pin);
            page.$set({ pins });
          },
          fail: function(_) {
            page.$set({ failure: "Failed to pin content" });
          }
        });
      }
    }
    if (delayClick) {
      delayClick = false;
    } else {
      page.$set({ left: null, bottom: null });
    }
  });
}
