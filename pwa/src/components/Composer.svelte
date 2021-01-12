<script lang="typescript">
  import { tick } from "svelte";
  import type { Reference, Memo } from "../conversation";
  import type { Block, InputEvent } from "../writing";
  import * as Writing from "../writing";
  export let previous: Memo[];
  export let blocks: Block[];

  export let position: number;
  console.log(position);

  import BlockComponent from "./Block.svelte";
  import * as Icons from "../icons";

  type Point = { path: number[]; offset: number };
  type Range = { anchor: Point; focus: Point };
  type Highlight = { range: Range };

  let composer: HTMLElement;
  let lastSelection: Range;
  // range + memoPosition
  export function addAnnotation(reference: Reference) {
    console.log(reference, "ADIT");
    blocks = [
      ...blocks,
      {
        type: "annotation",
        reference,
        blocks: [{ type: "paragraph", spans: [{ type: "text", text: "" }] }],
      },
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
    console.log(updated, "UUUUUUUUUUUU");

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

  function handleDragStart() {}
</script>

<div
  bind:this={composer}
  class="px-2 outline-none"
  contenteditable
  data-memo-position={position}
  on:beforeinput|preventDefault={handleInput}>
  {#each blocks as block, index}
    <div class="flex ">
      <div
        on:click={console.log}
        class="w-5 pt-2 text-gray-300 hover:text-gray-800 cursor-pointer "
        contenteditable="false">
        <!-- TODO get drag icon -->
        <Icons.Drag />
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
<!-- <hr />
<pre>

  {JSON.stringify(blocks, null, 2)}
</pre> -->
