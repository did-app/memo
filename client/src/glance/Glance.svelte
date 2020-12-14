<script type="text/javascript">
  import Page from "./Page.svelte"
  import ImageReel from "./ImageReel.svelte"
  export let href;
  export let text;

  async function fetchPreview(href) {
    let url = new URL(href, window.location.origin);
    if (url.origin === window.location.origin) {
      return {preview: "plain"}
    } else {
      let r = await fetch("__GLANCE_ORIGIN__/?" + href)

      const {preview} = await r.json()
      return preview
    }
  }
  let preview, next, running;
  async function updatePreview(href) {
    next = href

    if (running) {
      return
    }
    await run()
  }

  async function run() {
    if (running) throw "can't run twice"
    let promise = fetchPreview(next)
    running = true
    next = undefined

    try {
      preview = await promise
    } finally {
      running = false
      if (next) {
        await run()
      }
    }
  }
  $: updatePreview(href)

</script>

{#if preview}
{#if preview.item === 'page'}
<Page {...preview} />
{:else if preview.item === 'image_reel'}
<ImageReel {...preview} />
{:else if preview.item === 'plain'}
<a href="{href}">{text}</a>
{:else}
<!-- Note that Glance returns the promise even if non 200 response -->
<a href="{href}">{text}</a>
{/if}
{:else}
<a href="{href}">{text}</a>
{/if}
