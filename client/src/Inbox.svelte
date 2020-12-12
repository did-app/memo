<!-- This is a svelte APP that is a -->
<script>
  import authenticate from "./authenticate.js"
  import * as Client from "./client.js";
  import SignIn from "./SignIn.svelte"


</script>

  {#if !hasAccount}
  <div id="non-user">
    <section class="w-full max-w-3xl mx-auto">
      <!-- <h2 class="font-bold text-purple-700 text-2xl text-center mb-4">Your Conversations</h2> -->
      <div class="p-8 mt-4 rounded-lg text-white bg-gradient-to-t from-purple-400 via-purple-600 to-purple-800 shadow-xl">
        <h2 class="font-medium text-2xl border-b-2 border-white pb-4 mb-4">Welcome to Plum Mail</h2>
        <p class="my-2">This is your inbox.  It shows the conversations you have are part of.</p>
        <p class="my-2">Click the conversation to read or reply.</p>
        <p class="my-2"><a href="https://plummail.co" class="text-yellow-500 font-medium underline ">Visit our website</a> to find out what makes Plum Mail special.
        <p class="my-2">Enter your email below to join the waitlist for access to the full version of Plum Mail.</p>
        <script type="text/javascript">
        async function backgroundSumbit(event) {
        event.preventDefault()
        const data = new URLSearchParams();
        for (const pair of new FormData(event.target)) {
            data.append(pair[0], pair[1]);
        }
        console.log(data.toString())
        console.log(event)
        let response = await fetch(event.target.action, {
          method: "POST",
          body: data
        })
        console.log(response)
        if (response.status === 200) {
          event.target.innerHTML = "Welcome"
        } else {
          alert("Sorry, something unexpected has happened.")
        }
        }
        </script>
        <form class="text-center mx-auto mt-8 text-gray-600" action="__API_ORIGIN__/welcome" method="post" onsubmit="backgroundSumbit(event)">
          <input type="hidden" name="topic" value="Joining the waitlist">
          <input type="hidden" name="message" value="Welcome to the Plum Mail waitlist

I hope you are enjoying the conversations you are having in Plum Mail.
We started this project to make easier to stay focused on the conversations that matter to us.

Feel free to use this conversation to ask Richard and myself anything you like.

**Cheers Peter**

p.s. Richard will say hi in the next few days">
          <input type="hidden" name="author_id" value="1">
          <input type="hidden" name="cc" value="richard@plummail.co">
          <input class="border-2 rounded-lg bg-gray-100 border-gray-500 m-4 px-4 py-2" disabled type="email" name="email" value={emailAddress}>
          <button class="font-medium text-center bg-purple-700 hover:bg-purple-500 cursor-pointer transition duration-100 rounded-lg px-4 py-2 text-white text-lg">
            Join the waitlist
          </button>
        </form>
      </div>
    </section>
  </div>
  {/if}
