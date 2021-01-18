<script lang="typescript">
  import type { Span } from "../writing";
  import Text from "./Text.svelte";
  import Link from "./Link.svelte";
  import Glance from "../glance/Glance.svelte";

  export let span: Span;
  export let offset: number;
  export let unfurled: boolean;
  export let placeholder: "answer" | "message" | null;
</script>

{#if span.type === "text"}
  <Text text={span.text} {offset} {placeholder} />
{:else if span.type === "link"}
  <!-- Need to wrap to get an offset -->
  {#if unfurled}
    <span contenteditable="false">
      <Glance href={span.url} text={span.title} />
    </span>
  {:else}
    <span class="border-b hover:border-purple-700 mx-1 whitespace-no-wrap">
      <Link url={span.url} title={span.title} {offset} />
    </span>
  {/if}
{:else if span.type === "softbreak"}<br />{/if}
