<script lang="typescript">
  export let text: string;
  export let offset: number;

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

<style>
  .answer::after {
    content: "Your answer";
    color: #a6a6a6;
  }
</style>

{#if text === ''}
  <span
    class="whitespace-pre-wrap answer"
    data-span-offset={printOffset}>{printText}</span>
{:else}
  <span
    class="whitespace-pre-wrap"
    data-span-offset={printOffset}>{printText}</span>
{/if}
