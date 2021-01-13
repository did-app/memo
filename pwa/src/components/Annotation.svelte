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

<!-- The horizontal rule at the bottom of here was able to be a content editable target, could not fix -->
<div
  class="my-2 border rounded border-gray-200 w-full"
  data-block-index={index}>
  <blockquote class="text-gray-500" contenteditable="false">
    <div class="bg-gray-100 italic px-2 -mt-1 pt-1 pb-2 rounded-t border-t ">
      {#each Conversation.followReference(annotation.reference, peers) as block, index}
        <div class="-mb-2">
          <BlockComponent {block} {index} {peers} placeholder={null} />
        </div>
      {/each}
    </div>
    <a
      class="px-2 font-bold"
      href="#{annotation.reference.memoPosition}"><small>{referenceAuthor(peers, annotation)}</small></a>
  </blockquote>
  <div class="w-full px-2">
    {#each annotation.blocks as block, index}
      <BlockComponent
        {block}
        {index}
        {peers}
        placeholder={index === 0 ? 'answer' : null} />
    {/each}
  </div>
  <!-- <hr class="mx-auto w-1/2 border-t-2" contenteditable="false" /> -->
</div>
