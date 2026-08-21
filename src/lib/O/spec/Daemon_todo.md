# Daemon_todo — the machine as a process, not a tab

A node daemon that boots the whole jamsend machine headless and stays up: a stable long-running
 peer on the p2p network, serving the Radiobuddies v1.0 experience (listen + heist) and, later, a
  music collection. Built 2026-08-07 off to the side in `scripts/daemon/`; **nothing shared was
   edited** (a second agent was live on the Radio cluster the whole session).

---

## 0. What to get on with next

> **🔴 LIVE 2026-08-21 — "daemon drops every frame from a fresh friend: `no Pier … DROPPED`". It is
>  NOT a code regression; it is a two-STORE identity split. THE HANDSHAKE WORKS.**
>
> Symptom: `jamserve` (identity `7950f300faa8a4f9`, on the production relay `wss://djamsend…:9999`)
>  spews `🛰☠ deliver: no Pier for {pulse,ive_got,swarm_hi,pier_accept,repli_ready} from=eed831f1
>   to=7950f300 — DROPPED`, `them=0 crate(s)`, forever. Not a music problem — the shelf is full
>    (`shelf=40 rec`, ffmpeg encoding). The friend `eed` gets nothing.
>
> Root cause (evidence, not theory): eed's on-disk pier to 7950 is **WHOLE** — both `Grant:Music`
>  signatures present (eed↔7950), sealed 2026-08-21T02:29Z. So a body holding 7950's *key* completed
>   the full mutual seal. But that body was a **browser** that resumed 7950 (via `?I=7950f300…` — the
>    exact link handed over earlier in the session; that form *becomes* the server identity and forks
>     a second body) on the **dev server `:9091`**, which writes **`/app/.jamsend`**. The **daemon**
>      is a *separate* body of the same prepub reading **`/music/.jamsend`** (host
>       `${MUSIC_PATH:-/home/s/Music/71mix}/.jamsend`) — a DISJOINT store: the daemon's two friends
>        (`064b7731`, `d101899a`) don't exist in `/app/.jamsend` at all. eed sealed with the `/app`
>         body; the live wire routes eed's frames to the `/music` daemon, which has no such pier ⇒ drops.
>
> Why "worked in the previous OS": then the browser and daemon shared **one** `.jamsend`/relay/box, so
>  a browser seal *was* the daemon's seal. The new OS split dev (`/app`, `:9091`) from the production
>   daemon (`/music`, `wss://djamsend:9999` + the new `leproxy/`). Seals now land where the daemon
>    never reads. `docker-compose.yml`'s own comment states the intended shape drifted from: *"[the
>     daemon's `/music/.jamsend`] is where a browser session's FSA grant already put the account it
>      resumes from."*
>
> **The fix is infrastructure + discipline, NOT a ghost edit** (the pier gate correctly restricts
>  creation to `pier_hello`; reheal only re-mints a missing grant on a pier that EXISTS — neither can
>   conjure a pier into a store the seal never touched):
>   1. **One body per identity.** The daemon is the sole live `7950`. Never resume `7950` in a dev
>       browser (`?I=7950…`) while the daemon is up — that fork is what ate this seal.
>   2. **Seal into the daemon's store.** Provision/seal `7950`'s friendships from a browser that
>       FSA-grants the daemon's **`/music`** folder, so its `.jamsend` == the daemon's. Then eed's
>        redeem lands in `/music/.jamsend` and the daemon holds the pier. (Or unify the two `.jamsend`
>         mounts to one host dir — see the `app` vs `jamserve` volume split in `docker-compose.yml`.)
>   3. **Unstick eed:** its whole pier points at a dead `/app` body. Re-seal eed against the daemon
>       (redeem a `/music`-side invite), or copy eed's `Pier` into `/music/.jamsend/account/7950…/`
>        and re-mirror. Until then eed retries a stranger forever.
>   Open design question worth a REVIEWED follow-up (needs live Swarmation-Book verification, so not
>    done blind here): should a node that receives repeated post-seal frames from a peer it holds no
>     pier for — but whose Idzeug/invite it still holds — be allowed to re-trigger `pier_hello` so a
>      cross-body/lost-pier case self-heals over the wire? Today only `pier_hello` opens the door
>       (Peeroleum.g:589), by design; loosening it is security-relevant (spoof/DoS surface).
>   Verified from the `claude` container: `/app/.jamsend` accounts, daemon logs, live local-relay
>    census (`runner_ask runners --live`), and the daemon's own `/status`+`/c` (reachable at
>     `172.17.0.1:9099`, token from its boot log). Could NOT reach production relay or write `/music`.
>
> **DEEPER ROOT CAUSE (2026-08-21, second pass) — the invite ledger is PROCESS-LOCAL, and that is the
>  real "worked before / lost invite" bug.** When eed finally re-redeemed, the daemon logged
>   `🚪 rebuff %hello_unknown` on eed's `pier_hello`. That is `Swarm_hello` (Swarm.g:1566): the
>    invite's serial was not found in the daemon's OWN ledger. WHERE the invite ledger lives is the
>     crux the human asked and the account dir did NOT answer: **`%Idzeug` (the issuer, with its
>      `next`/`claimed` serials) is a RUNTIME particle under `%Peering`; its durable twin is the top-
>       House STASH `stashed.Swarm_izzes[prepub][nonce]` (Swarm.g:1045-1050), which persists to the
>        PROCESS's kv store — the daemon's `DAEMON_STATE=/var/lib/jamserve/state`, or a browser's
>         IndexedDB — NEVER `.jamsend/account/*` (that snap carries only Identity/Peering/Pier/Grant).**
>          So an invite minted in a browser body is invisible to the daemon even if they share
>           `.jamsend`/`/music` — the account snap does not carry the izzes. The ONLY body that can
>            issue an invite the daemon will honour is the daemon's own process.
>
> **FIX LANDED (working tree, needs a jamserve rebuild+restart to take effect — I cannot restart):**
>  a token-gated **`/invite`** route on the daemon status server (`scripts/daemon/main.ts`, beside
>   `/restock`). It calls `Swarm_mint_invite(w, ident, {Music:1})` and returns the `?Iz=` token, so a
>    headless server can finally issue an invite from its OWN ledger. Usage after restart:
>     `curl "http://localhost:9099/invite?token=<boot-token>"` → paste `invite` into eed's Door. This
>      is the reliable path; it also makes the daemon a real always-on host rather than one that can
>       serve music but never make a friend. Break-glass alternative unchanged: splice eed's already-
>        signed `Pier` into `/music/.jamsend/account/7950…/toc.snap` and restart.
>   Follow-up worth a look: the account mirror (`persist_account`, main.ts:864) throttles at
>    `MIRROR_MS=20s` and fingerprints — a friend sealed then a crash <20s later is lost; and the izzes
>     stash's durability under `DAEMON_STATE` deserves the same "settled ⇒ on disk" guarantee the human
>      is asking for. Neither is eed's bug, but both are the reliability itch behind it.

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

> **UPDATED 2026-08-08, small hours — jamserve now SERVES AUDIO. See §10.** The invite worked
>  end-to-end (two Piers sealed, surviving restarts), and then the friend opened an **empty glass**,
>   because `Ra_stock_one`'s decode/measure/encode are browser primitives and a headless dig learned
>    every path barren while reporting a clean shelf of zero. `Ra_native()` forks those three steps to
>     ffmpeg *inside* `Ra_stock_one`, so the card, the grid and the %Record stay one shared path. 16/16
>      cards verified structurally off the owner's real collection. **What is NOT proven is that it
>       sounds right — that is the two-minute listen, and it is the next thing to do.** §10 also
>        records two traps worth more than the feature: a meter that clipped what it measured, and
>         `Ra_stock_drop` silently inert on the node nav (so the shelf cap could never evict).

> **UPDATED 2026-08-08, afternoon — the 32s ceiling is LIFTED and LOFI is Ogg Vorbis. §10.5 item 2,
>  §10.8.** Both were the same shape as everything else in §10: a browser primitive missing headless,
>   and nothing carrying the fact. `Ra_native_continuation` encodes the whole remainder past the
>    preview in ONE ffmpeg pass and hands it out on the existing 2s grid, so a friend hears past 32
>     seconds for the first time; the streaming-pipe design §10.5 had scoped turned out to be more
>      machinery than the constraint needed (the constraint was *one encoder*, not *streaming*). LOFI
>       was failing 100% because its own validator asserted `OpusHead` on bytes that were now Vorbis.
>  **Neither is verified — there is no ffmpeg in the claude container and both land on the daemon's
>   next 900s restart.** Read §10.5 item 2 and §10.8 for the tells to look for.

Candidates, in the order they actually unblock things:

0. **LISTEN to a daemon-served track** (§10.5) — the one claim no snap can carry, and it now has a
    second half worth as much as the first: **listen ACROSS THE PREVIEW SEAM** (chunk 16, ~32s in).
     The gain is the card's on both sides and the continuation ships its own preskip, so it should be
      inaudible — but that is reasoning, not a measurement, and a step in volume or a click at 32s is
       exactly what it would sound like if either is wrong.

1. ~~**Boot like a client does** (§8.3)~~ — **DONE 2026-08-08.** `book`+`boot_role` are stamped, a
    bootless boot refuses with exit 4 instead of falling into Auto's dev library page, `ROLE` defaults
     OFF so a bare boot never mints, and `humdinger` comes off `boot_role`. (§9.6)
