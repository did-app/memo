<script>
  export let results = [];
  export let newTopic;
</script>

<header class="w-full max-w-2xl mx-auto text-right">
  <style media="screen">
    #notifications:checked ~ .inline-block  {
      display: none;
    }
    #notifications:checked ~ .hidden  {
      display: inline-block;
    }
  </style>
  <label>
    <input id="notifications" class="hidden" type="checkbox" name="" value="">
    <span class="inline-block ml-auto text-lg p-4">
      <span href="/c#1">Next update 8am <img class="inline-block w-8" src="002-clock.svg" alt=""> </span>
    </span>
    <span class="hidden ml-auto text-lg p-4">
      <a href="/c#3">New messages <img class="inline-block w-8" src="003-chat.svg" alt=""> </a>
    </span>
  </label>
</header>
<main class="w-full max-w-2xl m-auto p-6">
  <h1 class="flex-grow font-serif text-indigo-800 text-6xl text-center">plum mail</h1>
  <input id="search" type="text" class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Search by name, email, topic or content, also start conversation" autofocus autocomplete="off"/>
  <nav id="results">
    {#each results as {id, next, topic, participants}}
    <a class="block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl" href="/c/{id}#{next}">
      <h2 class="font-bold my-1">{topic}</h2>
      <div class="truncate">
        {participants.map(p => p.email_address).join(", ")}
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
</main>
