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
    console.log(contactEmailAddress);
    let [username, domain] = contactEmailAddress.split("@");
    if (domain === "plummail.co") {
      router.redirect("/" + username);
    } else {
      router.redirect("/" + domain + "/" + username);
    }
  }
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#if loading}
    <Loading />
  {:else if identifier === undefined}
    <SignIn success={(new_identifier) => (identifier = new_identifier)} />
  {:else}
    <ol>
      {#each contacts as { identifier }}
        <li>{identifier.email_address}</li>
      {/each}
    </ol>
    <form on:submit|preventDefault={findContact}>
      <span>Search for</span>
      <input type="email" bind:value={contactEmailAddress} />
      <button type="submit">Submit</button>
    </form>
    <a
      class="inline px-1 border-b-2 border-white hover:text-indigo-800 hover:border-indigo-800"
      href="{import.meta.env.SNOWPACK_PUBLIC_API_ORIGIN}/sign_out">Sign out</a>
  {/if}
</main>
