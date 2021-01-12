<script lang="typescript">
  import router from "page";
  import { onMount } from "svelte";
  import type { Reference, Memo } from "../conversation";
  import * as Conversation from "../conversation";
  import type { Contact, Stranger } from "../social";
  import * as Social from "../social";
  import type { State, Authenticated, Call } from "../sync";
  import * as Sync from "../sync";
  import type { Block, Annotation, Prompt } from "../writing";
  import * as Writing from "../writing";

  import type Composer__SvelteComponent_ from "../components/Composer.svelte";

  import Composer from "../components/Composer.svelte";
  import MemoComponent from "../components/Memo.svelte";
  import BlockComponent from "../components/Block.svelte";
  import LinkComponent from "../components/Link.svelte";
  import SpanComponent from "../components/Span.svelte";
  import * as Icons from "../icons";

  export let stateAll: State;
  if (stateAll.loading === true) {
    throw "Shouldn't be loading";
  }
  let state: Authenticated = stateAll as Authenticated;

  let composer: Composer__SvelteComponent_;

  export let emailAddress: string;

  // TODO this needs to be a promise of old ones we load up
  let contact = Social.contactForEmailAddress(state.contacts, emailAddress);

  // Note scroll after loadMemos
  let target: number | undefined;
  onMount(function () {
    let id = window.location.hash.slice(1);
    if (id) {
      target = parseInt(id);
      let element = document.getElementById(id);
      if (element) {
        element.scrollIntoView();
      }
    }
    window.addEventListener(
      "hashchange",
      function () {
        let id = window.location.hash.slice(1);
        // TODO I think we need an on distroy
        if (id) {
          target = parseInt(id);
        }
      },
      false
    );
  });

  // acknowledge not an option if no thread
  // let reply: boolean = threadId === undefined;
  let reply: boolean = true;

  let root: HTMLElement;

  let userFocus: Reference | null = null;
  let focusSnapshot: Reference | null = null;
  function handleSelectionChange() {
    let selection: Selection = (Writing as any).getSelection();
    let userFocus = Writing.rangeFromDom(selection.getRangeAt(0));
    if (userFocus) {
      console.log(userFocus[0]);

      // reply = false;
    }
  }
  // This captures the focus for duration of a click
  document.addEventListener("mousedown", function () {
    focusSnapshot = userFocus;
  });

  onMount(() => {
    document.addEventListener("selectionchange", handleSelectionChange);
    return () =>
      document.removeEventListener("selectionchange", handleSelectionChange);
  });

  let loading: Call<Memo[]>;
  loading = (async function (): Call<Memo[]> {
    if ("id" in contact.thread) {
      const response = await Sync.loadMemos(contact.thread.id);
      if ("data" in response) {
        let memos = response.data;
        let references = Conversation.gatherPrompts(
          memos,
          state.me.emailAddress
        );

        references.map(function (reference) {
          composer.addAnnotation(reference);
        });
      }
      return response;
    } else {
      return Promise.resolve({ data: [] });
    }
  })();

  function quoteInReply() {
    if (focusSnapshot === null) {
      console.warn("Shouldn't be quoting without focus");
    } else {
      composer.addAnnotation(focusSnapshot);
    }
    reply = true;
  }

  function postMemo(content: Block[]) {
    Sync.postMemo(
      contact,
      content,
      Conversation.currentPosition(contact.thread) + 1
    );
    router.redirect("/");
  }

  function acknowledge(user: Contact | Stranger) {
    if ("id" in user.thread) {
      let contact = user as Contact;
      Sync.acknowledge(contact, Conversation.currentPosition(contact.thread));
      router.redirect("/");
    } else {
      console.warn("can't acknowledge stranger");
    }
  }
</script>

<style>
  .sidebar {
    grid-template-columns: minmax(0px, 1fr) 0px;
  }

  @media (min-width: 768px) {
    .sidebar {
      grid-template-columns: minmax(0px, 1fr) 20rem;
    }
  }
</style>

<svelte:head>
  <title>{emailAddress}</title>
</svelte:head>

