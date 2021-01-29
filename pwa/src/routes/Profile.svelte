<script lang="typescript">
  import type { Identifier } from "../conversation";
  import * as conversation_module from "../conversation";
  import type { Block, Range } from "../writing";

  import Composer from "../components/Composer.svelte";
  import * as Icons from "../icons";

  export let identifier: Identifier;
  export let saveGreeting: (inboxId: string, greeting: Block[]) => void;

  let composerRange: Range | null = null;
</script>

<main class="w-full mx-auto md:max-w-3xl px-1 md:px-2">
  <article
    class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
  >
    <h2 class="font-bold">Welcome {identifier.emailAddress}</h2>
    <p class="my-4">
      Set up your public greeting that explains how people should get in touch
      with you.
    </p>
    <p class="my-4">
      Share your contact page using this link:
      <a class="underline" href={conversation_module.url(identifier)}
        >{window.location.origin}{conversation_module.url(identifier)}</a
      >
    </p>
    <p class="my-4">
      Only new contacts will see your greeting, anyone you already communicate
      with using Memo will see your message history when they visit your contact
      page.
    </p>
  </article>
  <article
    class="my-4 py-6  pr-6 md:pr-12 bg-white rounded-lg sticky bottom-0 border shadow-top"
  >
    <Composer
      previous={[]}
      blocks={identifier.greeting || []}
      position={1}
      selected={composerRange}
      let:blocks
    >
      <div class="mt-2 pl-6 md:pl-12 flex items-center">
        <div class="flex flex-1" />
        <button
          on:click={() => {
            blocks = [];
          }}
          class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2"
        >
          <span class="w-5 mr-2 inline-block">
            <Icons.Bin />
          </span>
          <span class="py-1">Clear</span>
        </button>
        <button
          on:click={() => saveGreeting(identifier.id, blocks)}
          class="flex items-center bg-gray-800 border-2 border-gray-800 text-white rounded px-2 ml-2"
        >
          <span class="w-5 mr-2 inline-block">
            <Icons.Send />
          </span>
          <span class="py-1"> Save </span>
        </button>
      </div>
    </Composer>
  </article>
</main>
