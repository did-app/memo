<script>
  import Paragraph from "./Paragraph.svelte"
  import Annotation from "./Annotation.svelte"
  export let type;
  export let data;
  export let index;
  export let notes;
  export let topLevel;

  const PARAGRAPH = "paragraph";
  const TEXT = "text";
  const LINK = "link";
</script>

{#if type === PARAGRAPH}
<Paragraph {...data} {index} {topLevel} on:annotate/>
{:else if type === "annotation"}
<Annotation {...data} {index} {notes} on:annotate/>
{:else}
{/if}
