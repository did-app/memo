<script lang="ts">
  import page from "page";
  import * as Thread from "../thread";
  import type { Note } from "../note";
  import { PROMPT } from "../note/elements";
  import type { Prompt } from "../note/elements";
  import { authenticationProcess } from "../sync";
  import * as API from "../sync/api";
  import type { Failure } from "../sync/client";

  import Loading from "../components/Loading.svelte";
  import ContactPage from "./ContactPage.svelte";

  export let handle: string;

  type Data = {
    threadId: number | undefined;
    notes: Note[];
    contactEmailAddress: string;
    myEmailAddress: string;
  };
  async function load(handle: string): Promise<Data | { error: Failure }> {
    let contactEmailAddress = handle;
    let authResponse = await authenticationProcess;

    // Contact Page
    // API.fetchContact
    // {identifier: {id, emailAddress, greeting}, {}}
    // could redirect to thread page but we want to show thread plus contact information
    // Why would we ever want to show direct thread without contact information?
    // But linked threads will have a thread id
    // but that could be nested under the original /contact/name/linked/1
    // Greeting Page
    if ("error" in authResponse && authResponse.error.code === "forbidden") {
      // There is no 404 as will always try sending
      let profileResponse = await API.fetchProfile(contactEmailAddress);
      if ("error" in profileResponse) {
        throw "todo error";
      }
      let myEmailAddress = "";
      let greeting = profileResponse.data && profileResponse.data.greeting;
      let notes = greeting
        ? [
            {
              blocks: greeting,
              author: contactEmailAddress,
              inserted_at: new Date(),
              counter: 0,
            },
          ]
        : [];
      return {
        threadId: undefined,
        notes,
        contactEmailAddress,
        myEmailAddress,
      };
    } else if ("error" in authResponse) {
      throw "error fetching self";
    } else {
      const myEmailAddress = authResponse.data.email_address;
      if (myEmailAddress === contactEmailAddress) {
        page.redirect("/profile");
        throw "redirected";
      } else {
        let contactResponse = await API.fetchContact(contactEmailAddress);
        if ("error" in contactResponse) {
          throw "error";
        }
        let { thread, identifier } = contactResponse.data;

        if (!identifier) {
          return {
            threadId: undefined,
            notes: [],
            contactEmailAddress,
            myEmailAddress,
          };
        }
        if (thread) {
          let threadId = thread.id;
          let notes = thread.notes.map(function ({
            inserted_at: iso8601,
            ...rest
          }) {
            let inserted_at = new Date(iso8601);
            return { inserted_at, ...rest };
          });
          return {
            threadId,
            notes: notes,
            contactEmailAddress,
            myEmailAddress,
          };
        } else {
          let greeting = identifier.greeting;

          let notes = greeting
            ? [
                {
                  blocks: greeting,
                  author: contactEmailAddress,
                  inserted_at: new Date(),
                  counter: 0,
                },
              ]
            : [];
          return {
            threadId: undefined,
            notes,
            contactEmailAddress,
            myEmailAddress,
          };
        }
      }
    }
  }

  // TODO remove this for real prompts
  function mapSuggestions(note: Note, noteIndex: number) {
    let suggestions = Thread.makeSuggestions(note.blocks);
    console.log(suggestions, "suggestions", noteIndex);
    let prompts = suggestions.map(function (suggestion): Prompt {
      return {
        type: PROMPT,
        reference: { note: noteIndex, blockIndex: suggestion.blockIndex },
      };
    });

    return { ...note, blocks: [...note.blocks, ...prompts] };
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
        thread={response.notes.map(mapSuggestions)}
        threadId={response.threadId}
        contactEmailAddress={response.contactEmailAddress}
        myEmailAddress={response.myEmailAddress} />
    {/if}
  {/await}
</main>
