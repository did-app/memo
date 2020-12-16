<script>
  import {onMount} from "svelte"
  import * as Thread from "../thread"
  import {parse} from "../note"
  import {PARAGRAPH, TEXT, LINK, ANNOTATION} from "../note/elements"
  import {getSelected} from "../thread/view"
  import Note from "../components/Note.svelte"
  import Block from "../components/Block.svelte"
  import Paragraph from "../components/Paragraph.svelte"
  import Link from "../components/Link.svelte"


  let root, selected;
  function handleSelectionChange() {
    selected = getSelected(root);
    if (selected.anchor && selected.focus) {
      let {noteIndex: anchorIndex, ...anchor} = selected.anchor;
      let {noteIndex: focusIndex, ...focus} = selected.focus;
      if (anchorIndex === focusIndex) {
        console.log(anchor, focus);
        console.log(notes[anchorIndex]);
      }
    }

  }

  onMount(() => {
    document.addEventListener('selectionchange', handleSelectionChange)
    return () => document.removeEventListener('selectionchange', handleSelectionChange)
  })

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
  function suggestedActions(notes) {
    const output = []
    notes.forEach(function (note, noteId) {
      note.blocks.forEach(function (block, blockId) {
        if (block.type === PARAGRAPH && block.spans.length > 0) {
          // always ends with softbreak
          const lastSpan = block.spans[block.spans.length - 2]
          if (lastSpan.type === TEXT && lastSpan.text.endsWith("?")) {
            const reference = {note: noteId, path: [blockId]}
            output.push({reference, raw: ""})
          }
        }
      })
    })
    return output
  }

  let previous = [];
  let draft = "";
  let annotations
  annotations = suggestedActions(previous);

  function mapAnnotation({reference, raw}) {
    return {
      type: "annotation",
      reference,
      blocks: parse(raw)
    }
  }

  // DOESNT WORK ON ACTIVE message
  function addAnnotation(note, path) {
    const annotation = {type: ANNOTATION, raw: "", reference: {note, path}}
    annotations = annotations.concat(annotation)
  }

  function clearAnnotation(index) {
    annotations.splice(index, 1)
    annotations = annotations
  }

  let current
  $: current = {
    blocks: [...(annotations.map(mapAnnotation)), ...parse(draft)],
    author: emailAddress
  }
  let notes
  $: notes = previous.concat(current)

  let suggestions
  $: suggestions = makeSuggestions(current)

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
    const output = []
    note.blocks.forEach(function (block, blockId) {
      if (block.type === PARAGRAPH && block.spans.length > 0) {
        // always ends with softbreak
        const lastSpan = block.spans[block.spans.length - 2]
        if (lastSpan.type === TEXT && lastSpan.text.endsWith("?")) {
          const reference = {note: previous.length, path: [blockId]}
          let choice = choices[blockId] || {dismissed: false, ask: "everyone"}
          choices[blockId] = choice
          output.push({reference, ...choice})
        }
      }
    })
    return output
  }

  function findPins(notes) {
    return notes.map(function (note, noteId) {
      return note.blocks.map(function ({spans}) {
        return (spans || []).filter(function (span, blockId) {
          return span.type === LINK
        })
      })
      .flat()
    })
    .flat()
  }

  let pins = [];
  $: pins = findPins(notes)

  let emailAddress
  function send() {
    previous = notes;
    annotations = suggestedActions(previous);
    draft = "";
  }
</script>

<style media="screen">
  textarea.message {
    min-height:8rem;
    max-height:60vh;
  }
  .grid {
    display: grid;
    /* grid-template-columns: 0 42rem 1fr */
    grid-template-columns: 0 42rem 1fr
  }
  @media (min-width: 1280px) {
    .grid {
      grid-template-columns: 1fr 42rem 1fr
    }
  }

</style>

