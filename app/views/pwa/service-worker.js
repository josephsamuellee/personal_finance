// Network-only service worker. Financial entries are never cached or queued.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return

  event.respondWith(fetch(event.request))
})
