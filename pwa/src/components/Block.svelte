<script lang="typescript">
  import { PARAGRAPH, ANNOTATION } from "../note/elements";
  import type { Block } from "../note/elements";
  import type { Note } from "../note";
  import Paragraph from "./Paragraph.svelte";
  import Annotation from "./Annotation.svelte";

  export let block: Block;
  export let index: number;
  export let thread: Note[];
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
{:else}
  <p>unknown block {JSON.stringify(block)}</p>
{/if}
