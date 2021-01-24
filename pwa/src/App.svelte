<script lang="typescript">
  import type { Conversation } from "./conversation";
  import type { State, Inbox } from "./sync";
  import * as Sync from "./sync";
  import * as API from "./sync/api";
  import type { Block } from "./writing";
  import Layout from "./routes/_Layout.svelte";
  import Contact from "./routes/Contact.svelte";
  import Home from "./routes/Home.svelte";
  import UnderConstruction from "./components/UnderConstruction.svelte";
  import SignIn from "./components/SignIn.svelte";
  import router from "page";

  let route: string;
  let params: { emailAddress: string } | { groupId: number } | undefined;
  router("/", (_) => {
    route = "home";
  });
  router("/groups/:groupId", (context) => {
    route = "contact";

    let groupId = parseInt(context.params.groupId);
    params = { groupId };
  });
  router("/:handle", (context) => {
    route = "contact";
    let emailAddress = context.params.handle + "@plummail.co";
    params = { emailAddress };
  });
  router("/:domain/:username", (context) => {
    route = "contact";
    let emailAddress = context.params.username + "@" + context.params.domain;
    params = { emailAddress };
  });

  let inbox: Inbox | null;
  let conversation: Conversation | null;
  let state = Sync.initial();

  $: inbox = Sync.selectedInbox(state);
  $: conversation = inbox && Sync.selectedConversation(inbox, params);

  initialize();
  router.start();

  async function initialize() {
    let response = await Sync.authenticate();
    state = { ...state, loading: false };
    if ("error" in response) {
      return (state = Sync.reportFailure(state, response.error));
    }
    let inboxes = response.data;
    if (inboxes) {
      state = { ...state, inboxes, inboxSelection: 0 };
    } else {
      return state;
    }
    console.log(state);

    let installPrompt = await Sync.startInstall(window);
    console.log(installPrompt);
  }
  async function pullMemos(conversation: Conversation | null) {
    if (conversation) {
      let response = await API.pullMemos(conversation.participation.threadId);
      if ("error" in response) {
        throw "TODO, this error needs to be passed up the component tree";
      }
      return response.data;
    } else {
      console.warn("TODO, look up profile");
      return Promise.resolve([]);
    }
  }
  async function acknowledge(threadId: number, position: number) {
    let { updated, counter } = Sync.startTask(state, "Acknowledging task");
    state = updated;
    router.redirect("/");
    let response = await API.acknowledge(threadId, position);
    if ("error" in response) {
      throw "Well this should be handled";
    } else {
      state = Sync.resolveTask(state, counter, "Conversation acknowledged");
    }
  }

  async function postMemo(
    threadId: number,
    position: number,
    content: Block[]
  ) {
    let { updated, counter } = Sync.startTask(state, "Posting memo");
    state = updated;
    router.redirect("/");
    let response = await API.postMemo(threadId, position, content);
    if ("error" in response) {
      throw "Well this should be handled";
    } else {
      state = Sync.resolveTask(state, counter, "Memo posted");
    }
  }

  async function startDirectConversation(
    authorId: number,
    emailAddress: string,
    content: Block[]
  ) {
    let message = "Starting conversation with " + emailAddress;
    let { updated, counter } = Sync.startTask(state, message);
    state = updated;
    router.redirect("/");
    let response = await API.startDirectConversation(
      authorId,
      emailAddress,
      content
    );
    if ("error" in response) {
      throw "Well this should be handled";
    } else {
      state = Sync.resolveTask(state, counter, "conversation started");
    }
  }

  let groupName = "";
  async function createGroup() {
    let response = await API.createGroup(groupName);
    console.log(response);

    // router.redirect;
  }
</script>

<Layout inboxes={state.inboxes} bind:inboxSelection={state.inboxSelection} />
<div class="w-full max-w-3xl mx-auto">
  {#each state.tasks as task}
    {#if task.type === "failure"}
      <article
        on:click={() => (state = Sync.removeTask(state, task.counter))}
        class="bg-gray-800 border-l-8 border-r-8 border-red-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
      >
        <h2 class="font-bold">{task.message}</h2>
        <p>We are working to fix this issue as soon as possible.</p>
      </article>
    {:else}
      <article
        on:click={() => (state = Sync.removeTask(state, task.counter))}
        class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
      >
        <h2 class="font-bold">
          {task.type === "running" ? "Running" : "Success"}
        </h2>
        <p>{task.message}</p>
      </article>
    {/if}
  {/each}
</div>
{#if route === "home"}
  {#if inbox}
    <Home {inbox} />
  {:else if state.loading === false}
    <SignIn />
  {/if}
{:else if route === "contact"}
  <!-- There should always be params on this route -->
  {#if inbox && params}
    {#if inbox.identifier.emailAddress === params.emailAddress}
      <!-- <Profile identifier={inbox.identifier} /> -->
      <UnderConstruction>
        <p>We are working on new features here.</p>
        <p>Thank you for your patience</p>
      </UnderConstruction>
    {:else}
      <Contact
        {conversation}
        contactEmailAddress={params?.emailAddress || "There should be an email"}
        {inbox}
        {pullMemos}
        {acknowledge}
        {postMemo}
        {startDirectConversation}
      />
    {/if}
  {:else}
    Will also show loading
  {/if}
{:else}
  <p>no route {JSON.stringify(route)}</p>
{/if}
<form on:submit|preventDefault={createGroup}>
  <input type="text" bind:value={groupName} />
  <button>Create group</button>
</form>
