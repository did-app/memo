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
  $: results = (panel === ARCHIVE) ? conversations : ((panel === UNREAD) ? unread : found);

  (async function () {
    const identifier = (await authenticate()).match({
      ok: function(identifier) {
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


<header class="w-full max-w-2xl mx-auto text-right">
  <nav class="ml-auto text-lg p-4">
    {#if unread.length}
    <a class="px-1 border-b-2 {panel === UNREAD ? 'text-indigo-800' : ''} hover:text-indigo-800 hover:border-indigo-800" href="#unread">Unread</a>
    {/if}
    <a class="px-1 border-b-2 {panel === SEARCH ? 'text-indigo-800' : ''} hover:text-indigo-800 hover:border-indigo-800" href="#">Search</a>
    <a class="px-1 border-b-2 {panel === ARCHIVE ? 'text-indigo-800' : ''} hover:text-indigo-800 hover:border-indigo-800" href="#archive">Archive</a>
    <a class="px-1 border-b-2 hover:text-indigo-800 hover:border-indigo-800" href="__API_ORIGIN__/sign_out">Sign out</a>
  </nav>
</header>
<main class="w-full max-w-2xl m-auto p-6" on:keydown={handleKeyDown}>
  <h1 class="flex-grow font-serif text-indigo-800 text-6xl text-center">plum mail</h1>
  {#if panel === BEGIN_CONVERSATION}
  <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Conversation topic" required pattern="[^@]*" minlength="2" maxlength="100" autofocus autocomplete="off"/>
  <div class="warning">
    Conversation topics must not contain '@'.
  </div>
  <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Email address" required type="email" autofocus autocomplete="off"/>
  <div class="warning">
    Not a valid email address
  </div>
  {:else}
  {#if panel === SEARCH}
  <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Search by name, email, topic or content, also start conversation" id="search" autofocus autocomplete="off" bind:value={searchTerm}/>
  {#if searchTerm.length > 2 && searchTerm.length =< 100 && !searchTerm.includes('@')}
  <form class="" action="__API_ORIGIN__/c/create" method="post">
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
</main>
{#if authenticationRequired}
<SignIn/>
{/if}
