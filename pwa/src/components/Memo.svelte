<script lang="typescript">
  import type { Note } from "../note";
  import * as Thread from "../thread";
  import Fragment from "./Fragment.svelte";
  import SpanComponent from "./Span.svelte";

  export let index: number;
  export let open: boolean;
  export let memo: Note;
  export let active: Record<number, undefined | (() => void)> = {};
  export let thread: Note[];
</script>

<!-- Note index and counter off by one and both used -->
{#if open}
  <article
    id={memo.counter.toString()}
    data-note-index={index}
    class="-mt-2 border-t mb-4 py-6 pr-12 bg-white rounded-lg shadow-md">
    <header
      class="ml-12 mb-6 flex text-gray-600 cursor-pointer"
      on:click={() => (open = false)}>
      <span class="font-bold">{memo.author}</span>
      <span class="ml-auto">{memo.inserted_at.toLocaleDateString()}</span>
    </header>
    <!-- TODO note Record<a, b>[] returns type b not b | undefined -->
    <Fragment blocks={memo.blocks} {active} {thread} />
  </article>
{:else}
  <article
    id={memo.counter.toString()}
    data-note-index={index}
    on:click={() => (open = true)}
    class="-mt-2 border-t mb-0 py-1 pr-12 bg-white rounded-t-lg shadow-md cursor-pointer">
    <header class="ml-12 mb-2 flex text-gray-600">
      <span class="font-bold">{memo.author}</span>
      <span
        class="truncate pl-2 pr-8">{#each Thread.summary(memo.blocks) as span, index}
          <SpanComponent {span} {index} unfurled={false} />
        {/each}</span>
      <span class="ml-auto">{memo.inserted_at.toLocaleDateString()}</span>
    </header>
    <!-- TODO note Record<a, b>[] returns type b not b | undefined -->
    <!-- <Fragment {blocks} active={noteSelection[index] || {}} {thread} /> -->
  </article>
{/if}
