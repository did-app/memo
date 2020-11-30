<script type="text/javascript">
  import Card from "./glance/Card.svelte"
  import ImageReel from "./glance/ImageReel.svelte"
  export let href;
  export let text;
  let url = new URL(href, window.location.origin);

  let snapshot = fetch("https://glance.did.app/?" + href).then(async (r) => {
		const {snapshot} = await r.json()
    return snapshot
	})
</script>

{#await snapshot}
<a href="{href}">{href}</a>
{:then {snapshot, ...data}}
{#if snapshot === 'card'}
<Card {...data} />
{:else if snapshot === 'image_reel'}
<ImageReel {...data} />
{:else}
Unknown snapshot type
{/if}
{/await}
