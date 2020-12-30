<script type="typescript">
  import * as API from "../sync/api";
  import type { Identifier } from "../sync/api";
  import * as Sync from "../sync";

  export let success: (identifier: Identifier) => void;
  let error: {};
  let emailAddress: string = "";
  let password: string = "";
  let emailSent = false;
  let accountRequired = false;

  async function authenticate() {
    if (hasPassword(emailAddress)) {
      let response = await Sync.authenticateWithPassword(
        emailAddress,
        password
      );
      if ("error" in response) {
        throw "Bad email ";
      }
      success(response.data);
    } else {
      let response = await API.authenticateWithEmail(emailAddress);
      if ("error" in response) {
        throw "Bad email ";
      }
      emailSent = true;
    }
  }

  function hasPassword(emailAddress: string): boolean {
    return emailAddress.split("@")[1] === "plummail.co";
  }
</script>

<div class="absolute bottom-0 flex flex-col left-0  p-4 right-0 top-0 bg-body">
  <div
    class="md:rounded-2xl m-auto w-full max-w-2xl my-shadow p-6 rounded-lg text-center z-0 bg-white">
    <h1 class="font-serif text-indigo-800 text-6xl">plum mail</h1>
    {#if error}
      <p>
        <strong
          class="border-2 border-indigo-200 py-2 px-4 rounded">{error}.</strong>
      </p>
      <p class="mt-2">We are looking into this issue.</p>
    {:else if emailSent}
      <p>A message has been sent to: <br /><strong>{emailAddress}</strong>.</p>
      <p class="mt-2">Click the link inside to sign in.</p>
    {:else if accountRequired}
      <div class="max-w-sm block mx-auto">
        <p class="my-2">You need an invitation to access Plum Mail.</p>
        <p class="my-2">
          <a
            class="focus:underline hover:underline outline-none text-indigo-600 font-bold"
            href="https://app.plummail.co/team">Contact us</a>
          to join the waitlist.
        </p>
      </div>
    {:else}
      <form
        on:submit|preventDefault={authenticate}
        class="max-w-sm block mx-auto ">
        <input
          type="email"
          required
          autocomplete="email"
          bind:value={emailAddress}
          class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none"
          placeholder="Email Address" />

        <input
          class:hidden={!hasPassword(emailAddress)}
          type="password"
          required
          bind:value={password}
          class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none"
          placeholder="Password" />
        <button
          class="w-full px-4 py-2 hover:bg-indigo-700 rounded bg-indigo-900 text-white mt-2"
          type="submit">Sign in</button>
      </form>
    {/if}
  </div>
</div>
