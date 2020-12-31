<script lang="ts">
  import * as Thread from "../thread";
  import type { Note } from "../note";
  import { PROMPT } from "../note/elements";
  import type { Prompt } from "../note/elements";
  import * as Sync from "../sync";
  import type { Authenticated } from "../sync";

  import Loading from "../components/Loading.svelte";
  import ContactPage from "./ContactPage.svelte";

  export let contactEmailAddress: string;
  export let state: Authenticated;

  type Data = {
    threadId: number | undefined;
    ack: number;
    notes: Note[];
    contactEmailAddress: string;
  };

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
  let data: Data | undefined;
  (async function run() {
    console.log("Syc");
    data = await Sync.loadContact(state, contactEmailAddress);
  })();
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#if data}
    <ContactPage
      thread={data.notes.map(mapSuggestions)}
      threadId={data.threadId}
      ack={data.ack}
      contactEmailAddress={data.contactEmailAddress}
      myEmailAddress={state.me.email_address} />
  {:else}
    <Loading />
  {/if}
  <!-- {}
  {:then response}
    {#if 'error' in response}
      unknown error
    {:else}
    {/if}
  {/await} -->
</main>
