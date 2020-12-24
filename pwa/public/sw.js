self.addEventListener('install', (event) => {
  console.log("Installing sw.js");
});

self.addEventListener('fetch', (event) => {
  // This is a no-op, the feature request was to have the conversation rediscoverable
  event.respondWith(
    fetch(event.request)
  );
});
