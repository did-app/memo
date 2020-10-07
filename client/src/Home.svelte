<script>
  export let navLinks = [];
  export let inner;
</script>

<header class="w-full max-w-2xl mx-auto text-right">
  <nav class="ml-auto text-lg p-4">
    {#each navLinks as {url, display}}
    <a class="px-1 border-b-2 hover:text-indigo-800 hover:border-indigo-800" href="{url}">{display}</a>
    {/each}
  </nav>
</header>
<main class="w-full max-w-2xl m-auto p-6">
  <h1 class="flex-grow font-serif text-indigo-800 text-6xl text-center">plum mail</h1>
  <svelte:component this={inner}/>
</main>
