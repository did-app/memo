<script type="typescript">
  import * as API from "../sync/api";

  let emailAddress: string = "";
  let password: string = "";
  let emailSent = false;

  async function wait(milliSeconds: number) {
    return new Promise(function (resolve) {
      setTimeout(resolve, milliSeconds);
    });
  }
  let message: string = "Sign in";
  async function authenticate(event: Event) {
    let delay = wait(600);
    if (hasPassword(emailAddress)) {
      // message = "Checking credentials";
      // let response = await Sync.authenticateByPassword(emailAddress, password);
      // await delay;
      // if ("error" in response) {
      //   throw "Bad email ";
      // }
      // // Doesn't show, because page is changed by success
      // message = "done";
    } else {
      event.preventDefault();
      message = "Working";

      let response = await API.authenticateByEmail(emailAddress);
      await delay;
      if ("error" in response) {
        throw "Bad email ";
      }
      emailSent = true;
    }
  }

  function hasPassword(emailAddress: string): boolean {
    return emailAddress.split("@")[1] === "plummail.co";
  }
  const action = `${
    (import.meta as any).env.SNOWPACK_PUBLIC_API_ORIGIN
  }/sign_in`;
</script>

<div class="absolute bottom-0 flex flex-col left-0  p-4 right-0 top-0 bg-body">
  <div
    class="md:rounded-2xl m-auto w-full max-w-2xl my-shadow p-6 rounded-lg text-center z-0 bg-white border">
    <p class="text-gray-800 text-lg">Sign-in to Memo</p>
    {#if emailSent}
      <p>A message has been sent to: <br /><strong>{emailAddress}</strong>.</p>
      <p class="mt-2">Click the link inside to sign in.</p>
    {:else}
      <form
        on:submit={authenticate}
        method="POST"
        {action}
        class="max-w-sm block mx-auto ">
        <input
          type="email"
          name="email_address"
          required
          autocomplete="email"
          bind:value={emailAddress}
          class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-green-600 outline-none"
          placeholder="Email Address" />

        {#if hasPassword(emailAddress)}
          <input
            type="password"
            name="password"
            required
            autocomplete="current-password"
            bind:value={password}
            class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-green-600 outline-none"
            placeholder="Password" />
        {/if}
        <button
          class="bg-green-500 hover:bg-green-700 mt-2 px-4 py-2 rounded text-white"
          type="submit">{message}</button>
      </form>
    {/if}
  </div>
</div>
