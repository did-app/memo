<script lang="typescript">
  export let url: string;
  export let title: string | undefined;
  export let offset: number;

  let favicon: string;
  // TODO get from glance
  $: favicon = new URL(url).origin + "/favicon.ico";
</script>

<a class="text-purple-600" href={url} data-span-offset={offset} target="_blank">
  <!-- TODO glance needs a mini link view -->
  <!-- Fallback -->
  <!-- https://stackoverflow.com/questions/980855/inputting-a-default-image-in-case-the-src-attribute-of-an-html-img-is-not-vali -->
  <img class="w-5 inline" src={favicon} alt="" />
  <span>
    <!-- TODO glance needs to get description -->
    {title || url}
  </span>
</a>
