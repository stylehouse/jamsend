# Migration handover — moving this Claude+jamsend setup to a new computer (2026-08-02)

Written by the docker-based Claude instance for the human + whatever fresh Claude session boots on
 the new machine. The goal: nothing load-bearing gets stranded on the old box. Read `## 0.` first.

## 0. What a fresh session should get on with

The live thread when this was written is **the KeepFace remount bug** (§5A) — it's one signal from
 root cause, with the confirming instrumentation already in the tree. Second is **standing up
  `scripts/pw_drive.mjs`** (§5B) so debugging stops needing a human to reload tabs and paste console.
   Everything else (§5C Repli fragile link, §5D pong/pulse noise) is filed and deferrable.
   **HOW to iterate without a human reloading tabs + copying console — read the next section first.**

---

## The self-serve debug loop (relay-free, no browser — the important bit)

The "Claude in a container can't see the browser" problem is already solved by two built-in pieces —
 no Playwright, no CDP, no human copying console. Reach for THIS before a browser driver:

1. **Observe — push marks to the on-disk trace ring.** `Radio_trace(radio, {ev:'…', …})` (`Radio.g:65`;
    `radio` may be `null`) appends a `{t, ev, …}` mark to `top_House().c.supply_trace` (a `.c`-only ring,
     capped 300). `Lies_dump_supply` (`LiesLies.svelte:1197`) flushes that ring to
      `wormhole/_trace/<role>-<pub>-<boot>.jsonl` every ~5s over the **FSA** path — keeps working when the
       relay is down or the CPU is pinned. `/app` is bind-mounted, so I read the file directly.
      - From a `.svelte` (Radio ghost not guaranteed mounted) push straight to the array:
         `const M = H.top_House(); (M.c.supply_trace ||= []).push({t:Date.now(), ev:'…', …})` (cap 300).
         Vytui's `show_viewport` toggle already does this (`ev:'vyto-show-toggle'`, see §5A).
2. **Arm the dump on the tab** — boot `?watch` (or `?socklog`, or the 🪪 Id-hatch socklog toggle).
    Without it `Lies_dump_supply` no-ops. Only editor/runner roles dump; the bug tab is a **runner**.
3. **Read it off disk** — `node scripts/tracelog.mjs --watch` (live tail, prints only NEW marks;
    `--list` = dump files w/ role·pub·boot·age, `--heist`/`--file <p>` filter). Format matches
     `runner_ask world` on purpose, so disk-view and relay-view read identically.
4. **Remote-reload after a code edit** — `node scripts/runner_ask.mjs reload --runner=<pub>` (LiesFunk
    reload op → `location.reload()` after 400ms). **Runner tabs ONLY** — it refuses an editor tab so a
     machine can't reload the human's live work out from under them. This is the long-wished "reload it
      for me", and it already exists. (HMR applies plain edits live; a `<script module>` change forces a
       reload — use this after those.)

**The loop:** edit → `runner_ask reload --runner=<pub>` → `tracelog.mjs --watch`. No browser, no human.
 Caveat: the ring is capped 300 and the file is OVERWRITTEN each flush (per-page-life), so it holds the
  last ~300 marks — push **sparingly** (one mark per event, never per frame).

---

## 1. The topology — what lives where, and what travels how

| Thing | Where it lives now | Travels to new machine by… |
|---|---|---|
| **The repo `/app`** | host ZFS `home_q37sgj`, bind-mounted `.:/app` into both containers | git **only if committed**, else copy the working dir wholesale (rsync). Uncommitted work is NOT in a clone — see §2. |
| **Claude's memory + auth** | docker **named volume `claude-auth`** → `/home/node/.claude` (on `rpool/var/lib/docker`) | does **not** follow a repo clone. Copy the volume (§4), or rely on the raw digest in `spec/ulative/memory-raw/` (205 files, committed with this doc). |
| **Secret env files** | host `/app/*.env*` (gitignored; masked from the claude container) | copy by hand (§3) — a clone won't carry them. |
| **Browser profiles (Brave+Chrome)** | host `~/.config/…` (NOT in the repo) | copy the profile dirs (§6) — this is where the p2p identities live. |
| **Music library** | host `${MUSIC_PATH:-/home/s/Music/71mix/}` → `/music:ro` | put music at that path on the new box, or set `MUSIC_PATH`. |

## 2. Uncommitted work that MUST travel (a `git clone` drops all of this)

At handover, `git status` on `main` (HEAD `7229106e`) showed these **uncommitted** — commit them or
 copy the working tree, or they're lost:

