<script lang="typescript">
  const apiOrigin = (import.meta as any).env.SNOWPACK_PUBLIC_API_ORIGIN;
  const clientId = (import.meta as any).env.SNOWPACK_PUBLIC_GOOGLE_CLIENT_ID;

  export let gapi: any;
  let signIn: (() => void) | null = null;
  let openPicker: (() => void) | null = null;
  let picked: { id: string; name: string } | null = null;

  type Uploader = {
    id: string;
    name: string;
  };
  let user: {
    accessToken: string;
    name: string;
    email: string;
    uploaders: Uploader[];
  } | null = null;

  gapi.load("auth2", function () {
    let auth2 = gapi.auth2.init({
      client_id: clientId,
      // Scopes to request in addition to 'profile' and 'email'
      scope: "https://www.googleapis.com/auth/drive.file",
    });
    signIn = async function () {
      let authResult = await auth2.grantOfflineAccess();
      let serverCode: string = authResult["code"];
      let currentUser = auth2.currentUser.get();
      let authResponse = currentUser.getAuthResponse({
        includeAuthorizationData: true,
      });

      let { access_token: accessToken } = authResponse;

      let name = currentUser.getBasicProfile().getName();
      let email = currentUser.getBasicProfile().getEmail();

      // sign in cookie for a session only hit /api

      let memoResponse = await fetch(apiOrigin + "/drive_uploaders/authorize", {
        method: "POST",
        credentials: "include",
        headers: {
          accept: "application/json",
          "content-type": "application/json",
        },
        body: JSON.stringify({ code: serverCode }),
      });
      if (memoResponse.status !== 200) {
        throw "Need to handle this";
      }

      let data: { uploaders: Uploader[] } = await memoResponse.json();
      let { uploaders } = data;

      // Google user not connected to general user so no way to list all my
      // uploaders accross services, however why have more than one.
      // uploader table google_drive_uploader link to id,

      user = { accessToken, name, email, uploaders };
    };
  });
  gapi.load("picker", function () {
    let google = (window as any).google;

    openPicker = function () {
      if (user) {
        var view = new google.picker.DocsView()
          .setOwnedByMe(true)
          .setIncludeFolders(true)
          .setSelectFolderEnabled(true)
          // .setEnableTeamDrives(teamDrive)
          .setMimeTypes("application/vnd.google-apps.folder");
        var picker = new google.picker.PickerBuilder()
          .enableFeature(google.picker.Feature.NAV_HIDDEN)
          .enableFeature(google.picker.Feature.SUPPORT_TEAM_DRIVES)
          .setTitle("Select a folder to use for the uploads")
          .addView(view)
          .setOAuthToken(user.accessToken)
          .setDeveloperKey("AIzaSyCnu1REwPCB-GKxUngpiQBAy1zkJYiIqKs")
          .setCallback(function (result: any) {
            if (result.action === "picked") {
              let { id } = result.docs[0];
              picked = { id, name: result.docs[0].name };
            }
          })
          .build();
        picker.setVisible(true);
      }
    };
  });

  let uploaderName = "";
  async function createUploader() {
    if (user) {
      let memoResponse = await fetch(apiOrigin + "/drive_uploaders/create", {
        method: "POST",
        credentials: "include",
        headers: {
          accept: "application/json",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          name: uploaderName,
          parent_id: picked?.id,
          parent_name: picked?.name,
        }),
      });
      if (memoResponse.status !== 200) {
        throw "Need to handle this";
      }

      let data: { uploaders: Uploader[] } = await memoResponse.json();
      let { uploaders } = data;
      user = { ...user, uploaders };
    } else {
      throw "definetly should be a user";
    }
  }
  async function deleteUploader(id: string) {
    if (user) {
      let url = apiOrigin + "/drive_uploaders/" + id + "/delete";
      let response = await fetch(url, {
        credentials: "include",
      });
      if (response.status !== 200) {
        throw "failed to delete";
      }
      let data: { uploaders: Uploader[] } = await response.json();
      let { uploaders } = data;
      user = { ...user, uploaders };
    } else {
      throw "definetly should be a user to delete uploaders";
    }
  }
</script>

