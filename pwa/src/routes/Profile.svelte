<script lang="typescript">
  import * as Conversation from "../conversation";
  import type { State } from "../sync";
  import type { Block } from "../writing";
  import { parse, toString } from "../writing";
  import * as API from "../sync/api";
  import type { Identifier } from "../sync/api";
  import { emailAddressToPath } from "../social";

  import SpanComponent from "../components/Span.svelte";
  import * as Icons from "../icons";

  export let state: State;
  let me: Identifier;
  // let contacts: Contact[];
  let draft: string;
  if ("me" in state && state.me) {
    me = state.me;
    // contacts = state.contacts;
    draft = toString(me.greeting);
  }
  let blocks: Block[] | null = null;
  let suggestions: Conversation.Question[] = [];
  type SaveStatus = "available" | "working" | "suceeded" | "failed";
  let saveStatus: SaveStatus = "available";

  $: blocks = (function (): Block[] | null {
    saveStatus = "available";
    let blocks = parse(draft);
    if (blocks !== null) {
      suggestions = Conversation.makeSuggestions(blocks);
    }
    return blocks;
  })();

  async function saveGreeting(): Promise<null> {
    saveStatus = "working";
    let response = await API.saveGreeting(me.id, blocks);
    if ("error" in response) {
      saveStatus = "failed";
      throw "failed to save greeting";
    }
    saveStatus = "suceeded";
    return null;
  }
</script>

<svelte:head>
  <title>Profile</title>
</svelte:head>
<div class="flex w-full mx-auto max-w-5">
  <article class="flex-1 my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
    <!-- Impossible to put annotations in the middle of text Impossible to save
  question preferences
  <br />
  Click to make question, NEEDS a text representation for editable pages Can be
  '#? can't have multiple blocks
  `#?ask=peter@plummail.co,bob@plummail.co&urgency=` Question dismissed needs a
  text representation for editing Could simply not make questions optional.
  Keeping the question choices separate means that we can use text editing. BUT
  any change matching to choices requires a hack or tracking where someone is
  typing in the textarea, at which point we might as well have a right text edit
  Ahh but key feature is making annotations look like answers. Alice writes
  something, Bob asks for comment, but without further text. type is Prompt. If
  not optional, direct conversation, no urgency levels
  <br />
  steps are
  <br />
  Go through the example creating what will be created
  <br />
  Find all the questions that are not from you, link to blocks make suggestions
  unless you have annotated previously need a dismiss annotation false
  <br />
  Still even in rich editor don't want attached to question -->
    <textarea />
    <!-- {JSON.stringify(suggestions)} -->
    {#if suggestions.length}
      <h2 class="font-bold pl-12">Questions</h2>
    {/if}
    {#each suggestions as suggestion}
      <div class="pl-12">
        {#each suggestion.spans as span, index}
          <SpanComponent {span} {index} unfurled={false} />
        {/each}
      </div>
    {/each}

    <div class="mt-2 pl-12 flex items-center">
      <div class="flex flex-1" />
      {#if saveStatus === 'available'}
        <button
          class="flex-grow-0 flex items-center py-2 px-4 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold"
          on:click={saveGreeting}>
          <span class="inline-block w-4 mr-2">
            <Icons.Send />
          </span>
          Save
        </button>
      {:else if saveStatus === 'working'}
        <button
          class="flex-grow-0 flex items-center py-2 px-4 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold"
          on:click={saveGreeting}>
          <span class="inline-block w-4 mr-2">
            <Icons.Send />
          </span>
          Saving
        </button>
      {:else if saveStatus === 'suceeded'}
        <button
          class="flex-grow-0 flex items-center py-2 px-4 rounded-lg bg-green-500 focus:bg-green-700 hover:bg-green-700 text-white font-bold"
          on:click={saveGreeting}>
          <span class="inline-block w-4 mr-2">
            <Icons.Send />
          </span>
          Saved
        </button>
      {:else if saveStatus === 'failed'}
        <button
          class="flex-grow-0 flex items-center py-2 px-4 rounded-lg bg-red-500 focus:bg-red-700 hover:bg-red-700 text-white font-bold"
          on:click={saveGreeting}>
          <span class="inline-block w-4 mr-2">
            <Icons.Send />
          </span>
          Failed to save update
        </button>
      {/if}
    </div>
  </article>
  <div class="flex-shrink-0 max-w-sm ">
    <article
      class="my-4 py-6 pr-12 bg-gray-800 text-white pl-12 rounded-lg shadow-md ">
      <h1 class="text-2xl">Hi {me.email_address}</h1>
      <p>
        Set up your public greeting, that explains how people should get in
        touch with you.
      </p>
      <p>
        Anyone who visits
        <a
          class="underline"
          href="{window.location.origin}{emailAddressToPath(me.email_address)}">{window.location.origin}{emailAddressToPath(me.email_address)}</a>
        will be able to response this greeting
      </p>
    </article>
  </div>
</div>
