<script lang="typescript">
  import router from "page";
  import * as Thread from "../thread";
  import type { Block } from "../note/elements";
  import { emailAddressToPath } from "../utils";
  import * as Flash from "../state/flash";
  import type { Authenticated } from "../sync";
  import SpanComponent from "../components/Span.svelte";

  export let state: Authenticated;
  let contactEmailAddress = "";

  function findContact() {
    router.redirect(emailAddressToPath(contactEmailAddress));
  }
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#each Flash.pop() as message}
    <article
      class="my-4 p-4 md:px-12 bg-white rounded-lg shadow-md bg-gradient-to-t from-gray-900 to-gray-700 text-white border-l-4 border-green-700">
      <h2 class="font-bold">Sucess</h2>
      <p>{message}</p>
    </article>
  {/each}
  <!-- {#if identifier.greeting === null}
  <article
    class="my-4 p-4 md:px-12 bg-white rounded-lg shadow-md bg-gradient-to-t from-gray-900 to-gray-700 text-white border-l-4 border-green-700">
    <h2 class="font-bold">Set up a greeting</h2>
    <p>
      Help filter new contacts when they reach out to you. visit your
      <a class="underline" href="/profile">profile page</a>
    </p>
  </article>
{/if} -->
  {state.me.email_address}

  <a
    class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800"
    href="{import.meta.env.SNOWPACK_PUBLIC_API_ORIGIN}/sign_out">Sign out</a>
  <ol>
    <h1>Your contacts</h1>
    {#each state.contacts as { identifier, outstanding, latest }}
      <li>
        <a
          class="block my-2 py-4 px-6 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl"
          href={emailAddressToPath(identifier.email_address)}>
          {identifier.email_address}
          <br />
          {#if outstanding}outstanding{:else}up to date{/if}
          {latest && new Date(latest.inserted_at).toLocaleDateString()}
          <br />
          {#if latest}
            <p class="truncate border rounded px-4">
              {#each Thread.summary(latest.content) as span, index}
                <SpanComponent {span} {index} unfurled={false} />
              {/each}
            </p>
          {/if}
        </a>
      </li>
    {/each}
  </ol>
  <form on:submit|preventDefault={findContact}>
    <span>Search for</span>
    <input type="email" bind:value={contactEmailAddress} />
    <button type="submit">Submit</button>
  </form>
</main>
