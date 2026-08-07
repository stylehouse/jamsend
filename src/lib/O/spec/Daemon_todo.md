# Daemon_todo — the machine as a process, not a tab

A node daemon that boots the whole jamsend machine headless and stays up: a stable long-running
 peer on the p2p network, serving the Radiobuddies v1.0 experience (listen + heist) and, later, a
  music collection. Built 2026-08-07 off to the side in `scripts/daemon/`; **nothing shared was
   edited** (a second agent was live on the Radio cluster the whole session).

---

## 0. What to get on with next

The daemon **boots, thinks, reads the wormhole, runs a Story Book to settle, and keeps a stable
 identity across restarts** — all proven below, on 2026-08-07.

> **It will not run today.** `fake-indexeddb` is not installed (§3.2), and installing it is a
>  coordinated job across the two libc containers, not a quick `npm i`. That is move 0.

Then three candidates, in the order they actually unblock things:

1. **Give the daemon its own relay address** (§4). Today it would register as `addr=runner`, the
    same address every runner tab claims. Until that's fixed `RELAY=1` is a foot-gun and the daemon
     is offline-only — which means none of the *peer* half of the point is exercised yet.
2. **The opus shim** (§2). Until node can encode/decode opus, the daemon can serve pre-stocked
    bytes but cannot stock a collection or listen. This is the biggest single piece of work and
     the one that turns "a headless machine" into "a music node".
3. **Point it at real music** (§5) — a nav over `/music` so `Crate_nav_meander` has something to
    dig through. Cheap, and it makes 1 and 2 testable against reality instead of synth tones.

The arc: **a Sounditron that can't be closed.** Everything the players do from a tab, a box in the
 corner should do from a socket — hold the collection, answer heists, carry a radio — so the network
  has at least one peer whose uptime isn't somebody's browser session.

---

## 1. What is built, and how to run it

```
node scripts/daemon/run.mjs                       # forever, offline, Auto toplevel
B=Sounditron SECS=90 node scripts/daemon/run.mjs  # boot a Book as a runner, exit after 90s
node -e "fetch('http://localhost:9099/status').then(r=>r.text()).then(console.log)"
```

| file | what it is |
|---|---|
| `scripts/daemon/run.mjs` | the launcher. Programmatic vite-node — **not** the vite-node CLI, see §3.1 |
| `scripts/daemon/main.ts` | jsdom + shims, mounts the shell, owns the crank loop, the probe and the status port |
| `scripts/daemon/Daemonic.svelte` | Otro's boot with none of Otro's chrome |
| `scripts/daemon/daemon.vite.config.mjs` | the Story_cli vitest config minus `test` |

Knobs are env vars, because `boot_param()` already reads env under node exactly as it reads `?query`
 in the browser — so `B=Sounditron` *is* `?B=Sounditron`. `A` `B` `E` `I` `ORIGIN` `SHARE` `OVERLAY`
  `PORT` `SECS` `RELAY` `KEYFILE` `QUIET`; the header of `main.ts` is the reference.

**Interrogation.** Two surfaces on purpose. The right one is the relay — a daemon booted with
 `RELAY=1` is a runner and `scripts/runner_ask.mjs` reaches it like any tab (proven: it registered,
  was accepted, and sent `run_phase` frames to the editor). The other is a local HTTP port that
   answers *even when the relay is down*, which is exactly when you want to ask:

- `/status` — uptime, ticks, per-House todo **with the queued elvis names**, worlds, wedge, `inside`,
   Book state (the numbers `runner_ask state` gives), identity
- `/c?depth=3` — the C tree, the daemon's `snap` without needing Story
- `/stop` — clean shutdown

### Proven (2026-08-07, evidence in `/tmp/jamsend_daemon/*.log`)

- **Boots the real thing.** `A=Auto` stands up Blank, Wormhole, DirectoryOpener, Auto, and picks up
   the Library's default Book — H:Story and H:MusuStaple appear on their own.
