<script lang="typescript">
  import type { Memo, Conversation, Identifier } from "./conversation";
  import * as conversation_module from "./conversation";
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
  import Introduce from "./routes/Introduce.svelte";
  import * as Icons from "./icons";

  import router from "page";

  let route: string;
  let params: { emailAddress: string } | { groupId: string } | undefined;
  let sharedParams:
    | { title: string | null; text: string | null; url: string | null }
    | undefined;
  router("/", (_) => {
    route = "home";
    params = undefined;
  });
  router("/sign-in", () => {
    route = "sign_in";
    params = undefined;
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
  // sync/inbox nextPrompt
  //
  type Prompt =
    | {
        kind: "set_name" | "set_greeting";
        identifier: Identifier;
      }
    | { kind: "add_contact"; contactCount: number; identifier: Identifier };
  let prompt: Prompt | null = null;
  $: prompt = (function name(inbox: Inbox | null): Prompt | null {
    if (inbox) {
      if (inbox.identifier.name) {
        if (inbox.identifier.greeting) {
          if (inbox.conversations.length >= 5) {
            return null;
          } else {
            return {
              kind: "add_contact",
              identifier: inbox.identifier,
              contactCount: inbox.conversations.length,
            };
          }
        } else {
          return { kind: "set_greeting", identifier: inbox.identifier };
        }
      } else {
        return { kind: "set_name", identifier: inbox.identifier };
      }
    } else {
      return null;
    }
  })(inbox);
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
            author: { name: null, emailAddress: conversation.stranger },
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
      let now = new Date();
      let hour = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDay(),
        now.getHours() + 1
      ).getHours();
      let time;
      if (hour === 0) {
        time = "Midnight";
      } else if (hour === 12) {
        time = "Noon";
      } else if (hour < 12) {
        time = hour + " am";
      } else {
        time = hour - 12 + " pm";
      }
      let s = Sync.resolveTask(
        state,
        counter,
        "Memo dispatched, it will be delivered after " + time
      );
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
      let now = new Date();
      let hour = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDay(),
        now.getHours() + 1
      ).getHours();
      let time;
      if (hour === 0) {
        time = "Midnight";
      } else if (hour === 12) {
        time = "Noon";
      } else if (hour < 12) {
        time = hour + " am";
      } else {
        time = hour - 12 + " pm";
      }
      let s = Sync.resolveTask(
        state,
        counter,
        "Conversation started, memo will be delivered after " + time
      );
      let data = response.data;
      state = updateInbox(s, inboxId, function (inbox) {
        let conversations = [data, ...inbox.conversations];
        return { ...inbox, conversations };
      });
    }
  }

  async function setName(inboxId: string, name: string) {
    let response = await API.setName(inboxId, name);
    if ("error" in response) {
      throw "Wonder what wen't wrong with the saving name";
    } else {
      state = updateInbox(state, inboxId, function (inbox) {
        let identifier = { ...inbox.identifier, name };
        return { ...inbox, identifier };
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
  let chosenName = "";
</script>

<Layout
  inboxes={state.inboxes}
  loading={state.loading}
  {installPrompt}
  bind:inboxSelection={state.inboxSelection}
/>

<div class="w-full max-w-3xl mx-auto">
  {#each state.tasks as task}
    {#if task.type === "failure"}
      <article
        on:click={() => (state = Sync.removeTask(state, task.counter))}
        class="bg-gray-800 border-l-8 border-r-8 border-red-500 md:px-12 my-4 p-4 rounded shadow-md text-white"
      >
        <h2 class="font-bold">{task.message}</h2>
        <p>We are working to fix this issue as soon as possible.</p>
        <nav class="flex flex-row-reverse pl-6 md:pl-12">
          <button
            class="flex items-center rounded px-2 inline-block ml-2 border-gray-500 border-2"
          >
            <span class="py-1">Dismiss</span>
          </button>
        </nav>
      </article>
    {:else if task.type === "success"}
      <article
        on:click={() => (state = Sync.removeTask(state, task.counter))}
        class="my-4 py-4 px-6 md:px-12 bg-white rounded shadow max-w-3xl border md:border-0 md:border-l-4 border-green-300"
      >
        <h2 class="font-bold">Success</h2>
        <p>{task.message}</p>
        <nav class="flex flex-row-reverse pl-6 md:pl-12">
          <button
            class="flex items-center rounded px-2 inline-block ml-2 border-gray-500 border-2"
          >
            <span class="py-1">Dismiss</span>
          </button>
        </nav>
      </article>
    {/if}
  {/each}
  {#if prompt && route === "home" && prompt.kind === "set_name"}
    <div
      class="md:my-2 py-2 px-4 md:px-12 bg-white md:rounded shadow max-w-3xl border md:border-white"
    >
      <p>Welcome to Memo.</p>
      <p class="my-2">
        Personalise your profile by setting a name. Along with your email this
        will be your identity on Memo.
      </p>
      <form
        on:submit|preventDefault={() => {
          prompt && setName(prompt.identifier.id, chosenName);
        }}
      >
        <input
          bind:value={chosenName}
          required
          class="text-right w-36 px-2 rounded border border-gray-100 bg-gray-100 focus:bg-white text-black outline-none"
          placeholder="e.g. Dan"
        />
        <span class="py-1">
          &lt;{prompt.identifier.emailAddress}&gt;
        </span>
        <p class="my-2">
          <button
            type="submit"
            class="rounded px-2 inline-block border-gray-300 hover:border-gray-500 border"
          >
            <span class="w-3 mr-1 inline-block">
              <Icons.Check />
            </span>
            <span class="">Save</span>
          </button>
        </p>
      </form>
    </div>
  {:else if prompt && route === "home" && prompt.kind === "set_greeting"}
    <div class="my-4 py-4 px-6 md:px-12 bg-white rounded shadow max-w-3xl">
      <p class="my-2">Have the first word in every conversation!</p>
      <p class="my-2">
        <a
          href={conversation_module.emailAddressToPath(
            prompt.identifier.emailAddress
          )}
          class="hover:underline focus:underline cursor-pointer"
        >
          Set up your personal greetings page here...
        </a>
      </p>
    </div>
  {/if}
  {#if !prompt && installPrompt && state.tasks.length === 0}
    <article
      on:click={() => (installPrompt = null)}
      class="my-4 py-4 px-6 md:px-12 bg-white rounded shadow max-w-3xl border md:border-0 md:border-l-4 border-green-300"
    >
      <h2 class="font-bold">Web-app available to install</h2>
      <p class="my-2">
        Install Memo's web-app on your computer, tablet or smartphone for faster
        access.
      </p>
      <nav class="flex flex-row-reverse pl-6 md:pl-12">
        <button
          on:click={installPrompt}
          class="flex items-center bg-gray-800 text-white rounded px-2 ml-2"
        >
          <span class="py-1"> Install </span>
        </button>
        <button
          class="flex items-center rounded px-2 inline-block ml-2 border-gray-500 border-2"
        >
          <span class="py-1">Dismiss</span>
        </button>
      </nav>
    </article>
  {/if}
  {#if sharedParams}
    <article
      class="bmy-4 py-4 px-6 md:px-12 bg-white rounded shadow max-w-3xl border md:border-0 md:border-l-4 border-gray-300"
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
    <Home {inbox} {prompt} />
  {:else if state.loading === false}
    <Introduce contactEmailAddress={"team@sendmemo.app"} {pullMemos} />
  {/if}
{:else if route === "sign_in"}
  <SignIn />
{:else if route === "contact"}
  <!-- There should always be params on this route -->
  {#if !inbox}
    {#if params && "emailAddress" in params}
      <div class="text-center my-4">
        <h1 class="text-2xl">{params.emailAddress}</h1>
        <h2 class="text-gray-500" />
      </div>
      <Introduce contactEmailAddress={params.emailAddress} {pullMemos} />
    {:else}
      <SignIn />
    {/if}
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
