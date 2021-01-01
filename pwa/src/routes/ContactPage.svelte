<script lang="typescript">
  import router from "page";
  import { onMount } from "svelte";
  import { parse } from "../note";
  import type { Note } from "../note";
  import { ANNOTATION, LINK } from "../note/elements";
  import type { Block, Annotation } from "../note/elements";
  import { isCollapsed } from "../note/range";
  import type { Range } from "../note/range";
  import { getSelected } from "../thread/view";
  import * as Thread from "../thread";
  import type { Reference } from "../thread";
  import * as API from "../sync/api";
  import * as Sync from "../sync";
  import type { Contact } from "../sync/api";
  import type { Failure } from "../sync/client";
  import * as Flash from "../state/flash";
  import Composer from "../components/Composer.svelte";
  import Fragment from "../components/Fragment.svelte";
  import Memo from "../components/Memo.svelte";
  import BlockComponent from "../components/Block.svelte";
  import LinkComponent from "../components/Link.svelte";
  import SpanComponent from "../components/Span.svelte";
  import AttachmentIcon from "../icons/attachment.svelte";

  export let thread: Note[];
  export let threadId: number | undefined;
  export let ack: number;
  export let contactEmailAddress: string;
  export let myEmailAddress: string;

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
  let reply: boolean = threadId === undefined;
  let draft = "";
  let blocks: Block[];
  let preview = false;
  let maxIndex = (thread[thread.length - 1] || { counter: 0 }).counter;
  let outstanding = maxIndex > ack;

  async function sendMessage(): Promise<null> {
    sendStatus = "working";
    let response: { data: Contact } | { error: Failure };
    // safe as there is no thread 0
    if (threadId) {
      response = await API.writeNote(threadId, thread.length + 1, blocks).then(
        function (response) {
          if ("error" in response) {
            return response;
          } else {
            let { latest } = response.data;
            let data = {
              latest,
              ack: latest.counter,
              identifier: {
                // TODO remove this dummy id, contacts have a different set of things i.e. you don't see there id
                id: 99999999,
                email_address: contactEmailAddress,
                greeting: null,
              },
            };
            return { data };
          }
        }
      );
    } else {
      // TODO define thread identifier profile types
      // {thread, identifier} | {emailaddress, maybeGreeting}
      response = await API.startRelationship(contactEmailAddress, blocks);
    }
    if ("error" in response) {
      sendStatus = "failed";
      return null;
    }

    Sync.updateContact(response.data);

    sendStatus = "suceeded";
    // reportSuccess("Message sent");
    // TODO redirect immediatly keep message is sending at the top
    Flash.set(["You message was sent"]);
    router.redirect("/");
    return null;
  }

  let root: HTMLElement;
  // map to navigate note id and section within that note
  let noteSelection: Record<
    number,
    Record<number, undefined | (() => void)>
  > = {};
  function handleSelectionChange() {
    const selected = getSelected(root);
    if (selected && selected.anchor && selected.focus) {
      let { noteIndex: anchorIndex, ...anchor } = selected.anchor;
      let { noteIndex: focusIndex, ...focus } = selected.focus;
      if (anchorIndex === focusIndex) {
        noteSelection = Object.fromEntries([
          [
            anchorIndex,
            Object.fromEntries([
              [
                anchor.path[0],
                function () {
                  // console.log(
                  //   Tree.extractBlocks(thread[anchorIndex].blocks, {
                  //     anchor,
                  //     focus,
                  //   })[1]
                  // );
                  addAnnotation(anchorIndex, { anchor, focus });
                },
              ],
            ]),
          ],
        ]);
      } else {
        noteSelection = {};
      }
    } else {
      noteSelection = {};
    }
  }

  onMount(() => {
    document.addEventListener("selectionchange", handleSelectionChange);
    return () =>
      document.removeEventListener("selectionchange", handleSelectionChange);
  });

  let prompts = Thread.gatherPrompts(thread, myEmailAddress);

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
  function addAnnotation(noteIndex: number, range: Range) {
    if (isCollapsed(range)) {
      const annotation = {
        type: ANNOTATION,
        raw: "",
        reference: { note: noteIndex, blockIndex: range.anchor.path[0] },
      };
      annotations = annotations.concat(annotation);
    } else {
      const annotation = {
        type: ANNOTATION,
        raw: "",
        reference: { note: noteIndex, range: range },
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
    let mappedAnnotations: Annotation[] = annotations.flatMap(mapAnnotation);
    let b = content ? [...mappedAnnotations, ...content] : mappedAnnotations;
    // suggestions = Thread.makeSuggestions(b);
    console.log("choice maping");

    choices = suggestions.map(function () {
      return { ask: "everyone", when: "no hurry" };
    });
    return b;
  })();

  function acknowledge() {
    if (threadId) {
      API.acknowledge(threadId, maxIndex);
      // Could wait for it to work, need regular erroring buttons
      outstanding = false;
    } else {
      throw "Should not be able to acknowledge without thread";
    }
  }
</script>

<svelte:head>
  <title>{contactEmailAddress}</title>
</svelte:head>

<div class="flex w-full mx-auto max-w-6xl">
  <div class="flex-1">
    <!-- TODO pass this message as the notes to the composer -->
    <!-- This goes to a fragment that binds on block -->
    <div class="" bind:this={root}>
      {#each thread as memo, index}
        <Memo
          {memo}
          active={noteSelection[index] || {}}
          open={memo.counter >= ack || memo.counter === focus}
          {index}
          {thread} />
      {:else}
        <h1 class="text-center text-2xl my-4 text-gray-700">
          Contact
          <span class="font-bold">{contactEmailAddress}</span>
        </h1>
      {/each}
    </div>
    {#if reply}
      <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md">
        {#if preview}
          <!-- TODO make sure can't always add annotation, or make it work with self -->
          <!-- TODO make sure spans paragraphs notes can't be empty -->
          <header class="ml-12 mb-6 flex text-gray-600">
            <span class="font-bold">{myEmailAddress}</span>
            <span class="ml-auto">{new Date().toLocaleDateString()}</span>
          </header>
          <Fragment {blocks} {thread} />
          {#each suggestions as block, index}
            Suggestion
            {index + blocks.length}

            <BlockComponent {block} {thread} index={index + blocks.length} />
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
            <!-- TODO icons included as string types -->
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
                on:click={sendMessage}>
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
                Send
              </button>
            {:else if sendStatus === 'working'}
              <button
                class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold">
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
                Sending
              </button>
            {:else if sendStatus === 'suceeded'}
              <button
                class="flex-grow-0 py-2 px-6 rounded-lg bg-green-500 focus:bg-green-700 hover:bg-green-700 text-white font-bold">
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
                Sent
              </button>
            {:else if sendStatus === 'failed'}
              <button
                class="flex-grow-0 py-2 px-6 rounded-lg bg-red-500 focus:bg-red-700 hover:bg-red-700 text-white font-bold">
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
                Failed to send message
              </button>
            {/if}
          </div>
        {:else}
          <!-- Could do an on submit and catch whats inside -->
          <!-- TODO name previous inside composer -->
          <Composer
            notes={thread}
            bind:draft
            {annotations}
            on:clearAnnotation={clearAnnotation} />
          <div class="mt-2 pl-12 flex items-center">
            <div class="flex flex-1">
              <span class="font-bold text-gray-700 mr-1">From:</span>
              <input
                class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700"
                bind:value={myEmailAddress}
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
      </article>
    {:else}
      <nav class="text-right">
        {#if outstanding}
          <button
            on:click={acknowledge}
            class="py-2 mx-2 px-4 rounded-lg bg-gray-500 focus:bg-gray-700 hover:bg-gray-700 text-white font-bold">Acknowledge</button>
        {/if}
        <button
          on:click={() => (reply = true)}
          class="py-2 mx-2 px-4 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold">Reply</button>
      </nav>
    {/if}
  </div>
  <ul class="px-2 max-w-sm w-full flex-shrink-0">
    {#each Thread.findPinnable(thread) as pin}
      <li
        class="my-1 p-1 truncate bg-white cursor-pointer text-gray-700 hover:text-purple-700 shadow-lg hover:shadow-xl rounded">
        {#if pin.type === LINK}
          <LinkComponent url={pin.item.url} title={pin.item.title} index={0} />
        {:else if pin.type === ANNOTATION}
          <!-- TODO remove dummy index -->

          <span class="w-5 inline-block">
            <AttachmentIcon />
          </span>
          <!-- {#each [Thread.followReference(pin.item.reference, thread)[0]] as block, index}
          <BlockComponent {block} {index} {thread} truncate={true} />
        {/each} -->
          <!-- TODO summary spans function -->
          {#each Thread.summary(Thread.followReference(pin.item.reference, thread)) as span, index}
            <SpanComponent {span} {index} unfurled={false} />
          {/each}
        {/if}
      </li>
    {/each}
  </ul>
</div>
