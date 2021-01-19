<script lang="typescript">
  import router from "page";
  import { onMount, tick } from "svelte";
  import type { Reference, Memo } from "../conversation";
  import * as Conversation from "../conversation";
  import type { Contact, Stranger } from "../social";
  import * as Social from "../social";
  import type { State, Authenticated, Call } from "../sync";
  import * as Sync from "../sync";
  import type { Block, Range } from "../writing";
  import * as Writing from "../writing";

  import type Composer__SvelteComponent_ from "../components/Composer.svelte";

  import Composer from "../components/Composer.svelte";
  import MemoComponent from "../components/Memo.svelte";
  import BlockComponent from "../components/Block.svelte";
  import LinkComponent from "../components/Link.svelte";
  import LoadingComponent from "../components/Loading.svelte";

  import * as Icons from "../icons";

  export let stateAll: State;
  if (stateAll.loading === true) {
    throw "Shouldn't be loading";
  }
  let state: Authenticated = stateAll as Authenticated;

  let composer: Composer__SvelteComponent_;

  export let emailAddress: string;

  // This needs to be a promise of old ones we load up
  let contactLookup = Social.contactForEmailAddress(
    state.contacts,
    emailAddress
  );

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
        // I think we need an on distroy
        if (id) {
          target = parseInt(id);
        }
      },
      false
    );
  });

  // acknowledge not an option if no thread
  // let reply: boolean = threadId === undefined;
  let reply: boolean = false;

  let root: HTMLElement;

  let userFocus: Reference | null = null;
  let focusSnapshot: Reference | null = null;
  let currentPosition: number = 0;
  let composerRange: Range | null = null;

  function handleSelectionChange() {
    let selection: Selection = (Writing as any).getSelection();
    let result = Writing.rangeFromDom(selection.getRangeAt(0));

    if (result && result[1] <= currentPosition) {
      const [range, memoPosition] = result;

      if (Writing.isCollapsed(range)) {
        userFocus = {
          memoPosition,
          blockIndex: range.anchor.path[0] as number,
        };
      } else {
        userFocus = { memoPosition, range };
      }

      reply = false;
    } else {
      userFocus = null;
    }
    if (result && result[1] == currentPosition + 1) {
      const [range] = result;
      composerRange = range;
    } else {
      composerRange = null;
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

  let loading: Call<{ contact: Contact | Stranger; memos: Memo[] }>;
  loading = (async function (): Call<{
    contact: Contact | Stranger;
    memos: Memo[];
  }> {
    let contactResult = await contactLookup;
    if ("data" in contactResult) {
      let contact = contactResult.data;
      if ("id" in contact.thread) {
        const response = await Sync.loadMemos(contact.thread.id);
        if ("data" in response) {
          let memos = response.data;
          currentPosition = memos.length;
          tick().then(function () {
            // Tick seems to now work with the composer getting rendered.
            setTimeout(function name() {
              let references = Conversation.gatherPrompts(
                memos,
                state.me.emailAddress
              );

              references.map(function (reference) {
                composer.addAnnotation(reference);
              });
            }, 100);
          });
          return { data: { contact, memos } };
        } else {
          throw "TROUBLE looking up memos";
        }
      } else {
        return Promise.resolve({ data: { contact, memos: [] } });
      }
    } else {
      throw "We had trouble looking up contact information";
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

  function postMemo(contact: Contact | Stranger, content: Block[]) {
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

<svelte:head>
  <title>{emailAddress}</title>
</svelte:head>

{#if "me" in state && state.me}
  <div class="w-full mx-auto max-w-3xl grid sidebar md:max-w-2xl">
    {#await loading}
      <div>
        <LoadingComponent />
      </div>
      <div />
    {:then response}
      {#if "data" in response}
        <div class="">
          <div class="" bind:this={root}>
            <!-- <p class="text-center">{contact.thread.acknowledged - 1} older</p>
            {#each response.data.slice(contact.thread.acknowledged - 1) as memo} -->
            {#each response.data.memos as memo}
              <MemoComponent
                {memo}
                open={memo.position >=
                  response.data.contact.thread.acknowledged ||
                  memo.position === target}
                peers={response.data.memos}
              />
            {:else}
              {#if response.data.contact.identifier.greeting === null}
                <h1 class="text-center text-2xl my-4 text-gray-700">
                  Contact
                  <span class="font-bold">{emailAddress}</span>
                </h1>
              {:else}
                <h1 class="text-center text-lg my-4 text-gray-700">
                  This is an automated greeting from
                  <span class="font-bold">{emailAddress}</span>
                </h1>

                <MemoComponent
                  memo={{
                    content: response.data.contact.identifier.greeting,
                    posted_at: new Date(),
                    position: 0,
                    author: response.data.contact.identifier.emailAddress,
                  }}
                  open={true}
                  peers={[]}
                />
              {/if}
            {/each}
          </div>
          <article
            class="my-4 py-6  pr-6 md:pr-12 bg-white rounded-lg sticky bottom-0 border shadow-top"
          >
            <div class:hidden={!reply}>
              <Composer
                previous={response.data.memos}
                bind:this={composer}
                selected={composerRange}
                blocks={[
                  { type: "paragraph", spans: [{ type: "text", text: "" }] },
                ]}
                position={response.data.memos.length + 1}
                let:blocks
              >
                <div class="mt-2 pl-6 md:pl-12 flex items-center">
                  <div class="flex flex-1" />
                  <button
                    on:click={() => {
                      reply = false;
                    }}
                    class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2">
                    <span class="w-5 mr-2 inline-block">
                      <Icons.ReplyAll />
                    </span>
                    <span class="py-1">Back</span>
                  </button>
                  <button
                    on:click={() => postMemo(response.data.contact, blocks)}
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
                  class="truncate ml-6 md:ml-12 border-gray-600 border-l-4 px-2 text-gray-600"
                >
                  <!-- {#each Writing.summary(Conversation.followReference(userFocus, response.data)) as span, index}
                    <SpanComponent {span} {index} unfurled={false} />
                  {/each} -->
                  {#each Conversation.followReference(userFocus, [
                    ...response.data.memos,
                    // current,
                  ]) as block, index}
                    <BlockComponent
                      {index}
                      {block}
                      peers={response.data.memos}
                      truncate={false}
                      placeholder={null}
                    />
                  {/each}
                </div>
              {/if}
              <nav class="flex pl-6 md:pl-12">
                {#if userFocus}
                  <button
                    on:click={() => {
                      userFocus = null;
                    }}
                    class="flex items-center rounded px-2 inline-block ml-auto border-gray-500 border-2">
                    <!-- <span class="w-5 mr-2 inline-block">
                      <Icons.ReplyAll />
                    </span> -->
                    <span class="py-1">Clear</span>
                  </button>
                  <button
                    on:click={quoteInReply}
                    class="flex items-center bg-gray-800 text-white ml-2 rounded px-2">
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
                  {#if "thread" in response.data.contact && "id" in response.data.contact.thread && Conversation.isOutstanding(response.data.contact.thread)}
                    <button
                      on:click={() => acknowledge(response.data.contact)}
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
            style="top:0.25rem"
          >
            {#each Conversation.findPinnable(response.data.memos) as pin}
              <li
                class="mb-1 mx-1 px-1 truncate  cursor-pointer text-gray-700 hover:text-purple-700 border-2 rounded flex items-center"
              >
                {#if pin.item.type === "link"}
                  <LinkComponent
                    url={pin.item.url}
                    title={pin.item.title}
                    offset={0}
                  />
                {:else if pin.item.type === "annotation"}
                  <!-- remove dummy index, simply make it optional -->

                  <span class="w-5 inline-block mr-2">
                    <Icons.Attachment />
                  </span>
                  <!-- {#each Writing.summary(Conversation.followReference(pin.item.reference, response.data)) as span, index}
                    <SpanComponent {span} {index} unfurled={false} />
                  {/each} -->
                {/if}
              </li>
            {:else}
              <li class="mb-1 mx-1 px-1">No items pinned yet.</li>
            {/each}
          </ul>
        </div>
      {/if}
    {/await}
  </div>
{:else}rest of contact page{/if}

<style>
  .sidebar {
    grid-template-columns: minmax(0px, 1fr) 0px;
  }

  @media (min-width: 768px) {
    .sidebar {
      grid-template-columns: minmax(0px, 1fr) 0px;
    }
  }
  .shadow-top {
    box-shadow: 0 -3px 10px 0px rgb(143 143 143);
  }
</style>
