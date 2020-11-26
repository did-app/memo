<script type="text/javascript">
  export let href;
  export let text;
  let url = new URL(href, window.location.origin);

  let og;
  let preview = fetch("https://composer.plummail.co/.netlify/functions/linkpeek?href=" + href).then(async (r) => {
		let json = await r.json()
    console.log(json);
    og = json
    return json
	})
  console.log(preview);
  $: console.log(og);
</script>

<div class="">

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
  {og}
  {#await preview}
  hello
  {:then og}
  done
  {#if og.images}
  {#each og.images as image}
  <img class="inline" src="{image}" alt="">
  {/each}
  {:else}
  <h3 class="font-bold text-lg">{og.title}</h3>
  <p>{og.description}</p>
  <img class="inline" src="{og.image || link + '/favicon.ico'}" alt="">
  {/if}

  {/await}
  {#if og}
  {#if og.images}
  {#each og.images as image}
  <img class="inline" src="{image}" alt="">
  {/each}
  {:else}
  <h3 class="font-bold text-lg">{og.title}</h3>
  <p>{og.description}</p>
  <img class="inline" src="{og.image || link + '/favicon.ico'}" alt="">
  {/if}
  {/if}
</div>
