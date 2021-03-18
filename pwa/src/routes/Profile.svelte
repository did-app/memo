<script lang="typescript">

  import type { Identifier } from "../conversation";
  import * as conversation_module from "../conversation";
  import type { Block, Range } from "../writing";

  import Composer from "../components/Composer.svelte";
  import * as Icons from "../icons";

  export let identifier: Identifier;
  export let saveGreeting: (inboxId: string, greeting: Block[]) => void;

  let composerRange: Range | null = null;
  function exampleGreeting(name: string): Block[] {return[{
    type: "paragraph", spans: [
      {
        type: "text", text: "Hi, thanks for reaching out to me."
      }
    ],

  }, {
    type: "paragraph", spans: [
      {
        type: "text", text: "I am trying out Memo to spend less time in my inbox and have more productive conversations. To help me get started would you mind giving me a bit of context about your query."
      }
    ]

  }, {
    type: "paragraph", spans: [
      {
        type: "text", text: "Do you need an answer quickly, in which case please start with your question?"
      }
    ]

  },
  {
    type: "paragraph", spans: [
      {
        type: "text", text: "How do I know you, can you share a public profile, e.g. twitter?"
      }
    ]
  }, {
    type: "paragraph", spans: [
      {
        type: "text", text: "Thanks you, " + name
      }
    ]
  }]}
  let greetingEmpty = (identifier.greeting || []).length === 0
  let original = greetingEmpty ? exampleGreeting(identifier.name || "") : identifier.greeting || []
</script>

<main class="w-full mx-auto md:max-w-2xl px-1 md:px-2">
  <article
    class="my-4 py-2 px-6 md:px-12 bg-white rounded shadow"
  >
    <!-- <h2 class="font-bold">Welcome {identifier.emailAddress}</h2> -->
    <!-- <p class="my-3">
      Set up your public greeting that explains how people should get in touch
      with you.
    </p>

    <p class="my-3">
      Only new contacts will see your greeting, anyone you already communicate
      with using Memo will see your message history when they visit your contact
      page.
    </p> -->

    {#if greetingEmpty}
    <p class="my-2">
      Set up a greeting for <strong>{identifier.emailAddress}</strong>
    </p>
    <div class="">

      <p class="my-2">
        The greeting below is an example and will not be shared with anyone until you save it.
      </p>
      <p class="my-2">
        Feel free to edit as you like, or clear and start over.
      </p>
    </div>
    {:else}
    <p class="my-2">
      Greeting for <strong>{identifier.emailAddress}</strong>
    </p>
    <p class="my-2">
      Share your contact page:
      <a class="underline" href={conversation_module.url(identifier)}
        >{window.location.origin}{conversation_module.url(identifier)}</a
      >
    </p>
    <!-- Sharingbutton Facebook -->
<a class="" href="https://facebook.com/sharer/sharer.php?u={window.location.origin}{conversation_module.url(identifier)}" target="_blank" rel="noopener" aria-label="Facebook">
  <div class="inline-flex pr-2 mr-2 items-center">
    <div aria-hidden="true" class="w-5 mr-2">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <circle style="fill:white;stroke:black;" cx="12" cy="12" r="11.5"/>
        <path d="M15.84 9.5H13.5V8.48c0-.53.35-.65.6-.65h1.4v-2.3h-2.35c-2.3 0-2.65 1.7-2.65 2.8V9.5h-2v2h2v7h3v-7h2.1l.24-2z"/>
      </svg>
    </div>Facebook
  </div>
</a>

<!-- Sharingbutton Twitter -->
<a class="resp-sharing-button__link" href="https://twitter.com/intent/tweet/?text=I'm trying out Memo to control my inbox, why not say hi&url={window.location.origin}{conversation_module.url(identifier)}" target="_blank" rel="noopener" aria-label="Twitter">
  <div class="inline-flex pr-2 mr-2 items-center">
    <div aria-hidden="true" class="w-5 mr-2">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <circle style="fill:white;stroke:black;" cx="12" cy="12" r="11.5"/>
        <path d="M18.5 7.4l-2 .2c-.4-.5-1-.8-2-.8C13.3 6.8 12 8 12 9.4v.6c-2 0-4-1-5.4-2.7-.2.4-.3.8-.3 1.3 0 1 .4 1.7 1.2 2.2-.5 0-1 0-1.2-.3 0 1.3 1 2.3 2 2.6-.3.4-.7.4-1 0 .2 1.4 1.2 2 2.3 2-1 1-2.5 1.4-4 1 1.3 1 2.7 1.4 4.2 1.4 4.8 0 7.5-4 7.5-7.5v-.4c.5-.4.8-1.5 1.2-2z"/>
      </svg>
    </div>Twitter
  </div>
</a>

<!-- Sharingbutton E-Mail -->
<!-- <a class="resp-sharing-button__link" href="mailto:?subject=I'm trying out Memo to control my inbox, why not say hi&amp;body={window.location.origin}{conversation_module.url(identifier)}" target="_self" rel="noopener" aria-label="E-Mail">
  <div class="inline-flex pr-2 mr-2 items-center">
    <div aria-hidden="true" class="w-5 mr-2">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <circle style="fill:white;stroke:black;" cx="12" cy="12" r="11.5"/>
        <path d="M19.5 16c0 .8-.7 1.5-1.5 1.5H6c-.8 0-1.5-.7-1.5-1.5V8c0-.8.7-1.5 1.5-1.5h12c.8 0 1.5.7 1.5 1.5v8zm-2-7.5L12 13 6.5 8.5m11 6l-4-2.5m-7 2.5l4-2.5"/>
      </svg>
    </div>E-Mail
  </div>
</a> -->

<!-- Sharingbutton Hacker News -->
<a class="resp-sharing-button__link" href="https://news.ycombinator.com/submitlink?u={window.location.origin}{conversation_module.url(identifier)}&amp;t=I'm trying out Memo to control my inbox, why not say hi" target="_blank" rel="noopener" aria-label="Hacker News">
  <div class="inline-flex pr-2 mr-2 items-center">
    <div aria-hidden="true" class="w-5 mr-2">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
        <circle style="fill:white;stroke:black;" cx="128" cy="128" r="122.5"/>
        <path fill-rule="evenodd" stroke-width="10px" d="M128 256c70.692 0 128-57.308 128-128C256 57.308 198.692 0 128 0 57.308 0 0 57.308 0 128c0 70.692 57.308 128 128 128zm-9.06-113.686L75 60h20.08l25.85 52.093c.397.927.86 1.888 1.39 2.883.53.994.995 2.02 1.393 3.08.265.4.463.764.596 1.095.13.334.262.63.395.898.662 1.325 1.26 2.618 1.79 3.877.53 1.26.993 2.42 1.39 3.48 1.06-2.254 2.22-4.673 3.48-7.258 1.26-2.585 2.552-5.27 3.877-8.052L161.49 60h18.69l-44.34 83.308v53.087h-16.9v-54.08z"/>
      </svg>
    </div>Hacker News
  </div>
</a>

    {/if}
  </article>
  <article
    class="my-4 py-6  pr-6 md:pr-12 bg-white rounded-lg sticky bottom-0 border shadow-top"
  >
    <Composer
      previous={[]}
      blocks={original}
      position={1}
      selected={composerRange}
      let:blocks
    >
      <div class="mt-2 pl-6 md:pl-12 flex items-center">
        <div class="flex flex-1" />
        <button
          on:click={() => {
            original = [];
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
