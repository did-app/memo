<script>
  import Search from "./pages/Search.svelte";
  import ComposerPage from "./pages/ComposerPage.svelte";
  import Outstanding from "./pages/Outstanding.svelte";
  import Begin from "./pages/Begin.svelte";
  import Archive from "./pages/Archive.svelte";
  import Conversation from "./pages/Conversation.svelte";
  import Contact from "./pages/Contact.svelte";

  import router from "page";

  // could be done in main.js but makes sense here because this is where we handle the url
  import {startSync} from "./sync";
  const sync = startSync()

  let page, params
  router('/', (context) => {params = context.params; page = Search})
  router('/composer', (context) => {params = context.params; page = ComposerPage})
  router('/unread', (context) => {params = context.params; page = Outstanding})
  router('/begin', (context) => {params = context.params; page = Begin})
  router('/archive', (context) => {params = context.params; page = Archive})
  router('/c/:conversationId', (context) => {params = context.params; page = Conversation})
  router('/:identifier', (context) => {params = context.params; page = Contact})

  router.start()
</script>

<svelte:component this={page} {...params} {sync} />
