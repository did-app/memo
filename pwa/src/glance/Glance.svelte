<script type="typescript">
  import Page from "./Page.svelte";
  import ImageReel from "./ImageReel.svelte";
  export let href: string;
  export let text: string | undefined;

  const GLANCE_ORIGIN = (import.meta as any).env.SNOWPACK_PUBLIC_GLANCE_ORIGIN;
  async function fetchPreview(href: string) {
    let url = new URL(href, window.location.origin);
    if (url.origin === window.location.origin) {
      return { preview: "plain" };
    } else {
      let r = await fetch(GLANCE_ORIGIN + "/?" + href);

      const { preview } = await r.json();
      return preview;
    }
  }
  type Preview =
    | {
        item: "page";
        description: string;
        image: string;
        title: string;
        url: string;
      }
    | { item: "image_reel"; images: string[]; title: string; url: string }
    | { item: "plain" }
    | { item: "image" }
    | { item: "embeded_video"; iframe: string };
  let preview: Preview, next: string | undefined, running: boolean;

  async function updatePreview(href: string) {
    next = href;

    if (running) {
      return;
    }
    await run();
  }

  async function run() {
    if (running) throw "can't run twice";
    if (!next) throw "shouldn't ever call run if no next";
    let promise = fetchPreview(next);
    running = true;
    next = undefined;

    try {
      preview = await promise;
    } finally {
      running = false;
      if (next) {
        await run();
      }
    }
  }
  $: updatePreview(href);
</script>

{#if preview}
  {#if preview.item === 'page'}
    <Page {...preview} />
  {:else if preview.item === 'image_reel'}
    <ImageReel {...preview} />
  {:else if preview.item === 'plain'}
    <a {href}>{text}</a>
  {:else if preview.item === 'image'}
    <img class="mx-auto" src={href} alt="" />
  {:else if preview.item === 'embeded_video'}
    <!-- Styling copied from loom -->
    <div class="w-full relative" style="padding-bottom:56.25%;">
      <iframe
        title="video TODO"
        src={preview.iframe}
        frameborder="0"
        allowfullscreen
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;" />
    </div>
  {:else}
    <!-- Note that Glance returns the promise even if non 200 response -->
    <a {href}>{text}</a>
  {/if}
{:else}<a {href}>{text}</a>{/if}
