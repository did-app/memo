<script>
  import Layout from "./_Layout.svelte"
  let nav = "search";
  let term = "";

  function filter(conversations, term) {
    console.log(conversations, term)
  }
</script>

<Layout {nav} let:conversations={conversations}>
  {filter(conversations, term)}
  <input type="text" name="" bind:value={term}>
</Layout>
