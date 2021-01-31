<script lang="typescript">
  import type { Memo, Conversation } from "./conversation";
  import type { State, Inbox } from "./sync";
  import * as Sync from "./sync";
  import * as API from "./sync/api";
  import type { Block } from "./writing";
  import Layout from "./routes/_Layout.svelte";
  import Contact from "./routes/Contact.svelte";
  import Home from "./routes/Home.svelte";
  import NewGroup from "./routes/NewGroup.svelte";
  import Profile from "./routes/Profile.svelte";
  import SignIn from "./components/SignIn.svelte";
  import router from "page";

  let route: string;
  let params: { emailAddress: string } | { groupId: string } | undefined;
  let sharedParams:
    | { title: string | null; text: string | null; url: string | null }
    | undefined;
  router("/", (_) => {
    route = "home";
  });
  router("/share", (_) => {
    sharedParams = readShareParams();
    router.replace("/");
  });

  router("/groups/new", (context) => {
    route = "new_group";
    params = undefined;
  });
  router("/groups/:groupId", (context) => {
    route = "contact";

    let groupId = context.params.groupId;
    params = { groupId };
  });
  router("/:handle", (context) => {
    route = "contact";
    let emailAddress = context.params.handle + "@sendmemo.app";
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
  let installPrompt:
    | (() => Promise<{
        outcome: "accepted" | "dismissed";
        platform: string;
      }>)
    | null;

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

    installPrompt = await Sync.startInstall(window);
  }

  async function pullMemos(
    identifierId: string,
    conversation: Conversation | { stranger: string }
  ): Promise<Memo[]> {
    if ("stranger" in conversation) {
      let response = await API.fetchProfile(conversation.stranger);
      if ("error" in response) {
        throw "TODO, this error needs to be passed up the component tree for Prof ile";
      }
      let greeting = response.data.greeting;
      if (greeting) {
        return [
          {
            author: conversation.stranger,
            position: 1,
            content: greeting,
            postedAt: new Date(),
          },
        ];
      } else {
        return [];
      }
    } else {
      let response = await API.pullMemos(
        identifierId,
        conversation.participation.threadId
      );
      if ("error" in response) {
        throw "TODO, this error needs to be passed up the component tree";
      }
      return response.data;
    }
  }

  async function acknowledge(
    inboxId: string,
    threadId: string,
    position: number
  ) {
    let { updated, counter } = Sync.startTask(state, "Acknowledging task");
    state = updated;
    router.redirect("/");
    let response = await API.acknowledge(inboxId, threadId, position);
    if ("error" in response) {
      throw "Well this should be handled";
    } else {
      let s = Sync.resolveTask(state, counter, "Conversation acknowledged");
      state = updateInbox(s, inboxId, function (inbox) {
        return updateConversation(inbox, threadId, function (conversation) {
          let participation = {
            ...conversation.participation,
            acknowledged: position,
          };
          return { ...conversation, participation };
        });
      });
    }
  }

  function updateInbox(
    state: State,
    inboxId: string,
    update: (i: Inbox) => Inbox
  ): State {
    let inboxes = state.inboxes;
    let inboxIndex = inboxes.findIndex(function (inbox) {
      return inbox.identifier.id == inboxId;
    });
    let inbox = inboxes[inboxIndex];
    if (!inbox) {
      throw "There should always be an inbox at this point";
    }
    inbox = update(inbox);
    inboxes = inboxes
      .slice(0, inboxIndex)
      .concat(inbox)
      .concat(inboxes.slice(inboxIndex + 1));
    return { ...state, inboxes };
  }

  function updateConversation(
    inbox: Inbox,
    threadId: string,
    update: (c: Conversation) => Conversation
  ) {
    let conversations = inbox.conversations;
    let conversationIndex = conversations.findIndex(function (conversation) {
      return conversation.participation.threadId === threadId;
    });
    let conversation = conversations[conversationIndex];
    if (!conversation) {
      throw "We should always have found a conversation";
    }
    conversation = update(conversation);
    conversations = [conversation]
      .concat(conversations.slice(0, conversationIndex))
      .concat(conversations.slice(conversationIndex + 1));

    return { ...inbox, conversations };
  }

  async function postMemo(
    inboxId: string,
    threadId: string,
    position: number,
    content: Block[]
  ) {
    let { updated, counter } = Sync.startTask(state, "Posting memo");
    state = updated;
    router.redirect("/");
    let response = await API.postMemo(inboxId, threadId, position, content);
    if ("error" in response) {
      throw "Well this should be handled";
    } else {
      let s = Sync.resolveTask(state, counter, "Memo posted");
      let latest = response.data;
      state = updateInbox(s, inboxId, function (inbox) {
        return updateConversation(inbox, threadId, function (conversation) {
          let participation = {
            ...conversation.participation,
            acknowledged: latest.position,
            latest: latest,
          };
          return { ...conversation, participation };
        });
      });
    }
  }

  async function createGroup(
    inboxId: string,
    name: string,
    invitees: number[]
  ) {
    // Could use the notification interface but we aren't redirecting to the home page
    let response = await API.createGroup(name, invitees);
    if ("error" in response) {
      throw "We need to show this error better";
    } else {
      let data = response.data;
      state = updateInbox(state, inboxId, function (inbox) {
        let conversations = [data, ...inbox.conversations];
        return { ...inbox, conversations };
      });
      router.redirect("/groups/" + response.data.contact.id);
    }
  }

  async function startDirectConversation(
    inboxId: string,
    authorId: string,
    emailAddress: string,
    content: Block[]
  ) {
    let message = "Starting conversation with " + emailAddress;
    let { updated, counter } = Sync.startTask(state, message);
    state = updated;
    router.redirect("/");
    // NOTE The author id is pulled from the session could be done as arg from role instead
    let response = await API.startDirectConversation(
      inboxId,
      emailAddress,
      content
    );

    if ("error" in response) {
      throw "Well this should be handled";
    } else {
      let s = Sync.resolveTask(state, counter, "conversation started");
      let data = response.data;
      state = updateInbox(s, inboxId, function (inbox) {
        let conversations = [data, ...inbox.conversations];
        return { ...inbox, conversations };
      });
    }
  }

  async function saveGreeting(inboxId: string, greeting: Block[]) {
    let message = "Saving your new greeting";
    let { updated, counter } = Sync.startTask(state, message);
    state = updated;
    router.redirect("/");
    let response = await API.saveGreeting(inboxId, greeting);
    if ("error" in response) {
      throw "Wonder what wen't wrong with the greeting";
    } else {
      let s = Sync.resolveTask(state, counter, "Greeting saved");
      state = updateInbox(s, inboxId, function (inbox) {
        let identifier = { ...inbox.identifier, greeting };
        return { ...inbox, identifier };
      });
    }
  }
  function readShareParams() {
    const parsedUrl = new URL(window.location.toString());

    // searchParams.get() will properly handle decoding the values.
    let title = parsedUrl.searchParams.get("title");
    let text = parsedUrl.searchParams.get("text");
    let url = parsedUrl.searchParams.get("url");
    if (title || text || url) {
      return { title, text, url };
    }
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
  {#if installPrompt}
    <article
      on:click={() => (installPrompt = null)}
      class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
    >
      <h2 class="font-bold">Web-app available to install</h2>
      <p>
        Install Memo's web-app on your computer, tablet or smartphone for faster
        access.
      </p>
      <button
        on:click={installPrompt}
        class="bg-green-500 flex hover:bg-green-600 items-center mt-4 px-4 rounded text-white"
      >
        <span class="py-1"> Install </span>
      </button>
    </article>
  {/if}
  {#if sharedParams}
    <article
      class="bg-gray-800 border-l-8 border-r-8 border-green-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
    >
      <h2 class="font-bold">Select a conversation to share the following</h2>
      <p>
        {sharedParams.title || sharedParams.text}
      </p>
    </article>
  {/if}
</div>
{#if route === "home"}
  {#if inbox}
    <Home {inbox} />
  {:else if state.loading === false}
    <SignIn />
  {/if}
{:else if route === "contact"}
  <!-- There should always be params on this route -->
  {#if !inbox}
    <SignIn />
  {:else if params}
    {#if "emailAddress" in params && inbox.identifier.emailAddress === params.emailAddress}
      <Profile identifier={inbox.identifier} {saveGreeting} />
    {:else}
      <Contact
        {conversation}
        {sharedParams}
        contactEmailAddress={"emailAddress" in params && params.emailAddress}
        {inbox}
        {pullMemos}
        {acknowledge}
        {postMemo}
        {startDirectConversation}
      />
    {/if}
  {:else}
    {JSON.stringify(params)} <br />
    Will also show loading
  {/if}
{:else if route === "new_group"}
  {#if inbox}
    <NewGroup {inbox} {createGroup} />
  {/if}
{:else}
  <p>no route {JSON.stringify(route)}</p>
{/if}
