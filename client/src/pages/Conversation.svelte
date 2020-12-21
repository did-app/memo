<script>
  import DOMPurify from "dompurify";
  import SignIn from "./SignIn.svelte"
  import Message from "../components/Message.svelte"
  import * as Client from "../client.js";
  import {extractQuestions} from '../content.js'


  // fetchConversation probably belongs here to ensure authentication has been done.
  // import {fetchConversation} from "../sync/index"
  export let conversationId;
  // TODO nice Flash setup
  let failure;
  function clearFailure() {
    failure = undefined;
  }

  let participation, conversation, messages, participants, questions;
  // Don't want to silently refresh,
  async function fetchConversation(conversationId) {
    let response = await Client.fetchConversation(conversationId);
    return response.match({ok: function (data) {
      conversation = data.conversation

      let emailAddress = data.participation.email_address
      participation = {emailAddress, done: data.participation.done}

      participants = data.participants.map(function({ email_address: emailAddress }) {
        const [name] = emailAddress.split("@");
        return { name, emailAddress };
      });

      var highest;
      let asked = []
      // If we follow the numerical id's all the way, just do it might be problems
      messages = data.messages.map(function({ counter, content, author, inserted_at }) {
        // marked doesn't like an html bumping up against markdown content
        content = content.replaceAll("</answer>", "\r\n</answer>\r\n")
        const html = marked(content)

        const parser = new DOMParser();
        const doc = parser.parseFromString(html, "text/html");
        const firstElement = doc.body.children[0]
        // It's possible there are empty messges
        const intro = firstElement ? DOMPurify.sanitize(firstElement.innerHTML) : "";

        asked = extractQuestions(doc, author == emailAddress, asked)

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

          const mine = author == emailAddress
          if (mine) {
            question.awaiting = false
          }
        })

        // checked = closed
        const checked = !(data.participation.cursor < counter);
        highest = counter;
        return { counter, checked, author, date: inserted_at, intro, doc };
      }).map(function ({ counter, checked, author, date, intro, doc }) {
        const html = DOMPurify.sanitize(doc.body.innerHTML)
        return { counter, checked, author, date, intro, html }
      });

      // TODO call remainingQuestions
      questions = asked.filter(function ({awaiting}) {
        return awaiting
      })

      // Always leave the last open
      if (messages[messages.length - 1]) {
        messages[messages.length - 1].checked = false;
      }

      // TODO cleanup
      document.title = conversation.topic;
      // TODO have a scroll into view thing
      Client.readMessage(conversationId, highest);

      return true
    }, fail: function (e) {
      if (e.code == "forbidden") {
        throw {reason: "unauthenticated"}
      } else {
        throw {reason: "unknown"}
      }
    }});
  }


  // could be details + summary in future https://stackoverflow.com/questions/37033406/automatically-open-details-element-on-id-call
  function openMessage(id) {
    messages[id - 1].checked = false
    messages = messages
  }

  window.onhashchange = function (_event) {
    let $target = document.getElementById(window.location.hash.slice(1))
    if ($target) {
      let $article = $target.closest('article')
      if ($article) {
        let id = parseInt($article.id)
        openMessage(id)
      }
    }
  }

  function dismiss(id) {
    const index = questions.findIndex(function (q) {
      return q.id === id
    })
    questions[index].dismissed = true
    questions[index].answer = "Dismissed"
  }
  function setAnswer(id, value) {
    const index = questions.findIndex(function (q) {
      return q.id === id
    })
    questions[index].answer = value
  }

  let newParticipant;
  async function addParticipant(){
    console.log(newParticipant);
    if (participants.find(p => p.emailAddress === newParticipant)) {
      newParticipant = "";
    } else {
      let response = await Client.addParticipant(
        conversationId,
        newParticipant
      );
      response.match({
        ok: function(_) {
          const [name] = newParticipant.split("@");
          const participant = { name, emailAddress: newParticipant };
          participants = participants.concat(participant);
          newParticipant = "";
        },
        fail: function({ status }) {
          if (status === 422) {
            failure = "Unable to add participant because email is invalid";
          } else {
             failure = "Failed to add participant";
          }
        }
      });
    }
  }

  function resize(event) {
    let x = window.scrollX
    let y = window.scrollY
    event.target.style.height = "1px";
    event.target.style.height = (+event.target.scrollHeight)+"px";
    window.scroll(x, y)
  }

  let draft;
  function process(content) {
    if (!content) return "No preview yet."
    const html = marked(content)

    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");

    // Maybe this should be questions already
    extractQuestions(doc, true, [])
    return DOMPurify.sanitize(doc.body.innerHTML)
  }

  let makeQuestion;
  function watchQuestions(event) {
    const $area = event.target
    if (document.activeElement !== $area) return
    // let range = selection.getRangeAt(0)
    const cursor = $area.selectionStart;
    const textValue = $area.value
    const leftChar = textValue.slice(cursor - 1, cursor)

    if (leftChar !== "?") {
      makeQuestion = undefined
      return
    }

    let pre = textValue.slice(0, cursor -1)
    let post = textValue.slice(cursor)
    let lineBreak = pre.lastIndexOf("\n")
    let question = pre.slice(lineBreak + 1)
    pre = pre.slice(0, lineBreak + 1)

    if (question[0] === "[") return
    if (question.trim() === "") return
    makeQuestion = function () {
      // Only replace up to first two new lines for the newlines added
      draft = pre + "[" + question + "?](#?)\n\n" + post.trimStart();

      $area.setSelectionRange(cursor + 8, cursor + 8)
      makeQuestion = undefined
    }
  }
  function tryMakeQuestion(event) {
    if (event.key === "Enter" && makeQuestion) {
      event.preventDefault()
      makeQuestion()
    } else {
      watchQuestions(event)
    }
  }

  export function formValues($form) {
  // https://codepen.io/ntpumartin/pen/MWYmypq
  var obj = {};
  var elements = $form.querySelectorAll("input, select, textarea");
  for (var i = 0; i < elements.length; ++i) {
    var element = elements[i];
    var name = element.name;
    var value = element.value;
    var type = element.type;

    if (type === "checkbox") {
      obj[name] = element.checked
    } else {
      if (name) {
        obj[name] = value;
      }

    }

  }
  return obj;
}

  // TODO handle answers
  // TODO flash message and direct to home screen
  async function writeMessage(event) {
    console.log(draft);
    console.log();
    let buffer = ""
    for (const [key, value] of Object.entries(formValues(event.target))) {
      if (key.slice(0, 2) === "Q:" && value.trim().length) {
        buffer += `<answer data-question="${key.slice(2)}">

${value}
</answer>

`
      }
    }
    await Client.writeMessage(
      conversationId,
      buffer + draft,
      false
    );
    window.location.reload();
  }

  async function markAsDone() {
    const counter = messages.length
    participation.done = counter
    const response = await Client.markAsDone(conversationId, counter);
    response.match({
      ok: function(_) {
        true
      },
      fail: function(_) {
        failure = "Failed to mark as done";
      }
    });
  }

