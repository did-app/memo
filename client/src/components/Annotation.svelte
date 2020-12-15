<script>
  import * as Thread from "../thread"
  import Block from "./Block.svelte"
  export let reference;
  export let blocks;
  export let index;
  export let notes;
</script>

<div class="my-2 ml-12" data-note-index="{index}">
  <blockquote class="border-gray-600 border-l-4 opacity-50 px-2">
    {#each Thread.followReference(reference, notes) as {type, ...data}, index}
    <Block {type} {data} {index}/>
    {/each}
  </blockquote>
  <div class="pl-4">
    {#each blocks as {type, ...data}, index}
    <Block {type} {data} {index}/>
    {/each}
  </div>
</div>
