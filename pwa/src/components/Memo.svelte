<script lang="typescript">
  import type { Memo } from "../conversation";
  import * as Writing from "../writing";
  import Fragment from "./Fragment.svelte";
  import SpanComponent from "./Span.svelte";

  export let open: boolean;
  export let memo: Memo;
  export let active: Record<number, undefined | (() => void)> = {};
  // This used to be called thread but we just pass the list of memos.
  // This could be called previous but lookup might work both ways when collecting all answers.
  export let peers: Memo[];
</script>

{#if open}
  <article
    id={memo.position.toString()}
    data-memo-position={memo.position.toString()}
    class="border-t mb-2 pt-4 pb-2 pr-12 bg-white md:rounded shadow-md overflow-hidden">
    <header
      class="ml-12 flex text-gray-600 cursor-pointer"
      on:click={() => (open = false)}>
      <span class="font-bold truncate">{memo.author}</span>
      <span class="ml-auto">{memo.posted_at.toLocaleDateString()}</span>
    </header>
    <Fragment blocks={memo.content} {active} {peers} />
  </article>
{:else}
  <article
    id={memo.position.toString()}
    data-memo-position={memo.position.toString()}
    on:click={() => (open = true)}
    class="-mb-2 border-t py-1 pr-12 bg-white md:rounded-t shadow-md cursor-pointer">
    <header class="ml-12 mb-2 flex text-gray-600 max-w-">
      <span class="truncate">
        <span class="font-bold">{memo.author}</span>
        <span
          class="truncate pl-2 pr-4">{#each Writing.summary(memo.content) as span, index}
            <SpanComponent {span} {index} unfurled={false} />
          {/each}</span>
      </span>
      <span class="ml-auto">{memo.posted_at.toLocaleDateString()}</span>
    </header>
  </article>
{/if}
