<script lang="typescript">
  import type { Span } from "../writing";
  import * as Writing from "../writing";
  import SpanComponent from "../components/Span.svelte";

  export let link: string;
  export let subject: string;
  export let description: string | null;
  export let datetime: Date | null;
  export let summary: Span[] | null;
</script>

<a
  class="block md:my-2 py-2 px-4 md:px-12 bg-white md:rounded shadow max-w-3xl border border-l-4 md:border-white hover:border-gray-600"
  href={link}
>
  <p class="flex items-center">
    <span class="font-bold ">{subject}</span>
    <span class="ml-auto text-gray-500">
      {datetime?.toLocaleDateString()}
    </span>
  </p>
  <!-- could be My group <5 participants> whatsapp doesnot show members very much -->
  <p>
    {description || ""}
  </p>
  {#if summary}
    <p class="mt-1 p-1 truncate text-gray-500">
      {#each summary as span}
        <SpanComponent
          {span}
          offset={0}
          unfurled={false}
          placeholder={null}
          active={false}
        />
      {/each}
    </p>
  {/if}
</a>
