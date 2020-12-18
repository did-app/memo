<script type="typescript">
  import {onMount} from "svelte"
  // TODO extract the conversation layout page
  import {fetchContact} from "../sync";
  import {parse} from "../note"
  import {getSelected} from "../thread/view"
  import * as Range from "../note/range";
  import {PARAGRAPH, TEXT, LINK, ANNOTATION} from "../note/elements"
  import Composer from "../components/Composer.svelte"
  import Note from "../components/Note.svelte"
  // Need to look up welcome message don't want all of those in client

  export let identifier;
  function emailAddressFor(identifier) {
    return (identifier.indexOf("@") === -1) ? identifier + "@plummail.co" : identifier
  }

  let contact;
  let previous
  fetchContact(emailAddressFor(identifier)).then(function ({data}) {

    // TODO remove put asyn on function above
    setTimeout(async function () {
      console.log(data, "-----------------");
      if (data.threadId !== undefined) {
        const url = "__API_ORIGIN__/threads/" + data.threadId;
        const response = await fetch(url, {
          credentials: "include",
          headers: {accept: "application/json"}
        })
        console.log(response);
        if (response.status === 200) {
          let raw = await response.json();
          console.log(raw);
          contact = data
          previous = raw.notes
        }
      } else {
        contact = data

        if (contact.introduction) {
          previous = [{blocks: parse(contact.introduction), author: contact.emailAddress}];
        } else {
          previous = [];
        }
      }
    }, 1000);
  })

  let draft = "";
  let preview = false;

  // fetch intro data
  async function send() {
    const url = "__API_ORIGIN__/relationship/start";
    const params = {
      contact_id: contact.contactId,
      counter: previous.length,
      content: {blocks: current.blocks}
    }
    console.log(params);
    const response = await fetch(url, {
      method: "POST",
      credentials: "include",
      headers: {
        accept: "application/json",
        "content-type": "application/json"
      },
      body: JSON.stringify(params)
    })
    if (response.status === 200) {
      let raw = await response.json();
      console.log(raw);
    }
    console.log(contact);
    console.log(current);
  }

  // TODO deduplicate in fragment
  let root, selected;
  let noteSelection = {};
  function handleSelectionChange() {
    selected = getSelected(root);
    if (selected.anchor && selected.focus) {
      let {noteIndex: anchorIndex, ...anchor} = selected.anchor;
      let {noteIndex: focusIndex, ...focus} = selected.focus;
      if (anchorIndex === focusIndex) {
        noteSelection = Object.fromEntries([[anchorIndex, {anchor, focus}]])
      } else {
        noteSelection = {};
      }
    } else {
      noteSelection = {};
    }
  }

  onMount(() => {
    document.addEventListener('selectionchange', handleSelectionChange)
    return () => document.removeEventListener('selectionchange', handleSelectionChange)
  })

  let annotations = [];

  function mapAnnotation({reference, raw}) {
    return {
      type: "annotation",
      reference,
      blocks: parse(raw)
    }
  }

  // DOESNT WORK ON ACTIVE message
  function addAnnotation({detail}) {
    const {noteIndex, selection} = detail;
    if (Range.isCollapsed(selection)) {
      const annotation = {type: ANNOTATION, raw: "", reference: {note: noteIndex, path: [selection.anchor.path[0]]}}
      annotations = annotations.concat(annotation)
    } else {
      const annotation = {type: ANNOTATION, raw: "", reference: {note: noteIndex, range: selection}}
      annotations = annotations.concat(annotation)
    }
  }

  function clearAnnotation(index) {
    annotations.splice(index, 1)
    annotations = annotations
  }

  let current
  $: current = {
    blocks: [...(annotations.map(mapAnnotation)), ...parse(draft)],
    author: "emailAddressTODO"
  }
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#if contact}
  <!-- maybe composer doesn't need to have the from field -->
  <!-- TODO a thread component -->

  {#if contact.introduction}
  <!-- TODO pass this message as the notes to the composer -->
  <!-- This goes to a fragment that binds on block -->
  <div class="" bind:this={root}>
    {#each previous as {blocks}}
    <Note {blocks} notes={[]} index={0} author={contact.emailAddress} selection={noteSelection[0]} on:annotate={addAnnotation}/>
    {/each}
  </div>

  {:else}
  <h1 class="text-center text-2xl my-4 text-gray-700">
    Contact <span class="font-bold">{contact.emailAddress}</span>
  </h1>
  {/if}
  <!-- If we put preview outside! -->
  <!-- extract rounding article a a thing -->
  {#if preview}
  <!-- TODO make sure can't always add annotation, or make it work with self -->
  <Note blocks={current.blocks} notes={previous} index={previous.length} author={"me"}>
    <div class="mt-2 pl-12 flex items-center">
      <div class="flex flex-1">
        <!-- TODO this needs to show your email address, or if in header nothing at all -->
        <!-- <span class="font-bold text-gray-700 mr-1">From:</span>
          <input class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" bind:value={contact} type="email" placeholder="Your email address" required> -->
        </div>
        <!-- TODO icons included as string types -->
        <button class="flex-grow-0 py-2 px-6 rounded-lg bg-gray-500 focus:bg-gray-700 hover:bg-gray-700 text-white font-bold" type="submit" on:click={() => {preview = false}}>
          <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
            <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
            <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
          </svg>
          Back
        </button>
        <button class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit" on:click={send}>
          <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
            <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
            <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
          </svg>
          Send
        </button>
      </div>
  </Note>

  {:else}
  <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
    <!-- Could do an on submit and catch whats inside -->
    <!-- TODO name previous inside composer -->
    <Composer bind:annotations notes={previous} bind:draft on:clearAnnotation={clearAnnotation}/>
    <div class="mt-2 pl-12 flex items-center">
      <div class="flex flex-1">
        <!-- TODO this needs to show your email address, or if in header nothing at all -->
        <!-- <span class="font-bold text-gray-700 mr-1">From:</span>
        <input class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" bind:value={contact} type="email" placeholder="Your email address" required> -->
      </div>
      <button class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit" on:click={() => {preview = true}}>
        <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
          <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
          <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
        </svg>
        Preview
      </button>
    </div>
  </article>
  {/if}
  {:else}
  <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
    <div class="w-2/3 bg-gray-200 ml-12 h-4 rounded mb-4">

    </div>
    <div class="w-1/3 bg-gray-200 ml-12 h-4 rounded mb-4">

    </div>
    <div class="w-1/2 bg-gray-200 ml-12 h-4 rounded mb-20">

    </div>
    <!-- Could do an on submit and catch whats inside -->
    <!-- TODO name previous inside composer -->
    <div class="mt-2 pl-12 flex items-center">
      <div class="flex flex-1">
        <!-- TODO this needs to show your email address, or if in header nothing at all -->
        <!-- <span class="font-bold text-gray-700 mr-1">From:</span>
        <input class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" bind:value={contact} type="email" placeholder="Your email address" required> -->
      </div>
      <button class="flex-grow-0 py-2 px-6 rounded-lg bg-gray-500  text-gray-200 font-bold" type="submit" on:click={() => {preview = true}}>
        <!-- <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
          <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
          <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
        </svg> -->
        Loading
      </button>
    </div>
  </article>
  {/if}
</main>
