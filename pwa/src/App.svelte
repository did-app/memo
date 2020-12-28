<script lang="typescript">
  import Contact from "./routes/Contact.svelte";
  import Contacts from "./routes/Contacts.svelte";
  import Profile from "./routes/Profile.svelte";
  import router from "page";

  let route: any = [];
  router("/profile", (_) => {
    route = ["profile"];
  });
  router("/", (_) => {
    route = ["contacts"];
  });
  router("/:handle", (context) => {
    route = ["contact", { handle: context.params.handle + "@plummail.co" }];
  });
  router("/:domain/:username", (context) => {
    route = [
      "contact",
      { handle: context.params.username + "@" + context.params.domain },
    ];
  });

  router.start();
</script>

{#if route[0] === 'contact'}
  <Contact {...route[1]} />
{:else if route[0] === 'profile'}
  <Profile />
{:else if route[0] === 'contacts'}
  <Contacts />
{:else}
  <p>no route {JSON.stringify(route)}</p>
{/if}
