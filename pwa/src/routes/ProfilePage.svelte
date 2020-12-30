<script lang="typescript">
  import { parse, toString } from "../note";
  import type { Block } from "../note/elements";
  import * as Thread from "../thread";
  import * as API from "../sync/api";
  import SpanComponent from "../components/Span.svelte";
  import Composer from "../components/Composer.svelte";
  import SendIcon from "../icons/Send.svelte";
  export let id: number;
  export let emailAddress: string;
  export let greeting: Block[] | null;

  let draft = toString(greeting);
  let blocks: Block[] | null = null;
  let suggestions: Thread.Question[] = [];
  type SaveStatus = "available" | "working" | "suceeded" | "failed";
  let saveStatus: SaveStatus = "available";

  $: blocks = (function (): Block[] | null {
    saveStatus = "available";
    let blocks = parse(draft);
    if (blocks !== null) {
      suggestions = Thread.makeSuggestions(blocks);
    }
    return blocks;
  })();

  async function saveGreeting(): Promise<null> {
    saveStatus = "working";
    let response = await API.saveGreeting(id, blocks);
    if ("error" in response) {
      saveStatus = "failed";
      throw "failed to save greeting";
    }
    saveStatus = "suceeded";
    return null;
  }
</script>

<article
  class="my-4 py-6 pr-12 bg-gray-800 text-white pl-12 rounded-lg shadow-md ">
  <h1 class="text-2xl">Hi {emailAddress}</h1>
  <p>
    Set up your welcome message, that explains how people should get in touch
    with you.
  </p>
</article>
<article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
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
  <Composer notes={[]} bind:draft annotations={[]} />
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
          <SendIcon />
        </span>
        Save
      </button>
    {:else if saveStatus === 'working'}
      <button
        class="flex-grow-0 flex items-center py-2 px-4 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold"
        on:click={saveGreeting}>
        <span class="inline-block w-4 mr-2">
          <SendIcon />
        </span>
        Saving
      </button>
    {:else if saveStatus === 'suceeded'}
      <button
        class="flex-grow-0 flex items-center py-2 px-4 rounded-lg bg-green-500 focus:bg-green-700 hover:bg-green-700 text-white font-bold"
        on:click={saveGreeting}>
        <span class="inline-block w-4 mr-2">
          <SendIcon />
        </span>
        Saved
      </button>
    {:else if saveStatus === 'failed'}
      <button
        class="flex-grow-0 flex items-center py-2 px-4 rounded-lg bg-red-500 focus:bg-red-700 hover:bg-red-700 text-white font-bold"
        on:click={saveGreeting}>
        <span class="inline-block w-4 mr-2">
          <SendIcon />
        </span>
        Failed to save update
      </button>
    {/if}
  </div>
</article>
