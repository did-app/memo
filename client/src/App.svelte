<script>
  import Search from "./pages/Search.svelte";
  import Begin from "./pages/Begin.svelte";
  import Archive from "./pages/Archive.svelte";
  import Introduction from "./pages/Introduction.svelte";

  import router from "page";

  // could be done in main.js
  import {handleAuthCode} from "./sync/index.js";
  handleAuthCode()

  let page, params
  router('/', (context) => {params = context.params; page = Search})
  router('/begin', (context) => {params = context.params; page = Begin})
  router('/archive', (context) => {params = context.params; page = Archive})
  router('/:identifier', (context) => {params = context.params; page = Introduction})
  // TODO share page

  router.start()
</script>

<svelte:component this={page} {...params} />
