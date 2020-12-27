<script lang="typescript">
  import { onMount } from "svelte";
  import { parse } from "../note";
  import type { Note } from "../note";
  import { ANNOTATION } from "../note/elements";
  import type { Block } from "../note/elements";
  import { isCollapsed } from "../note/range";
  import type { Range } from "../note/range";
  import { getSelected } from "../thread/view";
  import type { Reference } from "../thread";
  import * as API from "../sync/api";
  import Composer from "../components/Composer.svelte";
  import Fragment from "../components/Fragment.svelte";

  export let thread: Note[];
  export let threadId: number | undefined;
  export let contactEmailAddress: string;
  export let myEmailAddress: string;

  type SendStatus = "available" | "working" | "suceeded" | "failed";
  let sendStatus: SendStatus = "available";

  let draft = "";
  let blocks: Block[];
  let preview = false;

  // TODO load up the messages after sending
  async function sendMessage(): Promise<null> {
    sendStatus = "working";
    // safe as there is no thread 0
    // let response: null | Failure;
    if (threadId) {
      //   response = await API.writeNote(
      //     contact.threadId,
      //     previous.length,
      //     current.blocks
      //   );
    } else {
      // just start the relation ship with blocks and email address
      // people talking to me and richard number one
      // don't send previous.length Can ignore.
      let response = await API.startRelationship(contactEmailAddress, blocks);
      if ("error" in response) {
        sendStatus = "failed";
        throw "some more error needed";
        return null;
      }
      sendStatus = "suceeded";
    }
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

  let annotations: { reference: Reference; raw: string }[] = [];

  function mapAnnotation({
    reference,
    raw,
  }: {
    reference: Reference;
    raw: string;
  }) {
    return {
      type: "annotation",
      reference,
      blocks: parse(raw),
    };
  }

  // DOESNT WORK ON ACTIVE message
  function addAnnotation(noteIndex: number, range: Range) {
    if (isCollapsed(range)) {
      const annotation = {
        type: ANNOTATION,
        raw: "",
        reference: { note: noteIndex, path: [range.anchor.path[0]] },
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
    console.log(annotations, "vlearing");

    annotations.splice(event.detail, 1);
    annotations = annotations;
  }

  $: blocks = [...annotations.map(mapAnnotation), ...parse(draft)];
</script>

<!-- TODO pass this message as the notes to the composer -->
<!-- This goes to a fragment that binds on block -->
<div class="" bind:this={root}>
  {#each thread as { blocks, author, inserted_at }, index}
    <article
      id={index.toString()}
      data-note-index={index}
      class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md">
      <header class="ml-12 mb-6 flex text-gray-600">
        <span class="font-bold">{author}</span>
        <span class="ml-auto">{inserted_at}</span>
      </header>
      <!-- TODO note Record<a, b>[] returns type b not b | undefined -->
      <Fragment {blocks} active={noteSelection[index] || {}} {thread} />
    </article>
  {:else}
    <h1 class="text-center text-2xl my-4 text-gray-700">
      Contact
      <span class="font-bold">{contactEmailAddress}</span>
    </h1>
  {/each}
</div>
<!-- If we put preview outside! -->
<!-- extract rounding article a a thing -->
{#if preview}
  <!-- TODO make sure can't always add annotation, or make it work with self -->
  <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md">
    <header class="ml-12 mb-6 flex text-gray-600">
      <span class="font-bold" />
      <span class="ml-auto">Draft</span>
    </header>
    <Fragment {blocks} {thread} />
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
  </article>
{:else}
  <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
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
  </article>
{/if}