<header
  class="w-full max-w-3xl mx-auto border-b p-2 flex flex-wrap items-center"
>
  <span class="flex-grow mx-2">
    <a class="text-2xl font-light hover:opacity-50 flex items-center" href="/">
      <svg
        class="float-left w-6 mr-2"
        version="1.1"
        id="Layer_1"
        xmlns="http://www.w3.org/2000/svg"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        x="0px"
        y="0px"
        viewBox="0 0 301.4 356.4"
        enable-background="new 0 0 301.4 356.4"
        xml:space="preserve"
      >
        <g>
          <g>
            <path
              fill="#34D399"
              d="M150.7,2.6l149.1,304.7h-93.7l-33.3-69.2L150.7,2.6z"
            />
            <path
              fill="#6EE7B7"
              d="M150.7,2.6L1.6,307.3h93.7l33.3-69.2L150.7,2.6z"
            />
            <g>
              <path
                fill="#059669"
                d="M150.7,2.6l55.4,304.7l-55.4,47.5L143.4,216L150.7,2.6z"
              />
              <path fill="#10B981" d="M150.7,2.6L95.4,307.3l55.4,47.5V2.6z" />
            </g>
          </g>
        </g>
      </svg>
      Uploader - from Memo
    </a>
  </span>
  {#if signIn}
    <span class="mx-2">
      {#if user}
        <button
          class="bg-gray-800 rounded px-2 py-1 text-white font-bold"
          on:click={() => window.location.reload()}>Sign out</button
        >
      {:else}
        <button
          class="bg-gray-800 rounded px-2 py-1 text-white font-bold"
          on:click={signIn}>Sign in</button
        >
      {/if}
    </span>
  {/if}
</header>
{#if signIn && openPicker}
  <main>
    {#if user}
      <div class="max-w-xl mx-auto mx-2 my-6">
        <p>
          Connected to Google account:
          <span class="font-bold">{user.name}</span>
          &lt;<span>{user.email}</span>&gt;
        </p>
      </div>
      <div class="max-w-xl mx-auto mx-2 my-6">
        <h2 class="my-4 text-center text-xl underline">Uploaders</h2>
        {#each user.uploaders as uploader}
          <div class="bg-white border shadow">
            <header class="flex flex-wrap items-center my-2">
              <h3 class="px-2 text-lg">{uploader.name}</h3>
              <span class="flex-grow px-2 text-right">
                <button
                  on:click={() => {
                    deleteUploader(uploader.id);
                  }}>Delete</button
                >
              </span>
            </header>
            <p class="my-2 px-2">
              public link: <a
                class="underline text-green-600"
                href="{window.origin}/uploader#{uploader.id}"
                >{window.origin}/uploader#{uploader.id}</a
              >
            </p>
            <!-- <p class="my-2 px-2">
              View files in <a class="underline text-green-600" href="">Drive</a
              >
            </p> -->
          </div>
        {:else}
          You have no uploaders, create your first below
        {/each}
      </div>
      <form
        class="max-w-xl mx-auto mx-2 my-6"
        on:submit|preventDefault={createUploader}
      >
        <h2 class="my-4 text-center text-xl underline">Create an uploader</h2>
        <div>
          <span>name</span>
          <input
            class="bg-white border"
            type="text"
            bind:value={uploaderName}
            required
          />
        </div>
        <div>
          <span>Destination folder</span>
          <input
            class="bg-white border"
            type="text"
            readonly
            value={picked?.name}
            required
          />
          <button
            class="bg-gray-800 rounded px-2 py-1 text-white font-bold"
            type="button"
            on:click|preventDefault={openPicker}>Select Folder</button
          >
        </div>
        <button
          class="bg-gray-800 rounded px-2 py-1 text-white font-bold"
          type="submit"
        >
          Save
        </button>
      </form>
    {:else}
      <div class="max-w-xl mx-auto py-20 text-lg">
        <p class="my-4">Connect your cloud storage to receive files.</p>
        <p class="my-4">Files are directly stored in your Google Drive</p>
        <button
          class="bg-gray-800 rounded px-2 py-1 text-white font-bold"
          on:click={signIn}>Create an Uploader</button
        >
      </div>
    {/if}
  </main>
{/if}
