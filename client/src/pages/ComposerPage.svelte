<script>
  import { onMount } from "svelte";
  import { parse } from "../memo";
  import { PARAGRAPH, TEXT, LINK, ANNOTATION } from "../memo/elements";
  import { getSelected } from "../thread/view";
  import * as Range from "../memo/range";
  import Note from "../components/Note.svelte";
  import Link from "../components/Link.svelte";
  import Composer from "../components/Composer.svelte";

  let root, selected;
  let noteSelection = {};
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

  // iterate through would be nice to not pass noted down
  // however we want lazy loading of comments on notes in other conversations
  // can return a promise that we map in.
  // Need to see comments that have been replied to
  // suggestions NOT made from notes they are deliberate

  // compose with to/subject looking like a message
  // makes those the options of who to write as
  // iterate through notes, pick up all tasks with author audience etc
  // Quote/Annotate a Slice
  // Down at the bottom for actions like slice pin

  // iterate up find all annotations
  // for each block see if it has a later annotation
  // could act on the tree to push content into the quote block
  // for each block can add all the annotations
  //
  function suggestedActions(_notes) {
    const output = [];
    // TODO move this to working with the makeSuggestions result
    // notes.forEach(function (note, noteId) {
    //   note.blocks.forEach(function (block, blockId) {
    //     if (block.type === PARAGRAPH && block.spans.length > 0) {
    //       // always ends with softbreak
    //       const lastSpan = block.spans[block.spans.length - 2]
    //       if (lastSpan.type === TEXT && lastSpan.text.endsWith("?")) {
    //         const reference = {note: noteId, path: [blockId]}
    //         output.push({reference, raw: ""})
    //       }
    //     }
    //   })
    // })
    return output;
  }

  let previous = [];
  let draft = "";
  let annotations;
  annotations = suggestedActions(previous);

  function mapAnnotation({ reference, raw }) {
    return {
      type: "annotation",
      reference,
      blocks: parse(raw),
    };
  }

  // DOESNT WORK ON ACTIVE message
  function addAnnotation({ detail }) {
    const { noteIndex, selection } = detail;
    if (Range.isCollapsed(selection)) {
      const annotation = {
        type: ANNOTATION,
        raw: "",
        reference: { note: noteIndex, path: [selection.anchor.path[0]] },
      };
      annotations = annotations.concat(annotation);
    } else {
      const annotation = {
        type: ANNOTATION,
        raw: "",
        reference: { note: noteIndex, range: selection },
      };
      annotations = annotations.concat(annotation);
    }
  }

  // function clearAnnotation(index) {
  //   annotations.splice(index, 1)
  //   annotations = annotations
  // }

  let current;
  $: current = {
    blocks: [...annotations.map(mapAnnotation), ...parse(draft)],
    author: emailAddress,
  };
  let notes;
  $: notes = previous.concat(current);

  let suggestions;
  $: suggestions = makeSuggestions(current);

  let choices = {};
  // Can't put suggestions on node as always rebuilt
  // can merge with node
  // iterate note in preview, what if people don't click preivew need message at the bottom.
  // unfurl link
  // could go through preview then send.
  // which is where we make the comments
  // WORK out how we store the summaries on the backend,
  // Just calculate them in JavaScript that and stick the block on the backend
  // gives the updates for who needs to do what live as you work through.
  function makeSuggestions(note) {
    const output = [];
    note.blocks.forEach(function (block, blockId) {
      if (block.type === PARAGRAPH && block.spans.length > 0) {
        // always ends with softbreak
        const lastSpan = block.spans[block.spans.length - 1];
        if (lastSpan.type === TEXT && lastSpan.text.endsWith("?")) {
          const reference = { note: previous.length, path: [blockId] };
          let choice = choices[blockId] || {
            dismissed: false,
            ask: "everyone",
          };
          choices[blockId] = choice;
          output.push({ reference, ...choice });
        }
      }
    });
    return output;
  }
  let emailAddress;
  function send() {
    previous = notes;
    annotations = suggestedActions(previous);
    draft = "";
  }
</script>

<style media="screen">
  .grid {
    display: grid;
    /* grid-template-columns: 0 42rem 1fr */
    grid-template-columns: 0 42rem 1fr;
  }
  @media (min-width: 1280px) {
    .grid {
      grid-template-columns: 1fr 42rem 1fr;
    }
  }
</style>

<div class="min-h-screen bg-gray-200 grid">
  <div class="" />
  <main class="px-2 w-full max-w-2xl">
    <div class="" bind:this={root}>
      {#each notes as data, index}
        <Note
          {...data}
          {notes}
          {index}
          selection={noteSelection[index]}
          on:annotate={addAnnotation} />
      {/each}
    </div>
    <!-- Suggestions are internal -->
    <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
      <Composer {annotations} {notes} {suggestions} bind:draft />
      <div class="mt-2 pl-12 flex items-center">
        <div class="flex flex-1">
          <span class="font-bold text-gray-700 mr-1">From:</span>
          <input
            class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700"
            bind:value={emailAddress}
            type="email"
            placeholder="Your email address"
            required />
        </div>
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
    <h2 class="my-2 font-bold text-gray-400 text-2xl">Debug</h2>
    <input
      class="w-full"
      value={JSON.stringify(previous)}
      on:change={(event) => {
        previous = JSON.parse(event.target.value);
        annotations = suggestedActions(previous);
      }} />
    <pre>
      {JSON.stringify(notes, null, 2)}
      {JSON.stringify(choices, null, 2)}
    </pre>
  </main>
  <div>
    <ul class="sticky my-4 px-2 top-0 max-w-sm">
      {#each pins as { url, title }}
        <li
          class="my-1 p-1 truncate bg-white cursor-pointer text-gray-700 hover:text-purple-700 shadow-lg hover:shadow-xl rounded">
          <Link {url} {title} />
        </li>
      {/each}
    </ul>
  </div>
</div>
