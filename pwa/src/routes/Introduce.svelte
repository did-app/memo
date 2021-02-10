<script lang="typescript">
  import type { Memo, Conversation } from "../conversation";
  import * as API from "../sync/api";

  import MemoComponent from "../components/Memo.svelte";
  export let contactEmailAddress: string;
  export let pullMemos: (
    identifierId: string,
    conversation: Conversation | { stranger: string }
  ) => Promise<Memo[]>;

  let emailSent = false;
  let emailAddress = "";
  const action = `${
    (import.meta as any).env.SNOWPACK_PUBLIC_API_ORIGIN
  }/sign_in`;

  async function authenticate(event: Event) {
    event.preventDefault();
    let response = await API.authenticateByEmail(
      emailAddress,
      window.location.pathname
    );
    if ("error" in response) {
      throw "Bad email when going to public profile";
    }
    emailSent = true;
  }
</script>

<div class="w-full mx-auto max-w-3xl grid md:max-w-2xl">
  {#await pullMemos("", { stranger: contactEmailAddress })}
    <!-- Nought -->
    <!-- Note always only one memo -->
  {:then memos}
    {#each memos as memo}
      <!-- Memos should never be empty -->
      <MemoComponent {memo} open={true} peers={memos} />
    {/each}
    <article
      class="my-4 py-6  px-6 md:px-12 bg-white rounded-lg sticky bottom-0 border shadow-top max-w-2xl"
    >
      {#if emailSent}
        <p>
          A message has been sent to: <br /><strong>{emailAddress}</strong>.
        </p>
        <p class="mt-2">Click the link inside to validate your email.</p>
      {:else}
        <p>
          To contact {contactEmailAddress} please validate your email.
        </p>
        <form on:submit={authenticate} method="POST" {action}>
          <input
            type="email"
            name="email_address"
            required
            autocomplete="email"
            bind:value={emailAddress}
            class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-green-600 outline-none"
            placeholder="Email Address"
          />
          <button
            class="bg-green-500 hover:bg-green-700 mt-2 px-4 py-2 rounded text-white"
            type="submit">Validate email address</button
          >
        </form>
      {/if}
    </article>
  {/await}
</div>
