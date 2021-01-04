<script lang="typescript">
  import router from "page";
  import * as Thread from "../thread";
  import { emailAddressToPath } from "../utils";
  import * as Flash from "../state/flash";
  import type { State } from "../sync";
  import SpanComponent from "../components/Span.svelte";
  import type { Identifier, Contact } from "../sync/api";

  export let state: State;
  let me: Identifier;
  let contacts: Contact[];
  if ("me" in state && state.me) {
    me = state.me;
    contacts = state.contacts;
  }
  let contactEmailAddress = "";

  function findContact() {
    router.redirect(emailAddressToPath(contactEmailAddress));
  }
</script>

<svelte:head>
  <title>Better Conversations</title>
</svelte:head>
<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#each Flash.pop() as message}
    <article
      class="my-4 p-4 md:px-12 bg-white rounded-lg shadow-md bg-gradient-to-t from-gray-900 to-gray-700 text-white border-l-4 border-green-700">
      <h2 class="font-bold">Sucess</h2>
      <p>{message}</p>
    </article>
  {/each}
  {#if me.greeting === null}
    <article
      class="my-4 p-4 md:px-12 bg-white rounded-lg shadow-md bg-gradient-to-t from-gray-900 to-gray-700 text-white border-l-4 border-green-700">
      <h2 class="font-bold">Set up a greeting</h2>
      <p>
        Help filter new contacts when they reach out to you. visit your
        <a class="underline" href="/profile">profile page</a>
      </p>
    </article>
  {/if}

  <ol>
    {#each contacts as { identifier, latest, ack }}
      <li>
        <a
          class="block my-2 py-4 px-6 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl"
          href={emailAddressToPath(identifier.email_address) + '#' + ack}>
          {identifier.email_address}
          <br />
          {#if (latest || { position: 0 }).position > ack}
            outstanding
          {:else}up to date{/if}
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
