<script lang="typescript">
  import { onMount } from "svelte";
  import { autoResize } from "../svelte/textarea";
  import type { Reference } from "../conversation";
  import * as Conversation from "../conversation";
  import * as Social from "../social";
  import type { State, Authenticated } from "../sync";
  import * as Sync from "../sync";
  import type { Block, Annotation } from "../writing";
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

  // let prompts = Thread.gatherPrompts(thread, state.me.email_address);

  // let annotations: { reference: Reference; raw: string }[] = prompts.map(
  //   function (prompt) {
  //     return { reference: prompt.reference, raw: "" };
  //   }
  // );

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
  let annotations: AnnotationSpace[] = [
    {
      raw: "",
      reference: {
        memoPosition: 1,
        range: {
          anchor: { path: [0, 0], offset: 0 },
          focus: { path: [0, 0], offset: 2 },
        },
      },
    },
  ];

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

  $: blocks = (function (): Block[] {
    let content = Writing.parse(draft);
    let mappedAnnotations: Annotation[] = annotations.flatMap(mapAnnotation);
    return content ? [...mappedAnnotations, ...content] : mappedAnnotations;
  })();

  function acknowledge() {
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
  {#await Sync.loadMemos(contact.thread.id)}
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
                <!-- {#each suggestions as block, index}
                  Suggestion
                  {index + blocks.length}

                  <BlockComponent
                    {block}
                    peers={response.data}
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
                {/each} -->

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
                      <svg
                        class="w-full p-1 fill-current text-gray-700"
                        viewBox="-40 0 427 427.00131"
                        xmlns="http://www.w3.org/2000/svg"><path
                          d="m232.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0" />
                        <path
                          d="m114.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0" />
                        <path
                          d="m28.398438 127.121094v246.378906c0 14.5625 5.339843 28.238281 14.667968 38.050781 9.285156 9.839844 22.207032 15.425781 35.730469 15.449219h189.203125c13.527344-.023438 26.449219-5.609375 35.730469-15.449219 9.328125-9.8125 14.667969-23.488281 14.667969-38.050781v-246.378906c18.542968-4.921875 30.558593-22.835938 28.078124-41.863282-2.484374-19.023437-18.691406-33.253906-37.878906-33.257812h-51.199218v-12.5c.058593-10.511719-4.097657-20.605469-11.539063-28.03125-7.441406-7.421875-17.550781-11.5546875-28.0625-11.46875h-88.796875c-10.511719-.0859375-20.621094 4.046875-28.0625 11.46875-7.441406 7.425781-11.597656 17.519531-11.539062 28.03125v12.5h-51.199219c-19.1875.003906-35.394531 14.234375-37.878907 33.257812-2.480468 19.027344 9.535157 36.941407 28.078126 41.863282zm239.601562 279.878906h-189.203125c-17.097656 0-30.398437-14.6875-30.398437-33.5v-245.5h250v245.5c0 18.8125-13.300782 33.5-30.398438 33.5zm-158.601562-367.5c-.066407-5.207031 1.980468-10.21875 5.675781-13.894531 3.691406-3.675781 8.714843-5.695313 13.925781-5.605469h88.796875c5.210937-.089844 10.234375 1.929688 13.925781 5.605469 3.695313 3.671875 5.742188 8.6875 5.675782 13.894531v12.5h-128zm-71.199219 32.5h270.398437c9.941406 0 18 8.058594 18 18s-8.058594 18-18 18h-270.398437c-9.941407 0-18-8.058594-18-18s8.058593-18 18-18zm0 0" />
                        <path
                          d="m173.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0" /></svg>
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
                  {#each Writing.summary(Conversation.followReference(userFocus, response.data)) as span, index}
                    <SpanComponent {span} {index} unfurled={false} />
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
