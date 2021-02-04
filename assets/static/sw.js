const staticLiveDj = "live-dj-site-v1"
const assets = [
  "/css/app.css",
  "/js/app.js"
]

self.addEventListener("install", installEvent => {
  installEvent.waitUntil(
    caches.open(staticLiveDj).then(cache => {
      cache.addAll(assets)
    })
  )
})
