<script>
  import Layout from "./_Layout.svelte"
  let nav = "begin";

</script>

<Layout {nav}>
  <form action="__API_ORIGIN__/c/create" method="post">
    <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Conversation topic" name="topic" required pattern="[^@]*" minlength="2" maxlength="100"/>
    <div class="warning">
      Conversation topics must not contain '@'.
    </div>
    <input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Email address" name="participant" required type="email"/>
    <div class="warning">
      Not a valid email address
    </div>
    <button class="bg-indigo-800 block hover:bg-indigo-700 hover:shadow-lg mx-auto px-4 py-2 rounded shadow-xl text-white" type="submit">Begin conversation</button>
  </form>
</Layout>
