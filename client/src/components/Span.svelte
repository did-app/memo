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
  <!-- TODO Need to wrap to get an index -->
  <Glance href={data.url} text={data.title}/>
{:else if type === "softbreak"}
  <br>
{/if}
