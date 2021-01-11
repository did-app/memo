<script lang="typescript">
  import type { Span } from "../writing/elements";
  import SpanComponent from "./Span.svelte";

  export let spans: Span[];
  export let index: number;
  export let truncate: boolean;

  let unfurled: boolean;
  $: unfurled = spans.length <= 1;

  function render(spans: Span[]) {
    const output: { span: Span; offset: number }[] = [];
    spans.reduce(function (offset, span) {
      output.push({ span, offset });
      return offset + span.text.length;
    }, 0);

    if (output.length === 0) {
      let span: Span = { type: "text", text: "\uFEFF" };
      let offset = -1;
      output.push({ span, offset });
    }
    return output;
  }
</script>

<p class="my-1 min-w-0 w-full" data-block-index={index} class:truncate>
  <!-- TODO others will need to render empty paragraph i.e. annotation -->
  <!-- {JSON.stringify(render(spans))} -->
  {#each render(spans) as { span, offset }}
    <SpanComponent {span} {offset} {unfurled} />
  {/each}
</p>
