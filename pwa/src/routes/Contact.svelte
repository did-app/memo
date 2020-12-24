<script lang="ts">
  import page from "page";
  import type { Block } from "../note/elements";
  import type { Note } from "../note";
  import { authenticationProcess } from "../sync";
  import * as API from "../sync/api";
  import Loading from "../components/Loading.svelte";
  import ContactPage from "./ContactPage.svelte";

  export let handle: string;

  type Failure = { error: true };
  type Data = {
    thread: Note[];
    contactEmailAddress: string;
    myEmailAddress: string;
  };
  async function load(handle: string): Promise<Data | Failure> {
    let contactEmailAddress = handle;
    let authResponse = await authenticationProcess;
    if ("error" in authResponse && authResponse.error.code === "forbidden") {
      // There is no 404 as will always try sending
      let profileResponse = await API.fetchProfile(contactEmailAddress);
      if ("error" in profileResponse) {
        return { error: true };
      }
      let myEmailAddress = "";
      let greeting = profileResponse.data.greeting;
      let thread = greeting
        ? [{ blocks: greeting, author: contactEmailAddress }]
        : [];
      return { thread, contactEmailAddress, myEmailAddress };
    } else if ("error" in authResponse) {
      throw "error fetching self";
    } else {
      if (authResponse.identifier.email_address === contactEmailAddress) {
        page.redirect("/profile");
        throw "redirected";
      } else {
        let response = await API.fetchContact(contactEmailAddress);
        if ("error" in response) {
          throw "error";
        }
        throw "todo";
      }
    }
  }
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#await load(handle)}
    <Loading />
  {:then response}
    {#if 'error' in response}
      unknown error
    {:else}
      <ContactPage
        thread={response.thread}
        contactEmailAddress={response.contactEmailAddress}
        myEmailAddress={response.myEmailAddress} />
    {/if}
  {/await}
</main>