- **w:Wormhole works.** `NodeWormholeNav` injected at `A.c.nav`; the Wormhole worker's own seam
   (`if (!A.c.nav) … new WormholeNav(DL)`) means the browser DirectoryOpener path never runs.
   Reads are real: the Sounditron Book read `wormhole/Story/Sounditron/toc.snap` off it.
- **Runs a Book to settle.** `B=Sounditron` → Creduler acquires the spine (w:Lies, w:Vyto appear),
   7 steps snapped, `driving=false`. It comes up alright. (`ok=0` — see §6, do NOT read a daemon run
    as a verification gate.)
- **Stable identity across restarts** — the same prepub `8d550465790a9a60` on two cold boots, from a
   keyfile, adopted into a first-class `%Identity` by Auto's own migration leg (§3.4).
- **Joins the relay** — `ws OPEN ws://…/relay?addr=runner`, `become role=runner` accepted, `relay
   bridge UP`. Then immediately demonstrated why that must not be the default (§4).
- **No audio crashes.** Zero AudioContext/WebCodecs errors across every run: the `typeof X ===
   'undefined'` guards at each call site degrade instead of throwing.

---

## 2. The audio hole — the one genuinely browser-only thing

Everything else on the boot path had a seam. Audio doesn't.

| API | sites | node answer |
|---|---|---|
| `OfflineAudioContext` / `decodeAudioData` | `Crate.g:106,505`, `Ra.g:1287,1592`, `Ra.g:204` (LUFS) | `node-web-audio-api` (napi bindings) provides both for real |
| WebCodecs `AudioEncoder`/`AudioDecoder`/`AudioData`/`EncodedAudioChunk` | `Ra.g:300,412`, `Radio.g:2283` | **no node implementation** — needs a shim over libopus |
| the device clock | `Sound_gat()` (`Sound.g:210`), and `AC.currentTime` throughout `Radio.g` | a real node AudioContext, or a fake gat with a monotonic clock |

Two things make the WebCodecs shim tractable, and they're worth knowing before anyone quotes a
 big number for it: the **surface used is tiny** (construct with `{output,error}`, `configure`,
  `encode(AudioData)`, `flush`; and the decode twin), and **`Ra.g:22` says the Ogg mux is gone —
   a chunk is raw length-prefixed opus packets**, which is precisely the shape a libopus binding
    hands you. There is no container to fake.

**The split that shapes v1.0:** heist needs no codec *ever* — `Heist.g:5` "PAYLOAD IS ORIGINAL
 BYTES", census reads via `read_range`, slices at `Heist_chunk_bytes`, sha256s each chunk, and Repli
  moves them mainkey-blind. So a **serve-only daemon over pre-stocked radiostock** (`.jamsend/
   radiostock/<ts>-<pub>-<enid>.jamsend_radiostock` = a JSON header line + opus bufs back to back,
    `Ra.g:29`) is reachable with **zero codec work**. Codecs become mandatory only to *ingest* new
     music or to *hear*.

> Owner note 2026-08-07: there is also a **transcode-to-ogg** path that isn't well tested yet.
>  Whatever that lands as, it's a third codec surface — check it before sizing the shim.

---

## 3. The five traps, each of which cost real time

### 3.1 The vite-node CLI SSR-compiles your components

