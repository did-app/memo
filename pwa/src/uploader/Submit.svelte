<script lang="typescript">
  const apiOrigin = (import.meta as any).env.SNOWPACK_PUBLIC_API_ORIGIN;
  let id = window.location.hash.slice(1);
  type Uploader = { name: string; parent_id: string; parent_name: string };
  let uploader: Uploader | null = null;
  let sending = false;
  let lastSent: string | null = null;
  let error: string | null = null;

  async function sendFile(
    event: Event & { currentTarget: EventTarget & HTMLFormElement }
  ) {
    event.preventDefault();
    sending = true;
    lastSent = null;
    error = null;

    try {
      let form: HTMLFormElement = event.currentTarget;
      let input = form.querySelector('input[type="file"]') as HTMLInputElement;
      let file = input.files && input.files[0];
      if (!file) {
        throw "Needs a file";
      }

      let url = apiOrigin + "/drive_uploaders/" + id + "/start";
      let response = await fetch(url, {
        method: "POST",
        body: JSON.stringify({ name: file.name, mime_type: file.type }),
      });
      let { location } = await response.json();
      await fetch(location, {
        method: "PUT",
        headers: {
          "content-range": `bytes 0-${file.size - 1}/${file.size}`,
        },
        body: file,
      });
      lastSent = file.name;
    } catch (err) {
      error = "Failed to send file";
      throw err;
    } finally {
      sending = false;
    }
  }
  (async function () {
    // Don't need to handle error case here because we use id from hash for upload
    let response = await fetch(apiOrigin + "/drive_uploaders/" + id);
    let data = await response.json();
    uploader = data.uploader;
  })();
</script>

<div class="p-4 border-4 border-dashed">
  {#if uploader}
    {uploader.name}
  {:else}
    Loading
  {/if}

  {#if sending}
    Working
  {:else}
    {#if error}
      {error}
    {/if}
    {#if lastSent}
      lastSent
    {/if}
    <form on:submit={sendFile}>
      <input type="file" />
      <button>Submit</button>
    </form>
  {/if}
</div>
