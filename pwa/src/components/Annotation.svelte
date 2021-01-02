<script>
  import type { Block } from "../note/elements";
  import type { Note } from "../note";
  import * as Thread from "../thread";
  import type { Reference } from "../thread";
  import BlockComponent from "./Block.svelte";
  export let reference: Reference;
  export let blocks: Block[];
  export let index: number;
  export let thread: Note[];
  console.log(thread);
</script>

<div class="my-2 border-gray-600 w-full" data-block-index={index}>
  <blockquote class="border-l-4 px-2 text-gray-500">
    {#each Thread.followReference(reference, thread) as block, index}
      <div class="-mb-2">
        <BlockComponent {block} {index} {thread} />
      </div>
    {/each}
    <a
      class="text-purple-800"
      href="#{reference.note}"><small>{thread[reference.note].author}</small></a>
  </blockquote>
  <div class="w-full">
    {#each blocks as block, index}
      <BlockComponent {block} {index} {thread} />
    {/each}
  </div>
  <hr class="mx-auto w-1/2 border-t-2" />
</div>