2. ~~**Give the daemon its own relay address** (§4)~~ · ~~**Arm the Swarm station**~~ — **BOTH DONE
    2026-08-08** (§4a + §9.6). The daemon dials `/relay?addr=<its own prepub>`, gets `hello_ok`, and
     arms `Swarm_station_up` — verified on the real relay with the human's runner up throughout.
      `relay.ts` binds any sane role name; only `editor|runner` steer the r2r bridge; dispatch stays
       runner-only. **Next: §9.4's two-daemon harness** — the responder half is armed but no real
        redemption has crossed it, and redemption is a UI gesture (`Swarm_redeem` ← `InvitePanel.join()`),
         so proving it headlessly needs the test-only redeemer. That is the last piece of "invites
          end-to-end". Listing bound roles in a UI remains the owner's stated "maybe one day".

3. ~~**§9.4's two-daemon harness**~~ — **DONE 2026-08-08, and it passed: invites work end to end.**
    A mints, B redeems over the real relay, A spends the serial and seals; both ends hold a durable
     `%Pier`, and A still `remembers 1 friend(s), 1 invite(s)` after a restart. `MINT_INVITE=1` /
      `IZ=<token>`, test-only. (§9.6) **So the whole §9 work order is met.** The next real gate is
       item 7, the two-tab fingers-test — everything above is proven node-side only.
4. ~~**Close the security holes** (§8.4)~~ — **DONE 2026-08-08.** `.jamsend` files at 0600 and dirs at
    0700 (incl. fixing already-existing files), `path.join(root, rel)` confined to root, status port
     bound to localhost, token required on `/stop` and `/c`. (§9.6)
