<script type="text/javascript">
  export let images;
  export let title;
</script>

<div class="border rounded px-1">
  <h2>{title}</h2>
  <div class="">
    {#each images as image}
    <img class="mx-auto" style="max-height:300px;" src="{image}" alt="">
    {/each}
  </div>
</div>
