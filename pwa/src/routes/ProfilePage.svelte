<script lang="typescript">
  import { parse, toString } from "../note";
  import type { Block } from "../note/elements";
  import * as API from "../sync/api";
  import Composer from "../components/Composer.svelte";
  export let id: number;
  export let emailAddress: string;
  export let greeting: Block[];

  let draft = toString(greeting);
  let blocks: Block[] = [];
  $: blocks = parse(draft);

  async function saveGreeting(): Promise<null> {
    console.log(id, blocks);

    let response = await API.saveGreeting(id, blocks);
    if ("error" in response) {
      throw "failed to save greeting";
    }
    return null;
  }
</script>

<article
  class="my-4 py-6 pr-12 bg-gray-800 text-white pl-12 rounded-lg shadow-md ">
  <h1 class="text-2xl">Hi {emailAddress}</h1>
  <p>
    Set up your welcome message, that explains how people should get in touch
    with you.
  </p>
</article>
<article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
  <Composer bind:draft />
  <div class="mt-2 pl-12 flex items-center">
    <div class="flex flex-1" />
    <button
      class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold"
      on:click={saveGreeting}>
      <svg
        class="fill-current inline w-4 mr-2"
        xmlns="http://www.w3.org/2000/svg"
        enable-background="new 0 0 24 24"
        viewBox="0 0 24 24">
        <path
          d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z" />
        <path
          d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z" />
      </svg>
      Save
    </button>
  </div>
</article>
