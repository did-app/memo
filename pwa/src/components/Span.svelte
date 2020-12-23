<script lang="typescript">
  import { TEXT, LINK } from "../note/elements";
  import Text from "./Text.svelte";
  import Link from "./Link.svelte";
  import Glance from "../glance/Glance.svelte";
  export let type;
  export let data;
  export let index: string;
  export let unfurled: boolean;
</script>

{#if type === TEXT}
  <Text {...data} {index} />
{:else if type === LINK}
  <!-- TODO Need to wrap to get an index -->
  {#if unfurled}
    <Glance href={data.url} text={data.title} />
  {:else}
    <span class="border-b hover:border-purple-700 mx-1 whitespace-no-wrap">
      <Link {...data} {index} />
    </span>
  {/if}
{:else if type === 'softbreak'}<br />{/if}
