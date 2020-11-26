<script type="text/javascript">
  export let href;
  export let text;
  let url = new URL(href, window.location.origin);
</script>

{#if url.host === "whereby.com"}
  <a class="flex items-center items-stretch" {href} target="_blank">
    <img class="w-10" src="https://d32wid4gq0d4kh.cloudfront.net/favicon_whereby-196x196.png" alt="">
    <span class="align-middle p-2 border-b-4" style="border-color:#f8dbd5;">{text.trim() || 'Meet with Whereby'}</span>
  </a>
{:else}
<a { href }>
  { text }
</a>
{/if}
