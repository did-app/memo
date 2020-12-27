<script lang="ts">
  import { authenticationProcess } from "../sync";
  import SignIn from "../components/SignIn.svelte";
  import ProfilePage from "./ProfilePage.svelte";
  import Loading from "../components/Loading.svelte";
</script>

<!-- Put the sign in over the loading screen TODO -->
<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#await authenticationProcess}
    <Loading />
  {:then response}
    {#if 'error' in response && response.error.code === 'forbidden'}
      <SignIn />
    {:else if 'error' in response}
      unknown error
      {JSON.stringify(response.error)}
    {:else}
      <ProfilePage
        id={response.id}
        emailAddress={response.email_address}
        greeting={response.greeting} />
    {/if}
  {/await}
</main>
