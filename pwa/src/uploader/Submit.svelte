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
      // Could bind to file input
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

<div class="bg-gray-100 border-2 border-dashed rounded-lg text-center">
  <h1 class="my-4 text-xl">
    {#if uploader}
      {uploader.name || ""}
    {:else}
      Loading
    {/if}
  </h1>

  <form on:submit={sendFile}>
    {#if sending}
      <div class="my-4">Uploading file</div>
    {:else if error}
      {error}
    {:else if lastSent}
      <div class="my-4">
        Thank you! Successfully sent: <span class="italic">{lastSent}</span>
      </div>
      <div class="my-4">
        <button
          class="bg-gray-800 border-2 text-lg border-gray-800 text-white rounded px-2 ml-2"
          type="reset"
          on:click={() => {
            lastSent = null;
            document.querySelector("form")?.reset();
          }}>Send another</button
        >
      </div>
    {:else}
      <div class="my-4">
        <label for="">
          <input class="bg-white" type="file" required />
        </label>
      </div>
      <div class="my-4">
        <button
          class="bg-gray-800 border-2 text-lg border-gray-800 text-white rounded px-2 ml-2"
          >Submit</button
        >
      </div>
    {/if}
  </form>
</div>
