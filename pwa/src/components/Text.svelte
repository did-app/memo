<script lang="typescript">
  export let text: string;
  export let offset: number;

  let printText: string;
  let printOffset: number;

  if (text == "") {
    printText = "\uFEFF";
    printOffset = offset - 1;
  } else {
    printText = text;
    printOffset = offset;
  }
</script>

<span
  class="whitespace-pre-wrap"
  data-span-offset={printOffset}>{printText}</span>
