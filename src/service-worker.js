/// <reference lib="webworker" />

// Minimal service worker — its ONLY job is to make jamsend installable as a PWA.
//  Installability wants a manifest + a registered service worker; SvelteKit auto-
//  registers this file (src/service-worker.js) by convention.  jamsend is an always-
//  online app (WebRTC streaming, a live /relay websocket, peerjs signalling), so this
//  deliberately caches NOTHING and passes every request straight through: caching the
//  shell would only serve stale gen after an edit, and the live channels must never be
//  intercepted.  If it ever needs to go offline-capable, add a versioned cache HERE and
//  keep /relay + peerjs-server on the network path.

self.addEventListener('install', () => {
    // take over immediately so the first install doesn't wait for every tab to close.
    self.skipWaiting()
})

self.addEventListener('activate', (event) => {
    event.waitUntil(self.clients.claim())
})

self.addEventListener('fetch', (event) => {
    // The mere presence of a fetch handler is what older engines count toward
    //  installability.  We handle nothing ourselves — no respondWith — so the browser
    //  fetches exactly as it would without a service worker.  In particular the /relay
    //  websocket upgrade and the peerjs-server signalling never pass through here, and
    //  nothing (app shell, music bytes, gen) is cached.
    void event
})
