<script lang="typescript">
  import type { Memo } from "../conversation";
  import * as Conversation from "../conversation";
  import type { Annotation } from "../writing";
  import BlockComponent from "./Block.svelte";

  export let annotation: Annotation;
  export let index: number;
  export let peers: Memo[];
</script>

<!-- The horizontal rule at the bottom of here was able to be a content editable target, could not fix -->
<div class="my-4 w-full" data-block-index={index}>
  <blockquote class="font-bold border-l-8" contenteditable="false">
    <div class="px-4">
      {#each Conversation.followReference(annotation.reference, peers) as block, index}
        <div class="-mb-2">
          <BlockComponent
            {block}
            {index}
            {peers}
            placeholder={null}
            active={false}
          />
        </div>
      {/each}
      <small class="font-normal text-green-600"
        ><a href="#{annotation.reference.memoPosition.toString()}">source</a
        ></small
      >
    </div>
  </blockquote>
  <div class="w-full px-2 ml-4">
    {#each annotation.blocks as block, index}
      <BlockComponent
        {block}
        {index}
        {peers}
        placeholder={index === 0 ? "answer" : null}
        active={true}
      />
    {/each}
  </div>
</div>
