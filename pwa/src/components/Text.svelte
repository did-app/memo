<script lang="typescript">
  export let text: string;
  export let offset: number;
  export let placeholder: "answer" | "message" | null;

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

{#if text === ""}
  <span class={placeholder || ""} data-span-offset={printOffset}
    >{printText}</span
  >
{:else}
  <span class="" data-span-offset={printOffset}>{printText}</span>
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
