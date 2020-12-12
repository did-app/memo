<script>
  import Home from "./pages/Home.svelte";
  // import Begin from "./pages/Begin.svelte"
  // import Archive from "./pages/Archive.svelte"

  import router from "page";

  let page
  router('/', () => page = Home)

  router.start()
</script>

<svelte:component this={page} />