<div class="min-h-screen bg-gray-200 grid">
  <div class="">
  </div>
  <main class="px-2 w-full max-w-2xl">
    <div class="" bind:this={root}>
      {#each notes as data, index}
      <Note {...data} {notes} {index} on:annotate={({detail}) => { addAnnotation(index, detail.path) }}/>
        {/each}
    </div>
    <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
      {#each annotations as {reference}, index}
      <div class="flex">
        <div class="w-8 m-2 cursor-pointer flex-none" on:click={() => clearAnnotation(index)}>
          <svg class="w-full p-1 fill-current text-gray-700" viewBox="-40 0 427 427.00131" xmlns="http://www.w3.org/2000/svg"><path d="m232.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0"/><path d="m114.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0"/><path d="m28.398438 127.121094v246.378906c0 14.5625 5.339843 28.238281 14.667968 38.050781 9.285156 9.839844 22.207032 15.425781 35.730469 15.449219h189.203125c13.527344-.023438 26.449219-5.609375 35.730469-15.449219 9.328125-9.8125 14.667969-23.488281 14.667969-38.050781v-246.378906c18.542968-4.921875 30.558593-22.835938 28.078124-41.863282-2.484374-19.023437-18.691406-33.253906-37.878906-33.257812h-51.199218v-12.5c.058593-10.511719-4.097657-20.605469-11.539063-28.03125-7.441406-7.421875-17.550781-11.5546875-28.0625-11.46875h-88.796875c-10.511719-.0859375-20.621094 4.046875-28.0625 11.46875-7.441406 7.425781-11.597656 17.519531-11.539062 28.03125v12.5h-51.199219c-19.1875.003906-35.394531 14.234375-37.878907 33.257812-2.480468 19.027344 9.535157 36.941407 28.078126 41.863282zm239.601562 279.878906h-189.203125c-17.097656 0-30.398437-14.6875-30.398437-33.5v-245.5h250v245.5c0 18.8125-13.300782 33.5-30.398438 33.5zm-158.601562-367.5c-.066407-5.207031 1.980468-10.21875 5.675781-13.894531 3.691406-3.675781 8.714843-5.695313 13.925781-5.605469h88.796875c5.210937-.089844 10.234375 1.929688 13.925781 5.605469 3.695313 3.671875 5.742188 8.6875 5.675782 13.894531v12.5h-128zm-71.199219 32.5h270.398437c9.941406 0 18 8.058594 18 18s-8.058594 18-18 18h-270.398437c-9.941407 0-18-8.058594-18-18s8.058593-18 18-18zm0 0"/><path d="m173.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0"/></svg>
        </div>
        <div class="w-full">
          <blockquote class="border-purple-500 border-l-4 px-2">
            <div class="opacity-50">
              {#each Thread.followReference(reference, notes) as {type, ...data}, index}
              <Block {type} {data} {index}/>
              {/each}
            </div>
            <a class="text-purple-800" href="#{reference.note}"><small>{notes[reference.note].author}</small></a>
          </blockquote>
          <div class="pl-4">
            <textarea class="w-full outline-none" bind:value={annotations[index].raw} placeholder="Your comment ..."></textarea>
          </div>
        </div>
      </div>
      {/each}
      <textarea class="message w-full outline-none pl-12" bind:value={draft} placeholder="Your message ..."></textarea>
      {#each suggestions as {dismissed, ask}, index}
      <div class="pl-12 my-1">
        Ask question to <select bind:value={choices[index].ask}>
          <option value="everyone">Everyone</option>
          <option value="tim">tim</option>
          <option value="bill">Bill</option>
        </select>
      </div>
      {/each}
      <div class="mt-2 pl-12 flex items-center">
        <div class="flex flex-1">
          <span class="font-bold text-gray-700 mr-1">From:</span>
          <input class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" bind:value={emailAddress} type="email" placeholder="Your email address" required>
        </div>
        <button class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit" on:click={send}>
          <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
            <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
            <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
          </svg>
          Send
        </button>
      </div>
    </article>
    <h2 class="my-2 font-bold text-gray-400 text-2xl">Debug</h2>
    <input class="w-full" value="{JSON.stringify(previous)}" on:change={(event) => {
      previous = JSON.parse(event.target.value);
      annotations = suggestedActions(previous);
    }}>
    <pre>
      <!-- {JSON.stringify(notes, null, 2)} -->
      {JSON.stringify(choices, null, 2)}
    </pre>
  </main>
  <div>
    <ul class="sticky my-4 px-2 top-0 max-w-sm">
      {#each pins as data}
      <li class="my-1 bg-white cursor-pointer text-gray-700 hover:text-purple-700 shadow-lg hover:shadow-xl rounded">
        <Link {...data}/>
      </li>
      {/each}
    </ul>
  </div>
</div>
