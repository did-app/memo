<script lang="typescript">
  import type { Memo } from "../conversation";
  import * as Writing from "../writing";
  import Fragment from "./Fragment.svelte";
  import SpanComponent from "./Span.svelte";

  export let open: boolean;
  export let memo: Memo;
  // This used to be called thread but we just pass the list of memos.
  // This could be called previous but lookup might work both ways when collecting all answers.
  export let peers: Memo[];
</script>

{#if open}
  <article
    id={memo.position.toString()}
    class="border-t mb-2 pt-4 pb-2  pr-6 md:pr-12 bg-white md:rounded shadow-md overflow-hidden">
    <header
      class="ml-6 md:ml-12 flex text-gray-600 cursor-pointer"
      on:click={() => (open = false)}>
      <span class="mr-auto" />
      <span class="truncate">{memo.author}</span>
      <!-- <span class="ml-auto">{memo.posted_at.toLocaleDateString()}</span> -->
    </header>
    <Fragment blocks={memo.content} position={memo.position} {peers} />
  </article>
{:else}
  <article
    id={memo.position.toString()}
    on:click={() => (open = true)}
    class="-mb-2 border-t py-1  pr-6 md:pr-12 bg-white md:rounded-t shadow-md cursor-pointer">
    <header class="ml-6 md:ml-12 mb-2 flex  max-w-">
      <span class="truncate">
        <span
          class="truncate pr-4">{#each Writing.summary(memo.content) as span, index}
            <SpanComponent {span} {index} unfurled={false} />
          {/each}</span>
      </span>
      <span class="ml-auto text-gray-600">{memo.author}</span>
      <!-- <span class="ml-auto">{memo.posted_at.toLocaleDateString()}</span> -->
    </header>
  </article>
{/if}
