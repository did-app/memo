<script lang="typescript">
  import Layout from "./routes/_Layout.svelte";
  import Contact from "./routes/Contact.svelte";
  import Home from "./routes/Home.svelte";
  import Profile from "./routes/Profile.svelte";
  import router from "page";

  let route: string;
  let contactEmailAddress: string;
  router("/profile", (_) => {
    route = "profile";
  });
  router("/", (_) => {
    route = "home";
  });
  router("/:handle", (context) => {
    route = "contact";
    contactEmailAddress = context.params.handle + "@plummail.co";
  });
  router("/:domain/:username", (context) => {
    route = "contact";
    contactEmailAddress = context.params.username + "@" + context.params.domain;
  });

  router.start();
</script>

<Layout let:state>
  {#if route === 'contact'}
    <Contact {contactEmailAddress} {state} />
  {:else if route === 'profile'}
    <Profile {state} />
  {:else if route === 'home'}
    <Home {state} />
  {:else}
    <p>no route {JSON.stringify(route)}</p>
  {/if}
</Layout>
