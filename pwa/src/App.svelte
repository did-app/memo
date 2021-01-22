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
  state = start(state);

  function start({ taskCounter, tasks, ...current }: State) {
    tasks = [...tasks, { counter: taskCounter }];
    taskCounter += 1;
    Sync.authenticateBySession().then(function (inboxes: Inbox[]) {
      let { tasks, ...current } = state;
      let inboxSelection = 0;
      // TODO clear task ID
      state = { ...current, tasks: [], inboxes, inboxSelection };
    });
    return { taskCounter, tasks, ...current };
  }
  // Sync.run(state, function () {
  //   console.log(state);
  //   setTimeout(function () {
  //     console.log("later");
  //   }, 300);
  //   return { message: "foo", promise: "TODO" };
  // });
  // Can we pass Just run to the child processes
  // Perhaps even without a promise in cases where theres no later effect
  // Same option could have tasks return tasks?

  // // This is the stateful
  // // initialise a state
  // //
  // let emailAddresses = ["ab", "cd"];
  // $: inbox = emailAddresses[inboxSelection];

  // // common things, i.e. tasks can be split out and passed in.
  // // In reality tasks should be on the App/Layout
  // // facade to things that components can do?
  // function inboxAddresses(inboxes) {
  //   return;
  // }
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
  // let identifier = Identifier | null

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
  <Profile {state} />
{:else if route === "home"}
  <Home {inbox} />
{:else}
  <p>no route {JSON.stringify(route)}</p>
{/if}
