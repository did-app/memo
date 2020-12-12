<script>
  import Layout from "./_Layout.svelte"
  let nav = "search";
</script>

<Layout {nav} let:conversations={conversations}>
  <div>
    <nav id="results">
      {#each conversations as {id, updated_at, next, topic, participants, closed}}
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
  </div>
</Layout>
