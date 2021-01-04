<script lang="typescript">
  import type { Memo } from "../memo";
  import * as Thread from "../thread";
  import Fragment from "./Fragment.svelte";
  import SpanComponent from "./Span.svelte";

  export let open: boolean;
  export let memo: Memo;
  export let active: Record<number, undefined | (() => void)> = {};
  export let thread: Memo[];
  console.log(memo);
</script>

{#if open}
  <article
    id={memo.position.toString()}
    data-memo-postion={memo.position.toString()}
    class="border-t mb-2 pt-4 pb-2 pr-12 bg-white md:rounded shadow-md overflow-hidden">
    <header
      class="ml-12 flex text-gray-600 cursor-pointer"
      on:click={() => (open = false)}>
      <span class="font-bold truncate">{memo.author}</span>
      <span class="ml-auto">{memo.inserted_at.toLocaleDateString()}</span>
    </header>
    <!-- TODO note Record<a, b>[] returns type b not b | undefined -->
    <Fragment blocks={memo.content} {active} {thread} />
  </article>
{:else}
  <article
    id={memo.position.toString()}
    data-memo-postion={memo.position.toString()}
    on:click={() => (open = true)}
    class="-mb-2 border-t py-1 pr-12 bg-white md:rounded-t shadow-md cursor-pointer">
    <header class="ml-12 mb-2 flex text-gray-600 max-w-">
      <span class="truncate">
        <span class="font-bold">{memo.author}</span>
        <span
          class="truncate pl-2 pr-4">{#each Thread.summary(memo.content) as span, index}
            <SpanComponent {span} {index} unfurled={false} />
          {/each}</span>
      </span>
      <span class="ml-auto">{memo.inserted_at.toLocaleDateString()}</span>
    </header>
    <!-- TODO note Record<a, b>[] returns type b not b | undefined -->
    <!-- <Fragment {blocks} active={noteSelection[index] || {}} {thread} /> -->
  </article>
{/if}
