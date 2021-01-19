<script lang="typescript">
  import router from "page";
  import type { State } from "../sync";
  import * as Sync from "../sync";
  import type { Block, Range } from "../writing";
  import * as Writing from "../writing";
  import { emailAddressToPath } from "../social";

  import Composer from "../components/Composer.svelte";
  // import SpanComponent from "../components/Span.svelte";
  import * as Icons from "../icons";

  export let state: State;
  if (!("me" in state) || state.me === undefined) {
    throw "This should be an idified page only";
  }

  let composerRange: Range | null = null;

  function handleSelectionChange() {
    let selection: Selection = (Writing as any).getSelection();
    let result = Writing.rangeFromDom(selection.getRangeAt(0));

    if (result && result[1] == 1) {
      const [range] = result;
      composerRange = range;
    } else {
      composerRange = null;
    }
  }

  async function saveGreeting(blocks: Block[]) {
    // return id somehow, separate public profile from identifier
    Sync.saveGreeting(blocks);
    router.redirect("/");
  }
</script>

<svelte:head>
  <title>Memo Profile</title>
</svelte:head>

{#if "me" in state && state.me}
  <main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
    <article
      class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
    >
      <h2 class="font-bold">Hi {state.me.emailAddress}</h2>
      <p>
        Set up your public greeting, that explains how people should get in
        touch with you.
      </p>
      <br />
      <p>
        Anyone who visits
        <a
          class="underline"
          href="{window.location.origin}{emailAddressToPath(
            state.me.emailAddress
          )}"
          >{window.location.origin}{emailAddressToPath(
            state.me.emailAddress
          )}</a
        >
        will be able to response this greeting and get in touch with you.
      </p>
    </article>
    <article
      class="my-4 py-6  pr-6 md:pr-12 bg-white rounded-lg sticky bottom-0 border shadow-top"
    >
      <Composer
        previous={[]}
        blocks={state.me.greeting || [{ type: "paragraph", spans: [] }]}
        position={1}
        selected={composerRange}
        let:blocks
      >
        <!-- {JSON.stringify(state.me)}
        <br />
        {JSON.stringify(blocks)} -->
        <div class="mt-2 pl-6 md:pl-12 flex items-center">
          <div class="flex flex-1" />
          <button
            on:click={() => {
              blocks = [];
            }}
            class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2">
            <span class="w-5 mr-2 inline-block">
              <Icons.Bin />
            </span>
            <span class="py-1">Clear</span>
          </button>
          <button
            on:click={() => saveGreeting(blocks)}
            class="flex items-center bg-gray-800 border-2 border-gray-800 text-white rounded px-2 ml-2">
            <span class="w-5 mr-2 inline-block">
              <Icons.Send />
            </span>
            <span class="py-1"> Save </span>
          </button>
        </div>
      </Composer>
    </article>
  </main>
{/if}
