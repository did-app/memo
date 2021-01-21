<script lang="typescript">
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
</script>

<Layout let:state let:selected>
  {#if route === "contact"}
    <Contact {emailAddress} stateAll={state} />
  {:else if route === "profile"}
    <Profile {state} />
  {:else if route === "home"}
    <Home {state} {selected} />
  {:else}
    <p>no route {JSON.stringify(route)}</p>
  {/if}
</Layout>
