<script>
  import type { Thread } from "../conversation";
  import * as Conversation from "../conversation";
  import type { Annotation } from "../writing";
  import BlockComponent from "./Block.svelte";

  export let annotation: Annotation;
  export let index: number;
  export let thread: Thread;
</script>

<div class="my-2 border-gray-600 w-full" data-block-index={index}>
  <blockquote class="border-l-4 px-2 text-gray-500">
    {#each Conversation.followReference(annotation.reference, thread) as block, index}
      <div class="-mb-2">
        <BlockComponent {block} {index} {thread} />
      </div>
    {/each}
    <a
      class="text-purple-800"
      href="#{annotation.reference.memoPosition}"><small>{thread[annotation.reference.memoPosition].author}</small></a>
  </blockquote>
  <div class="w-full">
    {#each annotation.blocks as block, index}
      <BlockComponent {block} {index} {thread} />
    {/each}
  </div>
  <hr class="mx-auto w-1/2 border-t-2" />
</div>
