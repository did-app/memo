<script lang="typescript">
  import { onMount } from "svelte";
  import { getSelected } from "../conversation/view";
  import * as Conversation from "../conversation";
  import * as Social from "../social";
  import type { Block, Annotation } from "../writing";
  import * as Writing from "../writing";
  import { parse } from "../writing";
  // import * as Thread from "../thread";
  // import type { Reference } from "../thread";
  import type { State } from "../sync";
  import * as Sync from "../sync";
  import Composer from "../components/Composer.svelte";
  import Fragment from "../components/Fragment.svelte";
  import MemoComponent from "../components/Memo.svelte";
  import BlockComponent from "../components/Block.svelte";
  import LinkComponent from "../components/Link.svelte";
  import SpanComponent from "../components/Span.svelte";
  import * as Icons from "../icons";

  export let state: State;
  export let emailAddress: string;

  // TODO this needs to be a promise of old ones we load up
  let contact = Social.contactForEmailAddress(emailAddress);
  // TODO this could be returned as par of contact for emailAddress
  let memos = Sync.loadMemos(emailAddress);

  // Note scroll after loadMemos
  let focus: number | undefined;
  onMount(function () {
    let id = window.location.hash.slice(1);
    if (id) {
      focus = parseInt(id);
      let element = document.getElementById(id);
      if (element) {
        element.scrollIntoView();
      }
    }
    window.addEventListener(
      "hashchange",
      function () {
        let id = window.location.hash.slice(1);
        // TODO I think we need an on distroy
        if (id) {
          focus = parseInt(id);
        }
      },
      false
    );
  });

  type SendStatus = "available" | "working" | "suceeded" | "failed";
  let sendStatus: SendStatus = "available";

  // acknowledge not an option if no thread
  // let reply: boolean = threadId === undefined;
  let reply: boolean = false;

  let draft = "";
  let blocks: Block[];
  let preview = false;

  let root: HTMLElement;
  // map to navigate note id and section within that note
  let noteSelection: Record<
    number,
    Record<number, undefined | (() => void)>
  > = {};

  let activeAction:
    | { type: "quote"; fragment: Block[]; callback: () => void }
    | undefined;
  function handleSelectionChange() {
    const selected = getSelected(root);
    if (selected && selected.anchor && selected.focus) {
      let { memoPosition: anchorPosition, ...anchor } = selected.anchor;
      let { memoPosition: focusPosition, ...focus } = selected.focus;
      if (anchorPosition === focusPosition) {
        reply = false;
        let action = function () {
          addAnnotation(anchorPosition, { anchor, focus });
          reply = true;
          // TODO focus on area
        };

        if (anchor.offset != focus.offset) {
          activeAction = {
            type: "quote",
            callback: action,
            fragment: Conversation.followReference(
              // TODO better use of a location type
              { memoPosition: anchorPosition, range: { anchor, focus } },
              thread
            ),
          };
        }
        noteSelection = Object.fromEntries([
          [anchorPosition, Object.fromEntries([[anchor.path[0], action]])],
        ]);
      } else {
        activeAction = undefined;
        noteSelection = {};
      }
    } else {
      activeAction = undefined;
      noteSelection = {};
    }
  }

  onMount(() => {
    document.addEventListener("selectionchange", handleSelectionChange);
    return () =>
      document.removeEventListener("selectionchange", handleSelectionChange);
  });

  let prompts = Thread.gatherPrompts(thread, state.me.email_address);

  let annotations: { reference: Reference; raw: string }[] = prompts.map(
    function (prompt) {
      return { reference: prompt.reference, raw: "" };
    }
  );

  function mapAnnotation(draft: {
    reference: Reference;
    raw: string;
  }): Annotation[] {
    const { reference, raw } = draft;
    let blocks = parse(raw);
    if (blocks) {
      return [
        {
          type: "annotation",
          reference,
          blocks,
        },
      ];
    } else {
      return [];
    }
  }

  // DOESNT WORK ON ACTIVE message
  function addAnnotation(memoPosition: number, range: Range) {
    if (isCollapsed(range)) {
      const annotation = {
        type: "annotation",
        raw: "",
        reference: { memoPosition, blockIndex: range.anchor.path[0] },
      };
      annotations = annotations.concat(annotation);
    } else {
      const annotation = {
        type: "annotation",
        raw: "",
        reference: { memoPosition, range: range },
      };
      annotations = annotations.concat(annotation);
    }
  }

  function clearAnnotation(event: { detail: number }) {
    annotations.splice(event.detail, 1);
    annotations = annotations;
  }

  let choices: { ask: string; when: string }[];
  let suggestions: Block[] = [];
  $: blocks = (function (): Block[] {
    let content = parse(draft);
    console.log(content, annotations, "foo");

    let mappedAnnotations: Annotation[] = annotations.flatMap(mapAnnotation);
    let b = content ? [...mappedAnnotations, ...content] : mappedAnnotations;

    choices = suggestions.map(function () {
      return { ask: "everyone", when: "no hurry" };
    });
    return b;
  })();

  function acknowledge() {
    if (threadId) {
      API.acknowledge(threadId, maxPosition);
      // Could wait for it to work, need regular erroring buttons
      outstanding = false;
    } else {
      throw "Should not be able to acknowledge without thread";
    }
  }
