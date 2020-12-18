<script type="typescript">
  // TODO extract the conversation layout page
  import {fetchContact} from "../sync";
  import Composer from "../components/Composer.svelte"
  // Need to look up welcome message don't want all of those in client

  export let identifier;
  let emailAddress;
  $: emailAddress = (identifier.indexOf("@") === -1) ? identifier + "@plummail.co" : identifier
  fetchContact(emailAddress)
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  <!-- maybe composer doesn't need to have the from field -->
  <!-- TODO a thread component -->
  <h1 class="text-center text-2xl my-4 text-gray-700">
    Contact <span class="font-bold">{emailAddress}</span>
  </h1>
  <!-- If we put preview outside! -->
  <Composer />
</main>
