<script lang="typescript">
  import router from "page";
  import { authenticationProcess } from "../sync";
  import Loading from "../components/Loading.svelte";
  import SignIn from "../components/SignIn.svelte";
  import * as API from "../sync/api";
  import type { Identifier } from "../sync/api";

  let loading = true;
  let identifier: Identifier | undefined;
  // This can probably be done by binding on an authenticationState store
  (async function () {
    try {
      let response = await authenticationProcess;
      if ("error" in response) {
        throw "TODO error";
      } else {
        identifier = response.data;
        loadContacts();
      }
    } catch (error) {
    } finally {
      loading = false;
    }
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

  function emailAddressToPath(emailAddress: string) {
    let [username, domain] = emailAddress.split("@");
    if (domain === "plummail.co") {
      return "/" + username;
    } else {
      return "/" + domain + "/" + username;
    }
  }

  function onSignIn(new_identifier: Identifier) {
    identifier = new_identifier;
    loadContacts();
  }
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#if loading}
    <Loading />
  {:else if identifier === undefined}
    <!-- TODO load contacts -->
    <SignIn success={onSignIn} />
  {:else}
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
