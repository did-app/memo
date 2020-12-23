<script lang="typescript">
  export let handle: string;

  function emailAddressFor(handle: string) {
    return handle.indexOf("@") === -1 ? handle + "@plummail.co" : handle;
  }
  console.log(handle);
</script>

<div>
  <h1>Hello!</h1>
</div>
