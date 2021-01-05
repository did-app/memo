<script lang="typescript">
  import type { Block } from "../writing";
  import type { Memo } from "../conversation";
  import Paragraph from "./Paragraph.svelte";
  import Annotation from "./Annotation.svelte";

  export let block: Block;
  export let index: number;
  export let peers: Memo[];
  export let truncate: boolean = false;
</script>

{#if block.type === 'paragraph'}
  <Paragraph spans={block.spans} {index} {truncate} />
{:else if block.type === 'annotation'}
  <Annotation annotation={block} {index} {peers} />
{:else if block.type === 'prompt'}
  <!-- <div class="hidden" /> -->
  <div>{JSON.stringify(block)}</div>
{:else}
  <p>unknown block {JSON.stringify(block)}</p>
{/if}
