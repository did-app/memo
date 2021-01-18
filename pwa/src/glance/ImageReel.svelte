<script type="typescript">
  export let images: string[];
  export let title: string;
  export let url: string;
</script>

<style media="screen">
  .hover-zoom:hover {
    transition: 1s;
    transform: scale(1.05);
  }
  .check-toggle:checked + .hidden {
    display: block;
  }
</style>

<div class="rounded-lg border p-4" style="background:#F9F5F1;">  
  <div class="flex flex-wrap">
    {#each images as image}
      <label class="h-32 w-1/2 md:w-1/3 overflow-hidden cursor-pointer">
        <img class="object-cover hover-zoom min-h-full" src={image} alt="" />
        <input class="check-toggle hidden" type="checkbox" />
        <div class="hidden">
          <div
            class="fixed top-0 left-0 h-screen w-screen bg-gray-400 z-10 flex">
            <img class="m-auto" src={image} alt="" />
          </div>
        </div>
      </label>
    {/each}
  </div>
  <h5 style="margin:0;" class="pt-1 px-2">{title}</h5>
  <div class="flex items-center px-2 pb-1 opacity-75">
    <svg
      class="fill-current w-4 h-4 mr-1 inline"
      xmlns="http://www.w3.org/2000/svg"
      clip-rule="evenodd"
      fill-rule="evenodd"
      height="512"
      stroke-linejoin="round"
      stroke-miterlimit="2"
      viewBox="0 0 24 24"
      width="512">
      <g transform="translate(-216.731 -90.903)">
        <path
          d="m227.731 92.903h-5c-2.209 0-4 1.791-4 4v12c0 2.209 1.791 4 4 4h12c2.209 0 4-1.791 4-4 0-2.271 0-5 0-5 0-.552-.448-1-1-1s-1 .448-1 1v5c0 1.104-.896 2-2 2-3.33 0-8.671 0-12 0-1.105 0-2-.896-2-2 0-3.33 0-8.671 0-12 0-1.105.895-2 2-2h5c.552 0 1-.448 1-1s-.448-1-1-1zm7.586 2h-3.586c-.552 0-1-.448-1-1s.448-1 1-1h6c.552 0 1 .448 1 1v6c0 .552-.448 1-1 1s-1-.448-1-1v-3.586l-7.293 7.293c-.39.39-1.024.39-1.414 0-.391-.39-.391-1.024 0-1.414z" />
      </g>
    </svg>
    <!-- style added because markdown a taking precidence -->
    <a
      class="truncate flex-1 text-sm"
      href={url}
      target="_blank">
      {url}
    </a>
  </div>
</div>
