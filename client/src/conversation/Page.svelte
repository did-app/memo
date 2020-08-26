<script>
  import { Circle2 } from 'svelte-loading-spinners'
  export let topic;
  export let participants = [];
  export let messages = [];
</script>

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
    <h2 id="concluded-banner" class="hidden text-lg text-center font-bold text-gray-700 mb-14">
      This conversation has been resolved, <br> No further messages can be sent.
    </h2>

    <form id="reply-form" class="relative w-full rounded-2xl my-shadow bg-white mt-2 mb-8 py-6 px-20" data-action="writeMessage">
      <input id="preview-tab" class="hidden" type="checkbox">
      <textarea class="w-full px-2 bg-white outline-none" name="content" style="min-height:14em" placeholder="Write message ..."></textarea>
      <div id="preview" class="markdown-body p-2" style="min-height:14em;">
        No preview yet.
      </div>
      <section class="font-bold flex px-2 pb-1">
        <span class="text-gray-700 pr-2">From:</span>
        <input class="border-b bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" type="text" name="from" placeholder="<%= Helpers.email_address(identifier) %>" value="Richard">
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
        <input type="radio" class="opacity-0 absolute" name="resolve" checked>
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
          <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
      </div>
      <span class="text-gray-700 pr-2">All messages</span>
    </label>
    <label class="flex px-2 py-1 justify-start items-start">
      <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500">
        <input type="radio" class="opacity-0 absolute" name="resolve">
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
          <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
      </div>
      <span class="text-gray-700 pr-2">Conversation concluded</span>
    </label>
    <label class="flex px-2 py-1 justify-start items-start">
      <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500">
        <input type="radio" class="opacity-0 absolute" name="resolve">
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20">
          <path d="M0 11l2-2 5 5L18 3l2 2L7 18z" /></svg>
      </div>
      <span class="text-gray-700 pr-2">Never</span>
    </label>
  </aside>
</div>
{/if }
