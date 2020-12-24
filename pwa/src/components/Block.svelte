<script lang="typescript">
  import { PARAGRAPH, ANNOTATION } from "../note/elements";
  import type { Block } from "../note/elements";
  import Paragraph from "./Paragraph.svelte";

  export let block: Block;
  export let index: number;
</script>

{#if block.type === PARAGRAPH}
  <Paragraph spans={block.spans} {index} />
  <!-- {:else if block.type === ANNOTATION}
  <Annotation
    blocks={block.blocks}
    reference={block.reference}
    {index}
    {notes}
    on:annotate /> -->
{:else}
  <p>unknown block</p>
{/if}
