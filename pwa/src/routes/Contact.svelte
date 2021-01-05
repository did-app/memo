<script lang="typescript">
  import { onMount } from "svelte";
  import { autoResize } from "../svelte/textarea";
  import type { Reference, Memo } from "../conversation";
  import * as Conversation from "../conversation";
  import * as Social from "../social";
  import type { State, Authenticated } from "../sync";
  import * as Sync from "../sync";
  import type { Block, Annotation, Prompt } from "../writing";
  import * as Writing from "../writing";

  import Fragment from "../components/Fragment.svelte";
  import MemoComponent from "../components/Memo.svelte";
  import BlockComponent from "../components/Block.svelte";
  import LinkComponent from "../components/Link.svelte";
  import SpanComponent from "../components/Span.svelte";
  import * as Icons from "../icons";

  export let state: State;
  export let emailAddress: string;
  state = state as Authenticated;

  // TODO this needs to be a promise of old ones we load up
  let contact = Social.contactForEmailAddress(state.contacts, emailAddress);

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
        // TODO I think we need an on distroy
        if (id) {
          target = parseInt(id);
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

  let userFocus: Reference | null = null;
  let focusSnapshot: Reference | null = null;
  function handleSelectionChange() {
    userFocus = Conversation.getReference(root);
    if (userFocus) {
      reply = false;
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

  let loading = Sync.loadMemos(contact.thread.id).then(function (response) {
    if ("data" in response) {
      let memos = response.data;
      let references = Conversation.gatherPrompts(memos, state.me.emailAddress);
      annotations = references.map(function (reference) {
        return { reference, raw: "" };
      });
    }

    return response;
  });

  function mapAnnotation(draft: {
    reference: Reference;
    raw: string;
  }): Annotation[] {
    const { reference, raw } = draft;
    let blocks = Writing.parse(raw);
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

  type AnnotationSpace = {
    reference: Reference;
    raw: string;
  };
  let annotations: AnnotationSpace[] = [];

  // DOESNT WORK ON ACTIVE message
  function quoteInReply() {
    if (focusSnapshot === null) {
      console.warn("Shouldn't be quoting without focus");
    } else {
      let annotation = { reference: focusSnapshot, raw: "" };
      annotations = [...annotations, annotation];
    }
    reply = true;
  }

  function clearAnnotation(index: number) {
    annotations.splice(index, 1);
    annotations = annotations;
  }

  // I still think at the end we should pull out very flat variables. but helpers work on known data types

  $: blocks = (function (): Block[] {
    let content = Writing.parse(draft);
    let mappedAnnotations: Annotation[] = annotations.flatMap(mapAnnotation);
    return content ? [...mappedAnnotations, ...content] : mappedAnnotations;
  })();
  let current: Memo;
  $: nextPosition = contact.thread.latest.position + 1;
  $: current = {
    content: blocks,
    author: state.me.emailAddress,
    posted_at: new Date(),
    position: nextPosition,
  };
  let suggestedPrompts: Prompt[] = [];
  $: suggestedPrompts = preview
    ? suggestedPrompts
    : Conversation.makeSuggestions(blocks, nextPosition);
  function clearPrompt(index: number) {
    suggestedPrompts.splice(index, 1);
    suggestedPrompts = suggestedPrompts;
  }

  function postMemo() {
    Sync.postMemo(contact, [...blocks, ...suggestedPrompts], nextPosition);
  }
  function acknowledge() {
    // TODO this is a background thing we should switch back almost straight away.
    // Working message in the top
    // Tasks list in the state
    throw "TODO acknowledge";
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
  textarea.message {
    min-height: 8rem;
  }
  textarea.comment {
    max-height: 25vh;
  }
</style>

<svelte:head>
  <title>{emailAddress}</title>
</svelte:head>

{JSON.stringify(blocks)}
{#if 'me' in state && state.me}
  {#await loading}
    LOADING
  {:then response}
    {#if 'data' in response}
      <div class="w-full mx-auto max-w-3xl grid sidebar md:max-w-5xl">
        <div class="">
          <div class="" bind:this={root}>
            {#each response.data as memo}
              <MemoComponent
                {memo}
                open={memo.position >= contact.thread.acknowledged || memo.position === target}
                peers={response.data} />
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
                  <span class="font-bold">{state.me.emailAddress}</span>
                  <span class="ml-auto">{new Date().toLocaleDateString()}</span>
                </header>
                <Fragment {blocks} peers={response.data} />
                {#if suggestedPrompts.length !== 0}
                  <h3 class="ml-12 font-bold mt-4">
                    Ask the following as highlighted questions.
                  </h3>
                {/if}
                {#each suggestedPrompts as prompt, index}
                  <div class="flex my-1">
                    <div
                      class="w-8 m-1 cursor-pointe preview ? suggestedPrompts :r flex-none"
                      on:click={() => clearPrompt(index)}>
                      <div class="w-6">
                        <Icons.Bin />
                      </div>
                    </div>
                    <div>
                      {#each Conversation.followReference(prompt.reference, [
                        ...response.data,
                        current,
                      ]) as block, index}
                        <BlockComponent {block} {index} peers={response.data} />
                      {/each}
                    </div>
                  </div>
                {/each}

                <div class="mt-2 pl-12 flex items-center">
                  <div class="flex flex-1" />
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
                      on:click={postMemo}>
                      <span class="inline-block w-4 mr-2">
                        <Icons.Send />
                      </span>
                      Send
                    </button>
                  {:else if sendStatus === 'working'}
                    <button
                      class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold">
                      <span class="inline-block w-4 mr-2">
                        <Icons.Send />
                      </span>
                      Sending
                    </button>
                  {:else if sendStatus === 'suceeded'}
                    <button
                      class="flex-grow-0 py-2 px-6 rounded-lg bg-green-500 focus:bg-green-700 hover:bg-green-700 text-white font-bold">
                      <span class="inline-block w-4 mr-2">
                        <Icons.Send />
                      </span>
                      Sent
                    </button>
                  {:else if sendStatus === 'failed'}
                    <button
                      class="flex-grow-0 py-2 px-6 rounded-lg bg-red-500 focus:bg-red-700 hover:bg-red-700 text-white font-bold">
                      <span class="inline-block w-4 mr-2">
                        <Icons.Send />
                      </span>
                      Failed to send message
                    </button>
                  {/if}
                </div>
              {:else}
                <!-- TODO name previous inside composer -->
                {#each annotations as { reference }, index}
                  <div class="flex my-1">
                    <div
                      class="w-8 m-2 cursor-pointer flex-none"
                      on:click={() => clearAnnotation(index)}>
                      <div class="w-4">
                        <Icons.Bin />
                      </div>
                    </div>
                    <div class="w-full border-purple-500 border-l-4">
                      <blockquote class=" px-2">
                        <div class="opacity-50">
                          {#each Conversation.followReference(reference, response.data) as block, index}
                            <BlockComponent
                              {block}
                              {index}
                              peers={response.data} />
                          {/each}
                        </div>
                        <a
                          class="text-purple-800"
                          href="#{reference.memoPosition}"><small>{response.data[reference.memoPosition - 1].author}</small></a>
                      </blockquote>
                      <div class="px-2">
                        <textarea
                          class="comment w-full bg-white outline-none"
                          bind:value={annotations[index].raw}
                          use:autoResize
                          rows="1"
                          autofocus
                          placeholder="Your comment ..." />
                      </div>
                    </div>
                  </div>
                {/each}
                <textarea
                  class="message w-full bg-white outline-none pl-12"
                  use:autoResize
                  bind:value={draft}
                  placeholder="Your message ..." />
                <div class="mt-2 pl-12 flex items-center">
                  <div class="flex flex-1">
                    <span class="font-bold text-gray-700 mr-1">From:</span>
                    <input
                      class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700"
                      bind:value={state.me.emailAddress}
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
              {#if userFocus}
                <div
                  class="truncate ml-12 border-gray-600 border-l-4 px-2 text-gray-600">
                  <!-- {#each Writing.summary(Conversation.followReference(userFocus, response.data)) as span, index}
                    <SpanComponent {span} {index} unfurled={false} />
                  {/each} -->
                  {#each Conversation.followReference(userFocus, [
                    ...response.data,
                    current,
                  ]) as block, index}
                    <BlockComponent {block} {index} peers={response.data} />
                  {/each}
                </div>
              {/if}
              <nav class="flex pl-12">
                {#if userFocus}
                  <button
                    on:click={quoteInReply}
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
                  {#if Conversation.isOutstanding(contact.thread)}
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
          <ul
            class="max-w-sm w-full sticky overflow-hidden"
            style="top:0.25rem">
            {#each Conversation.findPinnable(response.data) as pin}
              <li
                class="mb-1 mx-1 px-1 truncate  cursor-pointer text-gray-700 hover:text-purple-700 border-2 rounded flex items-center">
                {#if pin.item.type === 'link'}
                  <LinkComponent
                    url={pin.item.url}
                    title={pin.item.title}
                    index={0} />
                {:else if pin.item.type === 'annotation'}
                  <!-- TODO remove dummy index, simply make it optional -->

                  <span class="w-5 inline-block mr-2">
                    <Icons.Attachment />
                  </span>
                  {#each Writing.summary(Conversation.followReference(pin.item.reference, response.data)) as span, index}
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
    {/if}
  {/await}
{:else}TODO rest of contact page{/if}
