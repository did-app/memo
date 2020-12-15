<script>
  import Text from "./Text.svelte"
  import Glance from "../glance/Glance.svelte"
  export let type;
  export let data;
  export let index;
</script>

{#if type === "text"}
  <Text {...data} {index} />
{:else if type === "link"}
  <!-- Doesn't need to be a link, can be a reference -->
  {#if data.url.startsWith("#M0")}
  <!-- TODO Need to wrap to get an index -->
  {:else}
  <Glance href={data.url} text={data.title}/>
  {/if}
{/if}
