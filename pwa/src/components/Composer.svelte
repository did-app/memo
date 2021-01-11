<script lang="typescript">
  import type { Reference, Memo } from "../conversation";
  import type { Block } from "../writing";
  import * as Writing from "../writing";
  export let previous: Memo[];
  export let blocks: Block[] = [];

  import BlockComponent from "./Block.svelte";
  import * as Icons from "../icons";

  type Point = { path: number[]; offset: number };
  type Range = { anchor: Point; focus: Point };
  type Highlight = { range: Range };

  let lastSelection: Range;
  // range + memoPosition
  export function addAnnotation(reference: Range) {}

  function handleInput(event: any) {
    let domRanges = event.getTargetRanges();
    let domRange: StaticRange = domRanges[0];

    let inputType: string = event.inputType;
    let data: string | null = event.data;
    let dataTransfer: DataTransfer | null = event.dataTransfer;

    const range = Writing.rangeFromDom(domRange);

    Writing.handleInput(blocks, range, { inputType, data, dataTransfer });
  }

  function handleDragStart() {}
</script>

Composer
<div
  class="px-2 outline-none bg-green-200"
  contenteditable
  data-memo-position="0"
  on:beforeinput|preventDefault={handleInput}>
  {#each blocks as block, index}
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