`vite-node main.ts` defaults every module to the **ssr** transform, and vite-plugin-svelte compiles
 for SSR under that flag — so `mount()` gets a render function and the machine never thinks. (This
  is also why every headless boot in this repo runs under vitest: `environment: jsdom` flips
   vitest's transformMode to `web`.) `run.mjs` uses vite-node's programmatic API with
    `transformMode: { web: [/.*/] }`, so the daemon stays a plain node process instead of pretending
     to be a test. Also needs `optimizeDeps: { noDiscovery: true, include: [] }` — the dep
      pre-bundler rewrites imports to `/@fs/…` dev-server URLs vite-node cannot resolve.

### 3.2 A stubbed indexedDB wedges the machine on tick one — THE BIG ONE

`Story_cli.setup.ts` gets away with a no-op IDB stub because a fixture Book never awaits Dexie.
 **A real boot awaits it immediately**: `Housing.DirectoryOpener` (`Housing.svelte.ts:1934`) opens
  with `await fsh.start()` → `restoreDirectoryHandle` → `await db.Handle.get(key)`. Against the stub
   that promise never settles — **and it is awaited inside the beliefs mutex**, the one lock every
    House drains under. Symptom: `beliefs mutex held 26s by H:Mundo think`, worlds half-built, todo
     stuck at 2, and a process that looks perfectly healthy.

The daemon needs `fake-indexeddb`. **It is NOT installed, and you must not casually install it —
 read CLAUDE.md "node_modules is SHARED by two different libc platforms" first.** Installing it
  `--no-save` from the claude container on 2026-08-07 drifted rollup off its pinned 4.40.2 and left
   the Alpine/musl dev container without its native rollup binary, taking the app down for hours;
    the human's reconcile then swept the unsaved package back out, which is correct and is why the
     daemon cannot boot today. **The real owed item is a proper `devDependencies` entry landed at a
      moment when both containers can be reconciled** — not another unsaved install. Until then
       `run.mjs` fails on the `fake-indexeddb/auto` import, which is a loud, honest failure rather
        than the silent wedge a stub gives.

Two follow-ons once it is back:

- **The two-globals trap.** `fake-indexeddb/auto` targets `typeof window !== "undefined" ? window
   : global` — and we install a jsdom window first, so it lands on the *window*. Dexie resolves its
    global as `globalThis`. Out of the box: window has IDB, globalThis doesn't, Dexie throws
     `MissingAPIError` — **and the wedge still clears**, because a Dexie that rejects unwedges the
      pass exactly like a Dexie that works. Do not read "the wedge went away" as "persistence
       works"; read `dexie: indexedDB=true` in the boot line.
- **It is memory-only.** Nothing in Dexie survives a restart. §3.4 is why that turned out not to
   matter for identity, but it still matters for everything else Dexie holds.

### 3.3 The machine does not self-drive under node

In the browser the House's `$effect.root` drives todo → beliefs off svelte's scheduler. Under node
 that pump doesn't carry itself (the header of `Story_cli.svelte` says so; every headless spec here
  hand-cranks `_really_answer_calls` in a loop). **So the daemon's main loop IS the pump.** It drains
   hard while there's work, idles at ~50ms, and wakes early for the soonest live ttlilt — sleeping
    past a ttlilt turns a timing-sensitive req into a spurious timeout, which reads as "the daemon is
     flaky" and is really "the driver overslept". This is the one structural difference from a tab.

### 3.4 `?I=<tag>` is a UI-shaped dead end for a daemon

The identity on-ramp is `?I=<tag>`, and for a named tag it can only **resume**. On a daemon with no
 durable store: `🪪⚠ identity ARRESTED — no key for daemon-alpha is stored in this browser`, and the
  boot stops dead — by design, Auto.svelte: *"Nothing past this point runs … until a human resolves
   it via the IdHatch"*. An IdHatch is a popover. A daemon renders no popovers. (Verified: with
    `I=daemon-alpha` no H:Story ever appears.) `I=new` is worse in its own way — a brand-new stranger
     every boot.

**The way through needed no shared-code change.** Auto's legacy-migration leg adopts a bare
 `stashed.cluster_idento` into a first-class `%Identity`, once, on any boot without `?I=`. So the
  daemon keeps its keypair in a file (`KEYFILE=`, default `/tmp/jamsend_daemon/idento.json`, minted
   on first run, mode 0600), stamps it on the top House's `stashed` **before `may_begin`** — Auto
    latches `identity_adopted` on its first pass, so a key stamped after that is never seen — and
     Auto does the rest. Same peer, same prepub, every restart. With an identity present, `w:Swarm`
      stands up, which is the layer that processes Invites.

### 3.5 Relative `fetch()` throws under node

`TypeError: Failed to parse URL from /log?stream=Startup-anon`. jsdom gives us `location`, but node's
 global fetch is node's and rejects a relative URL outright. Patched to resolve against `ORIGIN`.
  Worth remembering generally: **any app code doing `fetch('/thing')` is browser-only until someone
   gives it a base.**

