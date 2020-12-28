<script lang="typescript">
  import { authenticationProcess } from "../sync";
  import * as API from "../sync/api";
  import Loading from "../components/Loading.svelte";

  type Date = {
    contacts: {};
  };
  async function load() {
    await authenticationProcess;
    let response = await API.fetchContacts();
    if ("error" in response) {
      throw "error fetching contacts";
    }
    return response.data;
  }
  console.log();
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#await load()}
    <Loading />
  {:then response}
    CONTACTS
    {#if 'error' in response}
      unknown
    {:else}
      <p>{JSON.stringify(response)}</p>
    {/if}
  {/await}
</main>
