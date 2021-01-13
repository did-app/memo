<script lang="typescript">
  import { tick } from "svelte";
  import type { Reference, Memo } from "../conversation";
  import type { Block, InputEvent } from "../writing";
  import * as Writing from "../writing";
  export let previous: Memo[];
  export let blocks: Block[];

  export let position: number;

  import BlockComponent from "./Block.svelte";
  import * as Icons from "../icons";

  type Point = { path: number[]; offset: number };
  type Range = { anchor: Point; focus: Point };
  type Highlight = { range: Range };

  let composer: HTMLElement;
  let lastSelection: Range;
  // range + memoPosition
  export function addAnnotation(reference: Reference) {
    let lastBlock = blocks[blocks.length - 1];
    let before: Block[];
    if (
      lastBlock &&
      "spans" in lastBlock &&
      Writing.lineLength(lastBlock.spans) === 0
    ) {
      before = blocks.slice(0, -1);
    } else {
      before = blocks;
    }
    blocks = [
      ...before,
      {
        type: "annotation",
        reference,
        blocks: [{ type: "paragraph", spans: [{ type: "text", text: "" }] }],
      },
      { type: "paragraph", spans: [{ type: "text", text: "" }] },
    ];
  }

  function handleInput(event: InputEvent) {
    const domRange = event.getTargetRanges()[0];
    if (domRange === undefined) {
      throw "there should always be a dom range";
    }
    const result = Writing.rangeFromDom(domRange);
    if (result === null) {
      throw "There should always be a range";
    }
    const [range, _memoPosition] = result;
    const [updated, cursor] = Writing.handleInput(blocks, range, event);

    blocks = updated;
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

  function handleDragStart(event: DragEvent, index: number) {
    if (event.dataTransfer) {
      event.dataTransfer.setData("memo/position", index.toString());
    }
  }
  function handleDragOver() {
    return false;
  }
  function handleDrop(event: DragEvent, finish: number) {
    if (event.dataTransfer) {
      let start = parseInt(event.dataTransfer.getData("memo/position"));
      let removed = blocks.splice(start, 1);
      // Don't need this because if going up
      // finish = start < finish ? start : start - 1;
      blocks.splice(finish, 0, ...removed);
      blocks = blocks;
    }
  }
</script>

<div
  bind:this={composer}
  class="outline-none overflow-y-auto"
  style="max-height: 60vh;"
  contenteditable
  data-memo-position={position}
  on:beforeinput|preventDefault={handleInput}>
  {#each blocks as block, index}
    <div
      class="flex "
      draggable="true"
      on:dragstart={(event) => {
        handleDragStart(event, index);
      }}
      ondragover="return false"
      on:drop={(event) => handleDrop(event, index)}>
      <!-- text return false on dragover works, function call doesn't? -->
      <!-- -ml because padding on article is 2, probably should be dropped -->
      <div
        class="ml-1 md:ml-7 w-5 pt-2 text-gray-100 hover:text-gray-500 cursor-pointer "
        contenteditable="false">
        <!-- TODO get drag icon -->
        <Icons.Drag />
      </div>
      <BlockComponent
        {block}
        {index}
        peers={previous}
        placeholder={index === 0 ? 'message' : null} />
    </div>
  {:else}
    <BlockComponent
      block={{ type: 'paragraph', spans: [] }}
      index={0}
      peers={previous}
      placeholder={'message'} />
  {/each}
</div>
<slot {blocks} />
<!-- <hr />
<pre>

  {JSON.stringify(blocks, null, 2)}
</pre> -->
