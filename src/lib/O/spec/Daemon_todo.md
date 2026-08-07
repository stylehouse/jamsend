# Daemon_todo — the machine as a process, not a tab

A node daemon that boots the whole jamsend machine headless and stays up: a stable long-running
 peer on the p2p network, serving the Radiobuddies v1.0 experience (listen + heist) and, later, a
  music collection. Built 2026-08-07 off to the side in `scripts/daemon/`; **nothing shared was
   edited** (a second agent was live on the Radio cluster the whole session).

---

## 0. What to get on with next

The daemon **boots, thinks, reads the wormhole, runs a Story Book to settle, and keeps a stable
 identity across restarts and across losing its keyfile** — all proven below, on 2026-08-07.
  It needs no npm install and no fake-indexeddb: persistence is a file-backed `dexie` alias (§3.2).

> **⚠ ADVERSARIAL PASS, 2026-08-07/08 — read §8 before believing anything below.** Five reviewers
>  went at the daemon and the identity design. Several claims in this file were **false**, three of
>   them load-bearing: the daemon **cannot process Invites at all** (§8.1), it **cannot carry a
>    radio past a preview** (§8.2), and its **default invocation boots a dev-only page** no client
>     ever reaches (§8.3). §8 is the ledger; the sections below have been corrected in place where
>      the correction is short and cross-referenced to §8 where it is not.

> **UPDATED 2026-08-08 after the overnight run — items 1, 4 and most of the identity work are DONE.**
>  The night's full log, with evidence, is **§9.6**; read that before this list. Landed: all four
>   `Identity_persist_todo` §6 gaps (the identity chain now round-trips — Auto writes the account, a
>    cleared browser resumes off it, and a role identity is findable by its own prepub), the daemon's
>     boot shape + status-port + robustness hardening, and `.jamsend` at 0600 with path confinement.
>      **Step 3 below is now the single blocker for invites**, exactly as §9.1's chain predicted.

Candidates, in the order they actually unblock things:

1. ~~**Boot like a client does** (§8.3)~~ — **DONE 2026-08-08.** `book`+`boot_role` are stamped, a
    bootless boot refuses with exit 4 instead of falling into Auto's dev library page, `ROLE` defaults
     OFF so a bare boot never mints, and `humdinger` comes off `boot_role`. (§9.6)
2. **Give the daemon its own relay address** (§4) — **NOW THE TOP ITEM, and it is the owner's.**
    Promoted from 3 because everything it gated is otherwise ready. Today the daemon would register as
     `addr=runner`, the address every runner tab claims; `bind()` is additive and `deliverLocal` fans
      out to every socket, so both claimants get every frame — the `channel DEAD — 20s silent` symptom.
       Deliberately left alone overnight (§9.7 Phase 3): a bad `relay.ts` edit takes every runner down
        with nobody awake. Smallest change that works: give the daemon's `%Peering` a name that is not
         the bare role (`LiesLies.svelte:312`). **Do NOT** attempt §7.4's suffix/serial layer.
3. **Arm the Swarm station** (§8.1) — the ONE call that gives the daemon invites: `Swarm_station_up`.
    Nothing outside `InvitePanel.svelte` calls it, so no handler is armed and an inbound `pier_hello`
     has nowhere to land. Blocked only on item 2 (`RELAY=0` deletes `WebSocket` and the verb guards on
      it). **The ledger it needs is now waiting for it** — `Swarm_station_up` rehydrates piers, invites
       and chain roots from the stash *before* `Swarm_arm`, and as of tonight that stash is actually
        populated on a restored owner (§9.6, step 2). The daemon is the RESPONDER, never the joiner.
4. ~~**Close the security holes** (§8.4)~~ — **DONE 2026-08-08.** `.jamsend` files at 0600 and dirs at
    0700 (incl. fixing already-existing files), `path.join(root, rel)` confined to root, status port
     bound to localhost, token required on `/stop` and `/c`. (§9.6)
5. **The opus shim** (§2/§2.1): **ffmpeg behind the WebCodecs seam**, encode half only, with an
    Ogg-page→packet demux as the single real piece of work. Note §8.2 — this is no longer only about
     *stocking* a collection; the daemon cannot serve its OWN tracks past the preview window without
      it. **Probably the biggest genuinely-open piece of work in this file now.**
6. **Point it at real music** (§5.3) — a nav over `/music` so `Crate_nav_meander` has something to
    dig through. Makes the rest testable against reality instead of synth tones.
7. **The two-tab fingers-test** (`Identity_persist_todo` §6.7) — the one gate no daemon run can stand
    in for, and it matters MORE now: gap 1 means a real tab writes its private key to a real share, and
     every proof tonight is on the node fs nav. A human with two tabs, ten minutes.

**RULED 2026-08-07 (owner): the daemon never provisions.** Management — mint, Invites, grants —
 happens in browser sessions of the account; the share's `.jamsend/account/<prepub>/` is the
  hand-off; the daemon boots `I=<prepub>` and only ever RESUMES. An arrest is now an **error
   exit**, landed and verified (`arrest_watch` in `main.ts`: exit 2 = no account in the share,
    exit 3 = account on disk but the seed failed — the expected outcome until the Auto gaps land).
     Self-collision is NOT an exit but a **federation** — serial-number the extras, connect every
      place of one Identity, and take turns at the canonical address (disconnect / overthrow /
       reinstate) with the key never moving. **The daemon HOLDS until told to disconnect** — no
        auto-yield, so an always-up box is never silently displaced. It lands on Swarm's existing
         "one key, N addresses" machinery and is blocked on §4. The full flow and the relay
          analysis: `Identity_persist_todo.md` §7 (§7.4 for the federation).

