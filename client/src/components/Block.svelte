<script>
  import Paragraph from "./Paragraph.svelte"
  export let type;
  export let data;
  export let index;

  const PARAGRAPH = "paragraph";
  const TEXT = "text";
  const LINK = "link";
</script>

{#if type === PARAGRAPH}
<Paragraph {...data} {index}/>
{:else}
{/if}
