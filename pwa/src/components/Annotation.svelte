<script>
  import type { Block } from "../note/elements";
  import type { Note } from "../note";
  import * as Thread from "../thread";
  import type { Reference } from "../thread";
  import BlockComponent from "./Block.svelte";
  export let reference: Reference;
  export let blocks: Block[];
  export let index: number;
  export let notes: Note[];
</script>

<div class="my-2 ml-12 border-gray-600 border-l-4" data-block-index={index}>
  <blockquote class=" opacity-50 px-2">
    {#each Thread.followReference(reference, notes) as block, index}
      <div class="">
        <BlockComponent {block} {index} />
      </div>
    {/each}
    <a
      class="text-purple-800"
      href="#{reference.note}"><small>{notes[reference.note].author}</small></a>
  </blockquote>
  <div class="pl-4">
    {#each blocks as block, index}
      <BlockComponent {block} {index} />
    {/each}
  </div>
</div>
