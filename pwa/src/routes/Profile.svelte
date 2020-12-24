<script lang="ts">
  import { authenticationProcess } from "../sync";
  import { parse, toString } from "../note";
  import type { Block } from "../note/elements";
  import * as API from "../sync/api";
  import Composer from "../components/Composer.svelte";

  // blocks to string
  let draft = "";
  let blocks: Block[] = [];
  let id: number;
  let emailAddress: string;

  // TODO signin and Error
  (async function run() {
    let response = await authenticationProcess;
    if ("error" in response) {
      throw "Profile not found";
    }
    id = response.id;
    emailAddress = response.email_address;
    draft = toString(response.greeting);
  })();
  $: (function () {
    blocks = parse(draft);
  })();

  async function saveGreeting(): Promise<null> {
    let response = await API.saveGreeting(id, blocks);
    if ("error" in response) {
      throw "failed to save greeting";
    }
    return null;
  }
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  <article
    class="my-4 py-6 pr-12 bg-gray-800 text-white pl-12 rounded-lg shadow-md ">
    {#if emailAddress}
      <h1 class="text-2xl">Hi {emailAddress}</h1>
    {:else}
      <h1 class="text-2xl">Loading profile</h1>
    {/if}
    <p>
      Set up your welcome message, that explains how people should get in touch
      with you.
    </p>
  </article>
  <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
    <Composer annotations={[]} notes={[]} bind:draft />
    <div class="mt-2 pl-12 flex items-center">
      <div class="flex flex-1">
        <!-- TODO this needs to show your email address, or if in header nothing at all -->
        <!-- <span class="font-bold text-gray-700 mr-1">From:</span>
        <input class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" bind:value={contact} type="email" placeholder="Your email address" required> -->
      </div>
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
  {JSON.stringify(blocks)}
</main>
