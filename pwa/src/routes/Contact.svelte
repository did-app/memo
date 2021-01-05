<script lang="ts">
  import * as Thread from "../thread";
  import type { Memo } from "../memo";
  import { PROMPT } from "../memo/elements";
  import type { Prompt } from "../memo/elements";
  import * as Sync from "../sync";
  import type { Identifier } from "../sync/api";
  import type { State } from "../sync";
  import type { Authenticated } from "../sync";

  import Loading from "../components/Loading.svelte";
  import ContactPage from "./ContactPage.svelte";

  export let contactEmailAddress: string;
  export let state: State;
  let me: Identifier;
  // let contacts: Contact[];
  if ("me" in state && state.me) {
    me = state.me;
    // contacts = state.contacts;
  }

  type Data = {
    threadId: number | null;
    ack: number;
    memos: Memo[];
    contactEmailAddress: string;
  };

  // TODO remove this for real prompts
  function mapSuggestions(memo: Memo, memoPosition: number) {
    let suggestions = Thread.makeSuggestions(memo.content);
    let prompts = suggestions.map(function (suggestion): Prompt {
      return {
        type: PROMPT,
        reference: { memoPosition, blockIndex: suggestion.blockIndex },
      };
    });

    return { ...memo, content: [...memo.content, ...prompts] };
  }
  let data: Data | undefined;
  (async function run() {
    data = await Sync.loadContact(state as Authenticated, contactEmailAddress);
  })();
</script>

{#if data}
  <ContactPage
    thread={data.memos.map(mapSuggestions)}
    threadId={data.threadId}
    ack={data.ack}
    contactEmailAddress={data.contactEmailAddress}
    myEmailAddress={me.email_address} />
{:else}
  <Loading />
{/if}
