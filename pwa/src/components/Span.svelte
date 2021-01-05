<script lang="typescript">
  import type { Span } from "../writing";
  import Text from "./Text.svelte";
  import Link from "./Link.svelte";
  import Glance from "../glance/Glance.svelte";

  export let span: Span;
  export let index: number;
  export let unfurled: boolean;
</script>

{#if span.type === 'text'}
  <Text text={span.text} {index} />
{:else if span.type === 'link'}
  <!-- TODO Need to wrap to get an index -->
  {#if unfurled}
    <Glance href={span.url} text={span.title} />
  {:else}
    <span class="border-b hover:border-purple-700 mx-1 whitespace-no-wrap">
      <Link url={span.url} title={span.title} {index} />
    </span>
  {/if}
{:else if span.type === 'softbreak'}<br />{/if}
