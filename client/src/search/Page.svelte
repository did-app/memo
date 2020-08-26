<header class="w-full max-w-2xl mx-auto text-right">
  <style media="screen">
    #notifications:checked ~ .inline-block  {
      display: none;
    }
    #notifications:checked ~ .hidden  {
      display: inline-block;
    }
  </style>
  <label>
    <input id="notifications" class="hidden" type="checkbox" name="" value="">
    <span class="inline-block ml-auto text-lg p-4">
      <span href="/c#1">Next update 8am <img class="inline-block w-8" src="002-clock.svg" alt=""> </span>
    </span>
    <span class="hidden ml-auto text-lg p-4">
      <a href="/c#3">New messages <img class="inline-block w-8" src="003-chat.svg" alt=""> </a>
    </span>
  </label>
</header>
<main class="w-full max-w-2xl m-auto p-6">
  <h1 class="flex-grow font-serif text-indigo-800 text-6xl text-center">plum mail</h1>
  <input id="search" type="text" class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Search by name, email, topic or content, also start conversation" onkeyup="searchAll(event)" autofocus/>
  <nav id="results">

  </nav>
</main>
<div class="hidden w-full mx-auto text-center sticky bottom-0 mt-4 bg-gray-100">
  <nav class="inline-block my-4 text-indigo-800">
    <style media="screen">
      a[href="/index"]::after {
        content: ' ';
        width: 8px;
        height: 8px;
        background: #673AB7;
        display: inline-block;
        margin: 0 0 7px 7px;
        border-radius: 8px;
      }
    </style>
    <a class="inline-block px-4 py-1 border-b-2 border-gray-100 focus:border-indigo-800 hover:border-indigo-800 outline-none" href="/index">Inbox</a>
    <style media="screen">
    ol {
      max-height:0;
      transition:max-height 0.2s;
      overflow:hidden;
    }
    input[type="checkbox"]:checked + ol {
      max-height: 6em;
    }
    </style>
    <label for="advanced-menu">
      <span class="inline-block px-4 py-1 border-b-2 border-gray-100 focus:border-indigo-800 hover:border-indigo-800 outline-none cursor-pointer" href="#">Menu</span>
    </label>
    <input class="hidden" type="checkbox" id="advanced-menu" name="advanced-menu" value="">
    <ol class="text-left m-2 mt-0" style="">
      <!-- <li class="border-l-2 border-gray-100 hover:border-indigo-800">
        <a class="px-3 mb-2 block w-full" href="#">View attachments</a>
      </li>
      <li class="border-l-2 border-gray-100 hover:border-indigo-800">
        <a class="px-3 mb-2 block w-full" href="#">Set public URL</a>
      </li> -->
      <li class="border-l-2 border-gray-100 hover:border-indigo-800">
        <a class="px-3 mb-2 block w-full" href="/sign_out">Sign out (richard@plummail.co)</a>
      </li>
    </ol>
  </nav>
</div>
