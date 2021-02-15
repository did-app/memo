<script lang="typescript">
  import router from "page";
  import type { Conversation } from "../conversation";
  import * as conversation_module from "../conversation";
  import * as Writing from "../writing";
  import type { Inbox } from "../sync";
  import SpanComponent from "../components/Span.svelte";

  export let inbox: Inbox;
  let contactEmailAddress = "";

  function findContact() {
    router.redirect(
      conversation_module.emailAddressToPath(contactEmailAddress)
    );
  }

  function outstanding(conversations: Conversation[]) {
    return conversations.filter(function (conversation) {
      return conversation_module.isOutstanding(conversation.participation);
    });
  }

  function older(conversations: Conversation[]) {
    return conversations.filter(function (conversation) {
      return !conversation_module.isOutstanding(conversation.participation);
    });
  }
  let hasSupport: boolean;
  $: hasSupport =
    inbox.conversations.findIndex(function ({ contact }) {
      return (
        "emailAddress" in contact &&
        contact.emailAddress === "team@sendmemo.app"
      );
    }) != -1;
</script>

<main class="w-full mx-auto max-w-2xl px-1 md:px-2 mb-8">
  <ol>
    {#each outstanding(inbox.conversations).reverse() as { contact, participation }}
      <li>
        <a
          class="text-xs block my-2 py-4 px-6 rounded border border-l-8 text-gray-800 bg-white focus:outline-none focus:border-gray-400 hover:border-gray-400 focus:shadow-xl hover:shadow-xl"
          href={conversation_module.url(contact) +
            "#" +
            participation.acknowledged}
        >
          <span class="font-bold text-base"
            >{conversation_module.subject(contact)[0]}</span
          >
          <!-- could be My group <5 participants> whatsapp doesnot show members very much -->
          <br />
          <p>
            {conversation_module.subject(contact)[1]}
          </p>
          {#if conversation_module.isOutstanding(participation)}
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
                  active={false}
                />
              {/each}
            </p>
          {/if}
        </a>
      </li>
    {:else}
      <li>
        <span class="text-center w-full block font-bold mb-3"
          >No outstanding messages</span
        >
      </li>
    {/each}
    {#if !hasSupport && !inbox.identifier.emailAddress.includes("sendmemo.app")}
      <li>
        <a
          class="text-xs block my-2 py-4 px-6 rounded border border-l-8 text-gray-800 bg-white focus:outline-none focus:border-gray-400 hover:border-gray-400 focus:shadow-xl hover:shadow-xl"
          href="/team"
        >
          <span class="font-bold text-base">team@sendmemo.app</span>
          <!-- could be My group <5 participants> whatsapp doesnot show members very much -->
          <br />
          <p class="mt-2">
            <!-- {conversation_module.subject(contact)[1]} -->
            Need any help? Get in touch with the Memo team
          </p>
        </a>
      </li>
    {/if}
    <li>
      <hr />
      <small class="text-center w-full block font-bold text-gray-500"
        >archive</small
      >
    </li>
    {#each older(inbox.conversations) as { contact, participation }}
      <li>
        <a
          class="text-xs block my-2 py-4 px-6 rounded border border-l-8 text-gray-800 bg-white focus:outline-none focus:border-gray-400 hover:border-gray-400 focus:shadow-xl hover:shadow-xl"
          href={conversation_module.url(contact) +
            "#" +
            participation.acknowledged}
        >
          <span class="font-bold text-base"
            >{conversation_module.subject(contact)[0]}</span
          >
          <!-- could be My group <5 participants> whatsapp doesnot show members very much -->
          <br />
          <p>
            {conversation_module.subject(contact)[1]}
          </p>
          {#if conversation_module.isOutstanding(participation)}
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
                  active={false}
                />
              {/each}
            </p>
          {/if}
        </a>
      </li>
    {/each}
  </ol>
  <form on:submit|preventDefault={findContact} class="mb-8">
    <input
      class="border border-gray-400 focus:border-2 focus:border-gray-800 mt-8 p-2 rounded w-3/6"
      type="email"
      bind:value={contactEmailAddress}
      placeholder="Email address"
    />
    <button
      class="px-6 py-2 border bg-gray-800 hover:bg-gray-600 text-white rounded"
      type="submit">Add Contact</button
    >
  </form>
  <a
    class="px-6 py-2 border bg-gray-800 hover:bg-gray-600 text-white rounded"
    href="/groups/new"
  >
    Create Group
  </a>
</main>