</script>

{#await fetchConversation(conversationId)}
shared header ideallyy
Let's not have any pins
{:then _}
<header class="w-full max-w-5xl mx-auto flex text-center p-2 md:pt-6 md:pb-4 items-center">
  <a class="border border-indigo-800 rounded py-1 px-2" href="/">↶ Inbox</a>
  <h1 id="topic" class="flex-grow text-xl md:text-2xl">{conversation.topic}</h1>
</header>
{#if failure}
<div class="bg-indigo-100 font-bold mb-3 p-4 text-center cursor-pointer" on:click={clearFailure}>
  {failure}
</div>
{/if}
<div class="sm:flex w-full max-w-5xl mx-auto">
  <main class="sm:w-2/3 max-w-md mx-auto md:mr-0 md:max-w-3xl px-1 md:px-2 md:mb-16">
    <div id="messages" class="">
      {#each messages as message}
      <Message {...message} />
      {/each}
    </div>
    <form id="reply-form"  class="relative w-full mt-2 mb-2 p-2 md:py-6 md:px-20 rounded-lg md:rounded-2xl my-shadow bg-white " on:submit|preventDefault={writeMessage}>
      <input id="preview-tab" class="hidden" type="checkbox">
      <div class="">
        {#each questions as {query, awaiting, id, answer, dismissed}}
        {#if awaiting}
        <div class:hidden={dismissed}>
          <blockquote class="flex px-4 my-2 border-l-4 border-indigo-800" >
            <a class="flex-1  hover:underline" href="#Q:{id}">
              {@html query}
            </a>
            <nav>
              <button class="bg-gray-200 p-1 rounded" type="button" on:click={(e) => setAnswer(id, e.target.innerText)}>👍</button>
              <button class="bg-gray-200 p-1 rounded" type="button" on:click={(e) => setAnswer(id, e.target.innerText)}>👎</button>
              <button class="bg-gray-200 p-1 rounded" type="button" on:click={() => dismiss(id)}>&#x274C;</button>
            </nav>
          </blockquote>
          <textarea class="w-full bg-white outline-none" name="Q:{id}" rows="1" style="min-height:0em;max-height:60vh;" placeholder="Answer" on:input={resize}>{answer}</textarea>
        </div>
        {/if}
        {/each}
      </div>
      {#if questions.length}
      <hr class="mt-4">
      {/if}
      <textarea class="w-full bg-white outline-none" name="content" style="min-height:8rem;max-height:60vh;" placeholder="Write message ..." bind:value={draft} on:input={resize} on:input={watchQuestions} on:keypress={tryMakeQuestion}></textarea>
      <div id="preview" class="markdown-body p-2" style="min-height:8rem;">
        {@html process(draft)}
      </div>

      {#if makeQuestion}
      <button class="bg-indigo-100 p-1 my-1 rounded shadow w-full" on:click="{makeQuestion}" type="button">Make question (press Enter)</button>
      {/if}
      <section class="pb-1 whitespace-no-wrap overflow-hidden">
        <span class="font-bold text-gray-700">From:</span>
        <span class="truncate">{participation.emailAddress}</span>
      </section>
      <footer id="compose-menu" class="flex flex-wrap items-baseline border-t">
        <div class="font-bold flex py-1 justify-start items-start hidden">
          <span class="text-gray-700 pr-2">Conclude</span>
          <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500">
            <input type="checkbox" class="opacity-0 absolute" name="resolve">
            <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
              <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
          </div>
        </div>
        <div class="ml-auto">
          <label for="preview-tab" class="">
            <span class="my-1 py-1 px-2 rounded border cursor-pointer border-indigo-900 focus:border-indigo-700 hover:border-indigo-700 text-indigo-800 font-bold">Preview</span>
          </label>
          <button class="my-1 py-1 px-2 rounded bg-indigo-900 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit">Send</button>
        </div>
      </footer>
    </form>
    <form class="w-full md:px-20" on:submit|preventDefault={markAsDone}>
      {#if messages.length > participation.done}
      <div class="flex">
        <label class="ml-auto font-bold flex py-1 justify-start items-center">
          <p class="mr-2">No further action required?</p>
          <button class="my-1 py-1 px-2 rounded bg-gray-900 focus:bg-gray-700 hover:bg-gray-700 text-white font-bold" type="submit" title="Select to no longer see as outsanding">Mark as done</button>
        </label>
      </div>
      {/if}
    </form>
  </main>
  <aside class="sm:w-1/3 max-w-sm mx-auto md:ml-0 flex flex-col p-2 text-gray-700">
    <div class="sticky top-0">
      <h3 class="font-bold">Participants</h3>
      <ul id="participants">
        {#each participants as {name, emailAddress}}
        <li class="m-1 whitespace-no-wrap truncate">{name} <small>&lt;{emailAddress}&gt;</small></li>
        {/each}
      </ul>
      <form on:submit|preventDefault={addParticipant}>
        <input class="duration-200 mt-2 px-4 py-1 rounded transition-colors bg-white" id="invite" type="email" required bind:value={newParticipant} placeholder="email address">
        <button class="px-4 py-1 hover:bg-indigo-700 rounded bg-indigo-900 text-white mt-2" type="submit">Invite</button>
      </form>
    </div>
  </aside>
</div>
{:catch reason}
{#if reason === 'unauthenticated'}
<SignIn/>
{:else}
Unknown failure
TODO shared error page
{reason}
{/if}
{/await}
