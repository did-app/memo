<script lang="typescript">
  import type { Span } from "../note/elements";
  import SpanComponent from "./Span.svelte";

  export let spans: Span[];
  export let index: number;
  export let truncate: boolean;
</script>

<p class="my-1 w-full" data-block-index={index} class:truncate>
  {#each spans as span, index}
    <SpanComponent {span} {index} unfurled={spans.length === 1} />
  {/each}
</p>
