<!-- This is a svelte APP that is a -->
<script>
  import authenticate from "./authenticate.js"
  import * as Client from "./client.js";
  import SignIn from "./SignIn.svelte"

  const SEARCH = "SEARCH"
  const UNREAD = "UNREAD"
  const ARCHIVE = "ARCHIVE"
  const BEGIN_CONVERSATION = "BEGIN_CONVERSATION"

  function panelFromHash(hash) {
    if (hash.substring(1) === "archive") {
      return ARCHIVE
    } else if (hash.substring(1) === "unread") {
      return UNREAD
    } else if (hash.substring(1) === "begin") {
      return BEGIN_CONVERSATION
    } else {
      return SEARCH
    }
  }

  let authenticationRequired = false
  let panel;
  panel = panelFromHash(location.hash)

  addEventListener('hashchange', function (e) {
    panel = panelFromHash(location.hash)
  })

  let searchTerm = "";
  let conversations = [];
  let unread = [];
  let conversationSearch = new MiniSearch({
    fields: ['topic', 'participants', 'slug'], // fields to index for full-text search
    storeFields: ['topic', 'next', 'participants', 'slug', 'updated_at', 'closed'], // fields to return with search results
    tokenize: (string, fieldName) => {
     return string.split(/[\s,@]+/)
    },
    searchOptions: {
     tokenize: (string) => string.split(/[\s,@]+/) // search query tokenizer
    }
  })

  function searchAll(term) {
    if (term.length == 0) {
      return []
    }
    return conversationSearch.search(term, {combineWith: 'AND', fuzzy: 0.2, prefix: true})
  }

  let found;
  $: found = searchAll(searchTerm)
  let results;
  let hasAccount = false;
  let emailAddress = "";
  $: results = (function () {
    if (hasAccount) {
      return (panel === ARCHIVE) ? conversations : ((panel === UNREAD) ? unread : found);
    } else {
      return conversations
    }
  })();

  (async function () {
    const identifier = (await authenticate()).match({
      ok: function(identifier) {
        hasAccount = identifier.hasAccount;
        emailAddress = identifier.emailAddress;
        return identifier
      },
      fail: function(e) {
        authenticationRequired = true;
      }
    })

    let response = await Client.fetchInbox();
    conversations = response.match({ok: function ({conversations}) {
      conversations = conversations.map(function (c) {
        let participants = c.participants.map(function (p) {
          return p.email_address
        }).join(", ")
        return Object.assign({}, c, {participants})
      })

      unread = conversations.filter(function (c) {
        return c.unread
      }).slice().reverse()
      conversationSearch.addAll(conversations.slice().reverse())
      return conversations
    }, fail: function (_) {
      throw "Could not load inbox"
    }});
  })()
  // https://developer.mozilla.org/en-US/docs/Web/API/Document/keydown_event
  function handleKeyDown(e) {
    if (event.isComposing || event.keyCode === 229) {
      return;
    }
    var step
    if (event.code == 'ArrowUp') {
      step = -1
    } else if (event.code == 'ArrowDown') {
      step = 1
    } else {
      return
    }
    const focusable = [document.querySelector('#search')].concat(
      Array.from(document.querySelectorAll('#results > a, #results > form > button'))
    )

    const activeIndex = focusable.indexOf(document.activeElement)
    const nextActiveIndex = activeIndex + step
    const nextActive = focusable[nextActiveIndex];

    if (nextActive) {
      nextActive.focus();
      event && event.preventDefault();
    }
  }
</script>


