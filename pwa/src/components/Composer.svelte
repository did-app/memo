<script lang="typescript">
  import { autoResize } from "../svelte/textarea";
  import type { Reference, Memo } from "../conversation";
  import * as Conversation from "../conversation";
  import type { Block, Annotation, Prompt } from "../writing";
  import * as Writing from "../writing";

  import Fragment from "../components/Fragment.svelte";
  import BlockComponent from "../components/Block.svelte";
  import * as Icons from "../icons";

  type AnnotationSpace = {
    reference: Reference;
    raw: string;
  };

  export let position: number;
  export let peers: Memo[];
  // peers -> previous, positon derived from peers, particularly if previous changes
  export let emailAddress: string;
  // Might want editable to become a thing
  // Maybe this is a slot if other things to compose
  let draft = "";
  let preview = false;
  let annotations: AnnotationSpace[] = [];

  export function addAnnotation(reference: Reference) {
    annotations = [...annotations, { reference, raw: "" }];
  }

  function mapAnnotation(draft: AnnotationSpace): Annotation[] {
    const { reference, raw } = draft;
    let blocks = Writing.parse(raw);
    if (blocks) {
      return [
        {
          type: "annotation",
          reference,
          blocks,
        },
      ];
    } else {
      return [];
    }
  }

  function clearAnnotation(index: number) {
    annotations.splice(index, 1);
    annotations = annotations;
  }

  let suggestedPrompts: Prompt[] = [];
  $: suggestedPrompts = preview
    ? suggestedPrompts
    : Conversation.makeSuggestions(blocks, position);
  function clearPrompt(index: number) {
    suggestedPrompts.splice(index, 1);
    suggestedPrompts = suggestedPrompts;
  }

  function referenceAuthor(peers: Memo[], reference: Reference) {
    let memo = peers[reference.memoPosition - 1];
    if (memo) {
      return memo.author;
    } else {
      throw "Should have crashed on referemce";
    }
    // Probably follow reference should return author
  }

  $: blocks = (function (): Block[] {
    let content = Writing.parse(draft);
    let mappedAnnotations: Annotation[] = annotations.flatMap(mapAnnotation);
    return content ? [...mappedAnnotations, ...content] : mappedAnnotations;
  })();

  let content: Block[] = [];
  $: content = [...blocks, ...suggestedPrompts];
  let current: Memo;
  $: current = {
    content: blocks,
    author: emailAddress,
    posted_at: new Date(),
    position,
  };

  function back() {
    preview = false;
  }
</script>

<style>
  textarea.message {
    min-height: 8rem;
  }
  textarea.comment {
    max-height: 25vh;
  }
</style>

{#if preview}
  <header class="ml-6 md:ml-12 mb-6 flex text-gray-600">
    <span class="font-bold">{emailAddress}</span>
    <span class="ml-auto">{new Date().toLocaleDateString()}</span>
  </header>
  <Fragment {blocks} {peers} />
  {#if suggestedPrompts.length !== 0}
    <h3 class="ml-6 md:ml-12 font-bold mt-4">
      Ask the following as highlighted questions.
    </h3>
  {/if}
  {#each suggestedPrompts as prompt, index}
    <div class="flex my-1">
      <div
        class="w-8 m-1 cursor-pointe preview ? suggestedPrompts :r flex-none"
        on:click={() => clearPrompt(index)}>
        <div class="w-6">
          <Icons.Bin />
        </div>
      </div>
      <div>
        {#each Conversation.followReference(prompt.reference, [
          ...peers,
          current,
        ]) as block, index}
          <BlockComponent {block} {index} {peers} />
        {/each}
      </div>
    </div>
  {/each}

  <slot {content} {back} />
{:else}
  <!-- TODO name previous inside composer -->
  {#each annotations as { reference, raw }, index}
    <div class="flex my-1">
      <div
        class="w-8 m-2 cursor-pointer flex-none"
        on:click={() => clearAnnotation(index)}>
        <div class="w-4">
          <Icons.Bin />
        </div>
      </div>
      <div class="w-full border-purple-500 border-l-4">
        <blockquote class=" px-2">
          <div class="opacity-50">
            {#each Conversation.followReference(reference, peers) as block, index}
              <BlockComponent {block} {index} {peers} />
            {/each}
          </div>
          <a
            class="text-purple-800"
            href="#{reference.memoPosition}"><small>{referenceAuthor(peers, reference)}</small></a>
        </blockquote>
        <div class="px-2">
          <textarea
            class="comment w-full bg-white outline-none"
            bind:value={raw}
            use:autoResize
            rows="1"
            autofocus
            placeholder="Your comment ..." />
        </div>
      </div>
    </div>
  {/each}
  <textarea
    class="message w-full bg-white outline-none pl-6 md:pl-12"
    use:autoResize
    bind:value={draft}
    placeholder="Your message ..." />
  <div class="mt-2 pl-6 md:pl-12 flex items-center">
    <div class="flex flex-1 min-w-0">
      <span class="font-bold text-gray-700 mr-1">From:</span>
      <input
        class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700"
        bind:value={emailAddress}
        type="email"
        placeholder="Your email address"
        readonly
        required />
    </div>
    <button
      on:click={() => {
        preview = true;
      }}
      class="flex items-center bg-gray-800 border-2 border-gray-800 text-white rounded px-2 ml-2">
      <span class="w-5 mr-2 inline-block">
        <Icons.Send />
      </span>
      <span class="py-1"> Preview </span>
    </button>
  </div>
{/if}
