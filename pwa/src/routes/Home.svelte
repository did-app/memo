<script lang="typescript">
  import router from "page";
  import { authenticationProcess } from "../sync";
  import * as API from "../sync/api";
  import type { Identifier } from "../sync/api";
  import type { Failure } from "../sync/client";
  import { emailAddressToPath } from "../utils";
  import * as Flash from "../state/flash";
  import Loading from "../components/Loading.svelte";
  import SignIn from "../components/SignIn.svelte";

  let loading = true;
  let error: Failure | undefined;
  let identifier: Identifier | undefined;
  // This can probably be done by binding on an authenticationState store
  (async function () {
    let response = await authenticationProcess;
    if ("error" in response && response.error.code === "forbidden") {
      // Do nothing loading will be set to false
    } else if ("error" in response) {
      error = response.error;
      // reportError(response.error.detail);
    } else {
      identifier = response.data;
      if (identifier.greeting === undefined) {
        // TODO
      }
      loadContacts();
    }
    loading = false;
  })();

  let contacts: { identifier: Identifier }[] = [];
  async function loadContacts() {
    let response = await API.fetchContacts();
    if ("error" in response) {
      throw "TODO error";
    }
    contacts = response.data;
  }

  let contactEmailAddress: string;
  function findContact() {
    router.redirect(emailAddressToPath(contactEmailAddress));
  }

  function onSignIn(new_identifier: Identifier) {
    identifier = new_identifier;
    loadContacts();
  }
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#if error !== undefined}
    <article
      class="my-4 p-4 md:px-12 bg-white rounded-lg shadow-md bg-gradient-to-t from-gray-900 to-gray-700 text-white border-l-4 border-red-700">
      {error.detail}
    </article>
  {/if}
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
  {#if loading}
    <Loading />
  {:else if identifier === undefined}
    <SignIn success={onSignIn} />
  {:else}
    {identifier.email_address}

    <a
      class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800"
      href="{import.meta.env.SNOWPACK_PUBLIC_API_ORIGIN}/sign_out">Sign out</a>
    <ol>
      <h1>Your contacts</h1>
      {#each contacts as { identifier }}
        <li>
          <a
            class="block my-2 py-4 px-6 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl"
            href={emailAddressToPath(identifier.email_address)}>
            {identifier.email_address}</a>
        </li>
      {/each}
    </ol>
    <form on:submit|preventDefault={findContact}>
      <span>Search for</span>
      <input type="email" bind:value={contactEmailAddress} />
      <button type="submit">Submit</button>
    </form>
  {/if}
</main>
