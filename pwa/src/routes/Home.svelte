<script lang="typescript">
  import router from "page";
  import * as Conversation from "../conversation";
  import * as Writing from "../writing";
  import type { Inbox } from "../sync";
  import SpanComponent from "../components/Span.svelte";

  export let inbox: Inbox | null;
  let contactEmailAddress = "";

  function findContact() {
    router.redirect(Conversation.emailAddressToPath(contactEmailAddress));
  }
</script>

{#if inbox !== null}
  <main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
    <!-- {#if inbox.identifier.greeting === null}
      <article
        class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
      >
        <h2 class="font-bold">Set up a greeting</h2>
        <p>
          Help filter new contacts when they reach out to you. Set up your
          <a class="underline" href="/profile">contact page.</a>
        </p>
      </article>
    {/if} -->
    <h1 class="text-2xl py-4">
      Your Conversations as {inbox.identifier.emailAddress}
    </h1>
    <ol>
      {#each inbox.conversations as { contact, participation }}
        <li>
          <a
            class="text-xs block my-2 py-4 px-6 rounded border border-l-8 text-gray-800 bg-white focus:outline-none focus:border-gray-400 hover:border-gray-400 focus:shadow-xl hover:shadow-xl"
            href={Conversation.url(contact) + "#" + participation.acknowledged}>
            <span class="font-bold text-base"
              >{Conversation.subject(contact)}</span
            >

            {#if Conversation.isOutstanding(participation)}
              New message
            {:else}All caught up{/if}
            {#if participation.latest}
              {participation.latest.postedAt.toLocaleDateString()}

              <br />
              <p class="mt-2 truncate">
                {#each Writing.summary(participation.latest.content) as span}
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
