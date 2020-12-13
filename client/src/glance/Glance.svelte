<script type="text/javascript">
  import Page from "./Page.svelte"
  import ImageReel from "./ImageReel.svelte"
  export let href;
  export let text;
  let url = new URL(href, window.location.origin);

  let preview = (async function () {
    if (url.origin === window.location.origin) {
      return {preview: "plain"}
    } else {
      return fetch("__GLANCE_ORIGIN__/?" + href).then(async (r) => {
        const {preview} = await r.json()
        return preview
      })

    }
  }())
</script>

{#await preview}
<a href="{href}">{href}</a>
{:then {item, ...data}}
{#if item === 'page'}
<Page {...data} />
{:else if item === 'image_reel'}
<ImageReel {...data} />
{:else if item === 'plain'}
<a href="{href}">{text}</a>
{:else}
<!-- Note that Glance returns the promise even if non 200 response -->
<a href="{href}">{text}</a>
{/if}
{:catch e}
<a href="{href}">{text}</a>
{/await}
