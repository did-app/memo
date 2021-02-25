<script type="typescript">
  export let rows: (string | number)[][];
  export let fields: string[];
  export let title: string;

  let open = false;
</script>

<div
  class="rounded-lg border p-4 top-0 bottom-0 left-0 right-0 z-10"
  class:absolute={open}
  on:click|preventDefault={() => {
    open = !open;
  }}
  style="background:#F9F5F1;"
>
  <!-- <label> -->
  <h5 style="margin:0;" class="pt-1 px-2 text-center">{title}</h5>

  <table class="whitespace-nowrap overflow-x-auto block border-collapse">
    <thead>
      <tr>
        {#each fields as field}
          <th class="text-left px-3">{field}</th>
        {/each}
      </tr>
    </thead>
    <tbody>
      {#each open ? rows : rows.slice(0, 4) as row}
        <tr>
          {#each row as value}
            <td class="px-3">{value}</td>
          {/each}
        </tr>
      {/each}
    </tbody>
    {#if rows.length > 4}
      {#if open}
        <div class="text-gray-400 font-bold px-3 cursor-pointer">close ...</div>
      {:else}
        <div class="text-gray-400 font-bold px-3 cursor-pointer">more ...</div>
      {/if}
    {/if}
  </table>
  <!-- </label> -->
  <div class="flex items-center px-2 pb-1 opacity-75">
    <!-- <svg
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
    </svg> -->
    <!-- style added because markdown a taking precidence -->
    <!-- TODO needs url -->
    <!-- <a
      class="truncate flex-1 text-sm"
      href={url}
      target="_blank">
      {url}
    </a> -->
  </div>
</div>

<style media="screen">
  .check-toggle:checked + .hidden {
    display: block;
  }
</style>