5. **The opus shim** (§2/§2.1/**§2.2**): **ffmpeg behind the WebCodecs seam**, encode half only, with
    an Ogg-page→packet demux as the single real piece of work. Note §8.2 — this is no longer only
     about *stocking* a collection; the daemon cannot serve its OWN tracks past the preview window
      without it. **Now the biggest genuinely-open piece of work in this file**, and the only one that
       was blocked on a decision rather than on effort.
    **UNBLOCKED 2026-08-08 on both counts:** ffmpeg now ships in `jamserve/Dockerfile` (`apk add`, not
     npm — so it never touches the shared `node_modules`), and the owner ruled that **LUFS levelling
      is part of the encode** (§2.2), which also deletes the `needles`/Worker dependency instead of
       making the shim emulate it. Read §2.2 before starting: it changes what the shim is *for*.
6. ~~**Point it at real music** (§5.3)~~ — **DONE 2026-08-08.** `MUSIC=1` mounts this container's
    `/music` (212 opus tracks) as a READ-ONLY third root named `music`, and `Crate_nav_meander` walks
     it. Without it the daemon finds `testsounds` — 8 synth tones — which is the "proves plumbing,
      means nothing" case this closes. (§9.6)
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

### 2.2 LOUDNESS IS PART OF THE ENCODE — ruled by the owner, 2026-08-08

> *"I DO want the LUFS leveling done to the stream we ogg encode! so classical gets louder and we
>  encode it well pronounced."*

This is a **feature decision, not an implementation detail**, and it changes what the shim is for.
 The daemon is not merely filling a codec hole; it is producing a **levelled** stream, so a quiet
  classical record arrives at the same perceived loudness as everything else instead of being the
   track everyone reaches for the dial on.

**`ffmpeg -af loudnorm` is the whole answer** — EBU R128 normalisation, in the same pass that
 produces the opus. `-af ebur128` measures without changing anything if you only want the number.

**The good part: this DELETES a browser dependency rather than adding one.** `Ra_lufs`
 (`Ra.g:199-216`) measures integrated LUFS with `@domchristie/needles` over decoded PCM through a Web
  Worker (`/needles-worker.js`) — three browser things (Worker, AudioContext source, an npm package)
   for one number. Under ffmpeg you do not emulate any of it: **loudnorm's two-pass mode reports the
    measured `input_i` (integrated LUFS) as JSON on stderr *and* applies the correction**, so the
     measurement and the fix come out of the pipeline you were already running.
 The principle worth keeping, because it generalises to every other browser-shaped dependency here:
  **put the seam at the QUESTION, not at the API.** "Reimplement `LoudnessMeter`" is a lot of work;
   *"what is this file's integrated LUFS?"* is a flag. The gain decision downstream of it is
    arithmetic on that number.

**Where it goes in the chain** — filter first, encoder second, so §2.1's invariant survives:
```
source ──▶ decode ──▶ [loudnorm] ──▶ libopus ──▶ Ogg ──▶ demux to packets
                       ▲ the new bit          ▲ §2.1's preskip is read here, unchanged:
                                                loudnorm is a FILTER, it never touches OpusHead
```

Three things to get right, all cheap now and expensive later:
- **Two-pass, not one.** Single-pass loudnorm is a dynamic/streaming approximation and will pump on
   material with wide range — which is precisely the classical case this exists to serve. Measure
    first, then apply with the measured values. You are stocking a file you already hold, so the
     second pass costs nothing but time.
- **A normalised stream is a DIFFERENT artifact from the source, and identity must not blur them.**
   The enid is a sha256 **of the bytes** (`Crate_nav_meander`'s own note on why dedup costs a full
    read), so a levelled encode does not and must not hash to the source file. Key identity off the
     SOURCE; treat the levelled opus as a derived rendition. Getting this backwards would make the
      same record look like two, which is exactly the "there's only one of anything" rule in
       CLAUDE.md.
- **Record the target, and record it once.** Pick one integrated target (−14 LUFS is the streaming
   convention; the owner may want louder) and put it somewhere a reader can find, because a stock
    levelled at one target and a stock levelled at another are not interchangeable and nothing in the
     bytes says which is which.

**Not needed for heist.** §2's split still holds at its strongest here: a heist ships the *original
 bytes*, so it neither transcodes nor levels. Loudness belongs to the radio/stream path only.

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

### 4a. Measured 2026-08-08, and the fix above is NOT sufficient on its own

Run on a PRIVATE dead origin (`RELAY=1 ORIGIN=http://127.0.0.1:9199`) so nothing could reach the real
 cluster — the Peering is minted *before* `Socket_real` dials, so the claim is observable without ever
  connecting. The daemon says it itself:

```
🔌 Lies channel up [runner] addr=runner → editor
🛰 ws ERROR (relay down? wrong origin?)        ← the dead origin, by design
```

**THERE ARE TWO BINDINGS PER SOCKET, and §4's proposed change only moves one.**
- `?addr=<peering name>` → `relay.ts:480` `bind(meta.addr, ws)`
- `become role=<role>`   → `relay.ts:303` `bind(msg.role, ws)`, sent on EVERY (re)open by
   `LiesLies` — so renaming the Peering leaves the daemon still joining the `runner` set.
`locals` is `Map<addr, Set<ws>>`, `bind` is additive and `deliverLocal` fans out to the whole set.

**Where the role actually comes from — one knob doing two jobs.** `Auto.svelte:757-762`:
```js
if (H.c.boot_role === 'runner' && !H.c.creduler_up) {
    H.i({ A: 'Lies' }).i({ w: 'Lies', runner: 1, creduler: 1, … })
```
`runner:1` makes `Lies_role(w)` return `'runner'` (it reads `w?.sc?.runner`), which is what stands the
 channel; `creduler:1` is what runs Books. **The daemon wants the second and not the first**, and
  `boot_role='runner'` currently buys both. `Lies_channel_up` already returns early when the role is
   neither editor nor runner (*"bare: no channel"*), so the smallest honest fix may be to stop claiming
    the role rather than to route it — and that needs **no `relay.ts` change at all**.

**AND THE INVITE PATH MAY NOT NEED ANY OF THIS.** `Swarm_station_up` stands its OWN `%Peering` named
 the prepub *before* calling `Socket_real`, with a comment saying exactly why (*"BEFORE Socket_real,
  which reads the first Peering's name as its ?addr="*). So the **Swarm station socket already dials
   `?addr=<prepub>`** — correct and uncolliding. `addr=runner` is the **Lies control channel**, a
    different world and a different socket. If the daemon arms the station without claiming the runner
     role, invites work and nothing collides.

**So the decision is not "how do we route a daemon-runner" but "is the daemon a runner at all?"**
- **No** (recommended): it does not run Books for the editor, and §8.3's phantom-run footgun is exactly
   what pretending otherwise causes. Cost: the editor cannot dispatch to it — which is the point.
- **Yes**: then it needs a distinct addr *and* a distinct role, and `relay.ts:293` accepts only
   `'editor'|'runner'` — a real relay change plus an editor-side listing/dispatch decision.
Untested caveat on the "No" path: whether stripping `runner:1` while keeping `creduler:1` leaves Book
 running intact is unverified — `Lies_is_runner` has other readers. One daemon run settles it.

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

- **`/music`. LANDED 2026-08-08 — see §9.6.** `Crate.g:34` guards `showDirectoryPicker`, and Crate
   already reads *through the nav* — so this was a nav to write, not a picker to fake, and the nav is
    written: `MUSIC=1` grafts `/music` in READ-ONLY as a third root named `music`, and
     `Crate_nav_meander` walks it (212 tracks, verified through the app's own verb).
   **It does not replace the `SHARE=` shape below, it complements it.** `SHARE=/music OVERLAY=repo` is
    still the right single-purpose deployment; the mount is for the case that shape cannot express —
     keeping the repo as `base` (the wormhole, GhostList and gen trees the daemon boots from) *and*
      seeing a collection that lives somewhere else. A box that is only a jukebox wants `SHARE`; a box
       that is also the machine wants the mount.
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
- **No shipping vehicle exists.** — **PARTLY ANSWERED 2026-08-08: `jamserve`.** `jamserve/Dockerfile`
   + a profiled `jamserve` service in `docker-compose.yml` now exist (profiled, so nothing in the running stack changes
    until you `up` it). It carries ffmpeg from `apk`, shadows `/app/node_modules` with an anonymous
     volume so it does **not** join the shared-libc trap, mounts the library read-write for
      `.jamsend`, and keeps the identity in a named volume so it is the same peer across restarts.
       **What is still owed is the BUILD** — it boots vite in middleware mode exactly as below, which
        the `SECS`-recycle trick makes tolerable for a test rig and does not make right for a
         deployment. The rest of this bullet stands:
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
 Runner released afterwards.

 **Correction to what I first wrote here ("no fixture moved") — the code moved none, the RUNS did.**
  My edits change no snapped C shape (the restash verbs write only the Dexie `stashed` rail; the `Auto`
   changes touch `.c` flags and files), so nothing needed re-recording. But *running* the four Books
    rewrote their own snaps, and those are in the `Dae` commit:
  - `<Book>/toc.snap` — **`TimeSpool` telemetry only**: a rolling `sample=…,at=…` window, oldest rolled
     off, mine rolled on, `avg` recomputed. Noise, not signal.
  - `<Book>/Credulation/toc.snap` — the `uses:Ghost_*,dige:…` record of **which ghost versions the run
     ran against**. Most of that churn is **not mine**: `Ghost_M_Ra`, `Ghost_M_Radio`, `Ghost_M_Heist`,
      `Ghost_M_Crate`, `Ghost_N_Peeroleum`, `Ghost_N_Tribunal` and others all moved because the
       concurrent agent's edits to those files were live on the runner when I ran. So these records are
        a snapshot of a tree that was **mid-edit by someone else**. The verdicts stand (green is green,
         and it was the real runner), but do not read those diges as a settled baseline — re-run the
          Books once that other work lands if you want a clean record.

---

#### RUN 1 continued — §0 item 6: the daemon can see real music.

**`MUSIC=` mounts a collection READ-ONLY as `music/`** (`NodeWormholeNav.ts` `mounts`, wired in
 `main.ts:270-283`). `MUSIC=1` means this container's `/music`; any other value is a path.

**Why a third root rather than repointing `SHARE`.** `base` IS the repo — the wormhole fixtures, the
 GhostList and the gen trees all hang off it, so a daemon that repointed `SHARE` at music would find
  the collection and lose the machine it boots from. overlay/base is a **shadowing** pair (one
   namespace, one wins); a mount is a **disjoint** namespace, which is the honest shape for "this other
    tree is also visible here". Read-only is **enforced** (`writeRoot` throws on a mounted rel), not
     merely intended: `/music` is the owner's own files and the daemon's safety story is that it does
      not write outside its overlay.
 Nothing on the ghost side needed teaching — the meander walks whatever `dir_at`/`expand` report, and
  `Sounditron_muse` already probes `['testsounds','music','']`. The one thing that DID need doing:
   mount names are injected into the **root** listing, or a bare `Crate_nav_meander(nav, '', …)` — the
    path a real Radio takes — could never reach them.

**On the checks, and why the daemon now says what it can see.** A private file count would have
 answered *"is there music on disk?"*, which was never the question — the question is *"can the
  machine's own discovery path FIND it?"*, and those differ for exactly the reasons the meander exists
   (the no-enumeration law, dot-dir skips, dead-end climbs). An instrument that agrees with the thing
    it measures by construction measures nothing ([[comments-assert-unmeasured-properties]]). So the
     probe calls the **same verb the app calls**, once per boot, and says the answer:
```
🎵 collection reachable via music — meander picked 5: 00 - EBONY LAMB - SALT SAND SEA.opus · …
```
 - **Nav layer, direct unit check:** `music/` lists **212 files, all audio, 0 dirs**; the root listing
    contains `music`; `read_range` returns real `OggS` magic with a 3 591 119-byte size (the seekable
     read Radio needs, not a whole-file slurp); a write to `music/` is refused; `music/../../etc` is
      refused (Agent B's confinement composes with the mount); the repo stays readable.
 - **App layer:** the three env cases all behave — `MUSIC=1` → real tracks via `music`; **no `MUSIC` →
    `testsounds`, "DJ Oscillo - Cosmic C.wav"**, i.e. the 8 synth tones, which is precisely the
     measure-nothing state this closes; `MUSIC=/nope` → `⚠ MUSIC=/nope does not exist`, no mount.
 - `tsc --noEmit` clean on the nav; the no-`MUSIC` run proves the default path is unchanged (`mounts`
    defaults to `{}`, so every other caller — `Story_cli`, the spec harnesses — is byte-identical).

**What this does NOT do.** It makes the collection *reachable*, not *served*. §8.2 still stands: the
 daemon cannot carry a track past its preview window without the opus shim, because `Ra.g:1352/1657`
  construct `OfflineAudioContext` unguarded. Those two lines are the next real work and I did not touch
   them — `Ra.g` is the concurrent agent's file tonight.

#### Where the night stopped, and why each remaining item is genuinely blocked rather than skipped

I tried to keep going past item 6 and each road is closed by something that is not mine to decide:

- **Item 5, the opus shim — blocked on a DEPENDENCY DECISION that is the owner's.** There is **no
   `ffmpeg` and no `ffprobe`** on this container's PATH, and no opus/ogg/ffmpeg node module in
    `node_modules`. The only two ways in are a system package or an npm dependency, and **`npm install`
     is the one thing CLAUDE.md forbids outright** (the shared musl/glibc `node_modules` that took the
      app down for hours on 2026-08-07). So the shim cannot be *started*, let alone finished, without a
       call from you on how the binary arrives. Worth noting §8.2 already caught the related false
        claim: `node-web-audio-api`, cited in §2 as *"provides both for real"*, is **not in
         `package.json`** and does not resolve.
- **Measuring the codec wall with the newly-mounted real music — blocked on ATTRIBUTION.** The obvious
   move was to let the daemon stock real opus and watch precisely where it dies, turning §8.2 from a
    read-from-code claim into a measured one. Stocking never fires on a plain `B=Sounditron` boot (it
     needs the Radio path driven — [[share-arms-only-on-first-dial]]), and driving it with a Radio Book
      tonight would run against `Ra.g`/`Radio.g`/`Crate.g` **while another agent has all three
       mid-edit**. Any number I got would be unattributable, which is worse than no number
        ([[controlled-revert-to-attribute-a-red-book]] is the standard this repo holds itself to). Do
         this once their work lands — it is cheap and it is the right next measurement.
- **Items 2 and 3 (relay address, arm the station)** — deliberately yours, §9.7 Phase 3.
- **Item 7 (the two-tab fingers-test)** — needs a human and a browser.

So the honest state at stop: everything reachable tonight without a decision from you, or without
 touching another agent's live files, is done. The next three moves are all short, and all yours to
  unblock: **the relay address**, **how ffmpeg arrives**, and **ten minutes with two tabs**.

---

#### RUN 1 continued — STEPS 3 AND 4 LANDED. The daemon is on the network under its own address, with invite handlers armed.

The owner ruled at ~02:15: *"`accepts only editor|runner` sounds like it should fall, dispatching only
 runners, listing everyone somewhere maybe one day, but we may leave that TODO"* — and gave the go.
  The v1.0 framing they set: *"a way for a user to enjoy the app and set up this daemon to serve their
   presence on the network, to be reliably there when Invite codes are finally found and redeemed."*

**The result, on the REAL relay, with the human's runner up the whole time:**
```
🤝 Swarm station ARMED at 5691d4258dc79df6 — pier_hello handlers registered; invites can be answered
🛰 ws OPEN ws://172.17.0.1:9091/relay?addr=5691d4258dc79df6 — flushing 0 buffered
🛰 ws RECV control:hello_ok
```
Its own prepub as its address, signed hello accepted, handlers armed. No `addr=runner` anywhere.

**The one thing that made this safe rather than catastrophic.** A `become` does two unrelated things:
 `bind(role, ws)` (reachability — harmless for any name) and `setRole(role)` (which relay dials the
  r2r bridge — **set-once, and it THROWS on conflict**). Relaxing the `editor|runner` `if` naively
   would have let a daemon's become reach `setRole`, so whichever peer connected first would own the
    bridge and **the loser's become — quite possibly a human's runner tab — would throw**. That is
     exactly "a bad relay edit takes every runner down", reachable by relaxing one condition. So:
      `relay.ts` now binds **any sane role name** (`BRIDGE_ROLES` / `SANE_ROLE`, `relay.ts:292-330`)
       while only `editor|runner` steer the bridge. Dispatch stays runner-only for free — dispatch
        addresses `to:'runner'`, which nothing else binds. Listing is left as the owner's TODO;
         nothing enumerates `locals` for a UI.

**Daemon side: `boot_role='daemon'` — a runner in every respect but the role claim.** `CHANNEL=1` opts
 back into the old behaviour. Three call sites had conflated "runs Books" with "is the editor's
  runner", and **only measurement found the third**:
 1. `Auto.svelte:771-777` — `creduler:1` (runs Books) split from `runner:1` (claims the relay role).
 2. `Auto.svelte:980-992` — a daemon spools the Creduler soul but **never reports a verdict**: nobody
     dispatched this Book, so there is no dock awaiting one, and that is half of §4's observed
      "phantom run in someone else's cluster view".
 3. `Story.svelte:2229` — **the one that bit.** `is_runner()` is what makes a headless run *lenient*
     on a value-noise mismatch ("no one is there to resume it"). It read `boot_role === 'runner'`, so
      a daemon halted at the first mismatch: **1/1 steps where a runner does 7/7 — no error, no
       warning, just a Book that quietly stopped.** Nothing about the symptom pointed at a role check.
        Widened to accept `daemon`; 7/7 restored. Provably a no-op for existing roles.

**Verified after every edit, because this is the spine:** the live runner answered `ping` with
 `channel:"up"` throughout; the editor round-tripped a `ghost-compile`; `SwarmInvite` **5/5** and
  `SwarmDisk` **7/7**, both ok, 0 caveat; runner released. One transient stuck run (`phase:begun`,
   `n:null`) appeared right after the `Story.svelte` edit — HMR landing mid-flight, not a breakage: a
    `release` + re-run came back clean, so no reload was needed and no telegram sent.

**What is now true, and what is still missing for "invites end-to-end".** The RESPONDER half is
 built and armed: a redemption arriving at that address has handlers to land on, and tonight's ledger
  graft means the `%Idzeug` serials are actually under the live `%Peering` for `Swarm_hello` to find.
   What is untested is a real redemption, because **redemption is a UI gesture** — `Swarm_redeem` is
    only ever called from `InvitePanel.join()`. §9.4's two-daemon harness (a test-only headless
     redeemer, second `DAEMON_STATE`, second `PORT`) is the way to prove it without a human, and it is
      the next piece of work. It is a smoke test, not a gate (§6).

---

#### RUN 1 continued — ✅ **INVITES END-TO-END. The work order's stated goal is met.**

§9.0's goal was *"the daemon answers a redemption and mints a Grant."* It does. Two daemons, the real
 relay, no human anywhere in the loop:

```
A: 🤝 Swarm station ARMED at 1aac537896332e6f — invites can be answered
A: 🎟 invite minted by 1aac537896332e6f (serial 2941044c596f)
B: 🤝 Swarm station ARMED at 1acfce74a5da4357
B: 🎟 redeem ACCEPTED by 1aac537896332e6f — waiting for the seal…
B: 🤝 SEALED with 1aac537896332e6f — the friendship stands, both ends
```

**Verified in the durable stores, not just the log** — this is the part that matters, because a
 friendship that only exists in memory is the bug this whole file has been chasing:
 - **A spent the serial**: `Swarm_izzes.1aac…{2941044c596f: {to:"Music", spent:1}}`. Single-use holds,
    so a replay of that token now refuses. §8.1's security property, observed rather than asserted.
 - **A holds a %Pier for B**, with grants. **B holds a %Pier for A**, with grants. Mutual and durable.
 - **AND IT SURVIVES A RESTART.** Rebooting A on its existing state:
    `🤝 … ARMED at 1aac537896332e6f · remembers 1 friend(s), 1 invite(s)` — same identity, friendship
     rehydrated, spent invite still spent. That is tonight's ledger graft (step 2) doing the job it
      was built for, at the far end of the chain that motivated it.

**The harness** (`main.ts`, `invite_harness`) is **TEST-ONLY and says so at length**. `MINT_INVITE=1`
 on A, `IZ=<token>` on B, different `DAEMON_STATE` dirs and `PORT`s. It exists because **redemption is
  a UI gesture** — `Swarm_redeem` has exactly one caller in the tree, `InvitePanel.join()` — and the
   owner ruled the daemon is the RESPONDER, never the joiner. A daemon that could redeem in production
    would be the wrong thing built; a daemon that can redeem behind an explicit env knob is a rig.
 **It is a smoke test, not a gate** (§6). It does not replace the two-tab fingers-test.

**Also confirmed in passing:** Agent A's `DAEMON_STATE` lock works *including release* — two reboot
 attempts correctly bounced with `exit 6` while A was genuinely live, and the lock file was gone after
  A's clean exit (pid check + removal both good). I went looking for a permanent-wedge bug and there
   isn't one.

**What remains genuinely unproven:** the browser. Every proof here is node-side. §6.7's two-tab
 fingers-test is still the gate for the FSA backend, and it matters more now, not less.

---

#### RUN 1 continued — **jamserve**: the container, and the one knob that makes the layout work.

The owner named it (*"srv is a terrible name… let's call it jamserve — a user's personal internet
 infrastructure, music piracy only for now"*) and gave the deployment shape that I would otherwise
  have got wrong: ***"the user must have already set up via browser+FSA the /music/.jamsend etc"*** —
   i.e. **the share IS the music folder**, and the account is already inside it.

**Files added** (all additive; nothing in the running stack changes until it is `up`ed):
 `jamserve/Dockerfile` · a `jamserve` service in `docker-compose.yml` · a `## jamserve` section in
  `README.md` (the user-facing doc — keep it in step with the compose comments).
 **This went back and forth, and the deciding evidence was operational, so record it and stop
  re-litigating.** It first shipped as a separate `docker-compose.jamserve.yml`, on the reasoning that
   compose files are per-ENVIRONMENT (dev / staging / prod / a user's own box) and jamserve is a
    fourth. That reasoning is fine and it is still not what to do, because the cost lands on every
     single command: two `-f` flags forever, and `docker compose logs jamserve` failing outright with
      **"no such service"** — which is exactly how the owner hit it. `profiles: ["jamserve"]` buys the
       one property the separate file was actually for (never starts by accident) and naming the
        service auto-enables its profile, so the commands stay short. The duplicated `music-volume`
         anchor stays, and is correct: dev's is `:ro`, jamserve's must be read-write.
 Start once:
 `docker compose up -d --build jamserve`.
 No `--build` loop is needed — source is bind-mounted and `SECS=900` + `restart: always` relaunches
  on freshly-edited code, which is also how a sibling session iterates on it without a docker socket.

**Two lines in there are load-bearing, and both are CLAUDE.md's warnings made structural:**
 - `- /app/node_modules` — an anonymous volume shadowing the bind mount. `app` (musl) and `claude`
    (glibc) already share one `/app/node_modules` because `.:/app` mounts the host tree over whatever
     each image built; jamserve is a **third** libc consumer and without this line makes it worse.
 - **ffmpeg comes from `apk`, never npm.** `ffmpeg-static` ships a per-platform prebuilt as an
    *optional dep* — precisely the 2026-08-07 failure — and `@ffmpeg/ffmpeg` is the browser wasm
     build. The owner asked *"shall I npm i ffmpeg?"*; the answer is no, and this is why.

**`LIBRARY=` — one knob, because three roots is otherwise genuinely confusing.** `LIBRARY=/music`
 expands to `music` → the folder **read-only** and `.jamsend` → `<folder>/.jamsend` **read-write**.
  So: the collection is never written to, the account lands where a browser session would look for
   it, and machine scratch (Story snaps, gen writes) still goes to `OVERLAY` instead of littering
    someone's music. That needed a writable-mount option in `NodeWormholeNav`, since overlay/base is a
     *shadowing* pair and cannot express three roots with three different rules.

**A real bug, found by testing rather than reasoning — and it was the dangerous kind.** The first
 `LIBRARY=` run logged `🪪 account mirrored → .jamsend/account/<prepub>/toc.snap` and **wrote it to the
  scratch volume instead of the library**. Cause: `Swarm_account_dir(root, prepub)` is
   `(root||'') + '/.jamsend/…'` and every app caller passes `root=''`, so the rel that arrives has a
    **leading slash**; splitting it naively made the first segment the empty string, no mount matched,
     and it silently fell through to the overlay. *A green log for a wrong file* — the exact failure
      mode this file keeps warning about. Fixed in `mountFor`/`writeAbs`; re-verified: account and
       roster now land in `<library>/.jamsend/`, scratch has no `.jamsend`, the library holds only the
        music plus `.jamsend`, and the collection is still found through the app's own meander.

**FIRST REAL BOOT, 2026-08-08 ~03:5x — the owner started it and it came up.** Log + `/status` agree:
 dexie shim → the state volume · `w:Wormhole ← node nav` · `🪪 minted a daemon identity (fdddc007480f)`
  · `🪪 account mirrored → .jamsend/account/fdddc007480f0b6c/toc.snap (resume with I=…)` ·
   `🎵 collection reachable via music — meander picked 5` (real filenames off the owner's library) ·
    `🤝 Swarm station ARMED — invites can be answered · remembers 0 friend(s), 0 invite(s)` · then a
     steady `♥` with three Houses (Mundo, Story, Sounditron), 2601 ghosts, `wedge: null`, the
      Sounditron Book driving. **So: the container, the node nav, the mount split, the identity mint,
       the account mirror, the collection meander and the Swarm station all work outside a browser.**

**And the boot immediately found a defect that no amount of reading would have — the ownership one.**
 The container ran as **root**, so it laid down `/music/.jamsend` as `root:root` mode **700** *inside
  the owner's own music folder*. That inverts the whole documented workflow: the browser holds the FSA
   grant and runs as uid 1000, so it can no longer provision, read or repair the account it is supposed
    to own — and neither can the human without `sudo`. Note the shape, which is the same one as the
     leading-slash bug above: **every log line was green.** Fixed by `user: "1000:1000"` in the compose
      file plus a `chown` of `/var/lib/jamserve` and `/app/node_modules` in the Dockerfile before
       `USER node` — an empty named *or anonymous* volume inherits the ownership of the image directory
        it covers, which is also why `node_modules` needs it (vite writes `.vite/deps` at first
         transform, so root-owned would EACCES minutes after a clean boot, not at start).
 **And the fix does not land on a plain rebuild, which is the second half of the trap.** Docker keeps
  BOTH of jamserve's volumes across `up --build`: the *anonymous* one is reused from the previous
   container rather than repopulated from the new image (compose's own words: *"retrieving data from
    the previous containers"*), and the *named* `jamserve-state` survives by design. So the new
     image's `chown` never applies and the failure reappears identically. Verifying the fix needs
      `rm -sf` the container, `docker volume rm <project>_jamserve-state`, then
       `up -d --renew-anon-volumes` — **never `down -v`**, which takes the project's named volumes
        including `claude-auth` (the CLI's credentials and session history). Plus the
         `sudo rm -rf <music>/.jamsend` of the root-owned account. Recorded in README.md and the
          compose file so it is not re-discovered.

**§2.2 added — LOUDNESS IS PART OF THE ENCODE**, on the owner's ruling (*"I DO want the LUFS levelling
 done to the stream we ogg encode! so classical gets louder"*). It is `ffmpeg -af loudnorm`, in the
  same pass as the opus. The pleasing part: it **deletes** a browser dependency rather than adding
   one — `Ra_lufs` currently measures LUFS with `@domchristie/needles` through a Web Worker, and
    two-pass loudnorm reports the measured integrated LUFS *and* applies the correction. The general
     principle, worth reusing on every other browser-shaped dependency here: **put the seam at the
      QUESTION, not at the API.** Reimplementing `LoudnessMeter` is a lot of work; *"what is this
       file's integrated LUFS?"* is a flag on a binary you already installed. §2.2 carries the three
        traps (two-pass not one; a levelled encode must not hash as the source; record the target).

**§2.1/§2.2's first stone laid, and it is a MEASUREMENT not a shim.** New `scripts/daemon/ffmpeg.ts`
 exports the two *questions* rather than a WebCodecs emulation — `have()` (is there a binary) and
  `measure(abs, target)` (pass one of two-pass loudnorm, returning ffmpeg's own `input_i`/`input_tp`
   verbatim so pass two can hand them straight back). Its header carries the three traps in full. The
    rel→real-path problem this needed is solved by one new **read-side-only** public method on
     `NodeWormholeNav`, `native_path(rel)` — it goes through `readAbs`→`confine`, so it cannot name
      anything outside a mount, and there is deliberately no write twin.
 `main.ts` now probes at boot, **after** the meander so it asks a real question of a real track from
  the owner's own library: `🎬 ffmpeg <v> — measured <track>: <x> LUFS, tp <y> dBTP → <±z> dB to reach
   -14 (Ns)`. That second half is the load-bearing part — a version string passing while the measure
    fails is an ffmpeg built without the codec the collection is actually in, and nothing else catches
     it. Non-fatal throughout; no ffmpeg logs *"this box serves preview windows only"* and carries on.
 **Unverified as of writing** — it lands on jamserve's next `SECS=900` restart (bind-mounted source,
  no rebuild needed); check the log for the `🎬` line.

**"It should probably complain about no identity if there isn't one" (the owner) — and the knob that
 governs that is NOT the obvious one.** `ROLE` defaults off precisely so an unconfigured boot does not
  provision (§4.1), so the compose file defaulting `ROLE=jamserve` had quietly re-enabled the thing the
   ruling forbids. Fixing that alone is **not enough**, and the log proved it: with `ROLE` unset the box
    still minted `7c0d0bfdb35e`, because `seed_identity` writes a keypair to `KEYFILE` whenever none is
     there, independent of both `I=` and `ROLE` — and the keyfile adopt then WINS over `ROLE`, which is
      why the knob doc says *"ROLE is inert unless KEYED=0"*. **`KEYED=0` is the actual gate**; it is
       now the compose default, with `JAMSERVE_ROLE=<name>` as the explicit smoke-test throwaway.
 New `nag_identity()` says so for as long as it is true — once loudly with the exact recipe
  (`ls <music>/.jamsend/account/` → the dir names ARE the prepubs → `JAMSERVE_ID=`), then folded into
   the `♥` line, for the same reason the wedge is: **unprovisioned looks exactly like provisioned from
    outside**, so the heartbeat has to carry it or nobody finds out. Silent when correctly configured.

**THE INVITE WORKED, END TO END, AND IT IS THE NIGHT'S BEST RESULT.** The owner opened the throwaway's
 own printed link in an incognito tab. jamserve's log: `ws RECV pier_hello ← 47e9a9f5377a3169` ·
  `ws SEND pier_accept` · `ws RECV pier_confirm` · `ws RECV ive_got`. Then it **survived two restarts**:
   `🤝 Swarm station ARMED … remembers 1 friend(s), 2 invite(s)`. So a browser can befriend a headless
    daemon over the real relay, and the friendship is durable through `<music>/.jamsend/account/`.
 **What it cannot do is play anything**: `radiostock/` does not exist, because stocking runs through
  `Ra_stock_one` → WebCodecs. The two tabs traded `ive_got` and the daemon's answer was *nothing* —
   which is also why the owner reports "nothing in the Vyto glass". **That join is the remaining work**,
    and `ffmpeg.ts` now has all three pieces for it (`measure` → `level_to_ogg` → `demux_ogg_opus`,
     the last returning the raw length-prefixed packets `Ra_chunk_pack` actually stores). Nothing in
      `Ra` calls them yet.
 **A trap the invite URL walks into:** `/BigSoundland` is `boot_qualand({book:'Sounditron'})`, and a
  Book sets `boot_role:'runner'` — so the incognito tab logged `🔌 Lies channel up [runner] addr=runner`
   and became a SECOND claimant of the `runner` relay address. `bind()` is additive, so an open real
    runner tab now shares every editor frame with it. Pre-existing (the player page and the runner are
     the same page here), but the invite makes it easy to hit; close other runner tabs when testing.

**I KILLED THE DAEMON TWICE WITH A READ-ONLY DIAGNOSTIC, and the second one is the instructive half.**
 `/c?depth=8` reached a node `Timeout` (→ `TimersList` → circular) and `JSON.stringify` threw straight
  out of the request handler; node makes that an uncaughtException and `arrest_watch` correctly exits 5.
   A GET that stops the process is worse than anything it was looking for. I guarded `/c` — **and the
    crash moved to `/status`**, which had been safe all night and became unsafe the moment a Pier
     sealed, because `stats()` reports each House's `queued` and the Swarm's retransmit timers now sit
      there. *Guarding the route was the wrong altitude; guard the SHAPE.* Every response now goes
       through `safe_json` (a replacer that renders any non-plain constructor as `[Timeout]` and any
        cycle as `[circular]`) and the whole handler is wrapped. Verified against a real `setTimeout`
         and a real cycle. Note the separation: the CRASH was mine; whether a `Timeout` belongs in
          `queued` is a different question and is not evidence of a bug on its own.

**A THROWAWAY HANDS OUT ITS OWN WAY IN** (the owner's idea, and a much better use of that state than
 complaining about it): *"perhaps the THROWAWAY IDENTITY could log an invite to it, to make everything
  easy to test? then I can incognito-tab another Pier to listen to a bit of daemon-served music!"*.
   `MINT_INVITE` now defaults on when `!process.env.I`, and prints a **URL** rather than a bare token —
    `<origin>/BigSoundland?Iz=<token>`, because `?Iz=` on the page IS the redeem path a scanned invite
     takes, so an incognito tab on that link becomes a sealed Pier that can listen. Not knowing
      anybody is precisely the problem an invite solves; the least useful state this box has is now
       its most testable one.
 **Gated on `!I=`, and that gate is load-bearing.** A provisioned box is the owner; a daemon quietly
  minting single-use invites to a real identity on every boot — *into a logfile* — hands out their
   friendship unasked. Same condition as the nag, deliberately, so "complains that it is a throwaway"
    and "is useful because it is one" can never drift apart.
 The link is built from `INVITE_ORIGIN` (default `http://localhost:9091`) and **not** from `ORIGIN`:
  ORIGIN is the docker-bridge address the *container* reaches the dev server by, and a host browser
   opening that gets no secure context, so WebRTC refuses — which reads as a peering failure and is
    not one.

**§2.2's second half landed too — `level_to_ogg`, pass TWO.** Feeds `measure()`'s `measured_*` back in
 with **`linear=true`** (without it loudnorm silently reverts to its DYNAMIC mode: one constant
  whole-track gain is what `Ra_bake` means, and a dynamic pass is a different master that sounds
   fine), pins **`-ar 48000`** (loudnorm resamples internally to 192kHz and leaves it there; libopus
    would insert a resampler of its own choosing), and structurally verifies `OggS` + `OpusHead` in the
     output before returning it — a truncated pipe or a silently-swapped codec otherwise reaches a
      phone as a file that just does not play, the hardest failure to attribute later. Behind
       `FFTEST=1`: measuring costs seconds, transcoding costs minutes, and this box restarts on a timer.

**The security note the owner spotted, now in README.md where users will meet it.** The account snap
 holds the ed25519 **private key in the clear** (`Swarm_account_save`'s landmine). jamsend's own three
  invariants keep it safe — `.jamsend` never peer-readable, a share walk returns audio only, Repli
   moves particles not files — but *those are jamsend's guarantees alone*. Point Syncthing/Resilio/
    Dropbox/another p2p music app at the same collection and it replicates `.jamsend/` with the music,
     and whoever receives it **is you**. Mitigation is an ignore pattern for dot-dirs, or not sharing a
      collection jamsend lives in; there is no revoking a leaked identity, only minting a new one.

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


---

## 10. jamserve can serve audio now — the native stock fork (2026-08-08, small hours)

**The arc.** Everything before this made jamserve a *durable peer*: it holds an identity, answers an
 invite, seals a Pier and survives restarts. What it could not do was **have anything to play**. A
  friend sealed with it and opened an empty Vyto glass. That is now closed: a live incognito Pier can
   be served real tracks off the owner's collection, stocked by ffmpeg inside the daemon.

### 10.1 What was actually wrong (and why nothing said so)

`Ra_stock_one` is the whole of stocking, and **three of its steps are browser primitives**:
 `OfflineAudioContext` (decode), the needles Web Worker (`Ra_lufs`), and WebCodecs `AudioEncoder`
  (`Ra_encode_open`). Headless, the first of them throws. `Stoker_dig` catches per-pick
   (`Radio.g:1988`), counts it as "could not read or decode", and — correctly, for its own model —
    calls `Stoker_barren(base, p)` so the wander never costs a full file read for that path again.

So the daemon dug the entire collection, learned every path barren, and reported **a clean shelf of
 zero**. Every log line green. `radiostock/` simply did not exist. *Nothing anywhere said "I cannot do
  audio"* — this is the shape [[comments-assert-unmeasured-properties]] keeps warning about, in its
   silent form: not a false claim, an absent one.

### 10.2 The seam: three questions, not three shims

`scripts/daemon/ffmpeg.ts` already carried the principle — **put the seam at the question, not at the
 API**. The fork applies it:

| Ra asks | browser answers with | headless answers with |
|---|---|---|
| how long, how many channels? | `decodeAudioData` → AudioBuffer | `ffprobe` (banner-parse fallback) |
| this window's loudness + peak? | needles worker + `Ra_peak` | `astats,loudnorm` in one pass |
| that window, gained, as opus packets? | `Ra_bake` + WebCodecs | `volume` filter + `libopus` → demux |

`Ra_native()` reads the provider off the top House's `.c` (`scripts/daemon/ra_native.ts`, installed by
 `ra_native_arm()` before `station_up`). A browser has none, so **every browser path is byte-for-byte
  what it was**.

**The fork is INSIDE `Ra_stock_one`, not a second copy of it.** That was the design call worth making:
 the window arithmetic, `Ra_gain_for`'s decision, `Ra_chunk_cut`'s 2s grid, the card, `Ra_vouch_header`,
  `Ra_pack`, the GC and `Ra_record_from` all sit *below* the fork and are shared. A daemon-stocked card
   and a browser-stocked card cannot drift, because only one place builds one. `Ra_chunk_cut` in
    particular is pure packet arithmetic over an st-shaped bag, so native packets go through the
     identical grid rather than a second implementation.

### 10.3 Two traps found by measuring, both of the "plausible and wrong" kind

**(a) `volumedetect` clips the thing it measures.** `Ra_gain_for` divides the ceiling by `Ra_peak` — the
 **sample maximum**. loudnorm's `input_tp` is a 4× oversampled **true peak**, typically 0.3–1.5 dB
  higher; at a −1 dBFS ceiling that caps constantly (6 of 8 real tracks on the first pass). The obvious
   fix, `volumedetect` in front of loudnorm, is wrong: it accepts fixed-point formats only, so ffmpeg
    inserts a float→s16 conversion that **clips everything above 0 dBFS**, and loudnorm downstream then
     measures the clipped signal. The tell was small and unmistakable — the same track read
      `tp 0.69 dBTP` bare and `tp 0.39 dBTP` with the meter in front. *A measuring instrument that
       changes its subject.* `astats=measure_perchannel=none:measure_overall=Peak_level` declares float,
        nothing is inserted, and `tp` returns to 0.69 — that equality is now the standing check, and the
         boot line prints `pk … (astats)` vs `(true-peak)` so a silent fallback can never become
          permanent.

**(b) `Ra_stock_drop` was inert on the daemon — so the shelf could never be GC'd.** It opens with
 `if (!dl || typeof dl.deleteEntry !== 'function') return`, a graceful no-op written for a read-only
  proxy. `NodeWormholeNav`'s `dir()` had no `deleteEntry`, so it took that branch **every time**, and
   everything built on it went quietly inert: `Ra_stock_gc` (supersede an older render of the same
    path), **`Ra_stock_gc_cap` — the only thing bounding shelf growth** — and `Ra_stock_cascade`. An
     always-on box whose cache cap cannot evict fills the owner's music disk, slowly, reporting success.
  Found because `/restock` said "dropped 20" and twenty files sat there with their original mtimes.
   `deleteEntry` now exists on the node nav (through `writeAbs`, so a read-only mount throws exactly as
    a write would; files only), and `/restock` counts a **before/after listing** rather than its own
     calls — a count of attempts cannot tell that lie. Generalisation worth keeping:
      **a no-op that ANSWERS is worse than one that refuses.**

 **⚠ THE BLAST RADIUS IS WIDER THAN RADIOSTOCK — the owner should know this before the next heist.**
  `typeof dl.deleteEntry !== 'function'` is a guard **six** places use, and all six were inert on the
   daemon: `Ra_stock_drop` + `Ra.g:1569` (stock housekeeping), `Heist.g:292` (drop one landed file),
    `Heist.g:3006`/`3035` (`Heist_sweep` — recursive removal of a landing tree), and
     `Heistation.g:3181`. So a jamserve doing phone-sync heists was never cleaning up after itself
      either. **Adding `deleteEntry` turns all six ON at once**, `Heist_sweep`'s recursion included.
       Two things bound it and both are load-bearing: every path still resolves through `writeAbs`, so
        a read-only mount (`music`) **throws** rather than deletes; and `deleteEntry` refuses a
         directory outright, so a sweep can only remove files it listed. Worth an eye on the first real
          heist a jamserve runs — this is the one change tonight whose failure mode is *deletion*
           rather than a missing feature.

### 10.4 What is proven, and how

- **16/16 cards verified structurally** — unpacked, packets walked by lacing, samples counted off each
   TOC byte: 1601 opus packets = 32.02s across 16 chunks of exactly 2s, `preskip 312` (the same number
    WebCodecs reports), mid-track cut landing at 62% of a 348s track. Script kept at
     `scratchpad/verify_stock.mjs` — it also re-muxes the raw packets into a real Ogg, so where ffmpeg
      exists (`FF=1`) it reports the **stocked** audio's own LUFS rather than the card's claim.
- **Real music, not testsounds** — 8 real tracks from `/music` alongside the dev `testsounds`, stereo,
   200–3100s sources, gains from −8.35 to +2.21 dB.
- `probed=16 measured=16 encoded=16 failed=0`, on the heartbeat every 10s (`🎚 shelf=N rec …`).
- **The BROWSER path is gated, because `Ra.g` HMR'd straight into the owner's live tabs.**
   `MusuRaStock` — the direct Book over `Ra_stock_one` — runs **green, `caveat=0`**, meaning the
    browser-stocked card's dige is byte-identical to its fixture. `MusuRaStream` is red, and it was red
     before this work: step 1's *only* divergence is `w:MusuRaStream,now=1751980010`, which
      `Radiation.g:78` (`w.sc.now = 1751980000 + 10*n`, the pinned swarm clock) writes and the fixture
       predates; steps 20/40 then cascade off it as `self,round=46` vs `70`. Known baseline —
        [[radiation-books-red-at-baseline]]. **Stated as strong evidence, not proof: no controlled
         revert was run.** If someone wants the proof, revert `Ra.go`, recompile, rerun, compare diges.

**Not yet proven: that it SOUNDS right.** The framing is verified and the loudness numbers are
 self-consistent, but no ear has been on it. That is the owner's two-minute test — open the incognito
  Pier and listen. If a track plays but sounds wrong (noise at a chunk seam, a volume jump), suspect the
   `volume` filter's precision or the 20ms frame pinning, not the framing.

### 10.5 Next

1. **Listen.** The one thing a snap cannot carry.
2. **The continuation past the preview — scoped, NOT started, and the obvious approach is wrong.**
    Only the 32s window is stocked. Today a peer that asks past it gets nothing, and until tonight the
     way it got nothing was ugly: `Ra_source_pcm`'s `new OfflineAudioContext` sits *outside* its try, so
      headless it threw a ReferenceError; `Ra_transcode_ensure` kicks that decode **detached with a
       `.catch`**, so nothing crashed — it climbed the backoff ladder to the 60s ceiling and re-threw
        the same stack once a minute forever, while the asking peer saw only a want that never landed.
         Now guarded: one `pcm-nosource … 'headless — no OfflineAudioContext; preview only'` trace and a
          clean null, which is a path `Ra_transcode_ensure` already handles. **Same lesson as §10.1 —
           the fact was known in that function and no path carried it.**
  **The trap for whoever lifts this.** `encode_opus_window` looks like the answer and is not.
   `Ra_source_pcm` returns whole-file PCM for an **incremental** encode: `Ra_transcode_advance` feeds a
    page-stride per pump beat and cuts chunks off ONE long-lived encoder, because opening a new encoder
     per window means a new ~6.5ms convergence ramp — i.e. an audible seam — at every chunk boundary.
      That is the whole reason `Ra_stock_one` says "ONE continuous encode".
  **✅ BUILT 2026-08-08 afternoon — and the streaming-pipe design above was NOT what it needed.**
   That design (a long-lived `ffmpeg -f f32le -i pipe:0`, PCM on stdin, a streaming Ogg demux over
    stdout so `Ra_encode_open/feed/drain/close` map 1:1) is sound and was the plan. It is also far more
     machinery than the problem justifies, and it inherits the thing that made the browser path
      expensive: it still wants `rec.c.pcm` on stdin. **The cheaper shape satisfies the same
       constraint.** The constraint was never "stream it" — it was *one encoder for the whole
        remainder, so there is only one convergence ramp and it lands at a seam the format already
         has*. A single non-streaming pass gets that for free:
```
Ra_native_continuation(w, rec, nat)      # Ra.g, new
    from  = (pv_off + P) * seg_secs      # the same boundary Ra_transcode_ensure computes, in SECONDS
    enc   = nat.encode(base, path, from, rest + seg_secs, card.gain, nch, br)   # ONE ffmpeg pass
    bufs  = Ra_chunk_cut({packets: enc.packets, acc: [], accs: 0}, 1)           # the SAME 2s grid
    rec.c.ra = { nat:1, bufs, preskip: enc.preskip, next: P, at: 0, done: 0 }   # a ready QUEUE
```
   `Ra_transcode_advance` gained a `ra.nat` branch that hands out `stride` chunks per pass, so chunks
    still come into being *across* passes and the park/serve economy above is untouched. The fork in
     `Ra_transcode_ensure` is **detached** (never awaited under the beat — an ffmpeg pass over minutes
      of audio would freeze `Swarm_share_beat` under the beliefs mutex, starving the pump waiting on
       it) and shares the PCM backoff ladder, because a source that can never encode is exactly the
        1087-starts storm that ladder was written for.
  **The side effect the streaming design was chasing arrives anyway, larger.** A ~4-minute remainder is
   **~3MB of opus held**, against the **~92MB of Float32 PCM** the browser path pins for the same track
    — the entire reason `Ra_pcm_sweep` exists ([[pcm-pinned-on-records]]). Native records never join
     the PCM registry (`Ra_pcm_sweep`'s `if (!rec.c.pcm) continue` skips them), and the queue is
      dropped the instant it drains. Thirty times smaller *and* simpler, which is the tell that the
       constraint had been mis-stated as a technique.
  **Unproven where it matters: nobody has LISTENED across the seam.** The gain is the card's on both
   sides (`Ra_source_pcm` bakes `10^(card.gain/20)` for exactly this reason) so it should not step in
    volume, and the first continuation chunk ships its own `preskip` via `hp` as the browser path
     does — but "should not" is item 1 of this list, not a measurement.
3. **`Ra_stock_gc_cap` now actually evicts — and has not yet been seen to.** The cap is
    `Ra_stock_cap()` = **100 files per pub**; the shelf is at 20 and the conveyor adds ~4 per tour, so
     the eviction path could not be exercised tonight. It is the newly-live code with the sharpest
      failure mode (it deletes), so the first time a box crosses 100 is worth a look: `ls
       <music>/.jamsend/radiostock | wc -l` should plateau, not climb.
4. **⚠ THE CONVEYOR NEVER TURNS ON THE DAEMON — found at 05:45, unfixed, and it caps the shelf.**
    The shelf stocks once at boot and then sits flat forever. `/status` now carries the conveyor's own
     `.c` electrodes (`Stoker_dig` sets them; `/c` only dumps `sc`, so nobody outside a browser could
      read them), and they settle it in one number: **`tour_ago_s: null`** — `st.c.tour_at` is never
       stamped, so **`Stoker_tour` has never been called**, on any boot. That is a different fault from
        "it toured and found nothing", and it wants a different fix. Supporting reads: `Stoker` sits
         `watching` → `idle`, `stood=20 stock=20 fresh=20`, `Radio: off ("no web audio here")`,
          `picks=0 got=0 dup=0 bad=0` — every dig counter untouched, never incremented.
  **THE CAUSE, confirmed — it is the Book gate.** `Stoker_tour`'s only prod caller is
   `Swarm_share_beat` (`Swarm.g:1973`), and the beat's pump is started by `Swarm_share_up`, which
    `Stoker_ensure` gates with `if (!w.sc.w && …)` — a named Book run-world wears `w.sc.w`, and the
     gate exists so a Book never starts a wall-clock pump (Swarmation.g:1000, correctly). jamserve
      boots `B=Sounditron`, so **the world holding its Stoker reads `{"w":"Sounditron"}`** — one `/c`
       query, since `w` is an `sc` key. The gate is false, `Swarm_share_up` never arms, no beat, no
        tour. The 16 cards that DID appear are the Book's own muse stocking once, not a conveyor
         turning. (Ruled out on the way: the wrong-world Stoker miss — `stock_state`'s identical
          `rw.o({Stoker:1})[0]` finds it — and a throwing beat, zero `⨳ SHARE BEAT THREW` in fifteen
           boots. The earlier `ive_got` frames came from the station handlers answering a live peer,
            which needs no beat.)
  **⚠ CORRECTION (2026-08-08 midday) — the Book gate is only HALF of it, and a live tab proved it.**
   The owner's incognito `/BigSoundland` tab is the SAME Book (`boot_qualand({book:'Sounditron'})`)
    and its share beat runs fine — `⏳ Swarm_share_beat still running past 600ms (×101)` in its console.
     If the Book gate were the whole cause, a tab would be just as dead. It isn't, because a tab arms
      the beat by a SECOND path the daemon does not have: **`InvitePanel.svelte:55-57`, a UI
       component's `$effect`** calling `Swarm_share_up` directly. The daemon mounts no room chrome, so
        that path does not exist for it, and `Stoker_ensure`'s non-UI path (added 2026-08-06 precisely
         because UI-only arming was a race — Radio.g calls it "the worst kind") is the Book-gated one.
          **The daemon misses it twice.** Fixing only the gate is still the right move — it is the path
           meant to be authoritative — but do not expect the tab to have been proving it all along.
  **And note the shape**, because it is the second one found today: prod behaviour hanging off a
   MOUNTED FACE. §10.6 is the same idea from the other end — a face mounting work nobody watches.
   Ask of any pump: *does this arm because of what the machine IS, or because someone drew a panel?*
  **THE FIX, and why I did NOT apply it overnight.** The gate wants a third state: Book / browser /
   **prod-headless**. The minimal shape is a `.c` flag the daemon sets on the top House (beside
    `c.radio_w` and `c.humdinger`) and `Stoker_ensure` honours — invisible to Books and browsers,
     which never set it. But arming the share beat switches on `Ra_shuffle_cull` — *"check every
      Record in the shuffle Mag still has its source, and delete the ones that don't"* — **on the same
       night `deleteEntry` went live** (§10.3b). That is two newly-live deletion paths at once,
        unverified, pointed at the owner's music folder. Not a call to make autonomously at 06:00.
  **It is also a question, not just a bug:** should jamserve boot as a Book at all? The Book is a
   vehicle for settling, and it is dragging its test-safety gates into production with it.
  **Why it is not a regression:** the shelf was ZERO before tonight. This is a pre-existing gap the
   native fork made visible by giving it something to be measured against.
5. Unchanged from before: jamserve still boots vite in middleware mode (§5.3), and its Sounditron Book
    remains a vehicle, not a gate.

### 10.6 The glass was running on a box with no screen (2026-08-08, midday)

**The symptom the owner saw**, once every four seconds, forever, in `docker compose logs jamserve`:

    ▣⚠ Vyto watchdog: forced settle after 240 frames of unbroken motion — a cell never stopped
     moving (disp/drift pinned). Landing anyway.  { w: TheC { … wall_cuts: 23516, stir_n: 13041 … } }

**That warning is the watchdog WORKING.** Vytui counts unbroken motion frames and, past
 `MAX_MOTION_FRAMES = 240`, force-lands the springs rather than let a render pathology peg a thread
  (Vytui.svelte, the WATCHDOG comment — it is the fix for the freeze that used to stop a player's
   beat and read as "the Sounditrons stop talking"). The bug it is reporting is not in the renderer.
    **The bug is that the renderer is running at all.**

**The chain, four links, each individually sensible:**

1. `Daemonic.svelte` mounts every registered UI, on purpose — a Creduler acquire enrols each gen
    `.go` as a `watched:UIs` Pantheate-include and an include only deposits its methods when
     something MOUNTS it. Drop the loop and the whole spine silently never arrives. (Four UIs are
      registered on this box: `Pantheate-include`, `Lies`, `Story`, `Vyto`.)
2. `Sounditron.g` commissions the glass **unconditionally** — *"the glass is just what Sounditron
    does"* — and jamserve boots `B=Sounditron`.
3. **jsdom reports `document.hidden === false`.** Vytui has a hidden-tab path that jumps to target
    and settles synchronously without animating; the daemon never takes it. It takes the
     visible-resident-tab path: `requestAnimationFrame` — polyfilled in `main.ts` to
      `setTimeout(…, 16)` — springs, power-cell re-cuts, nine real-DOM faces diffed, into a document
       with no reader.
4. It never lands, because the daemon's grappled organs (Stoker levels, Session counters) churn
    every heartbeat, so the targets keep moving. 240 frames, forced settle, repeat. **23,516 wall
     cuts in 894s**, each an O(M²) half-plane clip.

**The fix, applied.** `Daemonic` now takes a FACELESS set — UIs this process registers but never
 mounts — defaulting to `Vyto`, overridable with `FACELESS=<csv>` (and `FACELESS=` mounts everything
  again, for comparing). Skipping *this* mount is safe in a way skipping a gen'd `.go` UI would not
   be: Vytui is a hand-written panel and the Vyto methods come from `Vyto.go` being **included**, not
    from Vytui mounting, so §1's load-bearing job is untouched. What stops is renderer-only —
     `Vyto_settle`/`yore_n`, and the measure pass that stamps `row.c.need_area`, which `Vyto_solve`
      already falls back without. Nothing the daemon serves reads either. `glass_done` latches on the
       commission dispatch, not on a mount, so Sounditron's own retry logic is unaffected.

**What it does NOT fix — the ghost half still turns.** The commission still stands, so every grapple
 bump still runs `Vyto_stir` → scan → fold → gang → relate → express → solve: **13,041 stirs in
  894s**, about 2.4 per crank tick. Turning that off means not commissioning the glass on a headless
   box, which means teaching `Sounditron.g` — a file the players' real tabs share — the difference
    between **Book / browser / prod-headless**. That is the *same third state* §10.5 item 4 wants for
     the share-beat gate. Two independent faults, one missing distinction: worth fixing once, as one
      idea, rather than twice as two patches. Owner's call.

**How to check it, rather than believe it.** `/status` now carries a `vyto` block, and the split is
 the point — `stir_n` is the ghost half, `wall_cuts` is the render half (bumped only inside Vytui's
  `build_cells`). Faceless and correct reads **`wall_cuts: 0` with `stir_n` still climbing**. The
   heartbeat prints a `▣ Vyto is RENDERING on a screenless box` line **only** when `wall_cuts > 0`,
    so its appearance is the alarm and silence is the reading.

**Measured, on the owner's box, across its own 900s restart** (2026-08-08 12:06 → 12:20). Instantaneous
 crank rate, not the cumulative average `/status` prints — the cumulative one climbs all boot and would
  flatter the change by itself:

| | before (glass rendering) | after (faceless) |
|---|---|---|
| ticks/s, instantaneous | **6.53** (783 ticks / 120.2s, twice) | **7.44** (335 ticks / 45s, ×5) |
| `wall_cuts` | 23,516 in 894s | **0**, flat over 4.5 minutes |
| `stir_n` rate | 14.6/s average | 19.8/s |

Confirmed a second way, at MATCHED uptime so the cumulative average is a fair comparison too: **7.16
 ticks/s at 825s, against 6.43 at 866s before** (+11%) — and `wall_cuts` still **0** after a full 900s
  cycle, so the renderer did not run once, not even at boot.

**+14% crank throughput**, and the ghost half sped up too — the stirs were competing with the renderer
 for the same thread. `commissioned: true` throughout: the glass still STANDS, which is right, because
  the commission is Sounditron's business and this change is only about who mounts a face on it.

**Note for whoever verifies next: `run.log` cannot show you the watchdog.** `say()` writes to the log
 file; the app's own `console.log` goes straight to stdout, so the watchdog line appears in `docker
  compose logs jamserve` and in NO boot of `run.log` — grepping the log for it returns 0 either way,
   before and after, which is the most convincing wrong answer available. Use the `wall_cuts` electrode.

**The transferable bit:** jsdom answers every "is anyone looking at this?" question with *yes*.
 `document.hidden` is false, `visibilityState` is `visible`, and every browser-side optimisation that
  hangs off them inverts on a daemon — the cheap path is taken in a tab and the expensive one on the
   box that can least afford it. Grep `document.hidden` before trusting a headless CPU reading.

### 10.7 The daemon could not RECEIVE either — one unarmed verb, both directions (2026-08-08, midday)

A sealed friend traded `ive_got` with the box every few seconds and the box held **zero `%MusuThem`**.
 Both sides looked healthy: `Pier` + `Peering` + `Friend` on the daemon, `seal at=7c0d0bfd grants=2` and
  `advertise piers=1 granted=1 told=1` in the tab's own ring, `Repli rx 0p/0KB tx 2p/24KB` in its console.

**`Swarm_share_up` is the rx registration, not just the tx.** It calls `Repli_arm` and sets
 `repli_mirror_by_from` / `repli_mirror_w` — so unarmed, a friend's cast has nowhere to land.
  Radio.g:1281 already says it: *"it never registers an rx for the friend's cast — it can neither send
   music nor receive it, while looking perfectly healthy"*. That comment described this box exactly, and
    §10.5 item 4 had filed the same root cause under "the shelf doesn't grow" — too small a claim.

**Fixed in the daemon, not the ghosts.** `main.ts`'s `share_arm()` calls `Swarm_share_up` right after
 the station arms — the same verb `InvitePanel.svelte:55-57` calls in a tab. No new gate for the
  ghosts to learn; "this process is a daemon" is a fact out here, not a flag they must be taught. The
   Book/browser/prod-headless third state is still the right fix and still owed — it is just no longer
    in the way. **`Ra_shuffle_cull` is held off via its own throttle** (fresh `ra_cull_at` + absurd
     `ra_cull_floor_ms`), so the beat runs without a deletion path going live the same day as
      `deleteEntry`; `CULL=1` releases it. Nothing is patched out — the mechanism declines itself.

**Measured, one boot:** `share true` at 38s · `them 1` at 70s · `tour` no longer `NEVER` (every
 10–20s, `picks=2 got=2`, alternating `base=music`/`testsounds`) · shelf **20 → 40** with
  `probed=10 measured=10 encoded=10 failed=0` — ffmpeg transcoding real tracks live.

**New in the log, and the distinction it draws:** `🎧 serving <friendly>(<pub8>) ← <title> n/total
 (re×N) tx NKB/s`, read off `Repli_serve_want`'s own cursor (`top.c.xfer.serves`, Repli.g:817).
  Deliberately not change-gated and absent when idle — *a peer is connected* and *bytes are leaving
   for that peer* are different claims, and only the second means the box is doing its job.

**Still not proven: a track pulled from this box and heard.** `serve.live` is `[]` — nothing has ASKED
 yet. That is now the whole remaining gap. Also newly reachable for the first time: the shelf is
  climbing toward `Ra_stock_cap()` = 100, so `Ra_stock_gc_cap` will finally evict. Watch it plateau.

### 10.8 LOFI shipped originals for a day because its own validator was wrong (2026-08-08, afternoon)

The human, testing on a 12-year-old phone: *"even though the originals are opus, I want them
 transcoded again to ogg, as that's more compatible with players of the last 15 years"* — so the LOFI
  rendition became **Ogg Vorbis**, not Opus. Vorbis has been universal since ~2005; Opus needs a
   decoder from 2012 and, on hardware players, often later than that or never. **A rendition the
    destination cannot open is not a rendition.**

`level_to_ogg` grew a `codec: 'opus' | 'vorbis'` switch, `has_encoder('libvorbis')` guards the exec,
 and `ra_native.ogg()` answers `Orig_ogg_from_source`'s fourth question the way the other three are
  answered (§10.2). Then every single transcode failed:

```
⇊⚠ lofi transcode failed for 01 - … A Muey A Muey.opus — serving the original instead
  ↳ lofi encode A Muey A Muey: Ogg but no OpusHead at the usual offset — wrong codec?
```

**ffmpeg had done its job perfectly every time.** The structural check at the bottom of `level_to_ogg`
 asserted `OpusHead` at offset 28 *unconditionally* — so the moment the same function learned to emit
  Vorbis, it began throwing away its own correct output and reporting it as a failure. Now
   codec-aware: Opus writes `OpusHead` (RFC 7845 §5.1), Vorbis writes packet-type `0x01` then
    `"vorbis"` (Vorbis I §4.2), both at 28 because an Ogg page header is 27 bytes plus one lacing byte
     and an id header is a single segment.

**The lesson, which is not "I forgot to update a check".** A validator that hardcodes *one* of the two
 things its caller can now produce is a fault detector **for itself** — and it fails in the most
  expensive possible direction, because the log is loud, specific, technically accurate, and points at
   the encoder. The bark named a real property of the bytes and still sent everyone to the wrong
    place. Sibling of [[comments-assert-unmeasured-properties]]: the assertion was true when written
     and nothing re-checked it when the world moved.

**Not a second gate, checked:** `Heist.g:1305` only tests that bytes came back, and `Heist.g:490`
 already derives the `.ogg` name from `lofi` itself — which is the correct extension for Vorbis, where
  it would have been mildly wrong for Opus. One fix, whole path.

**Unverified:** no ffmpeg in the claude container, so this was fixed by reading and lands on the
 daemon's next 900s restart. The tell that it worked is `⇊♪ lofi: … → ogg128` where the `⇊⚠` used to
  be, and `failed=` in the heartbeat's ffmpeg counters going flat.

## 11. The GC debt — tab-lifetime state hygiene in a process with no lifetime (2026-08-14)

**The arc.** This codebase's garbage collector was the page reload. `.c` "dies on reload" was never
 just a serialization rule — it was the cleanup strategy: every leaked ref, stale want and grow-only
  cache had a bounded life because a human closes the tab by evening. The daemon is the first process
   here with **no lifetime**, and it inherits every mint that assumed one. Worse, the squeeze: the
    one remaining amnesty (restart) is both expensive (~46s standup through vite middleware, §5.3)
     and lossy (keep-ids wiped, live listeners dropped) — so the tool that used to bound every leak
      is now the tool to avoid.

**Measured, 2026-08-14.** Four `%parked_want`s parked 5–15min after boot — during that morning's
 keepalive flap window (every prod tab tore its socket every 20s until the same-day `LiesLies.svelte`
  fix) — then barked `◈⚠ transcode STALLED` every 10s for six hours: ~7,500 log lines about four
   immortal particles. A want is removed only by being served (`Repli_serve_parked`); nothing culls
    one whose transcode wedged or whose asker left. `w.c.repli_casters` is append-only
     (`Repli.g:502`). The state doesn't multiply — it *resonates*: tiny particles, unbounded noise,
      plus real pump/admission work spent on ghosts every pass.

**What is already bounded — don't over-panic this list.** Swarm Piers are `oai` by prepub (one per
 unique friend, reconnects reuse). The editor-side roster GC is real (beacons consumed, ephemeral
  runners forgotten, transport Piers reaped at PIER_CULL — `LiesLies.svelte` roster fold) but it is
   editor machinery and never runs on the daemon. The pcm belt is capped with an admission budget,
    `ra_hot` caps at 4, trace rings at 300, Berth compacts at 64 parts, and docker rotates jamserve's
     log at 5m×2. And the whole **consumer half never runs here** — the conveyor never turns
      (jamserve wears `w.sc.w`), there is no AudioContext, so radiostock draws, spins and
       listening-side pcm simply don't accrue. Serve-only by *incapacity*, though — the §5.2
        declaration ("don't feed me radio") is still owed, so a peer can still waste bandwidth
         aiming a radio at it.

**The rule to build toward, one sentence:** anything minted on behalf of a peer carries that peer's
 lease, and a sweep evicts what outlives its lease — piers, wants, caster registrations, beacons.
  First concrete target: cull a `%parked_want` (and the `repli_casters` entry) whose pier has been
   silent past a window, the serve-side twin of the roster fold's transport reaper. Second: decay the
    L3 bark (10s → ~60s after ten minutes) so a genuinely wedged encoder stays legible without
     flooding. Watchdogs here bark but nothing reaps — in a tab the human is the reaper; the daemon
      needs the next rung of the ladder to act, not report.