{#if hasAccount}
<header class="z-20 md:h-16 h-auto fixed w-full bg-white text-left border-b-2">
  <nav class="ml-auto md:p-4 p-0 px-2 py-1">
    <a class="block md:inline text-center md:text-left" href="/">
      <span class="px-1 md:mr-8 mr-0 hover:text-indigo-800 hover:border-indigo-800 text-sm md:text-base font-semibold">Plum Mail</span>
    </a>
    <a style="padding-top:0.28em; padding-bottom:0.5em;" class="bg-green-500 hover:bg-green-700 transition duration-200 px-4 text-sm rounded-lg text-white leading-normal md:leading-none block sm:inline-block md:inline text-center sm:text-left w-8/12 mx-auto sm:w-auto" href="#begin">
      <svg class="fill-current w-4 mr-2 inline leading-none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" id="Capa_1" x="0px" y="0px" viewBox="0 0 512 512" style="enable-background:new 0 0 512 512;" xml:space="preserve">
        <g>
          <g>
            <path d="M485.743,85.333H26.257C11.815,85.333,0,97.148,0,111.589V400.41c0,14.44,11.815,26.257,26.257,26.257h459.487    c14.44,0,26.257-11.815,26.257-26.257V111.589C512,97.148,500.185,85.333,485.743,85.333z M475.89,105.024L271.104,258.626    c-3.682,2.802-9.334,4.555-15.105,4.529c-5.77,0.026-11.421-1.727-15.104-4.529L36.109,105.024H475.89z M366.5,268.761    l111.59,137.847c0.112,0.138,0.249,0.243,0.368,0.368H33.542c0.118-0.131,0.256-0.23,0.368-0.368L145.5,268.761    c3.419-4.227,2.771-10.424-1.464-13.851c-4.227-3.419-10.424-2.771-13.844,1.457l-110.5,136.501V117.332l209.394,157.046    c7.871,5.862,17.447,8.442,26.912,8.468c9.452-0.02,19.036-2.6,26.912-8.468l209.394-157.046v275.534L381.807,256.367    c-3.42-4.227-9.623-4.877-13.844-1.457C363.729,258.329,363.079,264.534,366.5,268.761z"></path>
          </g>
        </g>
      </svg>Compose
    </a>
    <p class="py-2 sm:py-0 ml-0 sm:ml-8 block sm:inline text-center sm:text-left text-xs text-gray-700">
      {#if unread.length}
      <a class="px-1 border-b-2 border-white {panel === UNREAD ? 'text-indigo-800' : ''}" href="#unread">Unread</a>
      {/if}
      <a class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800 {panel === SEARCH ? 'text-indigo-800' : ''}" href="#">Search</a>
      <a class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800 {panel === ARCHIVE ? 'text-indigo-800' : ''}" href="#archive">Archive</a>
      <a class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800" href="__API_ORIGIN__/sign_out">Sign out</a>
    </p>
  </nav>
</header>
{/if}
<main class="w-full max-w-2xl m-auto p-6" on:keydown={handleKeyDown}>
  <h1 class="flex-grow font-serif text-indigo-800 text-6xl text-center">plum mail</h1>
  {#if hasAccount && panel === BEGIN_CONVERSATION}
  <form action="__API_ORIGIN__/c/create" method="post">
    <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Conversation topic" name="topic" required pattern="[^@]*" minlength="2" maxlength="100" autofocus autocomplete="off"/>
    <div class="warning">
      Conversation topics must not contain '@'.
    </div>
    <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Email address" name="participant" required type="email"/>
    <div class="warning">
      Not a valid email address
    </div>
    <button class="bg-indigo-800 block hover:bg-indigo-700 hover:shadow-lg mx-auto px-4 py-2 rounded shadow-xl text-white" type="submit">Begin conversation</button>
  </form>
  {:else}
  {#if hasAccount && panel === SEARCH}
  <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Search by name, email, topic or content, also start conversation" id="search" autofocus autocomplete="off" bind:value={searchTerm}/>
  {#if searchTerm.length > 2 && searchTerm.length < 101 && !searchTerm.includes('@')}
  <form action="__API_ORIGIN__/c/create" method="post">
    <input type="hidden" name="topic" value="{searchTerm}">
    <button class="block w-full text-left my-2 py-2 px-4 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl" type="submit">
      <h2 class="my-1">Start new conversation with topic: <span class="font-bold">{searchTerm}</span></h2>
    </button>
  </form>
  {/if}
  {/if}
  <nav id="results">
    {#each results as {id, updated_at, next, topic, participants, closed}}
    <a class="block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl" href="/c/{id}#{next}">
      <div class="flex">
        <h2 class="flex-grow font-bold my-1">{closed ? "CONCLUDED:" : ""} {topic}</h2>
        <span class="my-1">{updated_at}</span>
      </div>
      <div class="truncate">
        {participants}
      </div>
    </a>
    {/each}
  </nav>
  {/if}
  {#if !hasAccount}
  <div id="non-user">
    <section class="w-full max-w-3xl mx-auto">
      <!-- <h2 class="font-bold text-purple-700 text-2xl text-center mb-4">Your Conversations</h2> -->
      <div class="p-8 mt-4 rounded-lg text-white bg-gradient-to-t from-purple-400 via-purple-600 to-purple-800 shadow-xl">
        <h2 class="font-medium text-2xl border-b-2 border-white pb-4 mb-4">Welcome to Plum Mail</h2>
        <p class="my-2">This is your inbox.  It shows the conversations you have are part of.</p>
        <p class="my-2">Click the conversation to read or reply.</p>
        <p class="my-2"><a href="https://plummail.co" class="text-yellow-500 font-medium underline ">Visit our website</a> to find out what makes Plum Mail special.
        <p class="my-2">Enter your email below to join the waitlist for access to the full version of Plum Mail.</p>
        <script type="text/javascript">
        async function backgroundSumbit(event) {
        event.preventDefault()
        const data = new URLSearchParams();
        for (const pair of new FormData(event.target)) {
            data.append(pair[0], pair[1]);
        }
        console.log(data.toString())
        console.log(event)
        let response = await fetch(event.target.action, {
          method: "POST",
          body: data
        })
        console.log(response)
        if (response.status === 200) {
          event.target.innerHTML = "Welcome"
        } else {
          alert("Sorry, something unexpected has happened.")
        }
        }
        </script>
        <form class="text-center mx-auto mt-8 text-gray-600" action="__API_ORIGIN__/welcome" method="post" onsubmit="backgroundSumbit(event)">
          <input type="hidden" name="topic" value="Joining the waitlist">
          <input type="hidden" name="message" value="Welcome to the Plum Mail waitlist

I hope you are enjoying the conversations you are having in Plum Mail.
We started this project to make easier to stay focused on the conversations that matter to us.

Feel free to use this conversation to ask Richard and myself anything you like.

**Cheers Peter**

p.s. Richard will say hi in the next few days">
          <input type="hidden" name="author_id" value="1">
          <input type="hidden" name="cc" value="richard@plummail.co">
          <input class="border-2 rounded-lg bg-gray-100 border-gray-500 m-4 px-4 py-2" disabled type="email" name="email" value={emailAddress}>
          <button class="font-medium text-center bg-purple-700 hover:bg-purple-500 cursor-pointer transition duration-100 rounded-lg px-4 py-2 text-white text-lg">
            Join the waitlist
          </button>
        </form>
      </div>
    </section>
  </div>
  {/if}
</main>

{#if authenticationRequired}
<SignIn/>
{/if}
