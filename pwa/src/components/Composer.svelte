<script lang="typescript">
  import { tick } from "svelte";
  import type { Reference, Memo } from "../conversation";
  import type { Block, InputEvent, Range, Point } from "../writing";
  import * as Writing from "../writing";
  import BlockComponent from "./Block.svelte";
  import * as Icons from "../icons";

  export let previous: Memo[];
  export let blocks: Block[] = [];
  export let position: number;
  export let selected: Range | null;

  export function addAnnotation(reference: Reference) {
    blocks = Writing.addAnnotation(blocks, reference);
  }

  export function addBlock(block: Block) {
    blocks = Writing.addBlock(blocks, block);
  }

  let composer: HTMLElement;
  let composition: { updated: Block[]; cursor: Point } | null = null;
  const supported = Writing.isBeforeInputEventAvailable();

  function handleInput(event: InputEvent) {
    // console.log(event);
    doubleInput = false;

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
      tick().then(function () {
        Writing.placeCursor(composer, updated, cursor);
      });
    } else {
      const domRange = window.getSelection()?.getRangeAt(0);
      if (domRange === undefined) {
        throw "Should have a current selection";
      }
      const result = Writing.rangeFromDom(domRange);
      if (result === null) {
        throw "There should always be a range for composition event";
      }
      const range = result[0];
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
  let doubleInput = false;
</script>

{#if supported}
  <div
    bind:this={composer}
    class="outline-none overflow-y-auto"
    style="max-height: 60vh; caret-color: #6ab869;"
    contenteditable
    on:input={(event) => {
      // This shouldn't be firing, it might on android
      // Prevent default on before input stops this mostly
      // I think the extra bit comes in after this step
      // console.log("input always happens", blocks);
      // https://svelte.dev/docs#key
      // you can do so, wait for a tick, then change the key to something (could be a timestamp even)
      if (doubleInput) {
        const cursor = composition?.cursor;
        // Sometimes an input event is called twice.
        // This is tracked with the double Input variable
        // blocks are not updated at this point and TICK, doesn't seem to help
        setTimeout(function () {
          let tmp = blocks;
          blocks = [];
          // flash the blocks
          tick().then(function () {
            blocks = tmp;
            tick().then(function () {
              if (cursor) {
                Writing.placeCursor(composer, tmp, cursor);
              } else {
                throw "By this point we should definetly have a cursor";
              }
            });
          });
        }, 0);
      } else {
        doubleInput = true;
      }
      return false;
    }}
    disabled
    data-memo-position={position}
    on:compositionstart={() => {
      isComposing = true;
    }}
    on:compositionend={() => {
      isComposing = false;

      if (composition) {
        let { updated, cursor } = composition;
        blocks = updated;
        composition = null;
        tick().then(() => {
          blocks = blocks;
          Writing.placeCursor(composer, updated, cursor);
        });
      } else {
        console.warn("composition end");
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
          placeholder={blocks.length === 1 && !isComposing ? "message" : null}
          active={true}
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
          placeholder={isComposing ? null : "message"}
          active={true}
        />
      </div>
    {/each}
  </div>
  {#if dragging}
    <div class="mt-2 pl-6 md:pl-12 flex items-center">
      <button
        {ondragover}
        on:drop={handleDragDelete}
        class="bg-gray-100 flex inline-block items-center justify-center mx-auto px-2 rounded w-full binnable"
      >
        <span class="w-5 mr-2 inline-block">
          <Icons.Bin />
        </span>
        <span class="py-1"> Bin </span>
      </button>
    </div>
  {:else}
    <slot {blocks} />
  {/if}
{:else}
  <h1 class="text-xl text-center font-bold my-4 ml-12">
    Browser not supported
  </h1>
  <p class="my-2 ml-12">
    Hi there, we can't offer Memo's message composing in this browser.
  </p>
  <p class="my-2 ml-12">
    Our composer makes use of <a
      class="underline"
      href="https://caniuse.com/?search=beforeinput">beforeInput</a
    > events which are available in most browsers, but not this one.
  </p>
  <p class="my-2 ml-12">
    We're pleased to see you trying out Memo, to continue try Chrome, Safari or
    Edge.
  </p>
{/if}
