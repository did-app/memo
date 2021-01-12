<script>
  import type { Memo } from "../conversation";
  import * as Conversation from "../conversation";
  import type { Annotation } from "../writing";
  import BlockComponent from "./Block.svelte";

  export let annotation: Annotation;
  export let index: number;
  export let peers: Memo[];

  function referenceAuthor(peers: Memo[], annotation: Annotation) {
    let memo = peers[annotation.reference.memoPosition - 1];
    if (memo) {
      return memo.author;
    } else {
      throw "Should have crashed on referemce";
    }
    // Probably follow reference should return author
  }
</script>

<div class="my-2 border-gray-600 w-full" data-block-index={index}>
  <blockquote class="border-l-4 px-2 text-gray-500" contenteditable="false">
    {#each Conversation.followReference(annotation.reference, peers) as block, index}
      <div class="-mb-2">
        <BlockComponent {block} {index} {peers} />
      </div>
    {/each}
    <a
      class="text-purple-800"
      href="#{annotation.reference.memoPosition}"><small>{referenceAuthor(peers, annotation)}</small></a>
  </blockquote>
  <div class="w-full">
    {#each annotation.blocks as block, index}
      <BlockComponent {block} {index} {peers} />
    {/each}
  </div>
  <hr class="mx-auto w-1/2 border-t-2" contenteditable="false" />
</div>
