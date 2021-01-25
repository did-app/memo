<script lang="typescript">
  import type { Span } from "../writing/elements";
  import SpanComponent from "./Span.svelte";

  export let spans: Span[];
  export let index: number;
  export let truncate: boolean;
  export let placeholder: "answer" | "message" | null;
  export let active: boolean;

  let unfurled: boolean;
  $: unfurled = spans.length <= 1;

  function render(spans: Span[]) {
    let offset = 0;
    const output: { span: Span; offset: number }[] = [];
    spans.reduce(function (offset, span) {
      output.push({ span, offset });
      if ("text" in span) {
        return offset + span.text.length;
      } else if ("url" in span) {
        return offset + 1;
      } else {
        return offset;
      }
    }, offset);

    if (output.length === 0) {
      let span: Span = { type: "text", text: "" };
      output.push({ span, offset });
    }
    return output;
  }
</script>

<p class="my-2 min-w-0 w-full" data-block-index={index} class:truncate>
  {#each render(spans) as { span, offset }, index}
    <SpanComponent
      {span}
      {offset}
      {unfurled}
      placeholder={index === 0 ? placeholder : null}
      {active}
    />
  {/each}
</p>
