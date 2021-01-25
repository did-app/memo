<script lang="typescript">
  import type { Personal } from "../conversation";
  import type { Inbox } from "../sync";
  export let inbox: Inbox;
  export let createGroup: (
    inboxId: string,
    name: string,
    invitees: number[]
  ) => void;

  let groupName = "";
  let invitees: number[] = [];
  function personalContacts(inbox: Inbox): Personal[] {
    return inbox.conversations
      .filter(function (conversation) {
        return conversation.contact.type === "personal";
      })
      .map(function ({ contact }) {
        return contact;
      }) as Personal[];
  }
  let working = false;
</script>

<main class="w-full mx-auto md:max-w-3xl px-1 md:px-2">
  <h1>New group</h1>
  <form
    on:submit|preventDefault|once={() =>
      createGroup(inbox.identifier.id, groupName, invitees)}
  >
    <input type="text" bind:value={groupName} required />
    <ul>
      {#each personalContacts(inbox) as { id, emailAddress }}
        <li>
          <input type="checkbox" bind:group={invitees} value={id} />
          {emailAddress}
        </li>
      {/each}
    </ul>
    {JSON.stringify(invitees)}
    {#if working}
      <button
        class="ml-auto flex items-center bg-gray-800 border-2 border-gray-800 text-white rounded px-2 ml-2">
        <span class="py-1"> Creating Group </span>
      </button>
    {:else}
      <button
        class="ml-auto flex items-center bg-gray-800 border-2 border-gray-800 text-white rounded px-2 ml-2">
        <span class="py-1"> Create group </span>
      </button>
    {/if}
  </form>
</main>
