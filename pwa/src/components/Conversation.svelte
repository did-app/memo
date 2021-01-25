<script lang="typescript">
  import { onMount, tick } from "svelte";
  import type { Reference, Memo, Identifier } from "../conversation";
  import * as conversation_module from "../conversation";
  import type { Block, Range } from "../writing";
  import * as Writing from "../writing";

  import type Composer__SvelteComponent_ from "../components/Composer.svelte";

  import Composer from "../components/Composer.svelte";
  import MemoComponent from "../components/Memo.svelte";
  import BlockComponent from "../components/Block.svelte";

  import * as Icons from "../icons";

  // Only need the reader id for pulling out questions
  // export let identifier: Identifier;
  export let acknowledged: number;
  export let memos: Memo[];
  // Might make sense to pass these in as a slot
  export let acknowledge: (() => void) | undefined;
  export let dispatchMemo: (content: Block[]) => void;

  let composer: Composer__SvelteComponent_;

  // Note scroll after loadMemos
  let target: number | undefined;
  onMount(function () {
    let id = window.location.hash.slice(1);
    if (id) {
      target = parseInt(id);
      let element = document.getElementById(id);
      if (element) {
        element.scrollIntoView();
      }
    }
    window.addEventListener(
      "hashchange",
      function () {
        let id = window.location.hash.slice(1);
        // I think we need an on distroy
        if (id) {
          target = parseInt(id);
        }
      },
      false
    );
  });

  // acknowledge not an option if no thread
  // let reply: boolean = threadId === undefined;
  let reply: boolean = false;

  let root: HTMLElement;

  let userFocus: Reference | null = null;
  let focusSnapshot: Reference | null = null;
  let currentPosition: number = 0;
  let composerRange: Range | null = null;

  function handleSelectionChange() {
    let selection: Selection = (Writing as any).getSelection();
    let result = Writing.rangeFromDom(selection.getRangeAt(0));

    if (result && result[1] <= currentPosition) {
      const [range, memoPosition] = result;

      if (Writing.isCollapsed(range)) {
        userFocus = {
          memoPosition,
          blockIndex: range.anchor.path[0] as number,
        };
      } else {
        userFocus = { memoPosition, range };
      }

      reply = false;
    } else {
      userFocus = null;
    }
    if (result && result[1] == currentPosition + 1) {
      const [range] = result;
      composerRange = range;
    } else {
      composerRange = null;
    }
  }
  // This captures the focus for duration of a click
  document.addEventListener("mousedown", function () {
    focusSnapshot = userFocus;
  });

  onMount(() => {
    document.addEventListener("selectionchange", handleSelectionChange);
    return () =>
      document.removeEventListener("selectionchange", handleSelectionChange);
  });

  // let references = conversation_module.gatherPrompts(
  //   memos || [],
  //   identifier.emailAddress
  // );

  // references.map(function (reference) {
  //   composer.addAnnotation(reference);
  // });
  // console.log(references);

  // let x = tick().then(function () {
  //   // Tick seems to now work with the composer getting rendered.
  //   setTimeout(function name() {
  //   }, 100)
  //   );

  function quoteInReply() {
    if (focusSnapshot === null) {
      console.warn("Shouldn't be quoting without focus");
    } else {
      composer.addAnnotation(focusSnapshot);
    }
    reply = true;
  }

  function isOpen(memo: Memo): boolean {
    return memo.position >= acknowledged || memo.position === target;
  }
</script>

<div class="">
  <div class="" bind:this={root}>
    {#each memos as memo}
      <!-- Memos should never be empty -->
      <MemoComponent {memo} open={isOpen(memo)} peers={memos || []} />
    {/each}
  </div>
  <article
    class="my-4 py-6  pr-6 md:pr-12 bg-white rounded-lg sticky bottom-0 border shadow-top"
  >
    <div class:hidden={!reply}>
      <Composer
        previous={memos || []}
        bind:this={composer}
        selected={composerRange}
        position={(memos?.length || 0) + 1}
        let:blocks
      >
        <div class="mt-2 pl-6 md:pl-12 flex items-center">
          <div class="flex flex-1" />
          <button
            on:click={() => {
              reply = false;
            }}
            class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2">
            <span class="w-5 mr-2 inline-block">
              <Icons.ReplyAll />
            </span>
            <span class="py-1">Back</span>
          </button>
          <button
            on:click={() => dispatchMemo(blocks)}
            class="flex items-center bg-gray-800 border-2 border-gray-800 text-white rounded px-2 ml-2">
            <span class="w-5 mr-2 inline-block">
              <Icons.Send />
            </span>
            <span class="py-1"> Send </span>
          </button>
        </div>
      </Composer>
    </div>
    {#if !reply}
      {#if userFocus}
        <div
          class="truncate ml-6 md:ml-12 border-gray-600 border-l-4 px-2 text-gray-600"
        >
          <!-- {#each Writing.summary(conversation_module.followReference(userFocus, response.data)) as span, index}
      <SpanComponent {span} {index} unfurled={false} />
      {/each} -->
          {#each conversation_module.followReference(userFocus, memos || []) as block, index}
            <BlockComponent
              {index}
              {block}
              peers={memos || []}
              truncate={false}
              placeholder={null}
            />
          {/each}
        </div>
      {/if}
      <nav class="flex pl-6 md:pl-12">
        {#if userFocus}
          <button
            on:click={() => {
              userFocus = null;
            }}
            class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2">
            <span class="py-1">Clear</span>
          </button>
          <button
            on:click={quoteInReply}
            class="flex items-center bg-gray-800 text-white ml-2 rounded px-2">
            <span class="w-5 mr-2 inline-block">
              <Icons.Quote />
            </span>
            <span class="py-1">Quote in Reply</span>
          </button>
        {:else}
          {#if acknowledge}
            <button
              on:click={acknowledge}
              class="flex items-center rounded px-2 inline-block ml-2 border-gray-500 border-2">
              <span class="w-5 mr-2 inline-block">
                <Icons.Check />
              </span>
              <span class="py-1">Acknowledge</span>
            </button>
          {/if}

          <button
            on:click={() => {
              reply = true;
            }}
            class="flex items-center bg-gray-800 text-white rounded px-2 ml-2">
            <span class="w-5 mr-2 inline-block">
              <Icons.ReplyAll />
            </span>
            <span class="py-1">
              {#if false}Draft{:else}Reply{/if}
            </span>
          </button>
        {/if}
      </nav>
    {/if}
  </article>
</div>