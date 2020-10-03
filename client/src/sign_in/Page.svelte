<script type="text/javascript">
  import * as Client from "../client.js";

  let error;
  let emailAddress;
  let emailSent = false;
  let accountRequired = false;
  async function requestEmailAuthentication(event) {
    let response = await Client.requestEmailAuthentication(emailAddress)
    response.match({
      ok: function(_) {
        emailSent = true;
      },
      fail: function({code, detail}) {
        if (code === "unknown_identifier") {
          accountRequired = true
        } else {
          error = detail
        }
      }
    })
  }
</script>

<main class="w-full max-w-2xl m-auto p-4">
  <div class="p-6 rounded-lg md:rounded-2xl my-shadow text-center">
    <h1 class="font-serif text-indigo-800 text-6xl">plum mail</h1>
    {#if error}
    <p><strong class="border-2 border-indigo-200 py-2 px-4 rounded">{error}.</strong></p>
    <p class="mt-2">We are looking into this issue.</p>
    {:else}
    {#if emailSent}
    <p>A message has been sent to: <br><strong>{emailAddress}</strong>.</p>
    <p class="mt-2">Click the link inside to sign in.</p>
    {:else if accountRequired}
    <div class="max-w-sm block mx-auto">
      <p class="my-2">
        You need an invitation to access Plum Mail.
      </p>
      <p class="my-2">
        Email us at <a class="focus:underline hover:underline outline-none text-indigo-600 font-bold" href=" mailto:yesplease@plummail.co?subject=Count%20me%20in&amp;body=I'm%20looking%20forward%20to%20trying%20plummail.co%20because%20... ">yesplease@plummail.co</a> to join the waitlist.
      </p>
    </div>
    {:else}
    <form on:submit|preventDefault={requestEmailAuthentication} class="max-w-sm block mx-auto ">
      <input type="email" bind:value={emailAddress} class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Email Address" autofocus/>
      <button class="w-full px-4 py-2 hover:bg-indigo-700 rounded bg-indigo-900 text-white mt-2" type="submit">Sign in</button>
    </form>
    {/if}
    {/if}
  </div>

</main>
