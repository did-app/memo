<script>
  import Home from "./pages/Home.svelte";
  import Introduction from "./pages/Introduction.svelte"
  // import Archive from "./pages/Archive.svelte"

  import router from "page";

  let page, params
  router('/', (context) => {params = context.params; page = Home})
  router('/:identifier', (context) => {params = context.params; page = Introduction})

  router.start()
</script>

<svelte:component this={page} {...params} />
