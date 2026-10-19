/// <reference lib="webworker" />

// The service worker — it makes jamsend installable as a PWA, and lets the MUSIC PAGE boot with the box unreachable.
//  SvelteKit auto-registers this file (src/service-worker.js) by convention, for EVERY tab on the origin — runners, the
//   editor, the hacker room — so it is opt-in by page:
//
//  • the genuine player (BigSoundland with no ?B=) is the only thing cached.  A navigation to `/` or `/BigSoundland`
//     without ?B=/?E= marks its resulting client as a music page, and the page posts {jamsend:'music_page'} on boot to
//      re-mark itself after the worker was stopped.  Every other tab's fetches are never touched (no respondWith), so a
//       dispatch tab can never be handed stale gen.
//  • NETWORK FIRST, the cache only when the network FAILS (a reject, not a 500) — online, the player gets exactly what it
//     would without a worker, and each good response refreshes the copy.  Offline (the box down, the relay unreachable),
//      the last copy boots the shell and the radio falls to the SoundPool (Radio_pocket_why, Ghost/M/Radio.g).
//  • NEVER the live channels: /relay (the websocket), /peerjs (signalling), /__* (dev-server endpoints).  Music bytes
//     travel over the wire and the pool lives in OPFS, so neither passes through here.
//
// To retire the cache, bump CACHE: activate deletes every other jamsend-shell-* cache.

const CACHE = 'jamsend-shell-v2'   // v1 cached raw .go sources (the empty-destination bug below)
const music = new Set()   // clientIds of music pages — lost when the worker stops; the page's boot message re-adds it

const is_music_url = (url) => {
    const p = url.pathname
    if (p !== '/' && p !== '/BigSoundland' && p !== '/BigSoundland/') return false
    return !url.searchParams.has('B') && !url.searchParams.has('E')
}
const never = (url) => url.pathname.startsWith('/relay') || url.pathname.startsWith('/peerjs') || url.pathname.startsWith('/__')

// the cache key: one shell per path for a navigation (the ?I= identity is read client-side), and a module without
//  Vite's HMR `t=` stamp so a hot-updated file overwrites its own entry instead of piling up beside it.
const key_of = (url, navigate) => {
    if (navigate) return url.origin + url.pathname
    const k = new URL(url.href)
    k.searchParams.delete('t')
    return k.href
}

// A ghost (`gen/**.go`) is a Svelte file under a foreign extension, so Vite transforms it only when it can tell the
//  request is for a script — by `Sec-Fetch-Dest: script`.  A fetch re-issued from this worker arrives as `empty`, Vite
//   serves the raw `<script lang="ts">…` source with no content-type, and the browser sniffs it as HTML: every Creduler
//    ghost then fails "Expected a JavaScript-or-Wasm module script… text/html" (found 2026-10-19 on the music page).
//     `?import` is Vite's own spelling of "this is an import", so ask with it; the response still answers the original
//      URL, and the cache key stays the original.
const network_request = (request, url) => {
    if (request.destination !== 'script' || !url.pathname.endsWith('.go') || url.searchParams.has('import')) return request
    const u = new URL(url.href)
    u.searchParams.set('import', '')
    return new Request(u.href, { credentials: request.credentials, cache: request.cache })
}

async function network_first(request, key) {
    try {
        const res = await fetch(network_request(request, new URL(request.url)))
        if (res.ok && res.type === 'basic') {
            const copy = res.clone()
            caches.open(CACHE).then((c) => c.put(key, copy)).catch(() => {})
        }
        return res
    } catch (er) {
        const hit = await caches.match(key)
        if (hit) return hit
        throw er
    }
}

self.addEventListener('install', () => {
    // take over immediately so the first install doesn't wait for every tab to close.
    self.skipWaiting()
})

self.addEventListener('activate', (event) => {
    event.waitUntil((async () => {
        for (const k of await caches.keys()) {
            if (k.startsWith('jamsend-shell-') && k !== CACHE) await caches.delete(k)
        }
        await self.clients.claim()
    })())
})

self.addEventListener('message', (event) => {
    if (event.data && event.data.jamsend === 'music_page' && event.source && event.source.id) music.add(event.source.id)
})

self.addEventListener('fetch', (event) => {
    const req = event.request
    if (req.method !== 'GET' || req.headers.has('range')) return
    const url = new URL(req.url)
    if (url.origin !== self.location.origin || never(url)) return
    const navigate = req.mode === 'navigate'
    if (navigate) {
        if (!is_music_url(url)) return
        if (event.resultingClientId) music.add(event.resultingClientId)
    } else if (!music.has(event.clientId)) {
        return
    }
    event.respondWith(network_first(req, key_of(url, navigate)))
})
