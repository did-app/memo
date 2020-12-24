<script lang="typescript">
  import { PARAGRAPH, ANNOTATION } from "../note/elements";
  import type { Block } from "../note/elements";
  import Paragraph from "./Paragraph.svelte";
  import Annotation from "./Annotation.svelte";

  export let block: Block;
  export let index: number;
  export let notes: { blocks: Block[] };
  export let topLevel: boolean;
  export let annotations;
  export let action;
</script>

{#if block.type === PARAGRAPH}
  <Paragraph
    spans={block.spans}
    {index}
    {action}
    {topLevel}
    {annotations}
    on:annotate />
{:else if type === ANNOTATION}
  <Annotation {...data} {index} {notes} on:annotate />
{:else}unknown block{/if}