---

## 4. `[OWED]` The daemon needs its own relay address — read before `RELAY=1`

A runner's relay address is its **role**, not its identity: `LiesLies.svelte:312` does
 `w.oai({ Peering: 1, name: role })` and `Socket_real` dials `/relay?addr=<that>`. So a daemon booted
  as a runner registers as **`addr=runner` — the same address every runner tab claims.** Observed on
   the first connected run: `become role=runner` accepted, then `channel DEAD — 20s silent` twice.
    It also sent `run_phase` frames to the editor: a phantom run in someone else's cluster view.

**The relay is therefore OFF unless `RELAY=1`**, using the app's own seam — `LiesLies` skips the whole
 channel on `typeof WebSocket === 'undefined'` ("not a browser (tests/node)"), so the daemon deletes
  the global and simply looks like node to the code that asks. Nothing is monkey-patched.

The fix is small but lives in shared files, so it was left alone: give the Peering a name that isn't
 the bare role (the identity prepub is right there — the signed `hello` already binds
  `prepubOf(pub)` → socket, so the precise layer exists; it's the coarse `?addr=` binding that
   collides), plus whatever `relay.ts` needs to route it. Do it with the human, when nobody else is
    on the cluster.

---

## 5. `[OWED]` The rest

- **`/music`.** `Crate.g:34` guards `showDirectoryPicker`, and Crate already reads *through the nav*
   — so this is a nav to write, not a picker to fake. Until then the daemon has no collection to dig.
- **Writes.** The nav is deliberately the overlay one: reads fall through overlay → repo, writes land
   in `/tmp/jamsend_daemon/fs`. A daemon that scribbles toc.snaps into a working tree someone else is
    editing is a bad neighbour. `OVERLAY=repo` opts in; a real deployment points `SHARE` at its own
     share.
- **Durable Dexie.** fake-indexeddb is memory-only. Identity is solved (§3.4); the stash, Thangs,
   Heist's keep_memo and Swarm's pier stash are not. Note `Heist.g:2212` — *"Dexie state is lost very
    easily, .jamsend survives it"* — the disk mirror is meant to be the durable twin, so the honest
     move may be to lean on it harder rather than to make IDB persistent.
- **Packaging.** It boots through a vite dev server in middleware mode, which costs ~12s of transform
   on every start. Fine for now; a real deployment wants a build.
- **`fake-indexeddb` as a real devDependency** — the one thing blocking the daemon from running at
   all right now. See §3.2: it is a coordinated-install job, not a quick `npm i`.

---

## 6. Do not use the daemon as a verification gate

The same warning CLAUDE.md gives about `Story_cli_run.mjs` applies here, for the same reason: a
 headless boot quiesces at a different depth than a live runner, so its fixtures match *itself*.
  The Sounditron run snapped 7/7 steps with `ok=0` — the Book **came up and settled**, which is a
   real smoke test and exactly what it was asked for. It is not a green. Recorded fixtures must
    still come from the live runner.

---

## 7. Books — where they go

None were written this session (a Book proves a mechanism *inside* the machine; what needed proving
 here was the process around it, and every finding above is reproducible from a log). When there are
  some, the owner's instruction is that they live under their own `What:` in the Credence Waft:

```
Waft:Credence
  What:Daemon,desc:the machine as a long-running process — headless boot identity and serving with no tab
    Funkcion:StoryTimes
    Funkcion:Storying,of_Book:DaemonStaple,born:<date>,wire:<...>,desc:<...>
```

`wormhole/Credence/toc.snap` was **not** edited — it is shared ground and a second agent was live.

Good Book candidates, all of which are daemon-shaped facts a Book can actually hold: a nav injected
 at `A.c.nav` serves `w:Wormhole` with no DirectoryListing; a world stands up with no AudioContext
  and says so rather than throwing; a bare `stashed.cluster_idento` becomes an active `%Identity` in
   one pass.