**Read §4.1 before touching identity anywhere.** Standing the daemon up on the app's own identity
 path turned up two bugs in `Auto.svelte`, both unmade because that file is shared ground: the
  disk-seed falls through to an ARREST when the Swarm ghost hasn't deposited yet, and a *successful*
   seed never clears `identity_pending` — so a daemon that found its key on disk stayed held forever
    with the key in hand. Plus the finding under them: **nothing in the app ever writes the account
     file the seed reads.**
 **ALL THREE LANDED 2026-08-08** under §9.0's standing grant, along with gap 4 and a fourth bug found
  while landing them: **`Clustation_pin` had never worked** — it read `Clustation_active_identity`
   (which returns `{pub,key}`, no `.c`) and then guarded on `ident.c.keys`, so it returned false at its
    first line, always, and the door's `?Iz`→`?I` swap has been silently not pinning. Evidence, the
     before/after table and the three places the written recipe was wrong: **§9.6**. The identity chain
      now round-trips on the node nav; the browser gate (§6.7's two-tab test) is still unrun.

Storage is **not** on that list any more, and §5.1 says why: the Dexie → `.jamsend` mirror is already
 built twice over (identity, Heist) and is a *coverage* problem, not an architecture one — so the
  shim can stay a cache and nobody has to design anything to keep going. §5.2 records the one genuinely
   missing protocol bit ("don't feed me radio"), which is shared ground and waits for the human.

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
 in the browser — so `B=Sounditron` *is* `?B=Sounditron`. `A` `B` `E` `I` `ROLE` `KEYFILE` `KEYED`
  `ACCOUNT` `DAEMON_STATE` `ORIGIN` `SHARE` `OVERLAY` `RELAY` `PORT` `SECS` `LOG` `QUIET`; the
   header of `main.ts` is the reference (and now lists all of them).

> **But `?B=`/`?I=` is a DEV shape, not the app's** (§8.3). A real client sets neither: `/BigSoundland`
>  is `boot_qualand({book:'Sounditron', role:'sound'})`, which stamps `book` and `boot_role` in code.
>   The bare `node run.mjs` above is the WORST invocation — it sets no `boot_role` and falls into
>    Auto's dev library page. Use `B=Sounditron` until the daemon stamps its own boot.

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
   > **⚠ CORRECTED §8.3:** "picks up the Library's default Book" is Auto's **library page** — the dev
   >  book-browser, reached only because a bare boot sets no `boot_role`. It activates whatever Book a
   >   human last left `active` in `wormhole/Present/toc.snap`, so "MusuStaple appears on its own" is
   >    editor state, not a daemon default. No real client ever takes this branch.
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
   > **⚠ CORRECTED §8.2 — the guards are NOT at each call site.** `Ra.g:204` has one; `Ra.g:1352`
   >  and `Ra.g:1657` construct `new OfflineAudioContext(1,1,48000)` bare. No run crashed only
   >   because no run ever asked for a track past its preview window — the throw is swallowed by a
   >    detached `.catch` and surfaces as the false note `'preview only — source unreadable'`.

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

> **⚠ HALF FALSE, CORRECTED §8.2.** The heist half holds. The radio half does not: serving a
>  *locally held* track past its pre-stocked preview window needs `Ra_transcode_ensure` →
>   `Ra_source_pcm`, which hits an **unguarded** `new OfflineAudioContext` (`Ra.g:1352`, `:1657`).
>    So "serve-only needs zero codec work" is true for HEIST and false for RADIO beyond the preview.
>     That promotes §2.1's ffmpeg shim from "needed to stock" to "needed to serve".
>      Also: `node-web-audio-api`, cited below as providing these "for real", is **not in
>       `package.json`** and does not resolve.

> Owner note 2026-08-07: there is also a **transcode-to-ogg** path that isn't well tested yet.
>  Whatever that lands as, it's a third codec surface — check it before sizing the shim.

### 2.1 ffmpeg is the right answer, and it is smaller than it looks

Owner, 2026-08-07: *"should we use ffmpeg? I had an ffmpeg server going before the app got p2p at
 all, two prototypes ago."* — **yes**, and the shape that keeps it honest is: **ffmpeg behind the
  WebCodecs seam, not instead of it.** Same move as the `dexie` alias — define
   `AudioEncoder`/`AudioDecoder`/`AudioData`/`EncodedAudioChunk` (and a `decodeAudioData`) as globals
    backed by subprocesses, and **not one line of `Ra.g` changes**. Every call site already guards on
     `typeof AudioEncoder === 'undefined'`, so the seam is pre-cut; the shim just makes the guard pass.

**Only the encode half is needed**, and §5.2 is why: a serve-only daemon never listens, so
 `AudioDecoder` and the whole `Radio_dec_feed` streaming path can stay undefined. What it needs is
  the *stocking* path — source file → PCM → opus packets:

| need | site | ffmpeg |
|---|---|---|
| source → f32 PCM @48k | `ctx.decodeAudioData` (`Crate.g:106,505`, `Ra.g:1341,1646`, `Orig.g:305`) | `-f f32le -ar 48000` to stdout. Exactly what `decodeAudioData` returns, minus the AudioBuffer wrapper |
| PCM → opus packets | `Ra_encode_open/feed/drain` (`Ra.g:300-336`) | `-c:a libopus -b:a <br> -frame_duration 20` |

The push/pull mismatch is not a problem in practice: `Ra_encode_feed` hands ~2s at a time and
 `Ra_encode_drain` awaits `flush()`, so one ffmpeg process per encode session, PCM in on stdin,
  packets collected on close, is a faithful enough `AudioEncoder`.

**The one real piece of work is de-containering.** `Ra.g:22`: the Ogg mux is gone, a chunk is *raw
 length-prefixed opus packets*. ffmpeg will not emit bare packets — the closest is `-f opus`, i.e.
  Ogg-Opus. So the shim must **demux Ogg pages back into packets**: read page headers, walk the
   segment table, concatenate 255-byte continuations. It is ~100 lines against a stable spec, and it
    hands you the other thing you need for free — **`OpusHead` is page 1**, and `Ra_encode_open`'s
     `preskip` (`Ra.g:283-299`, LE u16 at bytes 10-11 of the `decoderConfig.description`) is read
      straight out of it. The comment there already tells you where to look; it is the same 16 bits.

Two caveats worth carrying in:
- **ffmpeg is not installed in this container** (`which ffmpeg` → nothing). It is an `apt-get`, not an
   npm install, so it does **not** touch the shared `node_modules` and carries none of the libc-drift
    risk in CLAUDE.md. A real daemon image should just have it.
- **Match the encoder config exactly or the preskip lies.** `Ra.g` configures
   `{codec:'opus', sampleRate:48000, numberOfChannels:nch, bitrate:br}` and states the preskip reads
    the same on every head chunk *because every encode here is configured the same*. An ffmpeg-side
     drift in frame duration or application mode breaks that invariant silently — chunks that decode
      but drift. Assert the parsed `OpusHead` preskip is 312 and shout if it isn't.

And it settles the owner's other note: **transcode-to-ogg stops being a third codec surface** and
 becomes the *native* output — under ffmpeg, Ogg is what you get and raw packets are what you carve
  out of it, so the ogg path is the better-tested one here, not the shakier one.

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

**The fix is not an indexedDB at all.** `daemon.vite.config.mjs` aliases `dexie` →
 `scripts/daemon/dexie-node.ts`, a file-backed key-value store. The app's own
  `import { Dexie, liveQuery } from 'dexie'` resolves there in the daemon and stays the real Dexie
   everywhere else, so **nothing shared is edited and nothing is installed.**

That is affordable because the app's entire Dexie surface is ~20 calls across three databases, and
 every one is key-value — no cursors, no ranges, no upgrades:

| db | table | calls |
|---|---|---|
| `housing` | `House 'name'` | `toArray` `put` `delete` — the backing store for `.stashed` |
| `housing` | `Handle 'name'` | `get` `put` `delete` — browser directory handles, dead weight here |
| `thangs` | `Thang '[table+name]'` | `get` `put` `delete` `where('table').equals(x).toArray()`, one `transaction` |
| `stemdex` | `doc 'path'` | `toArray` `bulkPut` `bulkDelete` |

Three things this bought beyond just booting:

- **Durability, which fake-indexeddb would NOT have given** (it is memory-only). Proven: cold boot
   mints `43d27004eb98`, then a second boot **with the keyfile deleted** resumes the same prepub off
    `state/housing.json`. The keyfile (§3.4) is now belt-and-braces — useful for *provisioning* a
     chosen identity, no longer load-bearing for keeping one.
- **No npm.** Which in this repo means no libc drift across the two containers that share
   `/app/node_modules` — see CLAUDE.md. An earlier `--no-save` install of fake-indexeddb caused
    exactly that outage.
- **stemdex opts itself out.** `Lies_stemdex` (`LiesFunk.svelte:1378`) early-returns on
   `typeof indexedDB === 'undefined'`, and the daemon deliberately leaves `indexedDB` undefined. It
    is the code editor's search index (Lies+Lang), not the Jamsend app — irrelevant to a daemon.

**Gaps are loud, not silent.** `where().above()`, `between()`, `startsWith()`, `orderBy` and friends
 throw a named error naming the file. The `transaction` claims no isolation (it just awaits the
  callback); its one caller is an idempotent put-then-delete rename, so that is honest for the
   surface in use and dishonest the moment someone needs a rollback.

**This is a scaffold, not the design** (owner, 2026-08-07: *"Dexie is probably meant to be more
 properly imagined with an integration"*). See §5.1: the properly-imagined version is not a better
  Dexie backend but the **`.jamsend` mirror through the nav** — already built for identity
   (`Swarm_account_save`) and for the Heist magazine — which would make this file a warm cache rather
    than the record. It is only the record today for identity, which is why the keyfile exists.

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
      > **⚠ THAT LAST CLAUSE IS FALSE — CORRECTED §8.1.** `w:Swarm` standing up is
      >  `Swarm_station_world()` autovivifying an inert container. The arming lives in
      >   `Swarm_station_up` (`Swarm.g:661` → `Swarm_arm` `:672`), whose only non-Book callers are
      >    in `InvitePanel.svelte` — which the daemon never mounts. **The daemon has an identity and
      >     no invite-processing layer whatsoever.** "Identity present" and "station armed" are two
      >      disconnected facts.

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

## 4.1 The daemon's identity — it is a BigSoundland, and that path found two bugs

Owner, 2026-08-07: *"it needs to take on a specific Identity, like the `?I=…` thing does, and do
 something equivalent to BigSoundland with Story:Sounditron and everything… but slightly different?
  perhaps it wants a different Book, how different is it in there?"*

**Answer: it is not different at all.** `/BigSoundland` is one line —
 `boot_qualand({ book: 'Sounditron', role: 'sound' })` (`V/BigSoundland.svelte:46`) — and
  `boot_qualand` (`BigQualand.svelte:54-68`) does exactly what `Daemonic.svelte` already did, plus
   three stamps. Those three are now stamped (`ROLE=<name>`, default `daemon`; `ROLE=0` opts out):

| stamp | what it buys |
|---|---|
| `id_role` | Auto's `Clustation_ensure_default` resumes-or-mints the identity stored in the `identities` Thang under this role name. **The same peer every restart, off the app's own mechanism.** |
| `assume_identity` | opts into that ("this page always has an identity") |
| `humdinger` | an END-USER room: full Lies stack but invisible to the editor's grid — no advertise, no going-cold, no `from` on pings (`Lies_humdinger`) |

`humdinger` is the one nobody would think to want and the daemon must not skip: without it the editor
 enrols the box off its 5s heartbeat and **dispatches Book runs at it**, so someone's Story lands on
  the server. (It does not fix §4's `addr=runner` collision — that is a different layer — but it does
   remove the phantom-run symptom.)

**Proven, 2026-08-07** (`ROLE=daemon`, `KEYED=0`, no keyfile at all): first boot mints
 `ea5c82505cfc`, second boot resumes the same prepub off `state/thangs.json`, filed under
  `["identities","daemon"]`. So **the keyfile (§1) is now the fallback, not the mechanism** — it
   remains only because it is the one thing that works before Thangs is up.

> A role is a **storage name, not a derivation** — the key is a fresh random mint either way. Two
>  daemons sharing the role name on different boxes are two different peers, not impostors of one.

### The write side of the identity mirror has no caller

`Auto.svelte:176` says *"Swarm_account_save has been writing the whole account (keypair embedded) to
 `.jamsend/account/<prepub>/toc.snap` all along"*. **It has not.** Grep the tree: every caller of
  `Swarm_persist` / `Swarm_account_save` / `Swarm_roster_save` is inside the `SwarmDisk` Book. The
   READ side was wired 2026-08-04 (`Clustation_ensure_identity`'s disk-seed); the WRITE side has
    none, so a browser with a cleared Dexie arrests next to an account dir **that was never created**.
     That is `Identity_persist_todo`'s *"editor lost its crypto again!?"* with the cause in plain sight.

The daemon now calls `Swarm_persist` itself each boot (`ACCOUNT=0` opts out) — not as a fix for the
 app (shared ground), but because a daemon of all things must not keep its only key in a cache, and
  because it makes the seam testable. It also makes the daemon's identity **portable**: copy
   `.jamsend/account/<prepub>/` to another box, boot `I=<prepub>`, same peer.

### Two bugs the resume test then found — both shared code, both left alone

Test: mirror the account, **wipe the Dexie state entirely**, reboot with `I=ea5c82505cfc50ff`. This is
 the headless twin of the two-tab fingers-test `Identity_persist_todo` §3 says is owed — and unlike
  `SwarmDisk`, which runs on `SwarmDisk_memnav`, it exercises **`Swarm_boot_seed` against a real
   filesystem nav**. Observed:

```
[15.4s] 🪪… account mirror waiting — Swarm_persist not deposited
        🪪⚠ identity ARRESTED — no key for ea5c82505cfc50ff is stored in this browser.
[24.2s] 🪪 account mirrored → .jamsend/account/ea5c82505cfc50ff/toc.snap
[54.2s] ♥ 🪪ea5c82505cfc  worlds=Blank Wormhole Auto Lies Clustation/Thangs      ← no Story. ever.
```

1. **The disk-seed is skipped when the Swarm ghost hasn't deposited yet.** Its guard is
    `typeof Swarm_boot_seed === 'function' && typeof Crate_nav === 'function' && !identity_seed_tried`
     (`Auto.svelte:200`). The nav-not-up case correctly *retries* (`SEED_WAIT_MS`, and deliberately
      does not stamp `identity_seed_tried`) — but **ghost-not-deposited-yet has no such branch**: the
       block is skipped whole and execution falls straight through to the arrest. The ghosts arrive
        via the Creduler, i.e. always later than the first boot pass.
2. **A successful seed never clears `identity_pending`.** Only two things do:
    `Clustation_generate_for_pending` and the IdHatch paste (`Auto.svelte:370`) — both human gestures.
     So the later pass *does* find the key on disk and concretes it (the trace above: an active
      identity, keys present, the account re-mirrored) while `if (top.c.identity_pending) return`
       holds the boot forever. **Recovered and still arrested.** In the trace, `w:Story` never stands
        up across 60s with a perfectly good identity sitting right there.

**So `I=<prepub>` does not work on the daemon today** — it arrests and stays arrested, whatever is on
 disk. Use `ROLE=<name>` (which needs neither), and treat `I=` as blocked on the fixes below.

> **RULED, 2026-08-07 (owner): `I=<prepub>` is the PRODUCTION shape, and the arrest is an exit.**
>  *"all the management happens in sessions of the account running in a browser, configuring
>   Invites the usual way etc, then runs in the Daemon."* So `ROLE=` and the keyfile stay dev/smoke
>    conveniences (both MINT, which a production daemon must never do), and an arrested `I=` boot
>     now **exits instead of hanging** — `arrest_watch` (main.ts): exit 2 = no account in the share
>      (provision from a browser first), exit 3 = account on disk but the seed failed (the gaps
>       below; expected until 2/3 land). Verified live: `I=deadbeefdeadbeef` exits 2 at ~39s with
>        the message naming the missing path. The whole flow: `Identity_persist_todo.md` §7.
>
> **Self-collision is a FEDERATION, not an exit** (revised the same day, `Identity_persist_todo`
>  §7.4): the extras get **serial numbers** and every place of one Identity is connected, with
>   **disconnect / overthrow / reinstate** to take turns at the canonical address. The daemon steps
>    to `<prepub>_N` only when TOLD — it **holds until then**, so an always-up box is never silently
>     displaced, and an arriving session simply takes a serial and works from there. Same key
>      throughout, so every Pier still verifies; and the relay can hold the SAME websocket across a
>       hop (`unbind`/`bind` are map ops and a socket already carries a set of addresses), so no
>        channel is torn down. This is §4's real payoff: the daemon needs an address of its own
>         before it can meaningfully collide with anything — and once it has one, the daemon is a
>          **role** in the federation (`Swarm_take_role`: it takes `serve`, the session manages).
>
> **And the address is a WRITE LOCK, which is what makes it matter** (`Identity_persist_todo`
>  §7.4f): only the place holding bare `<prepub>` may write `.jamsend/account/<prepub>/`. So a
>   session takes the canonical address in order to acquire the right to change the account, not
>    merely to be reachable. The daemon is nearly a read-only holder already — `persist_account`
>     writes once per identity per boot — so the gate is one condition on that call.
>
> **DORMANCY is the daemon-side piece, and it is forced** (§7.4g). The owner: *"the Daemon would
>  have to quite totally shut down…? like down to only H:Mundo, drastically chucking out
>   everything… and later bringing it back."* Exit will NOT do: a dead process cannot be told to
>    reinstate, and a human restarting the box is the manual step this daemon exists to remove. So
>     the daemon must survive conceding — crank + status port + presence at its serial stay up,
>      everything above the root goes. Two things to carry in: the teardown does **not** clear
>       Dexie, so a re-standup would resume the stale cached identity and never look at disk (the
>        re-read must be explicit); and the boot latches are the real work — `began`, `keyed_done`,
>         `persisted`, `wrapped`, `_daemon_nocyto` here, plus Auto's `identity_*`/`creduler_up`
>          family in shared code. In our favour: `unwatch_owner`'s `dead` era guard is the
>           precedent, and the daemon's crank owns the pass boundary, so it can tear down BETWEEN
>            drains rather than out from under a held beliefs mutex — a seam a tab does not have.

Both are one-liners (retry instead of falling through; clear the latch on a successful seed) and
 **neither was made** — `Auto.svelte` is shared ground and a second agent was live. They are also
  currently *invisible in the app*, because with no write side there is never a file to find: fixing
   the write side without these two turns "restored from disk" into "held forever", which is worse
    than today. Do all three together, with the human.

> **The full plan lives in `Identity_persist_todo.md` §6** — four gaps (these two, the missing write
>  caller, and a fourth: a role-filed identity is invisible to its own `?I=<prepub>` in Dexie), the
>   order to land them in, what "production ready" needs beyond them, and the repeatable daemon test
>    that found them. This section is just where they were noticed.

---

## 5.1 Storage: Dexie is the cache, `.jamsend` is the twin, the nav is the road

> **Deliberately not resolved.** The owner, 2026-08-07: *"this has been a backgrounded topic the
>  whole time, only occasionally visited to slap-dash what we want. perhaps lets still not get it
>   all figured out."* So this section is **recorded ground, not a plan** — what already exists,
>    what the shim is really standing in for, and which fork is now closed. Nobody has to decide
>     anything to keep using the daemon.

Owner's framing: **`w:Wormhole` is the one already properly done, and Dexie is the one still waiting
 to be imagined properly.** *"Dexie holds Identities etc but also can sync these to
  `.jamsend/accounts` or so… Thangs probably all want to live in Dexie but also sync to disk, to be
   more robust. Getting them to disk is another thing, all via `w:Wormhole`, which may be
    relay-backended."*

The Wormhole has *four* interchangeable backends behind one nav contract
 (`read_file/write_file/bin_read/bin_write/bin_append/read_range/dir/dir_at`), and they are not
  variations on a theme — they are genuinely different substrates:

- `WormholeNav` — a real FSA `DirectoryListing` from the picker
- `OpfsOverlayNav` / the github-seeded OPFS cloud — a shadow disk with no local grant at all
- **`RemoteWormholeNav`** — *the disk arrives over the relay*. `&remoteWormhole=1` boots a tab with
   no local tree that begs a trusted editor to proxy its disk through the channel (Cluster_spec,
    "beg through the Brink"). **The relay is already a storage backend.**
- `NodeWormholeNav` — node fs, which is what this daemon injects

### The sync is not the weird bit — it is built, twice, the same way

*"Syncing dexie to it is the weird bit right?"* — **no, and that is the good news.** The
 Dexie → disk mirror already exists for the two kinds that most needed it, and both do it
  identically: **write a Waft snap through the nav, read it back at boot.**

- **Identity.** `Swarm_account_save/load/list` (`Ghost/S/Swarm.g:2133‑2250`) persists an account as
   its own export snap — keypair embedded, the human's ruling that keys ride the snap — to
    `.jamsend/account/<prepub>/toc.snap` via `nav.write_file`; `Swarm_boot_seed` reads it at boot,
     concretes the identity and **mirrors the row back into Dexie** so the next boot is a plain
      Dexie hit. Book: `SwarmDisk` (`Ghost/Story/Swarmation.g:1637`). Doc: `Identity_persist_todo.md`.
- **Heist.** The magazine *"lives in `.jamsend` as well as Dexie"* — `Heist.g:2258`, and the reason
   in the same breath: *"Dexie state is lost very easily, `.jamsend` survives it."*
    `Heist_defaults_rehydrate` is the read-back for a fresh Dexie with an existing disk.

So the durable form of this state is **a snap on the nav, not a second database**, and Dexie is a
 cache in front of it. What is missing is not a mechanism — it is **coverage, kind by kind**. Both
  existing mirrors say so in their own words:

- the boot-seed grafts into a *detached* vault, so only the **keypair** is adopted; piers and grants
   are not (`Swarm_piers_rehydrate` reads Dexie, which is empty in exactly that scenario) —
    `Identity_persist_todo.md` §0: *"a disk-restored owner comes back friendless"*;
- `Heist.g:1790` names its own gap outright: *"make the source's keep_memo durable (it is the
   Dexie ↔ .jamsend sync)"*.

### What that does to `dexie-node`

It **demotes it, which is the right direction.** The shim stops being the storage answer and becomes
 the cache that happens to persist. Every kind whose `.jamsend` mirror gets finished can be rebuilt
  from disk on a cold daemon, and the shim's JSON file is then a *warm start*, not the record. That
   also lowers what it is allowed to promise: it never has to be a database, only a Map that
    survives a restart — which it already is. If it is ever deleted mid-flight, the worst case
     should be a slow boot, not a lost daemon. That is not true today (identity is the one kind
      where it *is* the record, which is why the keyfile exists) and it is the thing to make true.

### One fork is now closed — and it was the one I liked

**"Let the relay be this backend too" cannot carry the account.** Housing `rw_op` refuses any path
 with a `.jamsend` segment over the wire, whatever grant the caller holds
  (`src/lib/O/Housing.svelte.ts:2287` — *"🔒 .jamsend is owner-local — never served over the wire"*,
   marked `fatal` so it is never retried), and `Identity_persist_todo.md` is explicit that **that
    guard is what makes an on-disk private key acceptable at all — do not relax it.**
     `Swarm_boot_seed` refuses a remote nav for the same reason.

A relay-backed daemon can therefore hold media and stock, but **not its own keys**. A daemon needs
 exactly one piece of genuinely local disk, and it already has it: the keyfile at
  `/tmp/jamsend_daemon/idento.json` (§1). That is the same conclusion `Swarm_account_save` reached
   from the other end — an account is owner-local by law, so the daemon *is* an owner, with a
    corner of disk of its own. Worth noticing that the keyfile and `.jamsend/account/<prepub>/toc.snap`
     are the same idea in two hands; the daemon should probably grow into the latter rather than keep
      inventing the former.

**And drop "give persistence a nav-shaped contract"** — that was the wrong shape. The daemon does
 not need an abstraction over Dexie; it *"simply does filesystem junk"* and already has the nav
  (`NodeWormholeNav`). The nav-shaped thing left to build is the **mirror-per-kind** above, which is
   nav-shaped by construction. `housing.House` (one JSON blob per House) and `thangs.Thang`
    (`[table+name] → json`) are files in everything but name already.

---

## 5.2 `[OWED]` "don't feed me radio" — the serve-only declaration

Owner, 2026-08-07: *"the daemon just serves radio|heist, we need a special protocol bit somewhere to
 say 'don't feed me radio', like we had before (called inhibition, didn't really make sense thus)."*

The prior art is real and still in the tree, in the **pre-C layer**:
 `Pier.inhibited_features: SvelteMap<TrustName, Inhibition>` (`src/lib/p2p/Peerily.svelte.ts:437`),
  where an `Inhibition` is a bare number. `Gardening.svelte:368` sets it — `9` on init, `2` for
   *"volunteer — sharing, no listen"*, `0` for fully on — and `Sharing.svelte.ts:212` reads it to
    decide which halves to mount: `< 3` → `A:racaster` (*we* grant *them* read, they receive),
     `< 1` → `A:raterminal` (*they* grant *us* read, we receive).

**Why it didn't make sense** — worth naming precisely, so the replacement doesn't repeat it:

- one **unnamed scalar with magic thresholds** encoding a **two-way asymmetric** permission, so
   "am I serving?" and "am I listening?" were two different comparisons against the same number;
- it was an **inhibition I hold about you**, computed centrally by Gardening — but the fact a daemon
   actually has is about **itself**: *I serve; do not open a radio at me.* That is a **declaration**,
    and it belongs in what a peer says about itself, not in a table its counterparty keeps;
- and the levels were really about **user focus** (`one_on`, Engagements, "too much skipping
   tracks") — a different question wearing the same knob.

So the shape to want is one bit each way on the peering, **sent rather than inferred**, and named for
 what it asserts. The modern stack has **no seam for it yet** — nothing in `Ghost/M/Radio.g` or
  `Ghost/N/Peeroleum.g` asks a peer what it wants — so this is a protocol addition on shared ground,
   to do with the human, and after §4 (the daemon has no relay address of its own yet, so it has no
    peer to refuse). Note the daemon does not need this to be *correct*, only to be a good citizen:
     it has no AudioContext (§2), so today a radio aimed at it is wasted bandwidth rather than a bug.

## 5.3 `[OWED]` The rest

- **`/music`.** `Crate.g:34` guards `showDirectoryPicker`, and Crate already reads *through the nav*
   — so this is a nav to write, not a picker to fake. Until then the daemon has no collection to dig.
   **But the root itself is already configurable and already right**: `SHARE=<dir>` IS the FSA-root
    equivalent (owner: *"it has the concept of the FSA root though right? … I think that's fine how
     it is"*), `.jamsend` lives inside it exactly as it does inside a granted library, and every
      `.jamsend` path in the tree is share-relative (`Ra_stock_dir` → `'.jamsend/radiostock'`,
       `Heist_berth_dir` → `'.jamsend/berth/…'`). So `SHARE=/music OVERLAY=repo` is the real
        deployment shape today; what's missing is only the *sub*-directory focus for the census, and
         the writes being safe enough to stop hiding them in an overlay. The knobs that make a
          deployment, all env, all read at `main.ts:32-46`:
          `SHARE` (the root) · `OVERLAY` (`repo` = write in place) · `ROLE` (the identity name, §4.1) ·
           `I` (a specific prepub to resume, §4.1) · `KEYFILE` · `DAEMON_STATE` · `B`/`E`/`A` ·
            `RELAY` · `PORT` · `ORIGIN` · `ACCOUNT` · `SECS`/`LOG`/`QUIET`.
          They want to become one config file before there is a second daemon; env is fine for one.
- **Writes.** The nav is deliberately the overlay one: reads fall through overlay → repo, writes land
   in `/tmp/jamsend_daemon/fs`. A daemon that scribbles toc.snaps into a working tree someone else is
    editing is a bad neighbour. `OVERLAY=repo` opts in; a real deployment points `SHARE` at its own
     share.
- **Packaging.** It boots through a vite dev server in middleware mode, which costs ~12s of transform
   on every start. Fine for now; a real deployment wants a build.
- **The storage seam** — §5.1. The shim works and persists; what it stands in for is the mirror, and
   the mirror already exists for two kinds. Coverage, not architecture.
- **Serve-only** — §5.2. The daemon has no way to tell a peer "don't feed me radio".

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

---

## 8. The adversarial pass (2026-08-07/08) — what was false

Five reviewers were pointed at this file, at `Identity_persist_todo` §7, and at the code. Every
 finding below was **re-verified by hand against the tree** before landing here; agent claims that
  did not survive that check are not recorded. Ordered by what it costs to be wrong about.

Two of these were found INDEPENDENTLY by two reviewers each (§8.1's chokepoint and §8.4's `/stop`),
 which is the only cheap signal of confidence available here — the rest are single-source but
  hand-verified.

### 8.1 The daemon cannot process Invites — and §3.4/§4.1 claimed it could

**The false sentence** (was in §3.4): *"With an identity present, `w:Swarm` stands up, which is the
 layer that processes Invites."* It does not. `Swarm_station_world()` (`Swarm.g:650`) only does
  `A.oai({w:'Swarm'})` — an inert container. The function that actually **arms** anything is
   `Swarm_station_up` (`Swarm.g:661`), which calls `Swarm_arm(w)` (`:672`) to register the
    `pier_hello`/`pier_accept` handlers, dials `Socket_real`, and hello-binds the key.

**Verified: `Swarm_station_up` has no callers outside `InvitePanel.svelte`** (lines 43, 45, 127,
 257) and the Story Books. `Daemonic.svelte` never renders `BigSoundland`, so `InvitePanel` does not
  exist in a daemon process under any env knob. **No handler is ever armed**, so an inbound
   `pier_hello` addressed to the daemon has no dispatch route even if the relay delivers it.
    "Identity exists" and "the station is armed" are two disconnected facts, and this file conflated
     them.

**Scope, per the owner (2026-08-07):** *"the ?Iz parsing would never happen on the Daemon, it would
 be minting Grants for the clients that come along with them."* So the daemon is the **responder**,
  never the joiner — which shrinks the job to exactly one thing (call `Swarm_station_up` from the
   crank, without Svelte reactivity) plus `RELAY=1`. Landing, QR, clipboard, an `IZ=` knob and the
    auto-join policy are all **out of scope** and should not be built.

**Nothing here is browser-bound.** Crypto is node-native (the daemon already mints and loads a
 keypair), `?Iz=` parsing is pure string work, QR/clipboard are cosmetic. The whole gap is wiring.

**But it opens a real one — the invite spend ledger gets a second writer.** `%Idzeug` records carry
 `sc.spent`; `Swarm_hello` spends the nonce and refuses the replay (`Swarm.g:218,252`). Those
  records live under the `%Peering`, so **they ride the account snap**. If a browser session mints
   invites and the DAEMON answers the redemptions, the daemon accumulates `spent` flags the browser
    never sees — and last-write-wins on the snap can **un-spend a spent invite**. Single-use is a
     security property, not a nicety. This is the first place `Identity_persist_todo` §6.6's
      two-writers problem has teeth, and §7.4f's write lock does not cover it (the lock gates the
       file write; the divergence happens in each place's live tree). Worth noticing the federation
        is what makes the check work at all — same key, so the daemon CAN verify a presig only the
         issuer can check.

### 8.2 "Carry a radio" is broken — the codec hole is wider than §2 says

§2 splits the world into "heist needs no codec ever" (true — `Heist.g:5`, payload is original bytes)
 and "codecs are only needed to INGEST new music or to HEAR" (**false**). Verified:
  `Ra.g:204` guards `typeof OfflineAudioContext === 'undefined'` and degrades; **`Ra.g:1352` and
   `Ra.g:1657` construct `new OfflineAudioContext(1, 1, 48000)` with NO guard.**

Consequence: the daemon serves pre-stocked *preview* bytes fine, but the moment `Radio_supply_go`
 needs to transcode a locally-held track past its preview window, `Ra_transcode_ensure` →
  `Ra_source_pcm` throws a `ReferenceError`. It is swallowed by a detached `.catch`, so nothing
   crashes — and the radio then reports `sc.note = 'preview only — source unreadable'`
    (`Radio.g:729`), which is **a lie**: the source is perfectly readable, the codec API is simply
     absent. Same "not yet reported as never" shape this repo keeps finding.

So of the daemon's three stated jobs — hold the collection, answer heists, **carry a radio** — the
 third does not work today beyond the preview window, and §1's *"No audio crashes. Zero
  AudioContext/WebCodecs errors across every run"* was true only because no run ever asked for a
   track past its preview. Also: `node-web-audio-api`, which §2 cites as *"provides both for real"*,
    **is not in `package.json`** and does not resolve.

This promotes the ffmpeg shim (§2.1) from "needed to stock a collection" to "needed to serve one".

### 8.3 The default invocation boots a dev-only page

`Auto.svelte:565`: `const page = H.c.boot_role ? 'run' : 'library'`. `main.ts` sets `boot_role` only
 when `E=`, `B=` or `I=` is given — so a bare `node scripts/daemon/run.mjs` (this file's own §1
  first example) takes the **library** branch: the disk-backed book browser, which reads
   `wormhole/Present/toc.snap` and activates whatever Book a human last left `active` there, falling
    back to `DEFAULT_BOOKS = ['LeafJuggle','LeafFarm','StuffFlipping','LakeSurfer']` — UI/editor test
     fixtures, not music.

**So §1's "H:Story and H:MusuStaple appear on their own" is not a daemon default — it is the
 human's editor state**, read out of a shared, frequently-dirty snap. Change what is active there
  and the daemon boots a different Book next start.

**No real client goes near that branch.** The owner: *"the app itself, on most clients, will not
 know their ?I or ever use a ?B, it'll Book:Sounditron under the hood."* Verified —
  `boot_qualand({book:'Sounditron', role:'sound'})` (`BigQualand.svelte.ts:47-71`) stamps
   `h.c.book`, `h.c.boot_role = 'runner'` (sound→runner), `id_role`, `assume_identity`, and derives
    `humdinger` from the role *"so no call site can forget it"*. The `?B=`/`?I=` URL params are a
     dev affordance; the real shape is stamped in code.

Three things follow:

- **The daemon should stamp `book` + `boot_role` the way `boot_qualand` does** and refuse to boot
   without one, rather than falling into the library page.
- **`ROLE` defaults to `'daemon'`** (`main.ts:187`), so a bare boot **mints an identity** — which
   contradicts §4.1's own ruling that a production daemon never provisions. The safe default is
    opt-in.
- **A live footgun: `humdinger` is wired off the wrong knob.** `boot_qualand` derives it from
   *role*; the daemon derives it from its *identity* knob (`main.ts:188`). So `ROLE=0 B=Sounditron`
    produces a daemon with no `humdinger` — the editor enrols it off the 5s heartbeat and dispatches
     Story runs at it, the exact phantom-run failure §4.1 describes.

### 8.4 Security — three holes, all small to close

- **The account snap lands world-readable.** `NodeWormholeNav.write_file` (`scripts/NodeWormholeNav.ts:53`)
   is a bare `writeFileSync(abs, content)` — no `mode`, so the process umask, typically 644. That is
    the path `Swarm_persist` writes `.jamsend/account/<prepub>/toc.snap` through, and that file
     **embeds the plaintext private key** (`Swarm_snap_keyed`). The dev-only keyfile fallback
      explicitly uses `{mode: 0o600}` (`main.ts:252`); the production artefact does not.
       `Identity_persist_todo` §5's "confirmed clean" audit traced which C-tree paths carry the key
        and never checked what mode the file lands with.
- **`/stop` is an unauthenticated GET on all interfaces.** `server.listen(PORT, …)` (`main.ts:388`)
   omits a host, so node binds `0.0.0.0`. "A Sounditron that can't be closed" closes with one curl.
    `/c?depth=N` dumps the whole `.sc` tree to the same port (no keys — those live on `.c` — but
     piers, friendly names, Book state, and eventually the collection).
- **`NodeWormholeNav` has no path confinement.** Every method does `path.join(root, rel)` with no
   check that the result stays under `root`; `path.join(root, '../../../etc/passwd')` escapes. The
    browser nav gets this for free from `FileSystemDirectoryHandle`, which structurally rejects `..`.
     Today only caller discipline saves it — and §4 wants `RELAY=1` next, after which any call site
      touching peer-influenced path data becomes an arbitrary-file primitive.

### 8.5 Robustness — what only bites after a while

- **Buffered writes are lost on shutdown.** `dexie-node`'s `save()` coalesces through
   `queueMicrotask`; SIGTERM sets `stopping`, the loop breaks, and `process.exit(0)` runs without
    draining. `process.exit` does not wait for queued microtasks, so a write issued in the last tick
     — an identity mint, an account mirror — is silently dropped. Directly contradicts §3.2's
      durability claim at the one moment durability matters.
- **Dexie writes report success while failing to persist.** `Table.put()` mutates the map, schedules
   `save()`, and returns as if durable; on ENOSPC/EACCES the catch only `console.error`s. Nothing
    propagates, so "the same peer across restarts" silently degrades to "same peer until the next
     restart, then a stranger", with no symptom beforehand.
- **`uncaughtException` logs and continues** (`main.ts:146`), which node explicitly warns against —
   and it means a crash-loop supervisor never fires, because the process never exits. Related: an
    unguarded `writeFileSync` in `seed_identity` can unwind the crank loop while the HTTP server
     keeps answering `/status` with frozen numbers — a zombie that looks alive, the exact lie the
      §3b probe was built to catch for the beliefs mutex.
- **No log rotation** (`appendFileSync` forever, heartbeat every 10s), **no cross-process lock** on
   `DAEMON_STATE` (two daemons silently clobber, last-writer-wins over the whole table), and
    **`allHouses`/`liveTtlilts` walk the entire tree ~4× per tick** with no incrementality, so
     per-tick cost rises monotonically with uptime.
- **No shipping vehicle exists.** Grepped every `ty/*.service` and `docker-compose*.yml`: nothing
   references `scripts/daemon`. The actual production stack runs Chromium under Xvfb/VNC — literally
    the browser-tab pattern this daemon exists to replace. There is no build target either; `run.mjs`
     boots vite in middleware mode every start (~12s of transform), so a crash-looping daemon
      recompiles from scratch each time. And `ORIGIN` is a **runtime** dependency, not just boot-time:
       `Auto.svelte:1051` and `Ghost/Tyranny.svelte` `fetch('/log?stream=…')` during normal operation,
        resolved against `ORIGIN` by the daemon's relative-fetch patch.

### 8.6 What SURVIVED the attack

Worth recording so nobody re-litigates it: the `dexie` alias approach (§3.2), the vite-node
 programmatic boot (§3.1), the crank-as-pump (§3.3), the `arrest_watch` exit contract (§7.2 of
  `Identity_persist_todo`), and the heist-needs-no-codec split (§2, for heist specifically) all
   held up under review. The reviewers also confirmed §4's `addr=runner` collision mechanically:
    relay `bind()` is an additive `Map<addr, Set<WebSocket>>` and `deliverLocal` fans out to every
     socket in the set, so two claimants both receive every frame — which is the `channel DEAD —
      20s silent` symptom, exactly as §4 guessed.

---

## 9. THE WORK ORDER — overnight 2026-08-08, invites end-to-end

**A fresh session starts HERE.** Read §0, then §8 (what is false), then this. Do not read §1–§7 as
 fact until you have read §8; three of their claims are wrong and §8 names which.

### 9.0 The standing grant — read this before you halt on a "with the human"

The owner granted, 2026-08-08, before sleeping, in answer to an explicit question:

- **Shared files are IN SCOPE tonight** — `Auto.svelte`, `Ghost/S/Swarm.g`, `src/lib/server/relay.ts`
   included. Every *"do this WITH the human"* / *"shared ground, left alone"* note in this file and in
    `Identity_persist_todo.md` **is superseded for this run**. Do not stall on them.
- **Goal: invites end-to-end** — the daemon answers a redemption and mints a Grant.
- **When blocked: telegram the owner and CONTINUE** to the next item. Do not down tools. Record the
   blocker in this section as you go.
   **Telegram freely until 04:20 — the owner: *"it's not a big deal."*** After 04:20 they are asleep
    for real: keep working, keep logging in §9.6, and let the morning read be the report. Use `send`
     (fire-and-forget), never `ask` — `ask` blocks for a reply and holds a mutex
      ([[telegram-send-vs-ask]]), which at 5am means a wedged session, not a question.
- **Commits remain the owner's** (CLAUDE.md). Leave everything in the working tree. No exceptions.

Two cautions that are NOT superseded:
- `Auto.svelte` and `Swarm.g` were **mode 664** at grant time (`relay.ts` and `main.ts` were 644) —
   the concurrent-writer tell ([[concurrent-agent-on-this-repo]]). Re-check before each edit; if a
    file changes under you, stop touching it and telegram.
- **`relay.ts` is the cluster's spine.** A bad edit takes every runner down while nobody is awake to
   notice. Change it last, change it small, and verify the editor + the live runner still ping after.

### 9.1 The dependency chain — why the order is not negotiable

The daemon cannot answer an invite until ALL of these hold. They are listed in the only order that
 works, and each one's failure mode when skipped:

```
1. Auto gaps 2+3          →  or `I=<prepub>` ARRESTS and the daemon never gets its identity
2. the ledger graft       →  or every redemption hits refuse('unknown') SILENTLY (§8.1)
3. the daemon's relay addr→  or RELAY=1 collides on addr=runner and the channel dies (§4)
4. Swarm_station_up call  →  or no handler is armed and pier_hello has nowhere to land
5. a redeemer to test with→  or none of the above is proven (see §9.4)
```

Gap 4 and gap 1 (§6 of `Identity_persist_todo`) are NOT on this chain — land them if there is time,
 after. Gap 1 especially: §6.5 says it makes things strictly worse until 2+3 are in, and 2+3 are
  step 1 here, so it is safe *after* step 1 and pointless before it.

### 9.2 The steps

**Step 1 — Auto gaps 2 + 3** (`src/lib/O/Auto.svelte`). Spec: `Identity_persist_todo` §6.2, §6.3.
 - Gap 2: the disk-seed block at `:200` has no branch for "the Swarm ghost has not deposited yet" —
    it falls through to the arrest. Add the same retry-not-latch idiom already at `:148`, bounded by
     the existing `SEED_WAIT_MS` so a build where the ghost never lands still reaches the hatch.
 - Gap 3: clear `identity_pending` + `identity_pending_why` in **`Clustation_concrete`** (`:271`) —
    the one chokepoint every resume path funnels through. The two existing manual clears (`:261`,
     `:370`) then become redundant rather than wrong; leave them.
 - **Check:** `I=<prepub> B=Sounditron node scripts/daemon/run.mjs` against an account on disk must
    stand `w:Story` and show the same 🪪 prepub, instead of `arrest_watch` exiting 3.
 - **Provision the account first** — nothing writes it yet (gap 1). Cheapest: boot once with
    `ROLE=daemon KEYED=0 OVERLAY=<dir>`, which mirrors via `persist_account`, then reuse that prepub.

**Step 2 — the ledger graft.** This is the one §8.1 turns on and it is NOT written down as a recipe
 anywhere, so read carefully. `Swarm_boot_seed` already loads *"grants + piers + iz ledger reborn"*
  into the container it is given. Auto (`:213`) gives it a **detached vault**, harvests only
   `keys`/`prepub`/`born`/`friendly` into `stored`, and drops the vault — so the `%Idzeug` ledger,
    the `%Pier`s and the grants are loaded and then thrown away.
 - The fix is `Swarm_restash_all(ident)` as specified in `Identity_persist_todo` §5 audit item 3 and
    §6.6: walk the seeded vault's Peering → `%Pier`s to `Swarm_pier_stash`, `%Idzeug`s to
     `Swarm_iz_stash`, `%ChainRoot`s to `Swarm_chainroot_stash`. **It does not exist — build it.**
      Guard on `live_self`, so set `active` FIRST (i.e. after `Clustation_concrete`).
 - **The invite half is the part that matters tonight**: without `%Idzeug` records under the live
    `%Peering`, `Swarm_hello`'s `o({ Idzeug: t.serial })[0]` misses and refuses silently.
 - **Check:** after an `I=` boot, `curl localhost:9099/c?depth=6` shows `%Idzeug` rows under the
    Peering with their `spent` flags matching what the mirroring session wrote.

**Step 3 — the daemon's own relay address** (§4). `LiesLies.svelte:312` does
 `w.oai({ Peering: 1, name: role })` and `Socket_real` dials `/relay?addr=<that>`, so the daemon
  claims `addr=runner`. The prepub is right there and the signed `hello` already binds
   `prepubOf(pub)` → socket, so the precise layer exists; it is the coarse `?addr=` binding that
    collides. Smallest change that unblocks tonight: give the daemon's Peering a name that is not the
     bare role. **Do not** attempt §7.4's suffix/serial layer — that is a much larger design
      (`Identity_persist_todo` §7.4b: `Socket_real` reads `sc.name`, and the signed layer cannot
       express `_N`) and is explicitly NOT tonight's job.
 - **Check:** `RELAY=1` daemon appears on the relay under its own addr; the editor and the existing
    runner both still answer `runner_ask ping`. If either stops, revert immediately and telegram.

**Step 4 — arm the station** (`scripts/daemon/main.ts`). Mirror `InvitePanel.svelte:41-46`'s effect
 in the crank, without Svelte reactivity: once an active identity exists and the transport ghosts are
  deposited, call `Swarm_station_up(w, self)` once, idempotently (it returns null until ready, so
   retry rather than latch on the first attempt). This is the ONLY call the daemon needs for invites —
    it arms `Swarm_arm(w)`, dials, and hello-binds the key.
 - Requires `RELAY=1`: with `RELAY=0` the daemon deletes `WebSocket` and `Swarm_station_up` guards on
    it (`Swarm.g:669`).
 - **Out of scope, per the owner:** landing/redeeming, `?Iz=` parsing, QR, clipboard, an `IZ=` knob
    for production. *"The ?Iz parsing would never happen on the Daemon, it would be minting Grants for
     the clients that come along with them."* The daemon is the RESPONDER.

### 9.3 Do these too if the chain stalls (all daemon-local, all independent)

Ordered by value; any of them is a good night's work on its own. Specs in §8.3/§8.4/§8.5.
1. **Boot like a client** — stamp `book` + `boot_role` the way `boot_qualand` does, refuse a bootless
    boot, default `ROLE` to OFF (it currently mints, against the owner's own ruling), and derive
     `humdinger` from **boot_role** not the identity knob (the `ROLE=0 B=…` dispatch-target footgun).
2. **Security** — `.jamsend` writes at mode 0600 in `NodeWormholeNav` (the account snap carries the
    plaintext key and currently lands 644); bind the status port to localhost; require a token on
     `/stop` and `/c`; confine `path.join(root, rel)` to root.
3. **Robustness** — drain pending `dexie-node` saves before `process.exit`; propagate write failures
    instead of `console.error`; make `uncaughtException` exit so a supervisor can restart; rotate the
     log; lock `DAEMON_STATE` against a second daemon.

### 9.4 How to actually PROVE step 4 — and the honest problem with it

**Redemption is a UI gesture.** `Swarm_redeem` is only ever called from `InvitePanel.join()`, behind a
 click or a Svelte `$effect`. So there is no headless redeemer, and with the owner asleep there is no
  clicker either.

**The way through: two daemons.** Boot a second daemon with its OWN identity, and give it a
 **test-only** headless redeem path (parse a token → `Swarm_station_pier` → `Swarm_redeem`). Daemon A
  mints an invite (`Swarm_mint_idzeug`/`Swarm_invite_url` are pure verbs, reachable once an identity
   is up); daemon B redeems it over the real relay; A's `Swarm_hello` should find the serial, spend
    it, mint the bound grant and answer `pier_accept`. That proves the responder half — which is the
     half that matters — over a real wire, with no human.
 - Keep the redeemer clearly marked test-only (it is explicitly not the production shape, §9.2 step 4).
 - Two daemons need **different `DAEMON_STATE` dirs** (there is no cross-process lock — §8.5) and
    different `PORT`s.
 - **This is a smoke test, not a gate** (§6). It does not replace the two-tab fingers-test.

### 9.5 The traps this repo will set for you

Read [[comments-assert-unmeasured-properties]] first. Then:
- **A comment here may be false.** Three were, in one day, in these very files (§8). Verify the claim
   against the code before building on it, and prefer one electrode per suspect, in sequence.
- **The instrument is often the bug.** Radio_todo's §0 records six cases in one week where the thing
   that looked broken was the thing doing the measuring. If a number looks wrong, suspect the counter.
- **Never `npm install`** — the two containers share `node_modules` across musl/glibc and an install
   from either strands the other. CLAUDE.md has the whole story and the recovery.
- **Do not verify with `Story_cli_run.mjs`,** and **do not use the daemon as a verification gate**
   (§6). A live runner is the only gate, and one is up (`96d0cf8852651a73` at grant time).
- **`.svelte.ts` edits force a full page reload** and kill the human's live tabs; `.g` edits HMR
   gesture-free. Prefer `.g` where there is a choice.
- **A `%see` is not a latch** and fixtures are the gate — if you move a snapped shape, the Book
   fixtures move with it, and re-recording them is its own job.

### 9.6 Log the night here

Append as you go: what landed, what was skipped and why, what you telegrammed about. The owner reads
 this before the diff. A blocker recorded with its evidence is worth more than a workaround.

---

#### RUN 1 — 2026-08-08, 01:00–01:1x. §9.2 steps 1–2 LANDED and proven; step 3 left for you, as §9.7 said.

**The headline: the identity chain now survives a cleared browser AND the reload after it.** Baseline
 exits 3 with the account sitting on disk; the fixed tree exits 0 with `w:Story` standing. Both halves
  were attributed by controlled revert, not assumed.

**Step 1 — Auto gaps 2+3. LANDED** (`src/lib/O/Auto.svelte`).
 - Gap 2 (`Auto.svelte:198-218`): the disk-seed block's guard required `Swarm_boot_seed` + `Crate_nav`
    to already be functions, and when they weren't it fell **through** to the arrest. Split the guard:
     ghost-not-deposited now returns `false` (retry next pass) on the *same* `SEED_WAIT_MS` clock the
      nav-not-up branch uses — one budget for "the seed is not possible yet", however many reasons stack.
 - Gap 3 (`Auto.svelte:338-351`): `identity_pending` is now cleared in **`Clustation_concrete`**, the
    chokepoint every resume path funnels through. The two manual clears are left in place, redundant.
 - **Evidence — same account, same fixture, only the file swapped** (`I=b9341b748657d3b4 B=Sounditron`):

   | | baseline (HEAD) | gaps 2+3 in |
   |---|---|---|
   | arrest | `🪪⚠ identity ARRESTED` | never fires |
   | key off disk | restored anyway (late) | restored |
   | houses | `Mundo` only — **no Story, ever** | `Mundo:1 Story Sounditron` |
   | worlds | `…Clustation/Thangs` | `…Clustation/Thangs,Swarm Story/Story Vyto Sounditron` |
   | exit | **3** (`☠ ARRESTED with the account ON DISK`) | **0** |

   That baseline row IS `Identity_persist_todo` §6.3's recorded failure, reproduced exactly — including
    the tell that the key *was* found and the boot stayed held anyway. Gap 2 kills the arrest line; gap 3
     is what lets Story stand. Two edits, two distinguishable symptoms, one run each.

**Step 2 — the ledger graft. LANDED** (`Ghost/S/Swarm.g:1392-1470`, compiled to `src/lib/gen/S/Swarm.go`
 via `npm run ghost-compile`; your editor was live and took it, dige `6da9331c389492ee`).

 **Three things in §9.2 step 2's recipe were wrong. Read these before you review the diff:**
 1. **`Swarm_restash_piers` already existed** (`Swarm.g:1396`, called from the graft at `:1377`). The
     spec says "it does not exist — build it". A third of it was already there and already wired.
 2. **`%ChainRoot` hangs off the `%Identity`, not the `%Peering`** (`Swarm_chainroots_rehydrate` does
     `ident.oai({ChainRoot:1,…})`). The recipe says "the Peering's ChainRoots" — walking the Peering
      finds nothing and reports a confident zero. Exactly the [[comments-assert-unmeasured-properties]]
       shape, in the spec rather than a comment.
 3. **The load-bearing one: the recipe cannot work as literally written.** It says "walk the seeded
     vault's Peering … guard on `live_self`". Those two clauses contradict each other. Every `_stash`
      verb guards `if (!live || live !== ident) return` — **object identity, not prepub** — and Auto
       seeds into a *detached vault* while `Clustation_concrete` mints a **separate** live `%Identity`.
        So the vault has the ledger and fails the guard; the live self passes the guard with an empty
         Peering. That is why the existing `Swarm_restash_piers(ident)` at `:1377` has been silently
          returning without stashing anything — it is handed the vault. The bug was already built.

 **What I built instead:** split *read-from* and *stash-under*. `Swarm_restash_piers/_izzes/
  _chainroots(ident, from)` read the ledger out of `from` (default `ident`) and stash it under `ident`
   (the live self, so the guard is honoured, never routed around). `Swarm_restash_all(ident, from)`
    does all three and **refuses a prepub mismatch** — reading from a vault means naming two objects,
     and filing a stranger's friends under our own prepub would be worse than the bug being fixed.
 **Stash, don't graft particles:** `Swarm_station_up` (`Swarm.g:663-665`) already rehydrates all three
  shelves from the stash *before* `Swarm_arm`, so the proven, idempotent rail rebuilds the live
   particles. A second hand-rolled grafter would just be a second thing to keep true.
 Auto calls it at the one moment both halves are in scope (`Auto.svelte:240-266`) — after concrete has
  set active, wrapped so a throw can never cost the key we just recovered.

 - **Evidence.** Fixture account carrying 2 `%Idzeug` (one `spent`), 1 `%Pier`, 1 `%ChainRoot`:
   ```
   🪪 Identity RESTORED from disk dawn-sail (b9341b748657d3b4) — .jamsend/account
   🪪 ledger restashed — 1 pier(s), 2 invite(s), 1 chain root(s)
   ```
   and in the Dexie state file afterwards — note `spent` survived, which is the single-use security
    property §8.1 says a second writer can un-spend:
   ```
   Swarm_izzes:{b9341b748657d3b4:{nonce-alpha:{to:listen},nonce-beta:{to:listen,spent:"1"}}}
   Swarm_piers:{b9341b748657d3b4:{cafe0011223344556677:{page:{prepub,pub,friendly:Testfriend}}}}
   Swarm_roots:{b9341b748657d3b4:{beef00…:{prepub:beef001122334455}}}
   ```
 - **Reload #2 — the trap this exists for — is closed.** Booting again on the same state dir logs
    `🪪 Identity active` (a plain Dexie hit, disk never consulted, §6.0 intact) and the stash still
     carries all three shelves. Before tonight that is the boot where friends vanish.

**What is NOT proven, honestly.** The ledger is in the **stash**; the live `%Idzeug` particles under the
 live `%Peering` appear only when `Swarm_station_up` runs, which needs `RELAY=1`, which needs step 3.
  So §9.2 step 2's own check (`curl /c?depth=6` showing `%Idzeug` rows) **cannot be run tonight** — not
   a failure, just the dependency chain in §9.1 doing what it says. The seam is verified one layer down
    instead, in the Dexie state file, which is where the durability actually lives.

**Step 3 — the relay address: DELIBERATELY NOT TOUCHED**, per §9.7 Phase 3. `relay.ts` is untouched;
 `git diff` will show it clean. Without it steps 4 and §9.4's two-daemon harness cannot run, so
  **"invites end-to-end" did not finish** — expected, and §9.7 said so up front. Telegrammed.

**§9.3, fanned out to two Sonnet agents split by file (Phase 1):**
 - **Agent B — `scripts/NodeWormholeNav.ts`: DONE, and independently re-verified by me.** `.jamsend`
    files now land `0600` (incl. an explicit `chmod` for the already-exists case, which `writeFileSync`'s
     create-only `mode` misses), `.jamsend` dirs `0700`, and `path.join(root, rel)` is confined via a
      `confine()` helper on every method. I checked the real files after a run: account snap `600`,
       `.jamsend` dirs `700`, `wormhole/` untouched at `644`/`755`. **Worth reading their report's own
        catch:** their first draft passed `mode` to a *recursive* `mkdirSync`, which stamps every
         ancestor it creates — it over-tightened the OVERLAY root itself. They found it by testing
          rather than by reading, which is the §9.5 discipline working.
 - **Agent A — `scripts/daemon/main.ts` + `dexie-node.ts`:** still running at the time of writing;
    result appended below when it lands.

**One stale claim in §8.3 spotted in passing:** it says `ROLE` defaults to `'daemon'` at `main.ts:187`
 so a bare boot mints. `main.ts:204` today reads `process.env.ROLE === '0' ? '' : (process.env.ROLE || '')`
  — it already defaults to empty. §8.3's line numbers have drifted generally (it cites `:187/:188`; the
   knobs are at `:204/:205`). Left for Agent A, whose file it is.

---

#### RUN 1 continued — gaps 4 and 1 also landed. **All four of `Identity_persist_todo` §6 are now in.**

§9.1 says gaps 4 and 1 are off the critical chain — *"land them if there is time, after"*. Step 3 being
 correctly parked freed that time, and §6.5's precondition for gap 1 (*"land it only once 2 and 3 are
  in"*) was satisfied by the work above, so it was safe tonight in a way it was not this morning.

**Gap 4 — a role-filed identity is invisible to its own `?I=`. LANDED** (`Auto.svelte:470-490`).
 `Clustation_ensure_default` filed the identity under the ROLE tag only, while `ensure_identity` looks
  up by TAG and demands `peeked.prepub === param` — so every client (which is to say, every real
   client, since `boot_qualand` stamps role in code and nobody sets `?I=`) missed Dexie and fell into
    gaps 1–3. It now also files under the prepub.

 **The find that made this more than a one-liner: `Clustation_pin` has never worked.** §6.4 asks for a
  both-homes write, and a verb that does exactly that was already sitting at `Auto.svelte:387` — so I
   reused it, and it silently did nothing. Cause: it asked `Clustation_active_identity`, which returns
    the **signing key** `{pub, key}` — a plain object with no `.c` — and then guarded
     `if (!ident?.c?.keys) return false`. **The guard can never pass.** Every call has returned false at
      the first line since it was written, and its only caller (the door's `?Iz`→`?I` address-bar swap)
       reads a false as "Thangs not mounted yet, fine". So the failure the verb exists to prevent —
        *"that reload would mint a STRANGER under the prepub tag — the friendship left on the old key"*,
         its own comment — is precisely what it has been allowing. Fixed at `Auto.svelte:391-408` by
          resolving the PARTICLE (the same two-step `active_identity` itself uses).
  Worth noticing the shape: a verb whose entire body is unreachable reads as working code in every
   review, and the diff that introduced it looked right. The tell available in hindsight was that §6.4
    was still open while a verb that closes it sat in the same file. [[comments-assert-unmeasured-properties]]
     again, one level up — not a false comment but a false *verb*.

 - **Evidence.** Role mint, then the identities Thang holds BOTH homes (before the pin fix it held only
    `daemon`, which is how the dead verb was caught):
    `["identities","daemon"]` **and** `["identities","b803ff619bb51324"]`.
   Then, with `.jamsend` **deleted from the share** so only Dexie can possibly answer:
   `I=b803ff619bb51324` → `🪪 Identity active gilded-sail (b803ff619bb51324)`, exit 0. A plain Dexie
    hit, zero disk reads — §6.0 satisfied harder, exactly as §6.4 predicts. Before the fix that boot
     misses Dexie, falls to a disk seed with no disk, and arrests.

**Gap 1 — the write side. LANDED LAST, as §6.5 requires** (`Clustation_mirror_account`,
 `Auto.svelte:425-472`; called from the boot tick at `:806`).
 Nothing in the app ever called `Swarm_persist` — every caller was inside the `SwarmDisk` Book — so the
  read side wired 2026-08-04 has been arresting beside an account dir nothing ever created. That is the
   whole of *"editor lost its crypto again!?"*.
 Placed after every identity path has had its say (so it mirrors whoever actually ended up active) and
  after the `identity_pending` gate (so an **arrested** boot never writes). Guards mirror the read's,
   for the read's reasons: no nav → retry later, **remote nav → refused** (`.jamsend` never crosses the
    wire, and an `atime_async` await under the beliefs mutex deadlocks), and never per tick.
 **On the throttle, honestly:** §6.1 asks for a `Waft:Account` version bump and no such Waft exists in
  the live tree, so it marks on `%Identity.version` + its `%Peering.version` — the two shelves that
   actually move (a rename bumps the identity; piers/grants/Idzeugs are created under the Peering, and
    creation bumps). That is a heuristic, not a proof: a mutation bumping neither waits for the next
     boot. Strictly better than the daemon's proven floor of once-per-identity-per-boot; tighten it if
      a case turns up. The mark is stamped BEFORE the await (the tick re-enters) and cleared on throw
       (so a gesture-less FSA handle retries rather than latching the session un-mirrored).
 - **Evidence.** With the daemon's own `persist_account` disabled (`ACCOUNT=0`), so only Auto's new
    write side can create anything: `🪪 account mirrored → .jamsend/account/2c67daaf1f134b8a/toc.snap`
     — **once** across 76+ ticks (the throttle holds), landing at **0600** (Agent B's mode fix
      composing correctly). Then the round trip, which is the point of the whole file: wipe Dexie,
       boot `I=2c67daaf1f134b8a` → `🪪 Identity RESTORED from disk moon-moray`, exit 0. **Auto writes
        it; a cleared browser reads it back.** That loop has never closed before tonight.

**The gate that is still unrun, and nothing here substitutes for it:** §6.7's two-tab fingers-test.
 Everything above is proven on the **node fs nav** only. A browser is still the only proof of the FSA
  backend, and gap 1 now means a real tab writes its private key to a real share — so that test matters
   more after tonight than before it, not less. Please run it before this reaches players.

**The advisory write lock came with gap 1, because gap 1 is what armed the hazard** (`Auto.svelte:437-452`,
 §7.4f / §6.6). Two writers, one file, no merge, last-write-wins — and an un-spent invite is a security
  property, not a nicety. Only the place holding the **bare `<prepub>`** mirrors; a serial-numbered place
   holds off and says so once. Fails safe (no `Swarm_address` → no write, i.e. pre-tonight behaviour) and
    verified not to over-refuse: the canonical holder still writes. **It does NOT close §6.6** — §7.4f's
     *re-read at reinstate* is still owed, so a place that hands the address back and later retakes it
      will write from its own stale tree.

**§9.3 Agent A — `scripts/daemon/main.ts` + `dexie-node.ts`: DONE** (reported after the above landed).
 Boot shape: `book`+`boot_role` stamped, bootless boot **refuses with exit 4** instead of falling into
  Auto's dev library page, `ROLE` defaults OFF so a bare boot never mints, `humdinger` derived from
   `boot_role` (the `ROLE=0 B=…` phantom-run footgun). Status port: binds `127.0.0.1`, token required on
    `/stop` and `/c`, `/status` left open. Robustness: `flush()`/`flush_all()` drained on every exit path
     via a new `shutdown(code)`, write failures now reject the awaited promise (deliberately not a
      permanent poison), `uncaughtException` exits 5 so a supervisor can fire, log rotation at ~10MB, and
       a pid-based `DAEMON_STATE` lock (second daemon exits 6; a stale lock from a dead pid self-recovers,
        which keeps §9.4's deliberate two-daemon harness possible).
 I re-verified the two that could bite: a bare `node scripts/daemon/run.mjs` refuses with the exit-4
  message, and the whole four-gap chain above still runs green against the settled `main.ts`.

**Type check:** `npx svelte-check` over `Auto.svelte` reports 20 findings, **none in any line I touched**
 — all are the baseline `Property X does not exist on type 'House'` eatfunc noise CLAUDE.md describes,
  at lines ≥847 (my edits end at 830).

**THE REAL GATE, RUN: all three Swarm Books are GREEN on the live runner** (`58517b484a8e896d`), which
 is what actually covers the `Swarm.g` edit — a daemon boot never would have.
 - `SwarmDisk` — **7/7, ok, 0 caveat** (the unit proof of the disk→identity→signing lift, incl.
    `grafted-stashed`: *"a disk-grafted Pier is stash-worthy … so the reseeded friend survives the next
     warm reload"* — the very claim step 2 turns on).
 - `SwarmInvite` — **5/5, ok, 0 caveat.**   · `Swarmation` — **1/1, ok, 0 caveat.**
 Runner released afterwards. No fixture moved: the restash verbs write only the Dexie `stashed` rail,
  and the `Auto` changes touch `.c` flags and files — no snapped C shape changed, so no Book fixture
   needed re-recording.

**Heads-up for the morning, not my work:** a **concurrent agent is live in this repo** — `Ghost/M/Heist.g`,
 `Error_channel_todo.md`, `Heist_todo.md`, a new `wormhole/Story/ErrChannel/` and a spread of `Musu*`
  snaps all appeared in `git status` during the night. Untouched by me; flagged only so the diff doesn't
   read as one session's. ([[concurrent-agent-on-this-repo]])

### 9.7 HOW TO RUN TONIGHT — read this first, then act

Do these in order. The point of the shape is that the safe, mechanical work banks itself in parallel
 while the main session does the part that needs judgement.

**Phase 1 — fan out §9.3 to two Sonnet subagents, split BY FILE so they cannot collide.**
 Launch both in one message so they run concurrently. Do NOT add a third: every remaining §9.3 item
  lives in a file one of these two already owns, and two agents in one file is a merge conflict with
   nobody awake to resolve it.

 - **Agent A — `scripts/daemon/main.ts` + `scripts/daemon/dexie-node.ts`** (one agent owns both; the
    shutdown drain spans them, so they cannot be split). Sequential within itself:
    1. **Boot shape** (§8.3): stamp `book` + `boot_role` the way `boot_qualand` does
        (`BigQualand.svelte.ts:47-71`); refuse to boot with neither; default `ROLE` to OFF so a bare
         boot never mints; derive `humdinger` from **boot_role**, not the identity knob.
    2. **Status port** (§8.4): bind localhost; require a token on `/stop` and `/c`.
    3. **Robustness** (§8.5): drain pending `dexie-node` saves before `process.exit` (add a `flush()`
        and await it); propagate write failures instead of `console.error`; make `uncaughtException`
         exit so a supervisor can restart; rotate the log; lock `DAEMON_STATE` against a 2nd daemon.
   *Check after each:* `B=Sounditron SECS=60 node scripts/daemon/run.mjs` still reaches
    `♥` heartbeat with worlds standing, and `/status` still answers on the bound host.

 - **Agent B — `scripts/NodeWormholeNav.ts`** (§8.4): write `.jamsend` paths at mode 0600 (the account
    snap carries the plaintext key and currently lands at umask); confine `path.join(root, rel)` to
     `root`. **Check the other callers first** — `Story_cli` uses this nav too, so confinement must not
      break a legitimate relative read. Verify by running one Story Book through the daemon after.

 Give both agents §9.5's trap list and CLAUDE.md's never-`npm install` rule. Tell them: **do not
  commit**, leave everything in the working tree, and report what they changed with file:line.

**Phase 2 — the main session does §9.2 steps 1 and 2 itself, on Opus.**
 These edit `Auto.svelte` (shared ground, mode 664 — re-check the tell before each edit) and build
  `Swarm_restash_all` from a prose spec. That is judgement work, not mechanical work; do not delegate
   it. Step 1 then step 2, verifying step 1 before starting step 2 — the check is that an `I=<prepub>`
    boot stops exiting 3 and stands `w:Story`.

**Phase 3 — STOP before §9.2 step 3.** The relay-address change is the one item whose failure mode is
 *everybody's* night: a bad `relay.ts` edit takes every runner down with nobody awake to notice, and
  its success criterion is "the editor and the live runner both still answer", which is exactly the
   check a tired session skips. **Leave it for the owner.** Telegram what is ready and why it waited.
    Without step 3 the invite chain cannot complete — that is expected and is not a failure of the
     night; §9.2's own dependency chain says so.

**Realistic expectation, stated up front so nobody reports success they did not have:** a good night
 lands §9.3 entire, plus §9.2 steps 1–2. "Invites end-to-end" needs step 3 AND the two-daemon harness
  of §9.4, and will not finish. Log what actually happened in §9.6 — a blocker with evidence beats a
   workaround.
