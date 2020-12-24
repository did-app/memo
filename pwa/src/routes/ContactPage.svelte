<script lang="typescript">
  import { onMount } from "svelte";
  import { parse } from "../note";
  import type { Note } from "../note";
  import { getSelected } from "../thread/view";
  import type { Reference } from "../thread";
  import Composer from "../components/Composer.svelte";
  // TODO rename fragment
  import Fragment from "../components/Fragment.svelte";

  export let thread: Note[];
  export let contactEmailAddress: string;
  export let myEmailAddress: string;

  let draft = "";
  let preview = false;

  // TODO load up the messages after sending
  async function send(): Promise<null> {
    // safe as there is no thread 0
    // let response: null | Failure;
    // if (contact.threadId) {
    //   response = await API.writeNote(
    //     contact.threadId,
    //     previous.length,
    //     current.blocks
    //   );
    // } else {
    //   response = await API.startRelationship(
    //     contact.id,
    //     previous.length,
    //     current.blocks
    //   );
    // }
    return null;
  }

  // TODO remove any on selected
  let root: HTMLElement, selected: any;
  let noteSelection: Record<number, any> = {};
  function handleSelectionChange() {
    selected = getSelected(root);
    if (selected.anchor && selected.focus) {
      let { noteIndex: anchorIndex, ...anchor } = selected.anchor;
      let { noteIndex: focusIndex, ...focus } = selected.focus;
      if (anchorIndex === focusIndex) {
        noteSelection = Object.fromEntries([[anchorIndex, { anchor, focus }]]);
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
  function addAnnotation({ detail }: { detail: string }) {
    console.log(detail);

    // const {noteIndex, selection} = detail;
    // if (Range.isCollapsed(selection)) {
    //   const annotation = {type: ANNOTATION, raw: "", reference: {note: noteIndex, path: [selection.anchor.path[0]]}}
    //   annotations = annotations.concat(annotation)
    // } else {
    //   const annotation = {type: ANNOTATION, raw: "", reference: {note: noteIndex, range: selection}}
    //   annotations = annotations.concat(annotation)
    // }
  }

  function clearAnnotation(event: { detail: number }) {
    annotations.splice(event.detail, 1);
    annotations = annotations;
  }

  let current: { blocks: any[]; author: string };
  $: current = {
    blocks: [...annotations.map(mapAnnotation), ...parse(draft)],
    author: "emailAddressTODO",
  };
</script>

{#if thread.length !== 0}
  <!-- TODO pass this message as the notes to the composer -->
  <!-- This goes to a fragment that binds on block -->
  <div class="" bind:this={root}>
    {#each thread as { blocks, author, date }, index}
      <article
        id={index.toString()}
        data-note-index={index}
        class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md">
        <header class="ml-12 mb-6 flex text-gray-600">
          <span class="font-bold">{author}</span>
          <span class="ml-auto">{date}</span>
        </header>
        <Fragment
          {blocks}
          notes={[]}
          selection={noteSelection[0]}
          on:annotate={addAnnotation} />
      </article>
    {/each}
  </div>
{:else}
  <h1 class="text-center text-2xl my-4 text-gray-700">
    Contact
    <span class="font-bold">{contactEmailAddress}</span>
  </h1>
{/if}
<!-- If we put preview outside! -->
<!-- extract rounding article a a thing -->
{#if preview}
  <!-- TODO make sure can't always add annotation, or make it work with self -->
  <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md">
    <header class="ml-12 mb-6 flex text-gray-600">
      <span class="font-bold" />
      <span class="ml-auto">Draft</span>
    </header>
    <Fragment blocks={current.blocks} notes={thread} selection={undefined} />
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
      <button
        class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold"
        type="submit"
        on:click={send}>
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
    </div>
  </article>
{:else}
  <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
    <!-- Could do an on submit and catch whats inside -->
    <!-- TODO name previous inside composer -->
    <Composer notes={thread} bind:draft on:clearAnnotation={clearAnnotation} />
    <div class="mt-2 pl-12 flex items-center">
      <div class="flex flex-1">
        <span class="font-bold text-gray-700 mr-1">From:</span>
        <input
          class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700"
          bind:value={myEmailAddress}
          type="email"
          placeholder="Your email address"
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
