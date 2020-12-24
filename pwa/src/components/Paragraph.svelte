<script lang="typescript">
  import type { Span } from "../note/elements";
  import SpanComponent from "./Span.svelte";

  export let spans: Span[];
  export let index: number;
</script>

<p class="my-2 w-full" data-block-index={index}>
  {#each spans as span, index}
    <SpanComponent {span} {index} unfurled={spans.length === 1} />
  {/each}
</p>
