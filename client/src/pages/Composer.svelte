<script>
  import {onMount} from "svelte"
  import Glance from "../glance/Glance.svelte"
  import Note from "../components/Note.svelte"
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
        node.spans = node.spans.concat(...parseLine(line, offset))
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

  let draft = "";
  let previous = []
  let notes
  $: notes = previous.concat({elements: parse(draft)})

  function send() {
    previous = previous.concat({elements: parse(draft)})
    draft = ""
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
    <Note {elements} {domRange}/>
    {/each}
    <article class="my-4 py-6 px-12 bg-white rounded-lg shadow-md ">
      <textarea class="message w-full outline-none" bind:value={draft} placeholder="Your message ..."></textarea>
      <div class="mt-2 flex">
        <button class="ml-auto py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit" on:click={send}>
          <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
            <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
            <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
          </svg>
          Send
        </button>
      </div>
    </article>

    <pre>
      {JSON.stringify(notes, null, 2)}
    </pre>
  </main>
</div>
