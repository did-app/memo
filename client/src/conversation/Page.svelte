<script>
  import {
    Circle2
  } from 'svelte-loading-spinners'
  export let nickname;
  export let displayName;
  export let topic;
  export let resolved = false;
  export let notify;
  export let participants = [];
  export let messages = [];
  export let pins = [];
  export let left;
  export let bottom;

  let draft;
  $: preview = draft ? marked(draft) : "No preview yet."

  // https://svelte.dev/repl/ead0f1fcd2d4402bbbd64eca1d665341?version=3.14.1
  function resize(event) {
    // // Reset field height
    // field.style.height = 'inherit';
    // // Get the computed styles for the element
    // var computed = window.getComputedStyle(field);
    // // Calculate the height
    // var height = parseInt(computed.getPropertyValue('border-top-width'), 10)
    //              + parseInt(computed.getPropertyValue('padding-top'), 10)
    //              + field.scrollHeight
    //              + parseInt(computed.getPropertyValue('padding-bottom'), 10)
    //              + parseInt(computed.getPropertyValue('border-bottom-width'), 10);

    event.target.style.height = "1px";
    event.target.style.height = (+event.target.scrollHeight)+"px";
    const $composeMenu = document.getElementById('compose-menu');
    $composeMenu.scrollIntoView();
  }
</script>

<style media="screen">
</style>

{#if !topic}
<div class="flex min-h-screen flex-col">
  <div class="m-auto">
    <Circle2 size="25" colorOuter="#3c366b" colorCenter="#3c366b" colorInner="#3c366b" unit="vw"></Circle2>
  </div>
</div>
{:else}
<header class="max-w-3xl mx-auto text-center pt-6 pb-4">
  <h1 id="topic" class="text-2xl">{topic}</h1>
</header>
<div class="flex">
  <main class="flex-grow max-w-3xl ml-auto px-2 mb-16">
    <div id="messages" class="">
      {#each messages as {checked, author, date, intro, html}, count}
      <article class="relative rounded-2xl my-shadow bg-white">
        <input id="message-{count}" class="message-checkbox hidden" type="checkbox" {checked}>
        <label for="message-{count}">
          <header class="pt-4 pb-4 flex">
            <span class="font-bold ml-20">{author}</span>
            <span class="ml-auto mr-8">{date}</span>
          </header>
          <div class="message-overlay absolute bottom-0 top-0 right-0 left-0 ">
          </div>
        </label>
        <div class="content-intro px-20 truncate">{intro}</div>
        <!-- TODO sanitize -->
        <div class="markdown-body px-20">{@html html}</div>
        <footer class="h-12 mb-2 mt-4">

        </footer>
      </article>
      {/each}
    </div>
    <h2 class:hidden="{!resolved}" class="text-lg text-center font-bold text-gray-700 mb-14">
      This conversation has been resolved, <br> No further messages can be sent.
    </h2>

    <form id="reply-form" class:hidden="{resolved}" class="relative w-full rounded-2xl my-shadow bg-white mt-2 mb-8 py-6 px-20" data-action="writeMessage">
      <input id="preview-tab" class="hidden" type="checkbox">
      <textarea class="w-full px-2 bg-white outline-none" name="content" style="min-height:25vh;max-height:60vh;" placeholder="Write message ..." bind:value={draft} on:input={resize}></textarea>
      <div id="preview" class="markdown-body p-2" style="min-height:25vh;">
        {@html preview}
      </div>
      <section class="font-bold flex px-2 pb-1">
        <span class="text-gray-700 pr-2">From:</span>
        <input class="border-b bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" type="text" name="from" placeholder="{displayName}" value="">
      </section>
      <footer id="compose-menu" class="flex items-baseline border-t">
        <label class="font-bold flex px-2 py-1 justify-start items-start">
          <span class="text-gray-700 pr-2">Close conversation</span>
          <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500">
            <input type="checkbox" class="opacity-0 absolute" name="resolve">
            <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
              <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
          </div>
        </label>
        <label for="preview-tab" class="ml-auto">
          <span class="m-1 ml-auto px-2 py-1 rounded border cursor-pointer border-indigo-900 focus:border-indigo-700 hover:border-indigo-700 text-indigo-800 font-bold mt-4">Preview</span>
        </label>
        <button class="m-1 px-2 py-1 rounded bg-indigo-900 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold mt-4" type="submit">Send</button>
      </footer>
    </form>
  </main>
  <aside class="w-full max-w-md flex flex-col py-2 px-6 text-gray-700 mr-auto">
    <h3 class="font-bold">Pins</h3>
    <style media="screen">
      .last-only {
        display: none;
      }

      .last-only:last-child {
        display: block;
      }
    </style>
    <ul id="pins">
      <li class="last-only">Select message text to add first pin.</li>
      {#each pins as pin}
      <li class="bg-white border-indigo-700 border-l-4 m-1 p-2 shadow-lg text-xl">{pin}</li>
      {/each}
    </ul>
    <h3 class="font-bold mt-8">Participants</h3>
    <ul id="participants">
      {#each participants as {name, emailAddress}}
      <li class="m-1 whitespace-no-wrap truncate">{name} <small>&lt;{emailAddress}&gt;</small></li>
      {/each}
    </ul>
    <form class="" data-action="addParticipant" method="post">
      <input class="duration-200 mt-2 px-4 py-1 rounded transition-colors bg-white" id="invite" type="text" name="emailAddress" value="" placeholder="email address">
      <button class="px-4 py-1 hover:bg-indigo-700 rounded bg-indigo-900 text-white mt-2" type="submit">Invite</button>
    </form>
    <h3 class="font-bold mt-4">Notifications</h3>
    <p>Send me notifications for</p>
    <label class="flex px-2 py-1 justify-start items-start">
      <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500">
        <input type="radio" class="opacity-0 absolute" name="notify" bind:group={notify} value={'all'}>
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
          <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
      </div>
      <span class="text-gray-700 pr-2">All messages</span>
    </label>
    <label class="flex px-2 py-1 justify-start items-start">
      <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500">
        <input type="radio" class="opacity-0 absolute" name="notify" bind:group={notify} value={'concluded'}>
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
          <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
      </div>
      <span class="text-gray-700 pr-2">Conversation concluded</span>
    </label>
    <label class="flex px-2 py-1 justify-start items-start">
      <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500">
        <input type="radio" class="opacity-0 absolute" name="notify" bind:group={notify} value={'none'}>
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
          <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
      </div>
      <span class="text-gray-700 pr-2">Never</span>
    </label>
  </aside>
</div>
{/if }
<div class="texttip texttip--theme-default" class:texttip--show="{!!left}" data-textip-iconformat="font" data-texttip-id="1" role="tooltip" aria-hidden="true" style="left:{left}px;bottom:{bottom}px">
  <div class="texttip__inner">
    <div class="texttip__btn" role="button" data-action="quoteInReply" data-texttip-btn-index="0" style="transition-delay: 40ms;">
      <i class="fa fa-quote-right" title="Quote" aria-hidden="true"></i>
      <span class="sr-only">Quote</span>
    </div>
    <div class="texttip__btn" role="button" data-action="pinSelection" data-texttip-btn-index="1" style="transition-delay: 80ms;" on:click="{console.log('00000')}">
      <i class="fa fa-map-pin" title="Pin" aria-hidden="true"></i>
      <span class="sr-only">Pin</span>
    </div>
  </div>
</div>
