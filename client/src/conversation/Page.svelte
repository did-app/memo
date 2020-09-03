<script>
  import {
    Circle2
  } from 'svelte-loading-spinners'
  export let nickname;
  export let displayName;
  export let emailAddress;
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
<header class="max-w-3xl mx-auto text-center py-2 md:pt-6 md:pb-4">
  <h1 id="topic" class="text-xl md:text-2xl">{topic}</h1>
</header>
<div class="sm:flex">
  <main class="sm:w-2/3 max-w-md mx-auto md:mr-0 md:max-w-3xl px-1 md:px-2 md:mb-16">
    <div id="messages" class="">
      {#each messages as {checked, author, date, intro, html}, count}
      <article class="relative border-l border-t border-r rounded-lg md:rounded-2xl my-shadow bg-white">
        <input id="message-{count}" class="message-checkbox hidden" type="checkbox" {checked}>
        <label class="cursor-pointer" for="message-{count}">
          <header class="py-1 md:py-4 flex text-gray-600">
            <span class="font-bold ml-2 md:ml-20 truncate">{author}</span>
            <span class="ml-auto mr-2 md:mr-8 whitespace-no-wrap">{date}</span>
          </header>
          <div class="message-overlay absolute bottom-0 top-0 right-0 left-0 ">
          </div>
        </label>
        <div class="content-intro px-2 md:px-20 truncate">{intro}</div>
        <!-- TODO sanitize -->
        <div class="markdown-body py-2 px-2 md:px-20">{@html html}</div>
        <footer class="h-2 md:h-12 mb-2 mt-4">

        </footer>
      </article>
      {/each}
    </div>
    <h2 class:hidden="{!resolved}" class="text-lg text-center font-bold text-gray-700 mb-14">
      This conversation has been resolved, <br> No further messages can be sent.
    </h2>

    <form id="reply-form" class:hidden="{resolved}" class="relative w-full mt-2 mb-8 p-2 md:py-6 md:px-20 rounded-lg md:rounded-2xl my-shadow bg-white " data-action="writeMessage">
      <input id="preview-tab" class="hidden" type="checkbox">
      <textarea class="w-full bg-white outline-none" name="content" style="min-height:25vh;max-height:60vh;" placeholder="Write message ..." bind:value={draft} on:input={resize}></textarea>
      <div id="preview" class="markdown-body p-2" style="min-height:25vh;">
        {@html preview}
      </div>
      <section class="pb-1 whitespace-no-wrap overflow-hidden">
        <span class="font-bold text-gray-700">From:</span>
        <!-- <input class="border-b bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" type="text" name="from" placeholder="{displayName}" value=""> -->
        <span class="truncate">{emailAddress}</span>
      </section>
      <footer id="compose-menu" class="flex flex-wrap items-baseline border-t">
        <label class="font-bold flex py-1 justify-start items-start">
          <span class="text-gray-700 pr-2">Resolve</span>
          <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500">
            <input type="checkbox" class="opacity-0 absolute" name="resolve">
            <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
              <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
          </div>
        </label>
        <div class="ml-auto">
          <label for="preview-tab" class="">
            <span class="my-1 py-1 px-2 rounded border cursor-pointer border-indigo-900 focus:border-indigo-700 hover:border-indigo-700 text-indigo-800 font-bold">Preview</span>
          </label>
          <button class="my-1 py-1 px-2 rounded bg-indigo-900 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit">Send</button>
        </div>
      </footer>
    </form>
  </main>
  <aside class="sm:w-1/3 max-w-sm mx-auto md:ml-0 flex flex-col p-2 text-gray-700">
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
