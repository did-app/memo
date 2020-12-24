<script lang="typescript">
  import Contact from "./routes/Contact.svelte";
  import Profile from "./routes/Profile.svelte";
  import router from "page";

  let route: any;
  router("/profile", (_) => {
    route = ["profile"];
  });
  router("/:handle", (context) => {
    route = ["contact", { handle: context.params.handle }];
  });
  router.start();
</script>

{#if route[0] === 'contact'}
  <Contact {...route[1]} />
{:else if route[0] === 'profile'}
  <Profile />

  <p>no route</p>
{/if}
