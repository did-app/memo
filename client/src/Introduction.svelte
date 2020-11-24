<main class="w-full max-w-md mx-auto md:max-w-3xl px-1 md:px-2 my-4">
  <h1 class="flex-grow text-xl md:text-2xl text-center">Make an introduction</h1>
  <article class="my-2 border-l border-t border-r rounded-lg md:rounded-2xl my-shadow bg-white">
    <div class="markdown-body py-6 px-2 md:px-20">
      <p>Hello</p>
      <p>
        Thanks for reaching out.
      </p>
      <p>
        I'm currently trying to take control of my communication.
        Please may I ask you consider the following in your message.
      </p>
      <ul>
        <li>Be explicit about if you need a reply, and how quickly.</li>
        <li>If I don't know you, share a link to your website, bio or twitter</li>
        <li>Recruiters, I'm very happy building <a href="https://plummail.co">Plum Mail</a> and not looking for new opportunities</li>
      </ul>
      <!-- <p>
        I respond faster to emails that are short.
        Two-liners I often reply to immediately.
        Long emails I leave in my inbox to deal with later, and never do.
      </p> -->
      <p>
        <strong>Cheers, Peter</strong>
      </p>
    </div>
  </article>
  <form class="relative border-l border-t border-r rounded-lg md:rounded-2xl my-shadow bg-white py-4" action="" method="post">
    <section class="py-2 px-2 md:px-20 flex">
      <span class="font-bold text-gray-700 mr-1">Subject:</span>
      <input class="border-b bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" type="text" name="from" placeholder="Please be specific" value="">
    </section>

    <section class="py-2 px-2 md:px-20 flex">
      <span class="font-bold text-gray-700 mr-1">Message:</span>
      <textarea class="border-b bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" name="message" rows="8" placeholder="I respond faster to emails that are short. Two-liners are best.
You can write Markdown in this box" value="" ></textarea>
    </section>

    <section class="py-2 px-2 md:px-20 flex">
      <span class="font-bold text-gray-700 mr-1">From:</span>
      <input class="border-b bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" type="text" name="from" placeholder="Your email address" value="">
    </section>

    <div class="py-2 px-2 md:px-20 flex">
      <button class="ml-auto my-1 py-1 px-2 rounded bg-indigo-900 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold" type="submit">Send</button>
    </div>
  </form>
</main>
