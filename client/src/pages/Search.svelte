<script>
  import Layout from "./_Layout.svelte"
  let nav = "search";
  let searchTerm = "";

  function init(conversations) {
    const searchIndex = new MiniSearch({
      fields: ['topic', 'participants', 'slug'], // fields to index for full-text search
      storeFields: ['topic', 'next', 'participants', 'slug', 'updated_at', 'closed'], // fields to return with search results
      tokenize: (string, _fieldName) => {
       return string.split(/[\s,@]+/)
      },
      searchOptions: {
       tokenize: (string) => string.split(/[\s,@]+/) // search query tokenizer
      }
    })
    searchIndex.addAll(conversations.slice().reverse())
    return searchIndex
  }

  let searchIndex = undefined;
  function searchAll(conversations, term) {
    searchIndex = searchIndex || init(conversations)
    if (term.length == 0) {
      return []
    }
    console.log("searching");
    return searchIndex.search(term, {combineWith: 'AND', fuzzy: 0.2, prefix: true})
  }

  // https://developer.mozilla.org/en-US/docs/Web/API/Document/keydown_event
  function handleKeyDown(event) {
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

<Layout {nav} let:conversations={conversations}>
  <div on:keydown={handleKeyDown}>
    <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Search by name, email, topic or content, also start conversation" id="search" autocomplete="off" bind:value={searchTerm}/>
    <nav id="results">
      {#each searchAll(conversations, searchTerm) as {id, updated_at, next, topic, participants, closed}}
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
      {#if searchTerm.length > 2 && searchTerm.length < 101 && !searchTerm.includes('@')}
      <form action="__API_ORIGIN__/c/create" method="post">
        <input type="hidden" name="topic" value="{searchTerm}">
        <button class="block w-full text-left my-2 py-2 px-4 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl" type="submit">
          <h2 class="my-1">Start new conversation with topic: <span class="font-bold">{searchTerm}</span></h2>
        </button>
      </form>
      {/if}
    </nav>
  </div>
</Layout>
