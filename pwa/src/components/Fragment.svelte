<script lang="typescript">
  import BlockComponent from "./Block.svelte";
  import type { Memo } from "../conversation";
  import type { Block } from "../writing";
  // import * as Icons from "../icons";

  export let blocks: Block[];
  export let peers: Memo[];
  export let position: number;
</script>

{#each blocks as block, index}
  <div class="flex ml-6 md:ml-12" data-memo-position={position.toString()}>
    <BlockComponent {block} {index} {peers} />
  </div>
{/each}
