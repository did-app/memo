<script lang="typescript">
  import { PARAGRAPH, ANNOTATION, PROMPT } from "../memo/elements";
  import type { Block } from "../memo/elements";
  import type { Memo } from "../memo";
  import Paragraph from "./Paragraph.svelte";
  import Annotation from "./Annotation.svelte";

  export let block: Block;
  export let index: number;
  export let thread: Memo[];
  export let truncate: boolean = false;
</script>

{#if block.type === PARAGRAPH}
  <Paragraph spans={block.spans} {index} {truncate} />
{:else if block.type === ANNOTATION}
  <Annotation
    blocks={block.blocks}
    reference={block.reference}
    {index}
    {thread} />
{:else if block.type === PROMPT}
  <!-- <div class="hidden" /> -->
  <div>{JSON.stringify(block)}</div>
{:else}
  <p>unknown block {JSON.stringify(block)}</p>
{/if}
