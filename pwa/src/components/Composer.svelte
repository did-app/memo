<script lang="typescript">
  import { tick } from "svelte";
  import type { Reference, Memo } from "../conversation";
  import type { Block, InputEvent, Range, Point } from "../writing";
  import * as Writing from "../writing";
  import BlockComponent from "./Block.svelte";
  import * as Icons from "../icons";

  export let previous: Memo[];
  export let blocks: Block[];
  export let position: number;

  let composer: HTMLElement;
  let composition: { updated: Block[]; cursor: Point } | null = null;

  if (!Writing.isBeforeInputEventAvailable()) {
    alert(
      "beforeInput event not supported on this browser, sorry the editor will not work."
    );
  }

  // TODO move to editor
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
    if (event.isComposing === false) {
      const domRange = event.getTargetRanges()[0];
      if (domRange === undefined) {
        throw "Should have a target range";
      }

      const result = Writing.rangeFromDom(domRange);
      if (result === null) {
        throw "There should always be a range for a domRange";
      }

      const range = result[0];
      const [updated, cursor] = Writing.handleInput(blocks, range, event);

      blocks = updated;

      tick().then(() => {
        Writing.placeCursor(composer, updated, cursor);
      });
    } else if (event.isComposing) {
      const domRange = window.getSelection()?.getRangeAt(0);
      if (domRange === undefined) {
        throw "Should have a current selection";
      }
      const result = Writing.rangeFromDom(domRange);

      if (result === null) {
        throw "There should always be a range for a domRange";
      }
      const [range] = result;
      const [updated, cursor] = Writing.handleInput(blocks, range, event);
      composition = { updated, cursor };
    }
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
  let isComposing = false;
</script>

<div
  bind:this={composer}
  class="outline-none overflow-y-auto"
  style="max-height: 60vh; caret-color: #6ab869;"
  contenteditable
  on:input={(event) => {
    // This shouldn't be firing, it might on android
    // alert(
    //   "Input event fired but it should not have been, this seems to be an issue affecting Chrome on Android"

    // );
    // Prevent default on before input stops this mostly
    console.log("input!!!!", event, event.getTargetRanges());

    return false;
    // Disabled doesn't seem to do anything on content editable
  }}
  disabled
  data-memo-position={position}
  on:compositionstart={(event) => {
    console.log("composition start", window.getSelection().getRangeAt(0));

    isComposing = true;
  }}
  on:compositionupdate|preventDefault={(event) => {
    // console.log(
    //   "composition update",
    //   event
    //   //   window.getSelection().getRangeAt(0)
    // );

    blocks = blocks;
    isComposing = false;
  }}
  on:compositionend={(event) => {
    console.log(event.preventDefault());

    console.log(
      "composition end",
      event.data
      //   window.getSelection().getRangeAt(0),
      //   false
    );
    if (composition) {
      blocks = composition.updated;
      let { updated, cursor } = composition;
      composition = null;
      tick().then(() => {
        blocks = blocks;
        Writing.placeCursor(composer, updated, cursor);
      });
    }
  }}
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
    <div class="flex">
      <div
        class="ml-1 md:ml-7 w-5 pt-2 text-gray-100 hover:text-gray-500 cursor-pointer "
        contenteditable="false"
      >
        <Icons.Drag />
      </div>

      <BlockComponent
        block={{ type: "paragraph", spans: [] }}
        index={0}
        peers={previous}
        placeholder={"message"}
      />
    </div>
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
