<script lang="typescript">
  import type { State, Inbox } from "./sync";
  import * as Sync from "./sync";
  import Layout from "./routes/_Layout.svelte";
  import Contact from "./routes/Contact.svelte";
  import Home from "./routes/Home.svelte";
  import Profile from "./routes/Profile.svelte";
  import router from "page";

  let route: string;
  let emailAddress: string;
  router("/profile", (_) => {
    route = "profile";
  });
  router("/", (_) => {
    route = "home";
  });
  router("/:handle", (context) => {
    route = "contact";
    emailAddress = context.params.handle + "@plummail.co";
  });
  router("/:domain/:username", (context) => {
    route = "contact";
    emailAddress = context.params.username + "@" + context.params.domain;
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
</script>

<Layout inboxes={state.inboxes} bind:inboxSelection={state.inboxSelection} />
<!-- {JSON.stringify(state)} -->
{#if route === "contact"}
  <Contact {emailAddress} stateAll={state} />
{:else if route === "profile"}
  <Profile {state} />
{:else if route === "home"}
  <Home inbox={selectedInbox(state)} />
{:else}
  <p>no route {JSON.stringify(route)}</p>
{/if}
