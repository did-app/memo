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

<main class="w-full mx-auto md:max-w-3xl px-1 md:px-2 py-6 ">
  <h1 class="text-2xl text-center">Create group</h1>
  <form
    class="shadow-md max-w-3xl mx-auto w-full bg-white rounded-lg px-8 pt-4 pb-8 my-6"
    on:submit|preventDefault|once={() =>
      createGroup(inbox.identifier.id, groupName, invitees)}
  >
    <label class="text-gray-600 font-bold">Group name:</label>
    <input
      class="w-full max-w-md block border-gray-500 shadow-md focus:border-green-600 outline-none focus:bg-gray-100 border-2 mb-6 py-2 px-4 rounded mt-4"
      type="text"
      bind:value={groupName}
      required
      placeholder="e.g. Dev Team"
    />
    <style>
      .checked:checked + span {
        font-weight: bold;
        color: rgba(16, 185, 129, var(--tw-bg-opacity));
      }
    </style>
    <label class="text-gray-600 font-bold">Select contacts:</label>
    <ul class="mb-2 mt-4 pb-4">
      {#each personalContacts(inbox) as { id, emailAddress }}
        <li class="flex items-center text-gray-600 hover:text-gray-800 my-2">
          <input
            class="w-4 h-4 checked"
            type="checkbox"
            bind:group={invitees}
            value={id}
          />
          <span class="ml-2">{emailAddress}</span>
        </li>
      {/each}
    </ul>
    {#if working}
      <button
        class="flex items-center bg-gray-800 border-2 border-gray-800 text-white rounded px-2"
      >
        <span class="py-1"> Creating Group </span>
      </button>
    {:else}
      <button
        class="flex items-center bg-gray-800 hover:bg-gray-600 border-2 border-gray-800 text-white rounded px-2"
      >
        <span class="py-1"> Create group </span>
      </button>
    {/if}
  </form>
</main>
