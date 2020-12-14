<script>
  import Span from "./Span.svelte"
  export let spans;
  export let index;
</script>


<p class="my-2" data-note-index="{index}">
  {#each spans as {type, ...data}, index}
  <Span {type} {data} {index}/>
  {/each}
</p>
