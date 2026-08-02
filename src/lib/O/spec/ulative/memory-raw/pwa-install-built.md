---
name: pwa-install-built
description: PWA install code half BUILT (manifest/SW/monolith icon/mediaSession); device-UNVERIFIED; the gate is a HTTPS phone-reachable origin
metadata: 
  node_type: memory
  type: project
  originSessionId: 5a75cfd5-1e53-4df0-a86a-d9f6d52ddc25
---

The code half of "jamsend installable on a phone" shipped 2026-07-05 (plan of record = spec/PWA_install_handover.md, updated with a Status block). Built: `static/manifest.webmanifest` (start_url `/` = the app, not a fleet runner — flip to `/?I=`/`/?B=` if a phone runner is wanted), `static/icon.svg` (a 2001 monolith seen from below on a hall ceiling; square + safe-zone-clear so it doubles as maskable), `src/app.html` (manifest link + theme-color + apple-mobile-web-app-* + apple-touch-icon), `src/service-worker.js` (minimal + INERT — SvelteKit auto-registers it, so it now also registers on the dev :9091 fleet; caches nothing, intercepts nothing, never touches /relay or peerjs; disable via `kit.serviceWorker.register:false` if it ever misbehaves), and Media Session wired in `src/lib/ghost/Radios.svelte` (`i_nowPlaying` sets the lockscreen card, `close_nowPlaying` clears it, `nexttrack`→`turn_knob`; feature-detected so it no-ops under jsdom + never rides the silent `keep_awake` gat).

**The bomb:** it is UNVERIFIED on a real device — nobody has seen "Add to Home Screen" yet. Two things owed: (1) **step 1, the real gate** — a secure HTTPS origin a phone can reach (tunnel/deploy) + its host added to `ALLOWED_HOSTS`, authenticated (don't open the relay `gen_write` RCE); host/infra + a physical phone, not doable from the container. (2) **iOS raster PNG** — the container has NO rasterizer (rsvg/inkscape/imagemagick/sharp absent), so `apple-touch-icon` needs a real 180×180 PNG (and 192/512 maskable) exported from `icon.svg`; do it as a Story Book per [[one-off-utilities-are-books]]. Related: [[allowed-hosts-env]], [[cluster-trust]].
