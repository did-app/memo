<script lang="typescript">
  export let gapi: any;
  let signIn: (() => void) | null = null;
  let openPicker: ((accessToken: string) => void) | null = null;

  let user: { accessToken: string; name: string; email: string } | null = null;

  gapi.load("auth2", function () {
    let auth2 = gapi.auth2.init({
      // Scopes to request in addition to 'profile' and 'email'
      scope: "https://www.googleapis.com/auth/drive.file",
    });
    signIn = function () {
      auth2.grantOfflineAccess().then(function (authResult: any) {
        let serverCode: string = authResult["code"];
        let currentUser = auth2.currentUser.get();
        let accessToken = currentUser.getAuthResponse({
          includeAuthorizationData: true,
        }).access_token;

        console.log(
          currentUser.getAuthResponse({
            includeAuthorizationData: true,
          })
        );
        alert("fff");
        auth2.grantOfflineAccess().then(console.log);

        let name = currentUser.getBasicProfile().getName();
        let email = currentUser.getBasicProfile().getEmail();

        // Submit to backend grant access
        // sign in cookie for a session only hit /api
        // /uploader/authenticate -> List of uploaders
        // /uploader/create ->
        // GoogleUser (sub, email address, refresh_token, access_token, expires)
        // DriveUploader(id, sub FK, name, )
        // List uploaders
        // /uploader/uuid/edit -> List uploaders
        // /uploaders/uuid/delete
        // On form submit
        // /uploaders/uuid/start
        //

        user = { accessToken, name, email };
      });
    };
  });
  gapi.load("picker", function () {
    openPicker = function (accessToken) {
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
        .setOAuthToken(accessToken)
        .setDeveloperKey("AIzaSyCnu1REwPCB-GKxUngpiQBAy1zkJYiIqKs")
        .setCallback(console.log)
        .build();
      picker.setVisible(true);
    };
  });
</script>

<header class="w-full max-w-3xl mx-auto border-b p-2 flex items-center">
  <span class="flex-grow">
    <a class="text-2xl font-light hover:opacity-50 flex items-center" href="/">
      <svg
        class="float-left w-6 mx-2"
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
    {#if user}{:else}
      <button
        class="bg-green-500 rounded px-2 py-1 text-white font-bold"
        on:click={signIn}>Sign in</button
      >
    {/if}
  {/if}
</header>
{#if signIn && openPicker}
  <main>
    {#if user}
      <div class="max-w-3xl mx-auto p-2">
        <!-- {JSON.stringify(user)} -->
        uploaders
      </div>
      <div class="max-w-3xl mx-auto p-2">
        <h1>Create an uploader</h1>
        <div>
          <span>name</span>
          <input type="text" />
        </div>
        <p>Destination folder</p>
        <button
          class="bg-green-500 rounded px-2 py-1 text-white font-bold"
          on:click={() => openPicker(user.accessToken)}>Select Folder</button
        >
      </div>
      <button> Save </button>
    {:else}
      <div class="max-w-xl mx-auto py-20 text-lg">
        <p class="my-4">Connect your cloud storage to receive files.</p>
        <p class="my-4">Files are directly stored in your Google Drive</p>
        <button
          class="bg-green-500 rounded px-2 py-1 text-white font-bold"
          on:click={signIn}>Create an Uploader</button
        >
      </div>
    {/if}
  </main>
{/if}
