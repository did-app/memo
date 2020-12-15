<script>
  import Glance from "../glance/Glance.svelte"
  import Block from "./Block.svelte"

  export let domRange;
  export let elements = [];
  export let notes;
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
</script>

<article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md" bind:this={root}>
  {#each elements as {type, ...data}, index}
  <Block {type} {data} {index} {notes} topLevel={true} on:annotate/>
  {/each}
  <!-- {JSON.stringify({anchor, focus}, null, 2)}
  <br>
  {#if anchor}
  #a={[...anchor.path, anchor.offset].join(",")}f={[...focus.path, focus.offset].join(",")}
  {/if} -->
</article>
