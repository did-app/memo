
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>File Uploader - from Memo</title>
  <script src="https://apis.google.com/js/platform.js?onload=start" async defer></script>
  <meta name="google-signin-client_id"
    content="296333378796-jeod0t6c4vmd26shsodjnqor389ibfmt.apps.googleusercontent.com">
</head>

<body>
  <h1>Hello</h1>
  <button id="my-signin2" onclick="connect(event)">Connect</button>
</body>

<script>
  // Svelte pages
  // if only google has the fancy file shower and stuff in the client might be nicer to do on the backend.
  // Write a direct conversation from uploader@sendmemo.app
  function pickerCallback(params) {
    console.log(params);
  }
  let auth2
  function connect(params) {
    console.log("connecting");
    auth2.grantOfflineAccess().then(function (authResult) {
      console.log(auth2);
      console.log(authResult);
      // TODO call something else maybe
      fetch("http://localhost:8000/uploader/allow", {
        method: "POST",
        body: JSON.stringify({ code: authResult.code })
      })

      let accessToken = auth2.currentUser.get().getAuthResponse({ includeAuthorizationData: true }).access_token;
      var view = new google.picker.DocsView()
        .setOwnedByMe(true)
        .setIncludeFolders(true)
        .setSelectFolderEnabled(true)
        // .setEnableTeamDrives(teamDrive)
        .setMimeTypes('application/vnd.google-apps.folder');
      var picker = new google.picker.PickerBuilder()
        .enableFeature(google.picker.Feature.NAV_HIDDEN)
        .enableFeature(google.picker.Feature.SUPPORT_TEAM_DRIVES)
        .setTitle('Select a folder to use for the uploads')
        .addView(view)
        .setOAuthToken(accessToken)
        .setDeveloperKey('AIzaSyCnu1REwPCB-GKxUngpiQBAy1zkJYiIqKs')
        .setCallback(pickerCallback)
        .build();
      picker.setVisible(true);
    })
  }
  function start() {
    gapi.load('auth2', function () {
      gapi.load('picker', console.log);

      auth2 = gapi.auth2.init({
        // client_id: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
        // Scopes to request in addition to 'profile' and 'email'
        scope: 'https://www.googleapis.com/auth/drive.file'
      });
      console.log("sone");
    });


    // function onSuccess() {
    //   console.log(arguments);
    // }
    // function onFailure() {
    //   console.log(arguments);
    // }

    // gapi.signin2.render('my-signin2', {
    //   'scope': 'profile email https://www.googleapis.com/auth/drive.file',
    //   'width': 240,
    //   'height': 50,
    //   'longtitle': true,
    //   'theme': 'dark',
    //   'onsuccess': onSuccess,
    //   'onfailure': onFailure
    // });

  }
</script>

</html>