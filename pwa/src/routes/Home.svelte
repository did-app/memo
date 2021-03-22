<script lang="typescript">
  import router from "page";
  import type { Conversation, Identifier } from "../conversation";
  import * as conversation_module from "../conversation";
  import * as Writing from "../writing";
  import type { Inbox } from "../sync";
  import SpanComponent from "../components/Span.svelte";
  import ContactComponent from "../components/Contact.svelte";

  type Prompt =
    | {
        kind: "set_name" | "set_greeting";
        identifier: Identifier;
      }
    | { kind: "add_contact"; contactCount: number };
  export let inbox: Inbox;
  export let prompt: Prompt | null;
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

<main class="w-full mx-auto max-w-3xl md:px-2 mb-8">
  {#if outstanding(inbox.conversations).length !== 0}
    <h2 class="my-4 text-center w-full block text-2xl  text-gray-600">
      Outstanding
    </h2>
  {/if}
  {#each outstanding(inbox.conversations).reverse() as { contact, participation }}
    <ContactComponent
      link={conversation_module.url(contact) + "#" + participation.acknowledged}
      subject={conversation_module.subject(contact)[0]}
      description={conversation_module.subject(contact)[1]}
      datetime={participation.latest?.postedAt || null}
      summary={Writing.summary(participation.latest?.content || [])}
    />
  {/each}
  <h2 class="my-4 text-center w-full block text-2xl  text-gray-600">
    Contacts
  </h2>
  <div
    class="md:my-4 py-4 px-6 md:px-12 bg-white md:rounded shadow-inner md:shadow max-w-3xl"
  >
    {#if prompt && prompt.kind === "add_contact"}
      <h2 class="my-4 text-lg font-bold">Let's get chatting</h2>
      <p>
        You can write to <strong>anyone</strong> using their email address, Memo
        user or not. They will be able to access the conversation directly from their
        emails.
      </p>
      <p class="my-2">
        {#if prompt.contactCount === 0}
          Add an email address below to start your first conversation on Memo. <span
            class="text-green-500 font-bold">(0/5)</span
          >
        {:else}
          Add an email address below to start your next conversation on Memo. <span
            class="text-green-500 font-bold">({prompt.contactCount}/5)</span
          >
        {/if}
      </p>
    {/if}
    <form on:submit|preventDefault={findContact} class="mb-8">
      <input
        class="border border-gray-400 focus:border-2 focus:border-gray-800 mt-8 p-2 rounded w-3/6"
        type="email"
        bind:value={contactEmailAddress}
        placeholder="Email address"
      />
      <button
        class="px-6 py-2 border bg-gray-800 hover:bg-gray-600 text-white rounded"
        type="submit">Start Conversation</button
      >
    </form>
    {#if !prompt || prompt.kind !== "add_contact"}
      <a
        class="px-6 py-2 border bg-gray-800 hover:bg-gray-600 text-white rounded"
        href="/groups/new"
      >
        Create Group
      </a>
    {/if}
  </div>
  {#if !hasSupport && !inbox.identifier.emailAddress.includes("sendmemo.app")}
    <ContactComponent
      link={"/team"}
      subject={"Team Memo <team@sendmemo.app>"}
      description={null}
      datetime={new Date()}
      summary={[
        {
          type: "text",
          text: "Need any help? Get in touch with the Memo team",
        },
      ]}
    />
  {/if}
  {#each older(inbox.conversations) as { contact, participation }}
    <ContactComponent
      link={conversation_module.url(contact) + "#" + participation.acknowledged}
      subject={conversation_module.subject(contact)[0]}
      description={conversation_module.subject(contact)[1]}
      datetime={participation.latest?.postedAt || null}
      summary={Writing.summary(participation.latest?.content || [])}
    />
  {/each}
</main>
