<script>
  import {onMount} from "svelte"
  import Glance from "../glance/Glance.svelte"
  import Note from "../components/Note.svelte"
  import Block from "../components/Block.svelte"
  const PARAGRAPH = "paragraph";
  const TEXT = "text";
  const LINK = "link";
  const ANSWER = "answer";

  function parseLine(line, offset) {
    // Can't end with |(.+\?) because question capture will catch all middle links
    // Questionmark in the body of a link causes confusion, not good if people are making their own questions
    // const tokeniser = /(?:\[([^\[]+)\]\(([^\(]*)\))|(?:(?:\s|^)(https?:\/\/[\w\d./?=#]+))|(^.+\?)/gm
    const tokeniser = /(?:\[([^\[]*)\]\(([^\(]+)\))|(?:(?:\s|^)(https?:\/\/[\w\d./?=#]+))/gm
    const output = []
    let cursor = 0;
    let token
    while (token = tokeniser.exec(line)) {
      const unmatched = line.substring(cursor, token.index).trim()
      cursor = tokeniser.lastIndex
      const start = offset + token.index
      let range = document.createRange()

      if (unmatched) {
        output.push({type: TEXT, text: unmatched, start})
      }
      if (token[3] !== undefined) {
        output.push({type: LINK, url: token[3], start})
      } else if (token[2] !== undefined) {
        output.push({type: LINK, url: token[2], title: token[1], start})
      } else  {
        throw "should be handled"
      }
    }
    const unmatched = line.substring(cursor).trim()
    if (unmatched) {
      output.push({type: TEXT, text: unmatched})
    }
    return output
  }

  function parse(draft) {
    const {doc, node} = draft.split(/\n/).reduce(function ({doc, node, offset}, line) {
      if (line.trim() == "") {
        // close node
        if (node.type === PARAGRAPH) {
          doc.push(node)
          node = false
        } else {
          // do nothing no node
        }

      } else {
        // append line
        node = node || {type: PARAGRAPH, spans: []}
        // TODO merge same text
        // Called softbreak from markdown even thought rendered with br
        node.spans = node.spans.concat(...parseLine(line, offset), {type: "softbreak"})
      }
      // plus one for the newline
      offset = offset + line.length + 1
      return {doc, node, offset}
    }, {doc: [], node: false, offset: 0})
    // close node
    if (node.type === PARAGRAPH) {
      doc.push(node)
    }
    return doc
  }

  onMount(() => {
    document.addEventListener('selectionchange', handleSelectionChange)
    return () => document.removeEventListener('selectionchange', handleSelectionChange)
  })

  function getSelection() {
    const domSelection = window.getSelection()
    if (domSelection === null) {
      throw "Why would there be no selection"
    } else {
      return domSelection
    }
  }

  const domSelection = getSelection();
  let domRange
  function handleSelectionChange() {
    domRange = domSelection.getRangeAt(0);
  }

  let annotations = [
  ]
  function mapAnnotation({reference, raw}) {
    return {
      type: "annotation",
      reference,
      blocks: parse(raw)
    }
  }

  // DOESNT WORK ON ACTIVE message
  function addAnnotation(note, path) {
    console.log(note, path);
    const reference = {note, path}
    const raw = ""
    annotations = [...annotations, {reference, raw}]
  }

  function clearAnnotation(index) {
    annotations.splice(index, 1)
    annotations = annotations
  }


  let draft = "";
  let previous = [
      // tasks annotation suggestion
      // choose your dinner
      // pay the bill
      // make a comment
      // answer the question
      // denomalise fn
  ]
  let notes
  $: notes = previous.concat({elements: [...(annotations.map(mapAnnotation)), ...parse(draft)]})



  function send() {
    previous = notes;
    annotations = [];
    draft = "";
  }


  // TODO deduplicae
  function displayReference(reference, notes) {
    let note = notes[reference.note]
    let [top, ...rest] = reference.path
    if (rest.length != 0) {
      throw "doesn't support deep path yet"
    }
    let element = note.elements[top]
    return [element]
  }
  window.loadState = function functionName(x) {
    previous = x
  }

</script>

<style media="screen">
  textarea.message {
    min-height:8rem;
    max-height:60vh;
  }
</style>

<div class="min-h-screen bg-gray-200">
  <main class="mx-auto max-w-3xl">
    {#each notes as {elements}, index}
    <Note {elements} {domRange} {notes} {index} on:annotate={({detail}) => { addAnnotation(index, detail.path) }}/>
    {/each}
    <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
      {#each annotations as {reference}, index}
      <div class="flex">
        <div class="w-8 m-2 cursor-pointer flex-none" on:click={() => clearAnnotation(index)}>
          <svg class="w-full p-1 fill-current text-gray-700" viewBox="-40 0 427 427.00131" xmlns="http://www.w3.org/2000/svg"><path d="m232.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0"/><path d="m114.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0"/><path d="m28.398438 127.121094v246.378906c0 14.5625 5.339843 28.238281 14.667968 38.050781 9.285156 9.839844 22.207032 15.425781 35.730469 15.449219h189.203125c13.527344-.023438 26.449219-5.609375 35.730469-15.449219 9.328125-9.8125 14.667969-23.488281 14.667969-38.050781v-246.378906c18.542968-4.921875 30.558593-22.835938 28.078124-41.863282-2.484374-19.023437-18.691406-33.253906-37.878906-33.257812h-51.199218v-12.5c.058593-10.511719-4.097657-20.605469-11.539063-28.03125-7.441406-7.421875-17.550781-11.5546875-28.0625-11.46875h-88.796875c-10.511719-.0859375-20.621094 4.046875-28.0625 11.46875-7.441406 7.425781-11.597656 17.519531-11.539062 28.03125v12.5h-51.199219c-19.1875.003906-35.394531 14.234375-37.878907 33.257812-2.480468 19.027344 9.535157 36.941407 28.078126 41.863282zm239.601562 279.878906h-189.203125c-17.097656 0-30.398437-14.6875-30.398437-33.5v-245.5h250v245.5c0 18.8125-13.300782 33.5-30.398438 33.5zm-158.601562-367.5c-.066407-5.207031 1.980468-10.21875 5.675781-13.894531 3.691406-3.675781 8.714843-5.695313 13.925781-5.605469h88.796875c5.210937-.089844 10.234375 1.929688 13.925781 5.605469 3.695313 3.671875 5.742188 8.6875 5.675782 13.894531v12.5h-128zm-71.199219 32.5h270.398437c9.941406 0 18 8.058594 18 18s-8.058594 18-18 18h-270.398437c-9.941407 0-18-8.058594-18-18s8.058593-18 18-18zm0 0"/><path d="m173.398438 154.703125c-5.523438 0-10 4.476563-10 10v189c0 5.519531 4.476562 10 10 10 5.523437 0 10-4.480469 10-10v-189c0-5.523437-4.476563-10-10-10zm0 0"/></svg>
        </div>
        <div class="w-full">
          <blockquote class="border-purple-500 border-l-4 px-2">
            <div class="opacity-50">
              {#each displayReference(reference, notes) as {type, ...data}, index}
              <Block {type} {data} {index}/>
              {/each}
            </div>
          </blockquote>
          <div class="pl-4">
            <textarea class="w-full outline-none" bind:value={annotations[index].raw} placeholder="Your comment ..."></textarea>
          </div>
        </div>
      </div>
      {/each}
      <textarea class="message w-full outline-none pl-12" bind:value={draft} placeholder="Your message ..."></textarea>
      <div class="mt-2 pl-12 flex">
        <button class="ml-auto py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit" on:click={send}>
          <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
            <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
            <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
          </svg>
          Send
        </button>
      </div>
    </article>

    <!-- <input class="w-full" value="window.loadState('{JSON.stringify(previous)}')"> -->
    <input class="w-full" value="{JSON.stringify(previous)}" on:change={(event) => {previous = JSON.parse(event.target.value)}}>

    <pre>
      <!-- {JSON.stringify(notes, null, 2)} -->
    </pre>
  </main>
</div>
