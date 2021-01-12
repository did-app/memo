<script lang="typescript">
  import { tick } from "svelte";
  import type { Reference, Memo } from "../conversation";
  import type { Block, InputEvent } from "../writing";
  import * as Writing from "../writing";
  export let previous: Memo[];
  export let document: { blocks: Block[] } = {
    blocks: [{ type: "paragraph", spans: [{ type: "text", text: "bob" }] }],
  };

  import BlockComponent from "./Block.svelte";
  import * as Icons from "../icons";

  type Point = { path: number[]; offset: number };
  type Range = { anchor: Point; focus: Point };
  type Highlight = { range: Range };

  let composer: HTMLElement;
  let lastSelection: Range;
  // range + memoPosition
  export function addAnnotation(reference: Range) {}

  function handleInput(event: InputEvent) {
    const [range, _memoPosition] = Writing.rangeFromDom(
      event.getTargetRanges()[0]
    );
    const [blocks, cursor] = Writing.handleInput(document.blocks, range, event);

    document.blocks = blocks;
    tick().then(function () {
      let paragraph = Writing.nodeFromPath(composer, cursor.path);
      let span = paragraph.childNodes[0] as HTMLElement;
      let textNode = span.childNodes[0] as Node;
      // This is why slate has it's weak Map

      let selection = window.getSelection();
      const domRange = selection?.getRangeAt(0);
      if (selection && domRange) {
        domRange.setStart(textNode, cursor.offset);
        domRange.setEnd(textNode, cursor.offset);
        selection.addRange(domRange);
      }
    });
  }

  function handleDragStart() {}
</script>

<div
  bind:this={composer}
  class="px-2 outline-none bg-green-200"
  contenteditable
  data-memo-position="0"
  on:beforeinput|preventDefault={handleInput}>
  {#each document.blocks as block, index}
    <div class="flex ">
      <div
        on:click={console.log}
        class="w-5 pt-2 text-gray-300 hover:text-gray-800 cursor-pointer "
        contenteditable="false">
        <!-- TODO get drag icon -->
        <Icons.Pin />
      </div>
      <BlockComponent {block} {index} peers={previous} />
    </div>
  {:else}
    <BlockComponent
      block={{ type: 'paragraph', spans: [] }}
      index={0}
      peers={previous} />
  {/each}
</div>
<hr />
<pre>

  {JSON.stringify(document.blocks, null, 2)}
</pre>