- `src/lib/O/ui/KeepFace.svelte` — remount instrumentation (§5A).
- `src/lib/O/Vytui.svelte` — remount instrumentation (§5A).
- `src/lib/O/spec/Download_stall_handover.md` — new "NEXT — reload-recovery gap" section (§5C).
- `scripts/pw_drive.mjs` — **untracked** new file, the Playwright driver (§5B).
- `package.json` + `package-lock.json` — playwright added as a devDependency (so `npm install` on
   the new box pulls it; then `npx playwright install chromium` for the browser binary).
- `src/lib/O/spec/ulative/` — this handover + the raw memory copy (untracked, new).
- `docker-compose.yml` — modified (pre-existing to this session; check whether it's yours).
- Several `wormhole/**/toc.snap` — **live-tab churn, NOT edits.** Leave them / `git checkout` them.

## 3. Secret env files to copy by hand (gitignored, not in a clone)

From the compose file, these are real files on the host that the containers read and a clone won't
 have. Copy each from old→new host:

- `.env.local` — Vite `ALLOWED_HOSTS`; **`up` errors without it** (`cp .env.example .env.local` if
   starting fresh).
- `.env.cluster-pubs` — PUBLIC cluster trust pubs (relay gen_write verify + VITE bake).
- `.env.cluster-claude` — the CLI's cluster **signing key** (masked from `app`, read by `claude`).
- `ty/.env.chrome-profiles`, `ty/droidlounge/.env.chrome-profiles` — your chrome-profile config
   (masked from the claude container; the host copies are the real ones).

Without the cluster env files, cluster trust is un-minted — the relay warn-and-allows, and the editor
 can re-mint via "🪪 Set up cluster trust", but existing signed identities won't line up.

## 4. Carrying Claude's memory (the `claude-auth` volume)

Two options, use both for safety:

- **Native (complete):** copy the docker volume. Its data is at
   `rpool/var/lib/docker/volumes/<project>_claude-auth/_data/` (or `docker run --rm -v
    <vol>:/v -v $PWD:/out alpine tar czf /out/claude-auth.tgz -C /v .`). Restore into the new
     machine's `claude-auth` volume the same way. This carries auth + session history + all 205
      memory files intact, so the fresh session boots with memory already loaded.
- **Repo digest (reliable fallback):** `spec/ulative/memory-raw/` holds a byte copy of all 205 memory
   files (incl. `MEMORY.md`, the index). Even if the volume is lost, a fresh session can read these.
    To re-seed the new volume, copy `memory-raw/*` into `/home/node/.claude/projects/-app/memory/`.
     (Auth won't be there — just re-run `claude` and log in.)

## 5. Live work threads (the load-bearing state)

### 5A. KeepFace remount — ONE signal from root cause

**Symptom:** the Heist/Keep glass cell (`KeepFace.svelte`, rendered through the Vyto glass) tears
 down and remounts repeatedly; the "directories editor snaps shut" as you type in it.

**Proven so far (with instrumentation now in the tree):**
- It is a **real teardown**, not a phantom effect re-run — the lifecycle-true `◈◈ REAL mount/destroy N`
   serial climbs. (The old `◈` `$effect` tell was a lie: it read the `n` prop so it re-fired on every
    dep bump; REMOVED, along with its 22k-line `console.trace`.)
- **Ruled out:** cell-field flip (the `◈ Vyto GATE FLIP` probe stayed silent → key/face/source/
   departing/hasKids all stable); cell omission from the keyed `{#each}` (`◈ Vyto CELL LEFT each`
    never fired → the key never leaves the each); `<svelte:boundary>` (read the Svelte 5.28.6 source:
     the child is `branch()`-created once, only re-created on an error-reset, and no `onerror` is
      wired); **Vytui itself remounting** (`◈ Vyto CELL ENTERED each` fired *once*, not per-cycle —
       and since that detector's map lives on the Vytui instance, it would fire every cycle if Vytui
        remounted → Vytui is stable, the churn is *inside* it).
- **Leading hypothesis (unconfirmed):** the outer **`{#if show_viewport(w)}`** that wraps the whole
   `.stage` (svg + faces + every KeepFace) is toggling false↔true on Housing ticks, tearing the stage
    down and rebuilding it — invisible to every cell-array probe because `build_cells` keeps emitting
     the cell regardless. Likely driven by the fold/`row.c.T`-null churn (`Vyto.g:360, 392`) making
      the mirror transiently all-`departing`/empty, or `w.c.commission` flickering.

**Instrumentation left in the tree (ALL diagnostics — REMOVE once fixed):**
- `KeepFace.svelte`: `<script module>` `__kf_serial` + `onMount`/`onDestroy` `◈◈ REAL` tell.
- `Vytui.svelte`: `<script module>` `__vytui_serial` + `onMount`/`onDestroy` `▣▣ Vytui REAL`;
   `show_viewport()` split into a `▣ show_viewport TOGGLE` logger + `show_viewport_calc()`;
    `lastGateByIdent` `◈ GATE FLIP` probe (in `layout`); `lastKeepEmit` `◈ CELL LEFT/ENTERED each`
     detector (end of `build_cells`).

**Next move (fully self-serve — uses the loop above):** the `show_viewport` toggle now also pushes a
 `vyto-show-toggle` mark into `supply_trace` (fields `to`/`comm`/`rows`/`live`), so:
   1. arm `?watch` on the bug tab, 2. `node scripts/runner_ask.mjs reload --runner=<pub>`,
    3. `node scripts/tracelog.mjs --watch` and look for `vyto-show-toggle` marks.
 If they appear at the remount cadence → the stage `{#if}` IS the teardown; `to=0` marks are the
  tear-down half and `comm`/`live` say why it flipped (commission dropped, or all rows went departing).
   **Fix then:** stop the stage `{#if}` tearing down on a transient false — gate it on a stabler
    predicate, or stop `Vyto_fold_scope` nulling `row.c.T` mid-stir (`Vyto.g:360, 392`) so the mirror
     never reads momentarily all-departing/empty. If the marks do NOT appear (no toggle), the remaining
      suspect is the faces `{#each}`/`$.component` dynamic block itself — chase that next.

### 5B. Playwright driver — `scripts/pw_drive.mjs` (FALLBACK to the disk loop)

The disk loop above is the primary channel; reach for a browser only for what a disk mark can't carry
 (pixels/screenshots, real DOM clicks). Two modes:
- **ATTACH (preferred)** — `--cdp=<url>` connects over CDP to the human's ALREADY-RUNNING desktop
   Chrome/Brave (real profile, real p2p identity, the live bug already on screen); I can read console,
    `--reload` the tab, `--goto=` navigate, screenshot — without launching anything. The human exposes
     it once (see the script header: relaunch browser with `--remote-debugging-port=9222
      --remote-allow-origins=*`, then `socat` the loopback port to `172.17.0.1` so the container reaches
       it). Security: the debug port = full control of that browser; keep it on the docker bridge, not a
        LAN interface, and tear it down after.
- **LAUNCH own chromium** — installed this session (playwright 1.62.1 + bundled chromium); flags bypass
   AC/getUserMedia and force `172.17.0.1` secure. **BLOCKED in the claude container** (20 missing system
    libs, non-root — see below); works from host node or a deps-added image.
- `node scripts/pw_drive.mjs /BigSoundland 12` — boot, watch 12s, probe (.vyto cells, faces), shot.
- `… --grep=KeepFace` — only console lines containing the string.
- `… --head` — headed; `--url=ORIGIN` to retarget.
- **BLOCKED — won't run inside the claude container yet.** The chromium binary needs 20 system libs
   (`libglib-2.0.so.0`, `libnss3`, `libatk*`, `libgbm1`, `libasound2`, …) the `node:22-bookworm-slim`
    image lacks, and the container runs as **uid 1000 (non-root)** so I can't `apt-get` them live.
     **Remedy (do on the new machine's build):** add to the `claude` service's inline Dockerfile in
      `docker-compose.yml`, after the `npm install -g @anthropic-ai/claude-code` line:
      `RUN npx -y playwright@1.62.1 install-deps chromium` (runs as root at build time), then
       `docker compose build claude && docker compose up -d`. Playwright's own image
        (`mcr.microsoft.com/playwright`) as a sidecar is the alternative.
   **Immediate alternative (no rebuild):** run `pw_drive.mjs` from **host node** (where Brave/Chrome
    already provide the libs) against `http://localhost:9091` — `node scripts/pw_drive.mjs
     http://localhost:9091/BigSoundland 12`. The human can do this today; only the in-container path
      needs the deps.
- **First successful run should confirm:** title, `crypto.subtle=true`, non-zero `.vyto .cell`. Open
   question: which URL/state puts a `%Keep` in the glass in a fresh browser — `/BigSoundland` alone may
    not; may need a Book (MusuHeist) or a minimal Keep-mint flow, since the "Zero Point" Keep came from
     the human's live p2p session.

### 5C. Repli reload-recovery fragile link (deferred)

Filed in `Download_stall_handover.md` → "NEXT — the reload-recovery gap". A stops sending NEW music
 after B reloads because the epoch (`station_era`) resync rides a single fire-and-forget `swarm_hi`
  (`Peeroleum.g:382`) whose only retry is defeated by `heard_at` warming. Fix direction: piggyback
   `station_era` on the `pulse` heartbeat + run the era-change reset+re-offer on hearing a pulse.
    Core p2p seam — prove on two live tabs (now doable with `pw_drive.mjs` two-context) before trusting.

### 5D. `pong`/`pulse` "no Pier — DROPPED" log noise (new todo, look-into-later)

The human flagged these as silly:
```
🛰⚠ deliver: no Pier for pong  seq=73 from=editor    to=runner    — DROPPED
🛰⚠ deliver: no Pier for pulse seq=66 from=56fbce44  to=56fbce44  — DROPPED
```
`Peeroleum_deliver` (`Peeroleum.go:599`) is trying to deliver a `pong`/`pulse` to an identity with no
 established `%Pier` and dropping it. The `pulse` case is self-addressed (`from==to==56fbce44`) — a
  heartbeat to itself with no Pier, which looks like a routing/registration gap, not a real send.
   Likely harmless noise but worth: (a) not logging a WARN for a self-addressed or expected-Pierless
    frame, and (b) checking whether a genuine `pong` is being lost (it correlates with the §5C epoch
     staleness — a stale/missing Pier). Related: `[[reconnect-epoch-seq-collision]]`,
      `[[roles-divide-addresses-deliver]]`.

## 6. Transporting your Brave + Chrome profiles

On Linux, Chromium-family browsers keep profiles under **`~/.config/`**, *not* `~/.local`:
- **Chrome:** `~/.config/google-chrome/`
- **Brave:** `~/.config/BraveSoftware/Brave-Browser/`
- (Chromium: `~/.config/chromium/`.) If you launch with a custom `--user-data-dir` (your
   `ty/.env.chrome-profiles` suggests you might), copy *that* directory instead.

Copy the **whole** browser dir (or a single-profile subdir like `Default` / `Profile 1`) old→new host
 with the browser **closed** (a running browser holds locks and will overwrite on exit):
```
rsync -a ~/.config/BraveSoftware/Brave-Browser/  new-host:~/.config/BraveSoftware/Brave-Browser/
rsync -a ~/.config/google-chrome/                new-host:~/.config/google-chrome/
```
What this preserves for jamsend: the **p2p identity** and app data for the `localhost:9091` origin
 (the ed25519 keypair / `.jamsend` account, IndexedDB, OPFS, LocalStorage) — these are plaintext
  LevelDB/OPFS inside the profile, so they copy cleanly and your friend-seals/cluster identity survive.
   **Caveat:** saved *passwords/cookies* are encrypted with the OS keyring ("Safe Storage" via
    gnome-keyring/kwallet); those won't decrypt on the new box unless the keyring moves too — but the
     app's own storage above is unaffected. Match the browser **version** on the new box (an older
      browser may refuse a newer profile's schema).

## 7. New-machine bring-up (order)

1. Get the repo onto the new host **with uncommitted work** (rsync the working dir, or commit §2 first
    then clone).
2. Copy the §3 secret env files.
3. `npm install` (pulls playwright too), then `npx playwright install chromium`.
4. Put music at `MUSIC_PATH` (or edit it in compose).
5. `docker compose up -d` (app on :9091). `docker compose exec claude claude` to attach a session.
6. Restore browser profiles (§6), reopen the :9091 tabs — cluster identity should line up.
7. (Optional) restore the `claude-auth` volume (§4) so memory carries; else the fresh session reads
    `spec/ulative/memory-raw/`. Re-run `claude` to re-auth regardless.
8. Resume §5A: run `pw_drive.mjs`, read the `▣ show_viewport TOGGLE` line, fix the stage teardown.

## 8. The most load-bearing memory lessons (full set in `memory-raw/`)

For a fresh session that can't load the volume — the handful that bite hardest:
- **Never stage/commit/push** — the human commits (CLAUDE.md).
- **Verify via a LIVE runner, never headless `Story_cli`** (jsdom quiesces at the wrong depth). A real
   browser via `pw_drive.mjs` is fine — it's the same engine as a human tab.
- **`.g` edits:** compile via `npm run ghost-compile -- <file.g>` / `scripts/LocalGen.spec.ts`.
   **`.svelte` edits:** bundle-fetch compile proof
    (`fetch('http://172.17.0.1:9091/<path>.svelte').then(r=>r.text())` → check no `CompileError`).
- **Don't run a Book on the human's live tab** (`become_book` hijacks their session).
- Address the user as **"the human"**; use they/them.
- **Testing/utilities are Books**, logic folds into **`.g`** (LangTiles DSL over raw JS); `lib/mostly`
   is legacy/out-of-bounds; new UI in `O/ui/`.
- **The one bet + posture:** `spec/Homethink_todo.md`; the belief-loop mechanics: `spec/Coding_guide.md`.
- The human runs **HIGH autonomy** — run the queue, don't check in for permission on safe work.