<!-- {JSON.stringify(blocks)} -->
{#if 'me' in state && state.me}
  {#await loading}
    LOADING
  {:then response}
    {#if 'data' in response}
      <div class="w-full mx-auto max-w-3xl grid sidebar md:max-w-5xl">
        <div class="">
          <div class="" bind:this={root}>
            <!-- <p class="text-center">{contact.thread.acknowledged - 1} older</p>
            {#each response.data.slice(contact.thread.acknowledged - 1) as memo} -->
            <!-- TODO reduced shown -->
            {#each response.data as memo, index}
              <MemoComponent
                {memo}
                open={memo.position >= contact.thread.acknowledged || memo.position === target}
                peers={response.data} />
            {:else}
              <h1 class="text-center text-2xl my-4 text-gray-700">
                Contact
                <span class="font-bold">{emailAddress}</span>
              </h1>
            {/each}
          </div>
          <article
            class="my-4 py-6  pr-6 md:pr-12 bg-white rounded-lg shadow-md sticky bottom-0 border overflow-y-auto"
            style="max-height: 60vh;">
            <div class:hidden={!reply}>
              <Composer
                previous={response.data}
                bind:this={composer}
                position={response.data.length + 1}>
                <div class="mt-2 pl-6 md:pl-12 flex items-center">
                  <div class="flex flex-1" />
                  <button
                    on:click={back}
                    class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2">
                    <span class="w-5 mr-2 inline-block">
                      <Icons.ReplyAll />
                    </span>
                    <span class="py-1">Back</span>
                  </button>

                  <button
                    on:click={() => postMemo(content)}
                    class="flex items-center bg-gray-800 border-2 border-gray-800 text-white rounded px-2 ml-2">
                    <span class="w-5 mr-2 inline-block">
                      <Icons.Send />
                    </span>
                    <span class="py-1"> Send </span>
                  </button>
                </div>
              </Composer>
            </div>
            {#if !reply}
              {#if userFocus}
                <div
                  class="truncate ml-6 md:ml-12 border-gray-600 border-l-4 px-2 text-gray-600">
                  <!-- {#each Writing.summary(Conversation.followReference(userFocus, response.data)) as span, index}
                    <SpanComponent {span} {index} unfurled={false} />
                  {/each} -->
                  {#each Conversation.followReference(userFocus, [
                    ...response.data,
                    // current,
                  ]) as block, index}
                    <BlockComponent {block} {index} peers={response.data} />
                  {/each}
                </div>
              {/if}
              <nav class="flex pl-6 md:pl-12">
                {#if userFocus}
                  <button
                    on:click={quoteInReply}
                    class="flex items-center bg-gray-800 text-white ml-auto rounded px-2">
                    <span class="w-5 mr-2 inline-block">
                      <Icons.Quote />
                    </span>
                    <span class="py-1">Quote in Reply</span>
                  </button>
                {:else}
                  <button
                    class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2">
                    <span class="w-5 mr-2 inline-block">
                      <Icons.Pin />
                    </span>
                    <span class="py-1">Pins</span>
                  </button>
                  {#if 'thread' in contact && 'id' in contact.thread && Conversation.isOutstanding(contact.thread)}
                    <button
                      on:click={() => acknowledge(contact)}
                      class="flex items-center rounded px-2 inline-block ml-2 border-gray-500 border-2">
                      <span class="w-5 mr-2 inline-block">
                        <Icons.Check />
                      </span>
                      <span class="py-1">Acknowledge</span>
                    </button>
                  {/if}

                  <button
                    on:click={() => {
                      reply = true;
                    }}
                    class="flex items-center bg-gray-800 text-white rounded px-2 ml-2">
                    <span class="w-5 mr-2 inline-block">
                      <Icons.ReplyAll />
                    </span>
                    <span class="py-1">
                      <!-- TODO Icons.scribe  -->
                      {#if false}Draft{:else}Reply{/if}
                    </span>
                  </button>
                {/if}
              </nav>
            {/if}
          </article>
        </div>
        <div class="">
          <ul
            class="max-w-sm w-full sticky overflow-hidden"
            style="top:0.25rem">
            {#each Conversation.findPinnable(response.data) as pin}
              <li
                class="mb-1 mx-1 px-1 truncate  cursor-pointer text-gray-700 hover:text-purple-700 border-2 rounded flex items-center">
                {#if pin.item.type === 'link'}
                  <LinkComponent
                    url={pin.item.url}
                    title={pin.item.title}
                    index={0} />
                {:else if pin.item.type === 'annotation'}
                  <!-- TODO remove dummy index, simply make it optional -->

                  <span class="w-5 inline-block mr-2">
                    <Icons.Attachment />
                  </span>
                  {#each Writing.summary(Conversation.followReference(pin.item.reference, response.data)) as span, index}
                    <SpanComponent {span} {index} unfurled={false} />
                  {/each}
                {/if}
              </li>
            {:else}
              <li class="mb-1 mx-1 px-1">No items pinned yet.</li>
            {/each}
          </ul>
        </div>
      </div>
    {/if}
  {/await}
{:else}TODO rest of contact page{/if}
