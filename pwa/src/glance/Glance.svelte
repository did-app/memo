<script type="typescript">
  import Page from "./Page.svelte";
  import ImageReel from "./ImageReel.svelte";
  import Table from "./Table.svelte";
  export let href: string;
  export let text: string | undefined;

  const GLANCE_ORIGIN = (import.meta as any).env.SNOWPACK_PUBLIC_GLANCE_ORIGIN;
  async function fetchPreview(href: string): Promise<Preview> {
    let url = new URL(href, window.location.origin);
    if (url.origin === window.location.origin) {
      if ((url.pathname = "/uploader")) {
        return {
          item: "embeded_frame",
          iframe: url.toString(),
        };
      } else {
        return { item: "plain" };
      }
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
    | { item: "embeded_video"; iframe: string }
    | { item: "embeded_frame"; iframe: string }
    | { item: "embeded_html"; html: string }
    | {
        item: "table";
        title: string;
        fields: string[];
        rows: (string | number)[][];
      };
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
  function watchResize(obj: HTMLIFrameElement | null) {
    let scrollHeight = 0;
    function resize() {
      let h = obj?.contentWindow?.document.documentElement.scrollHeight;
      if (obj && h && h !== scrollHeight) {
        scrollHeight = h;
        obj.style.height = scrollHeight + "px";
      }
      setTimeout(resize, 100);
    }
    resize();
  }
  let frame: HTMLIFrameElement | null = null;
</script>

{#if preview}
  {#if preview.item === "page"}
    <Page {...preview} />
  {:else if preview.item === "image_reel"}
    <ImageReel {...preview} />
  {:else if preview.item === "table"}
    <Table {...preview} />
  {:else if preview.item === "plain"}
    <a {href}>{text || href}</a>
  {:else if preview.item === "image"}
    <img class="mx-auto" src={href} alt="" />
  {:else if preview.item === "embeded_video"}
    <!-- Styling copied from loom -->
    <div class="w-full relative" style="padding-bottom:56.25%;">
      <iframe
        title="video name required"
        src={preview.iframe}
        frameborder="0"
        allowfullscreen
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"
      />
    </div>
  {:else if preview.item === "embeded_frame"}
    <iframe
      title="name required"
      src={preview.iframe}
      frameborder="0"
      allowfullscreen
      style="width: 100%;"
    />
  {:else if preview.item === "embeded_html"}
    <iframe
      title={href}
      class="w-full"
      bind:this={frame}
      on:load={function () {
        watchResize(frame);
      }}
      srcdoc="<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'></head><body>{preview.html}</body></html>"
    />
  {:else}
    <!-- Note that Glance returns the promise even if non 200 response -->
    <a class="underline text-green-400 hover:text-green-600 break-all" {href}
      >{text || href}</a
    >
  {/if}
{:else}<a class="underline text-green-400 hover:text-green-600 break-all" {href}
    >{text || href}</a
  >{/if}
