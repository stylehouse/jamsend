# PWA install — jamsend on a phone (homescreen icon, and the lockscreen truth)

Spun out of the runner-warmth work (task #35). The audio-keepalive half already shipped
 (`SoundSystem.keep_awake` + the Auto runner gate) — this is the OTHER half, the one that's
  genuinely handoverable as its own chunk because it barely touches the runner internals.

## The destination (two motives, one manifest)

The human wants jamsend **on their phone** — ideally on the lockscreen, would settle for the
 homescreen. That is really two wants riding one artifact:

- **User-facing:** a homescreen icon that opens the app full-screen, like a native app.
- **Fleet-facing:** an *installed* PWA is far more resistant to the browser discarding/freezing
   the tab than a plain browser tab — so it compounds with `keep_awake` to keep a phone-hosted
    runner alive in the background.

Both are served by the same thing: a web app manifest + a minimal service worker + an
 installable, HTTPS-served origin.

## The bomb — read this before you touch anything

**1. The real blocker is NOT the manifest — it's a secure origin the phone can reach.**
 jamsend needs a **secure context** (WebRTC + PeerJS + the localhost secure-context assumption in
  `CLAUDE.md`), and a PWA will only install over **HTTPS** (or `localhost`, which a phone is not).
   Today the app is reached at `172.17.0.1:9091` / `localhost:9091` — those resolve only on the dev
    host, never from a phone. So step zero is a real HTTPS origin the phone can load: an HTTPS tunnel
     (cloudflared/ngrok), a LAN box with a trusted cert, or a deploy. Get that wrong and you'll write
      a perfect manifest that never offers "Add to Home Screen". **This is the hard 80%; the manifest
       is the easy 20%.**

**2. Exposing the app to a phone goes through `ALLOWED_HOSTS`, authenticated.**
 `vite.config.ts:29` builds `allowedHosts` from the `ALLOWED_HOSTS` env (docker-compose `env_file`).
  The phone-reachable host must be added there — and per the standing rule (`allowed-hosts env`
   memory / cluster-trust), **do not expose the dev server unauthed**. The relay is already signed
    with the cluster Idento; a public origin must not become an open RCE on `gen_write`. Treat "make
     it reachable from the phone" as a security decision, not a convenience toggle.

**3. "Webpage on the lockscreen" is not literally possible — reframe it.**
 No browser lets an arbitrary webpage live on a phone lockscreen (iOS forbids it; Android is
  widgets-only, which needs a native app). What you CAN get, and what actually satisfies the intent
   for a music app, is the **Media Session now-playing card** on the lockscreen while audio plays:
    `navigator.mediaSession.metadata = new MediaMetadata({title, artist, artwork})` + action handlers
     (play/pause/next). It appears on the lockscreen and in the notification shade **only while the
      tab is actually producing audio** — i.e. when a real track plays, NOT from the gain-0
       `keep_awake` oscillator (that's deliberately silent and won't raise the card). So: homescreen
        icon = the manifest; lockscreen presence = media-session metadata wired to the real playback
         path. Set expectations with the human accordingly — they get a lockscreen *player card*, not
          an arbitrary page.

**4. Manifest by hand, not a plugin (probably).**
 SvelteKit supports a `static/manifest.webmanifest` + a `src/service-worker.js` (its own convention)
  with zero plugins; `@vite-pwa/sveltekit` exists but drags in Workbox and config surface. Given the
   house ethos (no scattered infra, prefer the small hand-rolled thing), lean hand-rolled: a static
    manifest, a ~20-line service worker that just satisfies the installability criterion (a `fetch`
     handler; it need not cache aggressively — an always-online app can pass-through), and a
      `<link rel="manifest">` in `src/app.html`. Let the human veto if they'd rather adopt the plugin.

**5. Decide what the installed icon opens (`start_url`).**
 There are two toplevels: `src/routes/Otro` (the app) and `src/routes/BigWordland` (the big-room
  editor). A phone install almost certainly wants the *app*, not a headless runner — but if the goal
   is a always-on phone RUNNER in the fleet, `start_url` could be `/?B=<Book>` (boots a runner) or
    `/?I=<tag>` (an idle grid runner, per the Clustation memory). This is a product decision; name it
     explicitly in the manifest and say which you chose and why.

## The pieces (all real paths)

- **`src/app.html`** — the SvelteKit shell (exists). Add `<link rel="manifest" href="%sveltekit.assets%/manifest.webmanifest">` and the iOS `apple-mobile-web-app-*` meta tags (iOS ignores the manifest's display/name and reads these instead — you need both).
- **`static/manifest.webmanifest`** — NEW. `name`, `short_name`, `start_url` (see #5), `display: "standalone"`, `theme_color`/`background_color`, and `icons`.
- **`static/` icons** — mostly already here: `palmtree_icon.svg`, `favicon-tepee.png`, `favicon.png`. A manifest wants at least a 192px and a 512px PNG plus a `maskable` variant; the palmtree SVG is the natural source — export the required raster sizes (icon prep is a fine job for a Story Book per the "utilities are Books" rule, if you want it reproducible).
- **`src/service-worker.js`** — NEW, minimal. SvelteKit auto-registers a service worker at this path; keep it tiny (a pass-through `fetch` + a version bump) — enough to be installable without fighting the always-online model.
- **Media Session (lockscreen card)** — wire `navigator.mediaSession` where real playback lives: the audio path (`src/lib/p2p/ftp/Audio.svelte.ts` / the Radios ghost). Set `metadata` when a track starts, clear it on stop, register play/pause handlers. This is the only "lockscreen" surface that exists.

## The next move (smallest first)

1. Stand up an HTTPS origin the phone can reach (tunnel is fastest to prove the concept), add its
    host to `ALLOWED_HOSTS`, confirm the app loads on the phone over HTTPS. — the gate for everything.
2. Add the manifest + iOS meta + a 192/512 icon; confirm the phone offers **Add to Home Screen** and
    the installed icon opens standalone. — the homescreen win, done.
3. Add the minimal service worker; confirm the install is "real" (installable criteria met).
4. Wire `navigator.mediaSession` metadata to the real playback start/stop; confirm the **lockscreen
    now-playing card** appears while a track plays. — the "lockscreen" win, honestly delivered.

Steps 2–4 are each an afternoon. Step 1 is the one that can eat a day and is where the secure-context
 and auth constraints bite — do it first, in the open, and don't let it hide behind the easy parts.

## What this is NOT

Not the Page Lifecycle re-announce (task #35 remainder): re-ping/re-advertise on `resume`/`freeze`
 and a "going cold" advertise on `freeze` is runner-internal networking, lives near `keep_awake` and
  the Lies keepalive, and stays with #35 — it doesn't need HTTPS, a manifest, or a phone. Keep the two
   apart so the PWA work can proceed on its own timeline (a real origin) without blocking the cheap
    lifecycle nicety.
