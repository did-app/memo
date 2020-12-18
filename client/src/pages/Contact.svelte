<script type="typescript">
  // TODO extract the conversation layout page
  import {fetchContact} from "../sync";
  import {parse} from "../note"
  import Composer from "../components/Composer.svelte"
  import Note from "../components/Note.svelte"
  // Need to look up welcome message don't want all of those in client

  export let identifier;
  function emailAddressFor(identifier) {
    return (identifier.indexOf("@") === -1) ? identifier + "@plummail.co" : identifier
  }

  let contact;
  $: fetchContact(emailAddressFor(identifier)).then(function ({data}) {
    setTimeout(function () {
      contact = data

    }, 1000);
  })

  let draft = "";
  let blocks = [];
  let preview = false;
  $: blocks = parse(draft);

  // fetch intro data
  function send() {
    console.log(blocks);
  }
</script>

<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2">
  {#if contact}
  <!-- maybe composer doesn't need to have the from field -->
  <!-- TODO a thread component -->

  <h1 class="text-center text-2xl my-4 text-gray-700">
    Contact <span class="font-bold">{contact.emailAddress}</span>
  </h1>
  <!-- If we put preview outside! -->
  <!-- extract rounding article a a thing -->
  {#if preview}
  <!-- TODO make sure can't always add annotation, or make it work with self -->
  <Note blocks={blocks} notes={[]} index={0} author={"me"}>
    <div class="mt-2 pl-12 flex items-center">
      <div class="flex flex-1">
        <!-- TODO this needs to show your email address, or if in header nothing at all -->
        <!-- <span class="font-bold text-gray-700 mr-1">From:</span>
          <input class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" bind:value={contact} type="email" placeholder="Your email address" required> -->
        </div>
        <!-- TODO icons included as string types -->
        <button class="flex-grow-0 py-2 px-6 rounded-lg bg-gray-500 focus:bg-gray-700 hover:bg-gray-700 text-white font-bold" type="submit" on:click={() => {preview = false}}>
          <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
            <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
            <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
          </svg>
          Back
        </button>
        <button class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit" on:click={send}>
          <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
            <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
            <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
          </svg>
          Send
        </button>
      </div>
  </Note>

  {:else}
  <article class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md ">
    <!-- Could do an on submit and catch whats inside -->
    <Composer bind:draft/>
    <div class="mt-2 pl-12 flex items-center">
      <div class="flex flex-1">
        <!-- TODO this needs to show your email address, or if in header nothing at all -->
        <!-- <span class="font-bold text-gray-700 mr-1">From:</span>
        <input class="flex-grow mr-2 bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" bind:value={contact} type="email" placeholder="Your email address" required> -->
      </div>
      <button class="flex-grow-0 py-2 px-6 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit" on:click={() => {preview = true}}>
        <svg class="fill-current inline w-4 mr-2" xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24">
          <path d="m8.75 17.612v4.638c0 .324.208.611.516.713.077.025.156.037.234.037.234 0 .46-.11.604-.306l2.713-3.692z"></path>
          <path d="m23.685.139c-.23-.163-.532-.185-.782-.054l-22.5 11.75c-.266.139-.423.423-.401.722.023.3.222.556.505.653l6.255 2.138 13.321-11.39-10.308 12.419 10.483 3.583c.078.026.16.04.242.04.136 0 .271-.037.39-.109.19-.116.319-.311.352-.53l2.75-18.5c.041-.28-.077-.558-.307-.722z"></path>
        </svg>
        Preview
      </button>
    </div>
  </article>
  {/if}
  {:else}
  loading
  {/if}
</main>
