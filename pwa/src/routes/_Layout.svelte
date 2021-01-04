<script lang="typescript">
  import { sync } from "../sync";
  import type { State } from "../sync";
  import Loading from "../components/Loading.svelte";
  import SignIn from "../components/SignIn.svelte";
  let state: State;
  $: state = $sync;
</script>

<!-- $store.attribute does not get properly collapsed types with typescript -->

<svelte:head>
  <slot name="head">
    <title>Better Conversations</title>
  </slot>
</svelte:head>
<header class="px-6">
  <nav class="max-w-5xl mx-auto flex flex-wrap items-center text-lg md:text-xl">
    <span class="my-1 flex-grow">
      <a
        class="text-purple-700 hover:text-purple-900 font-bold text-2xl"
        href="/">
        memo
      </a>
      {#if state.loading === false && state.me}
        /
        <a href="/profile"> {state.me.email_address} </a>
      {/if}
    </span>
    <span class="my-1 ml-4">
      {#if state.loading}
        loading
      {:else if state.me === undefined}
        <!-- <a
          href="https://auth.did.app"
          class="bg-gray-800 text-white ml-auto rounded px-2 py-1 ml-2">Sign in</a> -->
      {:else}
        <!-- explicitly set target so page.js ignores it -->
        <a
          target="_self"
          class="bg-gray-800 text-white ml-auto rounded px-2 py-1 ml-2"
          href="{import.meta.env.SNOWPACK_PUBLIC_API_ORIGIN}/sign_out">Sign out</a>
      {/if}
    </span>
  </nav>
</header>
<main class="w-full md:px-2">
  {#if state.loading}
    <Loading />
  {:else if state.me === undefined}
    {#if state.error !== undefined}
      <article
        class="my-4 p-4 md:px-12 bg-white rounded-lg shadow-md bg-gradient-to-t from-gray-900 to-gray-700 text-white border-l-4 border-red-700">
        {state.error.detail}
      </article>
    {/if}
    <SignIn />
  {:else}
    <slot {state} />
  {/if}
</main>
