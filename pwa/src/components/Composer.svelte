<script lang="typescript">
  import { tick } from "svelte";
  import type { Reference, Memo } from "../conversation";
  import type { Block, InputEvent, Range } from "../writing";
  import * as Writing from "../writing";
  import BlockComponent from "./Block.svelte";
  import * as Icons from "../icons";

  export let previous: Memo[];
  export let blocks: Block[];
  export let position: number;
  export let selected: Range | null;

  let composer: HTMLElement;

  if (!Writing.isBeforeInputEventAvailable()) {
    alert(
      "beforeInput event not supported on this browser, sorry the editor will not work."
    );
  }
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

    let range: Range;
    if (domRange !== undefined) {
      const result = Writing.rangeFromDom(domRange);

      if (result === null) {
        throw "There should always be a range";
      }
      range = result[0];
    } else {
      // domRange SHOULD NOT be undefined however on chrome for android this often seems to be the case.
      // This fix doesn't tackle moving the range for collapsed delete events
      if (selected === null) {
        // We still to this point on chrome on android when we press Space or new line
        alert(event.inputType + " with the following data: " + event.data);
        throw "How did we get input";
      } else {
        range = selected;
      }
    }
    const [updated, cursor] = Writing.handleInput(blocks, range, event);

    blocks = updated;
    tick().then(function () {
      let paragraph = Writing.nodeFromPath(composer, cursor.path);
      let line = Writing.getLine(updated, cursor.path);
      let [spanIndex, offset] = Writing.spanFromOffset(line, cursor.offset);
      let span = paragraph.children[spanIndex] as HTMLElement;
      let textNode = span.childNodes[0] as Node;

      // This is why slate has it's weak Map

      let selection = window.getSelection();
      const domRange = selection?.getRangeAt(0);
      if (selection && domRange) {
        domRange.setStart(textNode, offset);
        domRange.setEnd(textNode, offset);
        selection.addRange(domRange);
      }
    });
  }

  let dragging = false;
  function handleDragStart(event: DragEvent, index: number) {
    if (event.dataTransfer) {
      dragging = true;
      event.dataTransfer.setData("memo/position", index.toString());
    }
  }
  function handleDragEnd() {
    dragging = false;
  }
  // function handleDragOver() {
  //   return false;
  // }
  const ondragover = "return false" as any;
  // Seems to only work with this string
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
  function handleDragDelete(event: DragEvent) {
    if (event.dataTransfer) {
      let start = parseInt(event.dataTransfer.getData("memo/position"));

      blocks.splice(start, 1);
      if (blocks.length === 0) {
        blocks = [{ type: "paragraph", spans: [{ type: "text", text: "" }] }];
      }

      blocks = blocks;
    }
  }
</script>

<div
  bind:this={composer}
  class="outline-none overflow-y-auto"
  style="max-height: 60vh; caret-color: #6ab869;"
  contenteditable
  on:input={() => {
    // This shouldn't be firing, it might on android
    alert(
      "Input event fired but it should not have been, this seems to be an issue affecting Chrome on Android"
    );
    // Disabled doesn't seem to do anything on content editable
  }}
  disabled
  data-memo-position={position}
  on:beforeinput|preventDefault={handleInput}
>
  {#each blocks as block, index}
    <div
      class="flex "
      draggable="true"
      on:dragstart={(event) => {
        handleDragStart(event, index);
      }}
      on:dragend={handleDragEnd}
      {ondragover}
      on:drop={(event) => handleDrop(event, index)}
    >
      <!-- text return false on dragover works, function call doesn't? -->
      <!-- -ml because padding on article is 2, probably should be dropped -->
      <div
        class="ml-1 md:ml-7 w-5 pt-2 text-gray-100 hover:text-gray-500 cursor-pointer "
        contenteditable="false"
      >
        <Icons.Drag />
      </div>
      <BlockComponent
        {block}
        {index}
        peers={previous}
        placeholder={index === 0 ? "message" : null}
      />
    </div>
  {:else}
    <BlockComponent
      block={{ type: "paragraph", spans: [] }}
      index={0}
      peers={previous}
      placeholder={"message"}
    />
  {/each}
</div>
{#if dragging}
  <div class="mt-2 pl-6 md:pl-12 flex items-center">
    <button
      {ondragover}
      on:drop={handleDragDelete}
      class="bg-gray-100 flex inline-block items-center justify-center mx-auto px-2 rounded w-full binnable">
      <span class="w-5 mr-2 inline-block">
        <Icons.Bin />
      </span>
      <span class="py-1"> Bin </span>
    </button>
  </div>
{:else}
  <slot {blocks} />
{/if}
<!-- <hr />
<pre>

  {JSON.stringify(blocks, null, 2)}
</pre> -->
