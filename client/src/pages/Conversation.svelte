<script>
  import DOMPurify from "dompurify";
  import SignIn from "./SignIn.svelte"
  import Message from "../components/Message.svelte"
  import * as Client from "../client.js";
  import {extractQuestions} from '../content.js'


  // fetchConversation probably belongs here to ensure authentication has been done.
  // import {fetchConversation} from "../sync/index"
  export let conversationId;
  let failure;

  // Don't want to silently refresh,
  async function fetchConversation(conversationId) {
    let response = await Client.fetchConversation(conversationId);
    return response.match({ok: function (data) {
      let {participation, messages, participants, ...rest} = data
      let emailAddress = participation.email_address


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
        const checked = !(participation.cursor < counter);
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

      // TODO cleanup
      document.title = rest.conversation.topic;
      // TODO have a scroll into view thing
      Client.readMessage(conversationId, highest);

      console.log(rest);
      return {participation, messages, participants, ...rest}
    }, fail: function (e) {
      if (e.code == "forbidden") {
        throw {reason: "unauthenticated"}
      } else {
        throw {reason: "unknown"}
      }
    }});
  }
</script>

{#await fetchConversation(conversationId)}
shared header ideallyy
Let's not have any pins
{:then {conversation, messages, participants}}
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
  </main>
  <aside class="sm:w-1/3 max-w-sm mx-auto md:ml-0 flex flex-col p-2 text-gray-700">
    <div class="sticky top-0">
      <h3 class="font-bold">Participants</h3>
      <ul id="participants">
        {#each participants as {name, emailAddress}}
        <li class="m-1 whitespace-no-wrap truncate">{name} <small>&lt;{emailAddress}&gt;</small></li>
        {/each}
      </ul>
      <form class="" data-action="addParticipant" method="post">
        <input class="duration-200 mt-2 px-4 py-1 rounded transition-colors bg-white" id="invite" type="email" required name="emailAddress" value="" placeholder="email address">
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
