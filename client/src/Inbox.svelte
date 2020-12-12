<!-- This is a svelte APP that is a -->
<script>
  import authenticate from "./authenticate.js"
  import * as Client from "./client.js";
  import SignIn from "./SignIn.svelte"

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
    // try authenticate if code present
    await authenticate()

    let response = await Client.fetchInbox();
    conversations = response.match({ok: function ({conversations, identifier}) {
      hasAccount = identifier.has_account;
      emailAddress = identifier.email_address;

      conversations = conversations.map(function (c) {
        let participants = c.participants.map(function (p) {
          return p.email_address
        }).join(", ")
        return Object.assign({}, c, {participants})
      })

      unread = conversations.filter(function (c) {
        return c.to_reply
      }).slice().reverse()
      conversationSearch.addAll(conversations.slice().reverse())
      return conversations
    }, fail: function (e) {
      if (e.code == "forbidden") {
        authenticationRequired = true;
      } else {
        throw "Could not load inbox"
      }
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


  {#if hasAccount && panel === BEGIN_CONVERSATION}
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
