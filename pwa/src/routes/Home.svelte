<script lang="typescript">
  import router from "page";
  import * as Conversation from "../conversation";
  import * as Writing from "../writing";
  import { emailAddressToPath } from "../social";
  import type { State } from "../sync";
  import SpanComponent from "../components/Span.svelte";
  // TODO export top level
  import type { InstallPrompt } from "../sync/install";

  export let state: State;
  let contactEmailAddress = "";

  function findContact() {
    router.redirect(emailAddressToPath(contactEmailAddress));
  }
</script>

<svelte:head>
  <title>Better Conversations</title>
</svelte:head>
{#if 'me' in state && state.me}
  <main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
    {#each state.flash as f}
      {#if f.type === 'acknowledged'}
        <article
          class="my-4 p-4 md:px-12 bg-white rounded-lg shadow-md bg-gradient-to-t from-gray-900 to-gray-700 text-white border-l-4 border-green-700">
          <h2 class="font-bold">Sucess</h2>
          <p>{f.contact.identifier.emailAddress}</p>
        </article>
      {:else if f.type === 'install_available'}
        <article
          class="my-4 p-4 md:px-12 bg-white rounded-lg shadow-md bg-gradient-to-t from-gray-900 to-gray-700 text-white border-l-4 border-green-700">
          <h2 class="font-bold">Available to install</h2>
          <button
            on:click={f.prompt}
            class="flex items-center bg-gray-200 text-gray-800 rounded px-2 ml-2">
            <!-- <span class="w-5 mr-2 inline-block">
                      <Icons.ReplyAll />
                    </span> -->
            <span class="py-1"> Install </span>
          </button>
        </article>
      {/if}
    {/each}
    {#if state.me.greeting === null}
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
      {#each state.contacts as { identifier, thread }}
        <li>
          <a
            class="block my-2 py-4 px-6 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl"
            href={emailAddressToPath(identifier.emailAddress) + '#' + thread.acknowledged}>
            {identifier.emailAddress}
            <br />
            {#if Conversation.isOutstanding(thread)}
              outstanding
            {:else}up to date{/if}
            {#if thread.latest}
              {thread.latest.posted_at.toLocaleDateString()}
              <br />
              <p class="truncate border rounded px-4">
                {#each Writing.summary(thread.latest.content) as span, index}
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
{/if}
