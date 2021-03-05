<script lang="typescript">
  const apiOrigin = (import.meta as any).env.SNOWPACK_PUBLIC_API_ORIGIN;
  let id = window.location.hash.slice(1);
  type Uploader = { name: string; parent_id: string; parent_name: string };
  let uploader: Uploader | null = null;
  let sending = false;

  async function sendFile(
    event: Event & { currentTarget: EventTarget & HTMLFormElement }
  ) {
    event.preventDefault();
    sending = true;

    try {
      let form: HTMLFormElement = event.currentTarget;
      let input = form.querySelector('input[type="file"]') as HTMLInputElement;
      let file = input.files && input.files[0];
      if (!file) {
        throw "Needs a file";
      }
      console.log(file);

      let url = apiOrigin + "/drive_uploaders/" + id + "/start";
      let response = await fetch(url, {
        method: "POST",
        body: JSON.stringify({ name: file.name, mime_type: file.type }),
      });
      let { location } = await response.json();
      console.log(location);
      let uploading = await fetch(location, {
        // credentials: "include",
        method: "PUT",
        headers: {
          "content-range": `bytes 0-${file.size - 1}/${file.size}`,
        },
        body: file,
      });
      console.log(uploading);
    } finally {
      sending = false;
    }
  }
  (async function (params) {
    let response = await fetch(apiOrigin + "/drive_uploaders/" + id);
    console.log(response);
    let data = await response.json();
    console.log(data);

    uploader = data.uploader;
  })();
</script>

<div class="p-4 border-4 border-dashed">
  {#if uploader}
    {uploader.name}
    <!-- {JSON.stringify(uploader)} -->
  {:else}
    Loading
  {/if}

  {#if sending}
    Working
  {:else}
    <!-- Query for embed or /pub vs /embed -->
    <form on:submit={sendFile}>
      <input type="file" />
      <button>Submit</button>
    </form>
  {/if}
</div>
