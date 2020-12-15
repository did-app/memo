<script>
  import {PARAGRAPH, ANNOTATION} from "../note/elements";
  import Paragraph from "./Paragraph.svelte";
  import Annotation from "./Annotation.svelte";
  export let type;
  export let data;
  export let index;
  export let notes;
  export let topLevel;
  export let annotations;

</script>

{#if type === PARAGRAPH}
<Paragraph {...data} {index} {topLevel} {annotations} on:annotate/>
{:else if type === ANNOTATION}
<Annotation {...data} {index} {notes} on:annotate/>
{:else}
{/if}
