<script type="text/javascript">
  import Glance from '../Glance.svelte'
  import { tick } from 'svelte';
  export let counter;
  export let checked;
  export let author;
  export let date;
  export let intro;
  export let html;

  let rendered;

  tick().then(function() {
    const $links = rendered.querySelectorAll('a:only-child')
    $links.forEach(function ($link) {
      // https://github.com/sveltejs/svelte/issues/537
      const frag = document.createDocumentFragment();
      const preview = new Glance({ target: frag, props: {href: $link.href, text: $link.innerText} });
      $link.replaceWith( frag );
    })
  })
</script>

<article id="{counter}" class="relative border-l border-t border-r rounded-lg md:rounded-2xl my-shadow bg-white">
  <input id="message-{counter}" class="message-checkbox hidden" type="checkbox" {checked}>
  <label class="cursor-pointer" for="message-{counter}">
    <header class="py-1 md:py-4 flex text-gray-600">
      <span class="font-bold ml-2 md:ml-20 truncate">{author}</span>
      <span class="ml-auto mr-2 md:mr-8 whitespace-no-wrap">{date}</span>
    </header>
    <div class="message-overlay absolute bottom-0 top-0 right-0 left-0 ">
    </div>
  </label>
  <div class="content-intro px-2 md:px-20 truncate markdown-body">{@html intro}</div>
  <div class="markdown-body py-2 px-2 md:px-20" bind:this={rendered}>{@html html}</div>
  <footer class="h-2 md:h-12 mb-2 mt-4">
  </footer>
</article>
