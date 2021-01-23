<script lang="typescript">
  import type { Conversation } from "./conversation";
  import type { State, Inbox } from "./sync";
  import * as Sync from "./sync";
  import Layout from "./routes/_Layout.svelte";
  import Contact from "./routes/Contact.svelte";
  import Home from "./routes/Home.svelte";
  import Profile from "./routes/Profile.svelte";
  import router from "page";

  let route: string;
  let params: { emailAddress: string } | { group: number };
  router("/profile", (_) => {
    route = "profile";
  });
  router("/", (_) => {
    route = "home";
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

  router.start();

  let state = Sync.initial();

  // Requires taking current state as argument
  function update(mapper: (state: State) => State) {
    state = mapper(state);
  }

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

    let installPrompt = await Sync.startInstall(window);
    console.log(installPrompt);
  }

  initialize();

  function selectedInbox({ inboxSelection, inboxes }: State): Inbox | null {
    if (inboxSelection !== null) {
      return inboxes[inboxSelection] || null;
    } else {
      return null;
    }
  }

  function selectedConversation(state: State, params: any) {
    let inbox = selectedInbox(state);
    // TODO pull real one
    return inbox?.conversations[0] || null;
  }
  let inbox: Inbox | null;
  $: inbox = selectedInbox(state);

  let conversation: Conversation | null;
  $: conversation = selectedConversation(state, params);

  // At the top they could just be called notices.
  // type proccessing, failure, success, notification
  function acknowledge() {
    let { updated, counter } = Sync.startTask(state, "Acknowledging task");
    state = updated;
    router.redirect("/");
    setTimeout(() => {
      state = Sync.resolveTask(state, counter);
    }, 2000);
  }
  function postMemo() {
    let { updated, counter } = Sync.startTask(state, "Posting memo");
    state = updated;
    router.redirect("/");
    setTimeout(() => {
      state = Sync.resolveTask(state, counter);
    }, 2000);
  }
</script>

<Layout inboxes={state.inboxes} bind:inboxSelection={state.inboxSelection} />
{JSON.stringify(state.tasks)}
{#if route === "contact"}
  {#if conversation && inbox}
    <Contact
      {conversation}
      identifier={inbox?.identifier}
      {acknowledge}
      {postMemo}
    />
  {:else}
    Will also show loading
  {/if}
{:else if route === "profile"}
  {#if inbox}
    <Profile identifier={inbox.identifier} />
  {:else}
    Can't show
  {/if}
{:else if route === "home"}
  <Home {inbox} />
{:else}
  <p>no route {JSON.stringify(route)}</p>
{/if}
