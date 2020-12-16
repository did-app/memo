<script>
  import Glance from "../glance/Glance.svelte"
  import Block from "./Block.svelte"

  export let domRange;
  export let elements = [];
  export let author;
  export let notes;
  export let index;
  let root, anchor, focus;

  $: domRangeToRange(domRange, root);

  function domRangeToRange(domRange, root) {
    if (!domRange || !root) {
      return undefined
    }
    const {startContainer, startOffset, endContainer, endOffset} = domRange;
    const startPath = pathFromNode(startContainer, root)
    const endPath = pathFromNode(endContainer, root)
    anchor = startPath ? {path: startPath, offset: startOffset} : undefined
    focus = endPath ? {path: endPath, offset: endOffset} : undefined
  }

  function leafElement(node) {
    return node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement
  }

  function pathFromNode(node, root) {
    let element = leafElement(node)
    if (!root.contains(element)) {
      return undefined
    }
    const path = []
    while (element) {
      // Would need or {} if not for first text node
      let {noteIndex} = element.dataset || {}
      if (noteIndex) {
        path.unshift(parseInt(noteIndex))
      }
      if (element == root) {
        break
      }
      let parent = element.parentElement
      if (parent === null) {
        throw "We should always get to root first"
      }
      element = parent
    }
    return path
  }

  function annotationsForNote(notes, index) {
    // TODO this needs to do author
    return notes
    .map(function ({elements, author}, noteId) {
      return elements
      .filter(function ({type, reference}) {
        return type === "annotation" && reference.note === index
      })
      .map(function ({reference, blocks}) {
        return {reference, blocks, author, note: noteId};
      })
    })
    .flat()
    .reduce(function (state, {reference, ...data}) {
      let [index, ...rest] = reference.path
      if (rest.length !== 0) {
        throw "We haven't fixed this for deep elements"
      }
      // TODO needs author
      state[index] = [...(state[index] || []), data]
      console.log(state, "state");
      return state
    }, {})
    // This group by needs to happen after flat
  }
  let annotations;
  $: annotations = annotationsForNote(notes, index);
</script>

<article id={index} class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md" bind:this={root}>
  <header class="ml-12 mb-6 flex text-gray-600">
    <span class="font-bold">{author}</span>
    <span class="ml-auto">{index + 1} December</span>
  </header>
  {#each elements as {type, ...data}, index}
  <Block {type} {data} {index} {notes} topLevel={true} annotations={annotations[index] || []} on:annotate/>
  {/each}
  <!-- {JSON.stringify({anchor, focus}, null, 2)}
  <br>
  {#if anchor}
  #a={[...anchor.path, anchor.offset].join(",")}f={[...focus.path, focus.offset].join(",")}
  {/if} -->
</article>
