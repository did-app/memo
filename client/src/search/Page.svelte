<script>
  const SEARCH = "SEARCH"
  const UNREAD = "UNREAD"
  const ARCHIVE = "ARCHIVE"
  export let results = [];
  export let newTopic;
  export let unread = [];
  export let all = [];

  let nextDate = new Date()
  nextDate.setHours(nextDate.getHours() + 1, 0, 0, 0)
  let nextHour = nextDate.toLocaleTimeString(undefined, { hour: 'numeric', hour12: true })

  let page = SEARCH;
  function unreadPage() {
    page = UNREAD
  }
  function searchPage() {
    page = SEARCH
  }
  function archivePage() {
    page = ARCHIVE
  }
</script>

<header class="w-full max-w-2xl mx-auto text-right">
  <nav class="ml-auto text-lg p-4">
    {#if unread.length !== 0 && page === SEARCH}
    <a on:click|preventDefault={unreadPage} class="px-1 border-b-2 hover:text-indigo-800 hover:border-indigo-800" href="#">New messages</a>
    {/if}
    {#if page === SEARCH}
    <a on:click|preventDefault={archivePage} class="px-1 border-b-2 hover:text-indigo-800 hover:border-indigo-800" href="#">Archive</a>
    {/if}
    {#if page !== SEARCH}
    <a on:click|preventDefault={searchPage} class="px-1 border-b-2 hover:text-indigo-800 hover:border-indigo-800" href="#">Back to search</a>
    {/if}
    <a class="px-1 border-b-2 hover:text-indigo-800 hover:border-indigo-800" href="__API_ORIGIN__/sign_out">Sign out</a>
  </nav>
</header>
<main class="w-full max-w-2xl m-auto p-6">
  <h1 class="flex-grow font-serif text-indigo-800 text-6xl text-center">plum mail</h1>
  {#if page === UNREAD}
  {#each unread as {id, updated_at, next, topic, participants}}
  <a class="block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl" href="/c/{id}#{next}">
    <div class="flex">
      <h2 class="flex-grow font-bold my-1">{topic}</h2>
      <span class="my-1">{updated_at}</span>
    </div>
    <div class="truncate">
      {participants}
    </div>
  </a>
  {/each}
  {:else if page === ARCHIVE}
  <nav id="inbox">
    {#each all as {id, updated_at, next, topic, participants}}
    <a class="block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl" href="/c/{id}#{next}">
      <div class="flex">
        <h2 class="flex-grow font-bold my-1">{topic}</h2>
        <span class="my-1">{updated_at}</span>
      </div>
      <div class="truncate">
        {participants}
      </div>
    </a>
    {/each}
  </nav>
  {:else}
  <input id="search" type="text" class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Search by name, email, topic or content, also start conversation" autofocus autocomplete="off"/>
  <nav id="results">
    {#each results as {id, updated_at, next, topic, participants}}
    <a class="block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl" href="/c/{id}#{next}">
      <div class="flex">
        <h2 class="flex-grow font-bold my-1">{topic}</h2>
        <span class="my-1">{updated_at}</span>
      </div>
      <div class="truncate">
        {participants}
      </div>
    </a>
    {/each}
    {#if newTopic}
    <form class="" action="__API_ORIGIN__/c/create" method="post">
      <input type="hidden" name="topic" value="{newTopic}">
      <button class="block w-full text-left my-2 py-2 px-4 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl" type="submit">
        <h2 class="my-1">Start new conversation with topic: <span class="font-bold">{newTopic}</span></h2>
      </button>
    </form>
    {/if}
  </nav>
  {/if}
</main>
