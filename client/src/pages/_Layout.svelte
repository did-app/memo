<script type="text/javascript">
  import SignIn from "./SignIn.svelte"
  export let nav;
  import {loading} from "../sync";

  function unread(conversations) {
    return conversations.filter(function (c) {
      return c.to_reply
    }).slice().reverse()
  }
</script>

{#await loading}
TODO grey component blocks
{:then {identifier, conversations}}
{#if identifier && identifier.hasAccount}
<header class="z-20 md:h-16 h-auto fixed w-full bg-white text-left border-b-2">
  <nav class="ml-auto md:p-4 p-0 px-2 py-1">
    <a class="block md:inline text-center md:text-left" href="/">
      <span class="px-1 md:mr-8 mr-0 hover:text-indigo-800 hover:border-indigo-800 text-sm md:text-base font-semibold">Plum Mail</span>
    </a>
    <a style="padding-top:0.28em; padding-bottom:0.5em;" class="bg-green-500 hover:bg-green-700 transition duration-200 px-4 text-sm rounded-lg text-white leading-normal md:leading-none block sm:inline-block md:inline text-center sm:text-left w-8/12 mx-auto sm:w-auto" href="/begin">
      <svg class="fill-current w-4 mr-2 inline leading-none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" id="Capa_1" x="0px" y="0px" viewBox="0 0 512 512" style="enable-background:new 0 0 512 512;" xml:space="preserve">
        <g>
          <g>
            <path d="M485.743,85.333H26.257C11.815,85.333,0,97.148,0,111.589V400.41c0,14.44,11.815,26.257,26.257,26.257h459.487    c14.44,0,26.257-11.815,26.257-26.257V111.589C512,97.148,500.185,85.333,485.743,85.333z M475.89,105.024L271.104,258.626    c-3.682,2.802-9.334,4.555-15.105,4.529c-5.77,0.026-11.421-1.727-15.104-4.529L36.109,105.024H475.89z M366.5,268.761    l111.59,137.847c0.112,0.138,0.249,0.243,0.368,0.368H33.542c0.118-0.131,0.256-0.23,0.368-0.368L145.5,268.761    c3.419-4.227,2.771-10.424-1.464-13.851c-4.227-3.419-10.424-2.771-13.844,1.457l-110.5,136.501V117.332l209.394,157.046    c7.871,5.862,17.447,8.442,26.912,8.468c9.452-0.02,19.036-2.6,26.912-8.468l209.394-157.046v275.534L381.807,256.367    c-3.42-4.227-9.623-4.877-13.844-1.457C363.729,258.329,363.079,264.534,366.5,268.761z"></path>
          </g>
        </g>
      </svg>Compose
    </a>
    <p class="py-2 sm:py-0 ml-0 sm:ml-8 block sm:inline text-center sm:text-left text-xs text-gray-700">
      {#if unread(conversations).length}
      <a class="px-1 border-b-2 border-white {nav === "unread" ? 'text-indigo-800' : ''}" href="/unread">Outstanding</a>
      {/if}
      <a class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800 {nav === "search" ? 'text-indigo-800' : ''}" href="/">Search</a>
      <a class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800 {nav === "archive" ? 'text-indigo-800' : ''}" href="/archive">Archive</a>
      <a class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800" href="__API_ORIGIN__/sign_out">Sign out</a>
    </p>
  </nav>
</header>
{/if}
<main class="w-full max-w-2xl m-auto p-6">
  <h1 class="flex-grow font-serif text-indigo-800 text-6xl text-center">plum mail</h1>
  <slot {conversations}></slot>
</main>
{:catch {reason}}
{#if reason === 'unauthenticated'}
<SignIn/>
{:else}
Unknown failure
{/if}
{/await}
