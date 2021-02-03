<script lang="typescript">
  export let text: string;
  export let offset: number;
  export let placeholder: "answer" | "message" | null;
  export let active: boolean;

  let printText: string;
  let printOffset: number;

  $: if (text == "") {
    printText = "\uFEFF";
    printOffset = offset - 1;
  } else {
    printText = text;
    printOffset = offset;
  }
</script>

<!-- whitespace-pre-wrap needed for typing but messes up collapsing -->
{#if text === ""}
  <span
    class="{active ? 'whitespace-pre-wrap' : ''} {placeholder}"
    data-span-offset={printOffset}>{printText}</span
  >
{:else}
  <span
    class={active ? "whitespace-pre-wrap" : ""}
    data-span-offset={printOffset}>{printText}</span
  >
{/if}

<style>
  span::after {
    color: #a6a6a6;
  }
  .answer::after {
    content: "Your answer ...";
  }
  .message::after {
    content: "Write message ...";
  }
</style>
