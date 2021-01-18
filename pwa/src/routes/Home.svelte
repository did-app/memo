<script lang="typescript">
  import router from "page";
  import * as Conversation from "../conversation";
  import * as Writing from "../writing";
  import { emailAddressToPath } from "../social";
  import type { State } from "../sync";
  import SpanComponent from "../components/Span.svelte";

  export let state: State;
  let contactEmailAddress = "";

  function findContact() {
    router.redirect(emailAddressToPath(contactEmailAddress));
  }
</script>

<svelte:head>
  <title>Better Conversations</title>
</svelte:head>
{#if "me" in state && state.me}
  <main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
    
    {#each state.flash as f}
      {#if f.type === "acknowledged"}
        <article
          class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
        >
          <h2 class="font-bold">Sucess</h2>
          <p>{f.contact.identifier.emailAddress}</p>
        </article>
      {:else if f.type === "install_available"}
        <article
          class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
        >
          <h2 class="font-bold">Web-app download available</h2>
            <p>
              Install Memo's web-app on your computer, tablet or smartphone for faster access.
            </p>          
          <button
            on:click={f.prompt}
            class="bg-green-500 flex hover:bg-green-600 items-center mt-4 px-4 rounded text-white">
            <!-- <span class="w-5 mr-2 inline-block">
                      <Icons.ReplyAll />
                    </span> -->
            <span class="py-1"> Download </span>
          </button>
        </article>
      {/if}
    {/each}
    {#if state.me.greeting === null}
      <article
        class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
      >
        <h2 class="font-bold">Set up a greeting</h2>
        <p>
          Help filter new contacts when they reach out to you. Set up your
          <a class="underline" href="/profile">contact page.</a>
        </p>
      </article>
    {/if}
    <h1 class="text-2xl py-4">Your Contacts</h1>
    <ol>
      {#each state.contacts as { identifier, thread }}
        <li>
          <a
            class="text-xs block my-2 py-4 px-6 rounded border border-l-8 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-gray-400 hover:border-gray-800 focus:shadow-xl"
            href={emailAddressToPath(identifier.emailAddress) +
              "#" +
              thread.acknowledged}>
            <span class="font-bold text-base">{identifier.emailAddress}</span>

            {#if Conversation.isOutstanding(thread)}
              New message
            {:else}All caught up{/if}
            {#if thread.latest}
              {thread.latest.posted_at.toLocaleDateString()}

              <br />
              <p class="mt-2 truncate">
                {#each Writing.summary(thread.latest.content) as span}
                  <SpanComponent
                    {span}
                    offset={0}
                    unfurled={false}
                    placeholder={null}
                  />
                {/each}
              </p>
            {/if}
          </a>
        </li>
      {/each}
    </ol>
    <form on:submit|preventDefault={findContact}>
      <input
        class="border border-gray-400 focus:border-2 focus:border-gray-800 mt-8 p-2 rounded w-3/6"
        type="email"
        bind:value={contactEmailAddress}
        placeholder="Search Contacts"
      />
      <button
        class="px-6 py-2 border bg-gray-400 hover:bg-gray-800 text-white rounded"
        type="submit">Search</button
      >
    </form>
  </main>
{/if}
