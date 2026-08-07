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

Three candidates, in the order they actually unblock things:

1. **Give the daemon its own relay address** (§4). Today it would register as `addr=runner`, the
    same address every runner tab claims. Until that's fixed `RELAY=1` is a foot-gun and the daemon
     is offline-only — which means none of the *peer* half of the point is exercised yet.
    **Its identity is now settled** (§4.1): the daemon stamps `boot_qualand`'s three, so it IS a
     BigSoundland and keeps a stable peer across restarts through the app's own mechanism. What is
      left is only the coarse `?addr=` layer.
2. **The opus shim** (§2), and §2.1 now says what it is: **ffmpeg behind the WebCodecs seam**, encode
    half only, with an Ogg-page→packet demux as the single real piece of work. Until then the daemon
     can serve pre-stocked bytes but cannot stock a collection.
3. **Point it at real music** (§5.3) — a nav over `/music` so `Crate_nav_meander` has something to
    dig through. Cheap, and it makes 1 and 2 testable against reality instead of synth tones.

**Read §4.1 before touching identity anywhere.** Standing the daemon up on the app's own identity
 path turned up two bugs in `Auto.svelte`, both unmade because that file is shared ground: the
  disk-seed falls through to an ARREST when the Swarm ghost hasn't deposited yet, and a *successful*
   seed never clears `identity_pending` — so a daemon that found its key on disk stayed held forever
    with the key in hand. Plus the finding under them: **nothing in the app ever writes the account
     file the seed reads.** These three are one job, and it is the human's.

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

Both are one-liners (retry instead of falling through; clear the latch on a successful seed) and
 **neither was made** — `Auto.svelte` is shared ground and a second agent was live. They are also
  currently *invisible in the app*, because with no write side there is never a file to find: fixing
   the write side without these two turns "restored from disk" into "held forever", which is worse
    than today. Do all three together, with the human.

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
