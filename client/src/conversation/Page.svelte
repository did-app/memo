<script>
  import {
    Circle2
  } from 'svelte-loading-spinners'
  import SignIn from "../SignIn.svelte"
  import Message from "./Message.svelte"

  import DOMPurify from 'dompurify';
  import {extractQuestions} from '../content.js'

  export let failure;
  export let authenticationRequired;
  export let conversationId;
  export let emailAddress;
  export let topic;
  export let closed = false;
  export let notify;
  export let done;
  export let participants = [];
  export let messages = [];
  export let pins = [];
  export let left;
  export let bottom;
  export let questions = [];
  export let installPrompt;

  function process(content) {
    if (!content) return "No preview yet."
    const html = marked(content)

    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");

    // Maybe this should be questions already
    extractQuestions(doc, true, [])
    return DOMPurify.sanitize(doc.body.innerHTML)
  }

  let draft;
  $: preview = process(draft)


  function clearFailure() {
    failure = undefined;
  }

  // could be details + summary in future https://stackoverflow.com/questions/37033406/automatically-open-details-element-on-id-call
  function openMessage(id) {
    messages[id - 1].checked = false
    messages = messages
  }

  window.onhashchange = function (event) {
    let $target = document.getElementById(window.location.hash.slice(1))
    if ($target) {
      let $article = $target.closest('article')
      if ($article) {
        let id = parseInt($article.id)
        openMessage(id)
      }
    }
  }

  let makeQuestion;

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

function doInstall() {
  installPrompt.prompt()
  installPrompt = false
}
</script>


    <form class="w-full md:px-20" data-action="markAsDone">
      {#if messages.length > done}
      <div class="flex">
        <label class="ml-auto font-bold flex py-1 justify-start items-center">
          <p class="mr-2">No further action required?</p>
          <button class="my-1 py-1 px-2 rounded bg-gray-900 focus:bg-gray-700 hover:bg-gray-700 text-white font-bold" type="submit" title="Select to no longer see as outsanding">Mark as done</button>
        </label>
      </div>
      {/if}
    </form>
    <form class="w-full mb-8 md:px-20" on:submit|preventDefault={doInstall}>
      {#if installPrompt}
      <div class="flex">
        <label class="ml-auto font-bold flex py-1 justify-start items-center">
          <p class="mr-2">Find this conversation quicker?</p>
          <button class="my-1 py-1 px-2 rounded bg-gray-900 focus:bg-gray-700 hover:bg-gray-700 text-white font-bold" type="submit" title="Select to no longer see as outsanding">Install</button>
        </label>
      </div>
      {/if}
    </form>

  </main>

</div>
{/if }
