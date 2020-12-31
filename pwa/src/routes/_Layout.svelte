<script lang="typescript">
  import { sync } from "../sync";
  import type { State } from "../sync";
  import Loading from "../components/Loading.svelte";
  import SignIn from "../components/SignIn.svelte";
  let state: State;
  $: state = $sync;
</script>

<!-- $store.attribute does not get properly collapsed types with typescript -->

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
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