</script>

<style>
  .sidebar {
    grid-template-columns: minmax(0px, 1fr) 0px;
  }

  @media (min-width: 768px) {
    .sidebar {
      grid-template-columns: minmax(0px, 1fr) 20rem;
    }
  }
</style>

<svelte:head>
  <title>{emailAddress}</title>
</svelte:head>

{#if 'me' in state && state.me}
  <div class="w-full mx-auto max-w-3xl grid sidebar md:max-w-5xl">
    <div class="">
      <div class="" bind:this={root}>
        {#each memos as memo}
          <MemoComponent
            {memo}
            active={noteSelection[memo.position] || {}}
            open={memo.position >= contact.thread.acknowledged || memo.position === focus}
            thread={memos} />
        {:else}
          <h1 class="text-center text-2xl my-4 text-gray-700">
            Contact
            <span class="font-bold">{emailAddress}</span>
          </h1>
        {/each}
      </div>
      <article
        class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md sticky bottom-0 border overflow-y-auto"
        style="max-height: 60vh;">
        {#if reply}
          {#if preview}
            <header class="ml-12 mb-6 flex text-gray-600">
              <span class="font-bold">{state.me.email_address}</span>
              <span class="ml-auto">{new Date().toLocaleDateString()}</span>
            </header>
            <Fragment {blocks} thread={memos} />
            {#each suggestions as block, index}
              Suggestion
              {index + blocks.length}

              <BlockComponent
                {block}
                thread={memos}
                index={index + blocks.length} />
              <div class="pl-12 my-1 flex">
                <div>
                  Ask
                  <select bind:value={choices[index].ask}>
                    <option value="everyone">Everyone</option>
                    <option value="tim">tim</option>
                    <option value="bill">Bill</option>
                  </select>
                </div>
                <div>
                  For
                  <select bind:value={choices[index].when}>
                    <option value="today">Today</option>
                    <option value="no hurry">no hurry</option>
                  </select>
                </div>
              </div>
            {/each}

            <div class="mt-2 pl-12 flex items-center">
              <div class="flex flex-1">
                <!-- TODO this needs to show your email address, or if in header nothing at all -->
                <!-- <span class="font-bold text-gray-700 mr-1">From:</span>
              <input class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" bind:value={contact} type="email" placeholder="Your email address" required> -->
              </div>
              <!-- Icons.TODO s included as string types -->
              <button
                class="flex-grow-0 py-2 px-6 rounded-lg bg-gray-500 focus:bg-gray-700 hover:bg-gray-700 text-white font-bold"
                type="submit"
                on:click={() => {
                  preview = false;
                }}>
                <svg
                  class="fill-current inline w-4 mr-2"
                  xmlns="http://www.w3.org/2000/svg"
                  enable-background="new 0 0 24 24"
                  viewBox="0 0 24 24">
                  <path
                    d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z" />
                  <path
                    d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z" />
                </svg>
                Back
              </button>
              {#if sendStatus === 'available'}
                <button
                  class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold"
                  on:click={() => alert('send message')}>
                  <Icons.Send />
                  Send
                </button>
              {:else if sendStatus === 'working'}
                <button
                  class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold">
                  <Icons.Send />
                  Sending
                </button>
              {:else if sendStatus === 'suceeded'}
                <button
                  class="flex-grow-0 py-2 px-6 rounded-lg bg-green-500 focus:bg-green-700 hover:bg-green-700 text-white font-bold">
                  <Icons.Send />
                  Sent
                </button>
              {:else if sendStatus === 'failed'}
                <button
                  class="flex-grow-0 py-2 px-6 rounded-lg bg-red-500 focus:bg-red-700 hover:bg-red-700 text-white font-bold">
                  <Icons.Send />
                  Failed to send message
                </button>
              {/if}
            </div>
          {:else}
            <!-- Could do an on submit and catch whats inside -->
            <!-- TODO name previous inside composer -->
            <Composer
              {memos}
              bind:draft
              {annotations}
              on:clearAnnotation={clearAnnotation} />
            <div class="mt-2 pl-12 flex items-center">
              <div class="flex flex-1">
                <span class="font-bold text-gray-700 mr-1">From:</span>
                <input
                  class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700"
                  bind:value={state.me.email_address}
                  type="email"
                  placeholder="Your email address"
                  readonly
                  required />
              </div>
              <button
                class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold"
                type="submit"
                on:click={() => {
                  preview = true;
                }}>
                <svg
                  class="fill-current inline w-4 mr-2"
                  xmlns="http://www.w3.org/2000/svg"
                  enable-background="new 0 0 24 24"
                  viewBox="0 0 24 24">
                  <path
                    d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z" />
                  <path
                    d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z" />
                </svg>
                Preview
              </button>
            </div>
          {/if}
        {:else}
          {#if activeAction}
            <div
              class="truncate ml-12 border-gray-600 border-l-4 px-2 text-gray-600">
              {#each Writing.summary(activeAction.fragment) as span, index}
                <SpanComponent {span} {index} unfurled={false} />
              {/each}
            </div>
          {/if}
          <nav class="flex pl-12">
            {#if activeAction}
              <button
                on:click={activeAction.callback}
                class="flex items-center bg-gray-800 text-white ml-auto rounded px-2">
                <span class="w-5 mr-2 inline-block">
                  <Icons.Quote />
                </span>
                <span class="py-1">Quote in Reply</span>
              </button>
            {:else}
              <button
                class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2">
                <span class="w-5 mr-2 inline-block">
                  <Icons.Pin />
                </span>
                <span class="py-1">Pins</span>
              </button>
              {#if Social.isOutstanding(contact.thread)}
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
                  <!-- TODO Icons.scribe  -->
                  {#if draft.trim().length !== 0}Draft{:else}Reply{/if}
                </span>
              </button>
            {/if}
          </nav>
        {/if}
      </article>
    </div>
    <div class="">
      <ul class="max-w-sm w-full sticky overflow-hidden" style="top:0.25rem">
        {#each Conversation.findPinnable(memos) as pin}
          <li
            class="mb-1 mx-1 px-1 truncate  cursor-pointer text-gray-700 hover:text-purple-700 border-2 rounded flex items-center">
            {#if pin.item.type === 'link'}
              <LinkComponent
                url={pin.item.url}
                title={pin.item.title}
                index={0} />
            {:else if pin.item.type === 'annotation'}
              <!-- TODO remove dummy index -->

              <span class="w-5 inline-block mr-2">
                <Icons.Attachment />
              </span>
              {#each Writing.summary(Conversation.followReference(pin.item.reference, memos)) as span, index}
                <SpanComponent {span} {index} unfurled={false} />
              {/each}
            {/if}
          </li>
        {:else}
          <li class="mb-1 mx-1 px-1">No items pinned yet.</li>
        {/each}
      </ul>
    </div>
  </div>
{:else}TODO rest of contact page{/if}
