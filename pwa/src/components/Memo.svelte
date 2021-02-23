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
    class="border-t mb-2 pt-1 pb-16 pr-6 md:pr-12 bg-white md:rounded shadow-md overflow-hidden w-screen max-w-2xl"
  >
    <header
      class="ml-6 md:ml-12 flex text-gray-600 cursor-pointer pb-6"
      on:click={() => (open = false)}
    >
      <span class="mr-auto" />
      <span class="truncate font-bold text-gray-400 text-xs truncate"
        >{memo.author}</span
      >
      <!-- <span class="ml-auto">{memo.posted_at.toLocaleDateString()}</span> -->
    </header>
    <Fragment
      blocks={memo.content}
      position={memo.position}
      {peers}
      active={true}
    />
    <footer class="border-t-2 flex md:ml-12 ml-6 mt-4">
      <p class="my-1 min-w-0 w-full text-xs text-gray-400">
        Received: <span class="ml-auto"
          >{memo.postedAt.toLocaleDateString()}</span
        >
      </p>
    </footer>
  </article>
{:else}
  <article
    id={memo.position.toString()}
    on:click={() => (open = true)}
    class="-mb-2 border-t py-1  pr-6 md:pr-12 bg-white md:rounded-t shadow-md cursor-pointer w-screen max-w-2xl"
  >
    <header class="ml-6 md:ml-12 mb-2 flex text-gray-400">
      <span class="truncate">
        <span class="truncate pr-4"
          >{#each Writing.summary(memo.content) as span}
            <SpanComponent
              {span}
              offset={0}
              unfurled={false}
              placeholder={null}
              active={false}
            />
          {/each}</span
        >
      </span>
      <span class="ml-auto font-bold text-gray-400 text-xs">{memo.author}</span>
      <!-- <span class="ml-auto">{memo.posted_at.toLocaleDateString()}</span> -->
    </header>
  </article>
{/if}
