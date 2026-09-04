# V1 cut — what ships, what waits, what needs your word

*Opened 2026-08-11, from the owner: "is it reasonable to attempt the credentials FSA for v1.0?
 there's a bit else to do huh…" — and, the same night, "§0 is such sludge… no idea what asking."*

---

## 0. How to read this

`Radio_todo` §0 and `Supervisor_todo` §0 are between them **3,268 lines of reverse-chronological
 diary** holding **~51 open decisions** (23 in Radio, 28 in Supervisor) and **~50 open work
  items**. That is the sludge, and it is why nothing reads as an ask. This file is the triage on
   top of them: **five questions**, a ship-blocker list, and an explicit cut list. Nothing here is
    new work — it is the same backlog, sorted by *whether v1.0 can ship without it*.

**The 51 collapse to 5.** They are not 51 independent choices: **~20** are one question wearing
 different hats (*what does a granted music folder look like to the app* — the wormhole shape and
  its four sub-questions, the stash's composition, where each kind of write goes); **~12** are
   radio-feel defaults I can pick and you can veto on hearing them (skip-restores-mid-track,
    re-arrival after a friend returns, the warm-window/dial disagreement, the heard-set collision,
     retry policy on a hopeless decode); **~9** are editorial and mine to do (folding this diary,
      moving discovery findings to `Composition_todo`, re-recording drifted fixtures); **~5** are
       blocked on threads already cut from v1.0 (follower player, wire crypto, two-runner Books).
        That leaves the five below, which genuinely gate the release and genuinely need you.

Provenance is marked, because it matters which claims were measured: **[today]** = verified
 2026-08-11 by reading the code or the live tabs; **[doc]** = asserted by the §0 diaries, not
  re-checked; **[memory]** = carried from an earlier session.

Answer §1 in a word each. §2 is mine to get on with meanwhile.

---

## 1. Waiting on your word

**Status, morning of 2026-08-12 — read this and you have the night.**

**Built and verified:** Q1 (credentials can leave the share), Q2 (the mount table + the app tree
 composed under a granted share, lazily filled — checked against real github), Q5 (the download
  ledger). **Q4 is withdrawn as doc noise** — worth reading as a specimen of §0 manufacturing a
   decision nobody asked for. **Q3** (do watches outlive their Book) is the only open question, and
    nothing is blocked on it.

**Also fixed overnight, and it was a regression of my own making:** both your players had silently
 lost two Supervisor watches (9 where there had been 11). Last night's come-back fix made standup
  ~3s faster, so it started winning a race against the Supervisor world's creation, and two watches
   that only ever register at standup registered nothing at all. `Swarm_watch_repair` (Swarm.g)
    re-registers them from the watch loop. Both tabs 9 → 11 with no reload. **A fix that makes
     something happen sooner can turn a latent ordering assumption into a live one.**

**Three things want your eye, none of them a question:**
1. the **un-swept old key copy** under Q1 — deleting key material, so it wants your yes;
2. **`npm test` is red at baseline** (§7) — 15 of 20 files, environmental, not a regression, but
    somebody should decide whether to fix the config or delete the stranded specs;
3. **VytoCrush** (§6a–6c) — two stacked defects, one of them a real find about the Story drive that
    reaches well beyond Vyto. **It is blocked on you**: see §6c.

**Fixture coverage turned out to be a non-issue** (§7a) — 136 Books carry a toc, exactly ONE is
 hollow, and two of the six "hollow Books" in the handover were never Books at all. That item can
  come off the list.

### Q1 — ✅ LARGELY ANSWERED 2026-08-11: the stash is a MOUNT, not a mode

**The owner, closing Q1 and Q2 with one mechanism:** *"I kinda addressed Q1 and Q2, making virtual
 wormhole/ that isn't on disk and virtual .jamsend at another share, but seeming to be there with
  the one unified w:Wormhole interface."*

That dissolves the expensive part of the stash. There is no second MODE to persist, no
 `MyJamsendData` convention to teach, no separate "open stash" flow to sequence against onboarding
  — **`.jamsend` is simply a mount that can point somewhere other than the music folder**, resolved
   through the same unified `w:Wormhole` namespace as the virtual `wormhole/`. One mechanism, two
    problems. The three cures I costed below are superseded: this is a better (c).

**The default — ✅ RULED 2026-08-11, and built overnight.** The owner: *"`.jamsend` defaults to in
 the music share, but we could put it in a credentials store location… after they open the first
  share the first time there'll be a 'store account data here' tickbox that's checked by default,
   and unchecking it reveals another 'open folder' button."* So: **default stays in the share, the
    way out is an explicit grant.** (My OPFS-by-default recommendation is withdrawn — it trades the
     leak for a recovery story the owner does not want to lose, and the owner is right that being
      asked is fine: *"we're beyond okay with asking them if they want another place to store
       credentials."*)

**What landed [today]** — `Housing.svelte.ts` `DirectoryOpener` + `Wormhole_mount_creds`:

- a **second FSA handle**, same Dexie handle table, key `<House>:creds`; restore is silent and
   picker-free at boot, and a `'prompt'` permission means *not yet*, never *gone* (the same care
    the main share already takes — that bug cost people their share on every browser restart).
- a **`🔑 Credentials folder` action** beside `📂 Open directory`. An action, not a face, because
   `showDirectoryPicker` only works inside a real gesture and that seam already speaks actions.
    Re-tapping re-points the mount, which is how someone *moves* their credentials.
- **only the keyed paths move.** `.jamsend/account` and `.jamsend/identities` (`Swarm.g:2875,2877`)
   mount to the chosen folder; `.jamsend/radiostock` (multi-GB decoded audio) and `.jamsend/berth`
    (landed downloads) stay beside the music, where they belong. Longest-prefix mounting is what
     lets those two verdicts coexist under one `.jamsend/`. The chosen folder gets a bare
      `account/` + `identities/` — *"a directory just for this app"*, not a hidden dot-dir.

**Still owed, deliberately not done unattended:** granting a folder does not *remove* the account
 snap already in the music share. Sweeping the old copy is deleting key material — it wants an
  explicit yes and a face to ask it in. And the tickbox itself is still presentation: today the
   action is simply always offered, which reaches the same security outcome with less state.

<details><summary>the original three-way question, kept for the record</summary>

#### Q1 (superseded) — The credentials leak. How do we close it?

The threat is real and I confirmed the mechanism **[today]**: `Swarm_export` folds the **private
 key inline** into the account snap (`Swarm_snap_keyed`, two hex scalars on the Identity root
  line), and `Swarm_account_save` writes that file to `<share>/.jamsend/account/<prepub>/toc.snap`.
   Its own header calls itself a landmine, safe only while three invariants hold — and the one you
    named ("other ways to share your music") breaks invariant 2 *from outside our code*. A synced
     or copied music folder ships a usable signing key. **This is a ship-blocker; the only question
      is the cure.**

| | cure | what it costs | recovery on a new browser |
|---|---|---|---|
| **(a)** | the stash as sketched — a second FSA, `MyJamsendData` | a mode with nowhere to persist on a fresh browser · a user-created directory (you called it naff) · migration of already-written keys · must compose with the **unbuilt** prosthetic wormhole (Q2) · lands on the onboarding path where step 4 does not exist | automatic, if they granted the stash |
| **(b)** | encrypt the on-disk key with a passphrase | passphrase UX in onboarding · WebCrypto + versioned file format · a "forgot it" story | automatic + passphrase |
| **(c)** ⟵ **my recommendation** | key lives in the browser (Dexie) only; the share keeps a **redacted** account snap (identity, friends, grants — no key); recovery is an explicit **"save my account file"** the user puts where they like | stop the auto-write · redact the snap · wire the existing `Swarm_export`/`Swarm_import`/`Swarm_boot_seed` to a save/open-file gesture · delete keys already written | only if they saved the file |

**Why (c) for v1.0:** it is the smallest change that makes the leak *impossible* rather than
 *guarded*, it needs no second persistent grant, no invented directory, and no answer to Q2. A
  save-file picker is one gesture, not a standing capability. The code's own landmine note offers
   exactly two cures — "encrypt, or move the key back to Dexie-only" — and (c) is the second.
**What (c) gives up:** a user who never saved the file and wipes their browser loses the account.
 (b) can be added on top later without redoing (c); (a) cannot be reached from anywhere cheaply.

> ~~Answer with: (a) / (b) / (c).~~ — superseded by the mount ruling above.

</details>

### Q2 — ✅ ANSWERED 2026-08-11: MOUNTS, lazily filled from github

**The owner's ruling, verbatim-close:** *"Wormhole needs to know mounts, so we can move wormhole/ to
 .jamsend/wormhole and prefill it… we don't want to have to wait for real files to write there
  though (each Sounditron step), perhaps they could lazily load from github? we already have a
   Wormhole backend for that."*

So it is neither of the two shapes I offered: **the nav learns a MOUNT TABLE.** `wormhole/` mounts
 at `<share>/.jamsend/wormhole`; it is *prefilled lazily* from the OPFS-github backend that already
  exists (`is_opfs_github`, `WormholeOpfs.svelte.ts`) rather than eagerly written, because an eager
   materialise makes every Sounditron step wait on real file writes. Mount + lazy fetch +
    write-through.
**And a correction to how this was framed** (the owner): *"granting your music folder replaces the
 app's own wormhole/ — not accurate; the app really wants a music folder, is in development being
  fed the repo which has wormhole/."* There is no app-owned wormhole being displaced. There is ONE
   nav; in development it is the repo, which happens to carry both `wormhole/` and music. The
    dev arrangement is the accident, not the user's folder.
**What landed [today]** — `src/lib/O/MountNav.svelte.ts` + the seam in `Housing.svelte.ts`:

- **`MountNav`** — one wormhole namespace over several backends. Longest-prefix mounting, each
   method one rebase + one delegation, `inner` to say where inside a mounted backend the mount
    point really lives. A **wrapper**, composing `WormholeNav` / `OpfsOverlayNav` /
     `RemoteWormholeNav` and editing none of them.
- **Wired at the seam**: `A.c.nav = new MountNav(new WormholeNav(DL), 'share')`. With no mounts it
   is a pass-through, so on the repo checkout the whole mechanism is inert — that is asserted, not
    hoped (`scripts/MountNav.spec.ts`, first test).
- **`app_tree_decision`** — the policy for *may we compose the app tree here*. Absence is believed
   only from a successfully expanded root that listed directories and had no `wormhole` among them;
    an editor boot is refused outright. **The dangerous direction is the false positive**: deciding
     "no wormhole here" on a share that has one would mount a github snapshot over the developer's
      real repo and send every Story write silently into OPFS scratch. Stale handles are a
       documented reality here (`_is_stale`, `mkdirp_fresh`), so one failed read must never read as
        absence.
- **Verified**: 18 unit tests; **12 mutations, each seen to go red** — including one that caught a
   test asserting less than it claimed (longest-prefix passed under first-match-wins because the
    test only registered the deep mount first). Live tabs reloaded through the wrapped nav and
     re-arrived clean, both players, `radio.shelf` and `sound.pulled` green — those are the reads
      that go through it.

**One defect this nearly shipped, worth knowing:** `Heist.g:689`, `Heist.g:3003` and
 `Heistation.g:414` probe `typeof nav.bin_append` / `bin_writer` / `read_range` **path-blind**, to
  choose a download strategy before they have a path to route on. A class method always answers
   `"function"` — so an un-narrowed wrapper would promise Heist a streaming landing and then
    silently no-op the append: every downloaded track a zero-byte file, nothing thrown. `MountNav`
     therefore presents the optional capabilities as the **intersection** over base + every mount,
      shadowing the method with `undefined` so `typeof` reads absent. Same law as
       `Housing.svelte.ts:2694` — *"the honest subset — no partial interface that pretends to
        stream"* — held one level out.

**The lazy fill — ✅ RULED AND BUILT 2026-08-12.** The owner: *"just the Sounditron toc.snap needs
 downloading initially, each step may only download if it wants diffing."* So the eager seed is gone
  from this path. `LazyGithubNav` (`WormholeOpfs.svelte.ts`): **one index, N lazy blobs.**

- a single git Trees call lists the repo — 1 request against the 60/hr API budget, not N — and it is
   persisted (`.tree_index.json`, keyed by ref+subpaths, so a changed ref invalidates it, which is
    also the staleness story asked for below).
- **listing is free.** `dir()`/`dir_at()` are answered entirely from that manifest and never touch
   the network, so a Story walk enumerates the tree without pulling any of it.
- a blob is fetched from the raw CDN only when something actually **reads** it, then stays in the
   OPFS seed. Concurrent readers of one path share a single fetch. Writes go to scratch and shadow
    the seed, so a file this app wrote is never re-fetched.
- stored as bytes, not `.text()` as the eager seeder does — text is lossy and this path can reach
   any file in the tree.

Verified by `scripts/LazyGithubNav.spec.ts` against a counted fetch stub, because *"it didn't
 download"* is the whole claim and is invisible in the returned value: reading one `toc.snap` pulls
  exactly one blob and leaves the sibling `NNN.snap`s on the server. **7 mutations, each seen to go
   red**; one caught a real bug — `OpfsOverlayNav.dir()` hands back an EMPTY listing until
    `.expand()` is called, and I was reading `.files` without it, so any file this app wrote was
     silently missing from every listing.

**Checked against real github, 2026-08-12** (the tests stub the network, so the network half was
 the one part that could be wrong in reality — and if the repo were unreadable the whole feature
  would fail silently for every new user):

| | |
|---|---|
| `stylehouse/jamsend` readable unauthenticated | ✅ 200 |
| git tree truncated? | **no** — 2,633 entries, so the manifest is complete |
| blobs inside `wormhole/` + `Ghost/` | **1,369** |
| `wormhole/Story/Sounditron/toc.snap` present | ✅, fetches in 5,318 bytes |
| github `main` vs local HEAD | **identical** (`3f76dd9a`) — you push, so a listener gets current Books |

So the ruling's saving is exact: **1,369 requests → 2** (one index, one blob) to reach the first
 Book. The eager `mount_opfs_github_nav` is deliberately **kept** for the no-share cloud path, which
  is going to read most of the tree anyway.

**The staleness story — a defect I nearly shipped, now fixed.** I first wrote this up as "still to
 settle", which was wrong: the obvious cache key is `ref + subpaths`, and the ref in use is `main` —
  a **moving** target. Keyed that way the key never changes as main advances, so a browser profile
   that indexed once would keep that manifest **forever** and never see a Book added after its first
    visit. Silent, permanent, and invisible in testing because a fresh profile always looks right.
 Fixed by resolving the ref to a **commit sha** (`head_sha`), making the key content-addressed: one
  cheap request per boot, one more only when you have pushed. It **fails soft** — offline or
   rate-limited (this is the 60/hr API, unlike the raw CDN) keeps whatever manifest was already
    there, because a freshness check that can take the tree *away* is worse than a stale one.
 ⚠ The eager `seed_from_github` marker has the **same ref-keyed shape** and is left alone on purpose
  (a note in the code says why): it is the no-share path, hundreds of blobs, and re-seeding on every
   push is a worse trade than re-indexing a manifest. It wants an incremental sha-keyed update.

**Still to settle:** whether writes under `wormhole/` go to disk immediately or stay in the lazy
 (OPFS scratch) layer — today they stay in scratch.

<details><summary>the original question, kept for the record</summary>

#### Q2 (superseded) — The prosthetic wormhole: materialise, or compose?

A listener who grants their music folder **loses the app's own `wormhole/`** (`A.c.nav` is one nav)
 **[memory + doc]** — so they run with ghosts from the bundle and no Books. Two shapes, from
  Supervisor_todo §0 L44–58: **(i) Materialise** — seed `wormhole/` into `<share>/.jamsend/wormhole/`
   from the OPFS-github cloud (needs a staleness story); **(ii) Compose** — a composite nav,
    `wormhole/` prefix → cloud, everything else → granted dir (needs a new nav class).
**My recommendation: (i) Materialise for v1.0** — it is your own leaning in the original wording,
 and it needs no new nav class on the critical path. Compose is the better end state.
Four sub-questions (mount under or beside · which root wins a collision · where each *write* goes ·
 how the cloud layer versions) were deliberately not guessed; **(i) collapses three of them**.

> ~~Answer with: materialise / compose.~~ — answered above.

</details>

### Q3 — Do watches outlive the Book that registered them?

Proposed but not built **[doc]**: an `eternal` flag on `Supervisor_watch`/`_dial` plus a
 `Supervisor_teardown(H)` from `auto_teardown_story`. It is a persistence-semantics call, not a bug
  with one right answer, and it touches `Auto.svelte`. **My recommendation: yes, add the flag** —
   a roster that accumulates dead watches reads green for things nobody is watching, which is the
    failure this whole subsystem exists to prevent.

> **Answer with: add the flag / leave it.**

### Q4 — `%Caper` or `%Pull`? (the owner: *"I'll need to be sold on again, we don't show the user any of that?"*)

**We do show it.** `CaperFace.svelte` is a real face — *"the Pirating flow in the glass, one face per
 %Caper"* — imposed by mainkey, styled pink in `Matstyle`, and you called it "the Caper glass"
  yourself on 2026-08-09 **[today]**. So the word is on screen, which is exactly why it needed
   explaining.

**What it means:** `%Heist` is the *decision* — the album you chose to take, sitting as a keep.
 `%Caper,at:<pier>` is the *job actually doing it*: original file bytes moving over Repli into your
  collection, through newlyadded probation and catalog dedup. Decision vs. the act. That is a real
   distinction and the glass shows both.

**My recommendation: KEEP `%Caper`** — reversing my earlier lean, on two findings. (1) `%Pull`
 collides head-on with Repli's own established vocabulary, where "pull" already means fetching
  bytes for a want (`the pull's from-address`, `pull its bytes on want`) — so the "plainer" name
   would make the glass *less* legible, not more. (2) The rename costs four Book re-records for a
    word whose problem is that it is unexplained, not that it is wrong.

> ### ❌ WITHDRAWN 2026-08-11 — this was never a decision
> **The owner:** *"I have no idea what Caper or Pull is. that's the Heist… what problem is there
>  with this? I think it's doc noise."* Correct, and the withdrawal is the useful part: **nobody
>   ever asked for this rename.** It entered the backlog as an offhand "what the heck is a Caper?"
>    on 2026-08-09, was written up in `Supervisor_todo` §0 as an open naming decision with a costed
>     four-Book price tag, and was then extracted and put back to the owner as one of five questions
>      gating v1.0 — by me, on 2026-08-11.
> **This is the sludge's actual failure mode, in one specimen.** A long §0 does not merely bury real
>  decisions; it *manufactures* them, because an aside written down in the register of a ruling is
>   indistinguishable from a ruling a year later. Weigh this when restructuring: the test for the
>    "waiting on you" list is not *did someone once wonder about this* but **does anything stop if it
>     goes unanswered**. Nothing stopped. `%Caper` stays, unexplained and fine.

### Q5 — ✅ ANSWERED 2026-08-11: keep a ledger of WHAT and WHEN, never WHO

**The owner's ruling:** *"yeah we want to keep list of things we downloaded… just the destination
 directory and when, not who it came from? easy?"*

**Yes, easy — it is one field, because two thirds of it already exist [today].** The ledger is
 already built and already honours the line: `newlyadded` is a Berth of `%Probation` cards, one per
  landed path, minted by `Heist_newlyadded_note` (Heist.g:3250). Each card carries `of` (the landed
   path) and `sc.dir` (the folder it landed under) — and Heist.g's own header states the design
    outright: *"the newlyadded log never names where music came from"*. So **destination: present ·
     source: already absent by design · when: MISSING.** The build is a timestamp plus a face to
      read it.

**One gotcha worth a minute before adding the field.** A wall-clock stamp on a snapped particle
 makes every fixture that sees it flap — the same defect a single live-presence line once put into
  a Supervisor probe. So either keep `at` out of the encoded `sc` (an `omit_sc` in the protocol,
   the way session keys are already stripped) or record a coarse date rather than a millisecond.
    That is a build detail; it does not touch the ruling.

**What this does NOT unlock:** the traffickers'-history half of `Heist_todo.md` stays shut — that
 half is about *who*, and the answer above is that who is not recorded.

**✅ BUILT 2026-08-11** — `Heist_newlyadded_note` (Heist.g:3258) now stamps `card.sc.at`, epoch
 seconds, once per path at first landing (the idempotent guard returns before it on a replay, so it
  means *when this landed* and never *when we last re-verified it*). Compiled.
 **No face, per the owner:** *"I don't want to see the %Probation yet though, it's beyond v1. it'll
  be a music player in time I suppose."* The record accrues now so the history exists when there is
   somewhere to show it. Nothing renders it.
 Fixture safety was checked rather than assumed: **no snap under `wormhole/` holds a `%Probation`
  card**, so the wall-clock value cannot flap a Book. If one ever does, strip the field with an
   `omit_sc` — do not delete it.

---

## 2. Ship-blockers I can take alone

Ranked. None of these need you.

1. **The prod compose runs a dev server [today].** `docker-compose.prod.yml:21` is
   `npx vite --host 0.0.0.0 --port 19091` — Vite's dev server, bound to every interface, serving
    the module graph and an HMR socket. And `docker-compose.yml:317` still defaults the control
     token to `jamserve-local` (`STATUS_TOKEN=${JAMSERVE_TOKEN:-jamserve-local}`). Neither is
      recorded in any spec; both were carried in memory from 2026-08-08 and re-confirmed today.
       **A build + preview server and a required token are the fix.**
2. **A radio that silently stops, "cured" by a skip [doc, live 3×].** The auto-skip in
   `Sounditron.g` is scaffolding over an unknown cause and must be deleted once it lands. I have a
    concrete lead from reading the pump today: `Radio_pump_tick` has **three early returns that
     kill the loop without rescheduling** (era mismatch · a non-playing state word · `!w || !AC ||
      !radio.c.aud`), and `Radio_nudge` explicitly refuses to restart a radio whose state word says
       `playing` — so a chain that dies while the word still reads `playing` is unrecoverable from
        inside, which is exactly the reported symptom. Next move: one electrode per exit.
3. **Onboarding step 4 does not exist, and steps 1–3 vanish on reload [doc].** Also: `landing`
   must become a **list** of discovered invites, and per-invite dismissal must ship *before* the
    stricter fulfilled=SEALED hold (order matters — the strict hold without dismissal strands people).
4. **Eight watches and four dials owe a mutation test [doc].** A green gate that has never been
   seen to go red gates nothing — one was already found to be theatre **[memory]**.
5. **Hollow Books [memory]:** Mine/Theirs have no fixtures; four Vyto Books are `dige:lie`.
   Their green is not evidence.

---

## 3. Cut from v1.0

Deferred deliberately, each with the reason — so this is a decision, not a backlog leak.

- **The stash as a second FSA (Q1a)** — superseded by Q1c if you take it; a mode + an invented
  directory + migration + a dependency on Q2 is a chain of unbuilt things on the newest path.
- **Compose-style prosthetic wormhole (Q2ii)** — a new nav class; materialise ships.
- **The follower player · wire crypto port · distributed two-runner Books** — all gated behind
  other threads **[doc]**; none is on the path a first user walks.
- **Every "worth a look" in the two §0s** — the mirror's 24-vs-16 count, the one-off `known`
  tick-down, the MusuHeist reporting bug. Real, small, not blocking.

---

## 4. Resolved since the diaries were written

- **The peer come-back**: 65–74s → ~3.5–5s, both directions, measured **[today]**.
- **The "open share" tap frequency** — the owner, 2026-08-11: *"openshare prompt prevalence is good
  now."* Supervisor_todo §0's two-fork diagnosis (L92–105) is **closed**; do not spend the console read.
- **The blank Butler card**, the empty-share fail-noise, play-next-from-start streaming it all.

---

## 5. Where the detail lives

The diaries stay authoritative for *how* each thing landed: `Radio_todo` §0 (streaming, the radio,
 the wire) and `Supervisor_todo` §0 (the roster, the Butler, onboarding). Both are due the
  treatment the human already ruled on 2026-07-12 — *§0 stays a brief, not a log*, with the diary
   moved to `spec/history/*_buildlog.md`. That move is queued and is pure editing; this file is the
    brief they should have been pointing at.

---

## 6. The hollow Books — three of six now gate (2026-08-12)

The handover's standing item: *"Mine, Theirs, VytoCrush, VytoDepth, VytoMemo, VytoNeed are all
 dige:lie or fixture-less. Six green gates that gate nothing."* Worked through overnight.

**First correction: `dige:lie` means NOT YET RECORDED, not "deliberately un-gated"**
 (`Musuation.g:6`: *"real seq, lie diges till a run records them"*). These Books had simply never
  been recorded. And they were not green — every step read `ok:0`, because with no recorded dige
   there is nothing to match.

**The procedure, and it must be determinism-first.** Run the Book twice, diff the per-step diges
 (`runner_ask steps`), and only `accept` if they agree. Accepting a churning step bakes in a fixture
  that flaps and costs someone an attribution session later.

| Book | outcome |
|---|---|
| **VytoDepth** | ✅ **recorded and gating** — 3/3, caveat 0. Deterministic across two runs, and the gate is **mutation-proven**: a wrong dige in the fixture takes caveat 0 → 1, the right one returns it to 0. |
| **VytoNeed** | ✅ **recorded and gating** — 4/4, caveat 0, deterministic. |
| **VytoCrush** | ◐ **diges recorded and gating**, but **3 of its 4 assertions are ABSENT** — all three step-3 claims. Investigated below. |
| **VytoMemo** | ✗ **left hollow on purpose.** Step 4 is *"hold the settled glass under forced repaints — the wall counter must stand still"*, and its dige **differs between identical runs** — it snaps a repaint counter, so it cannot be stable by construction. Reverted to its committed `dige:lie`. The fix is at the source (stop snapping the churning value), not in the toc. |
| **Mine / Theirs** | no fixture directory at all — untouched, still hollow. |

⚠ **Two traps, both hit tonight** (recorded as [[dige-lie-means-unrecorded]]): a runner **rewrites
 the toc after every run**, so a hand edit to a fixture is clobbered by the next run unless you
  `runner_ask reload` first — I lost the same edit twice before spotting it. And running any Book
   dirties `wormhole/Story/*/toc.snap` with TimeSpool samples, which is most of the wormhole churn in
    tonight's diff.

### 6a. VytoCrush's three absent assertions — narrowed to one measurement

`runner_ask assertions` — **declared 4, sworn 1, gaps 3**. All three gaps are step 3 (the FOLDED
 commission): `board-folded`, `crushed`, `crest-counts`. The one that swears is step 4, the **plain
  control** — *"commissioned plain the same twenty cogs draw twenty cells and no crest is minted"*.

**That pairing is the finding.** All three step-3 claims share the precondition `vw.c.folded`, and
 step 4 asserts `if (vw.c.folded) return 0` and passes. **A folded glass and a plain one are coming
  out identical** — the fold is a no-op, so the control cannot tell them apart and swears anyway.
 The step-3 snap agrees: 20 Cogs present (oak 8 · pine 7 · birch 5) and `req:fold_wait` still
  pending on a ttlilt — the 18-unit wait for `crushed_ready` simply timed out.

**Every link in the chain reads correct, and I checked each rather than assuming** (three of these
 were live hypotheses that turned out fine):

| link | checked | result |
|---|---|---|
| the fold's size gate `members.length > budget` | computed `budget_for(800,450)` from QUANTUM 118 / PACK 0.46 | **12**, and the rig has 20 — gate passes |
| `bucket_key_of` picks the partitioning key | ran the pure function against the rig's exact sc shapes | returns **`"genus"`**, groups `oak:8 pine:7 birch:5`, all ≥2 — exactly what the assertion wants |
| is `Vyto_fold` even called? | `Vyto.g:239` | **yes**, it is in `Vyto_stir`'s sequence |
| does the commission flag reach the world? | `Vytonation.g:566` → `Vyto.g:128` | `commission.sc.folded = 1` → `w.c.folded = req.sc.folded ? 1 : 0` — wired |

⚠ **Two comments in the tree are stale and will mislead the next reader**: `Vytonation.g:1435`
 (*"Vyto_fold is the display refactor's stub (uncalled)"*) and `Vyto.g:500` (*"`Vyto_fold` above
  stays a stub until…"*). It is neither a stub nor uncalled. Classic
   [[comments-assert-unmeasured-properties]] — and worth fixing while in there.

**THE ELECTRODE ANSWERED (2026-08-12).** A temporary Book-side stamp into VytoCrush's own world,
 read out of each step's snap, then removed (source and `gen/` both back at HEAD — verified byte-identical):

| step | reading |
|---|---|
| 1–2 | `nA0-no-vw` — no Vyto world yet, correct |
| **3 — FOLDED commission** | `nA1` · **`mir-1` (NO MIRROR)** · **`fold0`** · vis 0 · folded 0 · no crest |
| **4 — PLAIN commission** | `nA1` · **`mir20`** · `fold0` · **vis 20** |

**The stray-world hypothesis is dead** — `nA1`, exactly one `A:Vyto` under the staple, so the Book
 reads the same world the commission minted. The real fact is narrower and stranger: at step 3 the
  world exists **but its mirror was never built and `w.c.folded` was never set**, while step 4's
   commission completes fully on the same path.

`w.c.folded` is assigned *inside* `Vyto_commission` (`Vyto.g:128`), so **step 3's commission never
 reached that line**. Everything else follows from that one fact and needs no separate explanation:
  no commission ⇒ no grapples ⇒ `Vyto_scan` returns early ⇒ no mirror ⇒ nothing to fold ⇒ all three
   step-3 claims absent ⇒ and the plain control at step 4 swears *because* a fold that never ran is
    indistinguishable from no fold at all.

**So the question is no longer "why doesn't the fold crush" but "why does the FIRST commission not
 land while the second does".** `Vyto_commission_on` ends in `SH.i_elvisto('Vyto/Vyto',
  'Vyto_commission', {req})` — a deferred call ([[minted-elvisto-is-not-a-run-elvisto]]) — and step 3
   mints the `A:Vyto`/`w:Vyto` pair in the same breath as dispatching to it. A world that is not stood
    up yet cannot receive the elvisto; by step 4 it is standing, and the same call lands.
 ⚠ But note VytoDepth's step 3 IS a first commission and goes green, so "first commission never
  lands" cannot be the whole rule — something differs between the two Books' step 3. That is the next
   thing to establish, and it is one more reading, not a rewrite.

**AND THE TWO OBVIOUS EXPLANATIONS ARE BOTH DEAD (2026-08-12, later).** Worth writing down so nobody
 re-walks them:

1. **"the reader bails before it drives."** All three step-3 readers open with
    `if (!vw.c.folded) return 0`, *before* the call that stirs — and `Vyto_rest_poll`'s own header says
     the poll IS the drive (*"a Story-run House goes quiescent under a ttlilt hold… a client that needs
      a settled read STIRS THE GLASS DIRECTLY… this loop also patiently covers the async commission"*).
       So it looks like a deadlock: the wait for the commission gated on the commission having finished.
    **But it is not the cause** — `Vyto_stir` is scan/fold/gang/relate/express/solve; it does not
     process the commission elvisto, so reaching the driver sooner would not land it either. It is
      still a smell worth tidying, just not this bug.
2. **"the elvisto never gets a belief cycle."** `VytoStaple_await` calls `this.main()` on **every
    200ms poll** — about 90 nudges across step 3's 18s window, and the comment says exactly why it is
     there. The House is being driven.

**So the fact that needs explaining is sharp:** step 3's `Vyto_commission` never executes despite ~90
 belief nudges, while step 4's **identical call on the identical path** completes. The only
  difference between them is `folded=1` vs `folded=0` — a flag the commission does not read until
   `Vyto.g:128`, well after the dispatch.
 Also note VytoDepth_nest opens `if (!vw || !vw.c.nested) return 0` — the *same* bail-before-drive
  shape as VytoCrush — and goes green. So whatever this is, it is not the reader's structure.

**NEXT EXPERIMENT (one of two, cheapest first):**
 (a) a temporary stamp INSIDE `Vyto_commission` (product code — so in and straight out again)
  recording whether it is entered at all for step 3, and if so how far it gets;
 (b) failing that, make VytoCrush's beat 3 byte-identical to beat 4 except the flag (add the
  `Vyto_rest_reset`, drop the `w.c.last_vis = null`) and see whether it starts landing — which would
   point at the beat, not the flag.

---

## 7. Regression sweep, 2026-08-12 ~04:45 — and a note about `npm test`

Everything touched overnight, re-checked against its expected state:

| check | result |
|---|---|
| SwarmInvite (exercises the edited `Swarm.g`) | **5/5, caveat 0** — unchanged |
| SwarmShare (same) | **9/9, caveat 8** — exactly its documented baseline |
| VytoDepth / VytoNeed (fixtures recorded tonight) | **3/3 and 4/4, caveat 0** — the recordings hold |
| the nav seam (`Housing`/`WormholeOpfs`/`MountNav`) | both players booted through it all night at **11 watches, arrived, amiss 0** — that is the seam in production, repeatedly |
| `MountNav.spec` + `LazyGithubNav.spec` | **29 tests green**, 22 mutations each seen red |
| svelte-check | no errors in any edited file; total moved only by the untyped-Dexie/implicit-any noise already in that function |

⚠ **`npm test` is RED at baseline and always has been** — 15 of 20 spec files fail, 36 tests. **This
 is not a regression and not worth chasing.** The `test: { workspace: [...] }` block in
  `vite.config.ts` is **commented out**, so there is no jsdom environment and no `svelteTesting()`
   setup; every spec runs in node. Two signatures, both environmental: `document is not defined`, and
    `lifecycle_function_unavailable` (adding `--environment jsdom` alone does **not** fix it — checked).
 The only specs that pass are the ones needing neither a DOM nor a Svelte lifecycle — `VytoFocus`,
  `VytoGauge`, `MountNav`, `LazyGithubNav`, `src/demo`. So a whole-suite run proves nothing about an
   edit; run the specific pure-logic spec that covers it, and let a **Book on the live runner** be the
    real gate. Recorded as [[npm-test-is-red-at-baseline]]. Worth a decision sometime: either
     un-comment that block and fix what it surfaces, or delete the specs it strands.

### 7a. "Six green gates that gate nothing" — the count is now ONE, and two of the six never existed

The handover's standing item named six hollow Books. Chased to the end 2026-08-12:

- **`Mine` and `Theirs` are not Books at all.** They are **particle types** — `%Mine,pub:…`
   is the stock-shelf census convention (`Swarmation.g:755`) and `%Theirs` is a friend's shelf that
    Sounditron grapples. There is no `wormhole/Story/Mine/` because there was never a Book to have
     one. `Swarmation.g` in fact defines **eleven** Swarm Books (SwarmBlotter · SwarmChain · SwarmDisk
      · SwarmDoor · SwarmGot · SwarmInvite · SwarmPolicy · SwarmShare · SwarmSpoof · SwarmSteal ·
       SwarmWire), all with fixtures — the discovery layer IS covered.
   The error came from a session memory written 2026-08-06 that named two Books which have since been
    replaced; it was copied into a handover, where a stale claim reads like a measured fact. Memory
     corrected.
- **The other four are done** (§6): VytoDepth, VytoNeed and VytoCrush now carry real diges;
   **VytoMemo stays hollow on purpose.**

**The survey, over the whole tree:** `136 Books carry a toc.snap · 1 fully hollow · 0 partial`.
 That one is VytoMemo. One line reproduces it:

```sh
for d in wormhole/Story/*/; do echo "$(basename $d) $(grep -c dige:lie $d/toc.snap) $(grep -cE '^  step' $d/toc.snap)"; done
```

So fixture coverage is **not** a v1 concern — it is essentially complete, and the one gap is
 documented and deliberate. What is NOT covered is a different thing entirely and is worth not
  confusing with it: assertions that are declared and never sworn (VytoCrush's three, §6a). A Book
   can hold a perfect fixture and still make claims it never proves.

### 6b. FOUND IT — the hold starves the belief cycle the commission needs (2026-08-12)

No new electrode was needed: `Vyto_commission` **already carries one** —
 `Radio_trace(null, {ev:'vyto-commission'})` at its top, fired the moment the elvisto crosses the
  queue. And `runner_ask trace <n>` prints each step's beliefs-cycle trace. Between them the answer
   was already on the runner.

**Step 3 (folded — fails):**
```
step 3 · todo think+1 · beliefs begin think · think VytoCrush/VytoCrush→VytoCrush · beliefs done
        · ttlilt "Story poll: held by w:VytoCrush req:fold_wait +17906ms"
        · ttlilt … ×~90, for the whole 18s, AND NOTHING ELSE
```
**Step 4 (plain — works):**
```
step 4 · think · beliefs done
        · rekick "todo:1 idle:1.50s"        ← the revival
        · beliefs begin reqyonciliation · reqyoncile req:plain_wait
        · todo think+1 · beliefs begin think · think · done · quiescent · snap
```

**The mechanism, stated plainly:** during step 3's hold the House runs **zero belief cycles** after the
 beat's own. `Vyto_commission_on` ends by MINTING an elvisto; an elvisto is delivered BY a belief
  cycle; so the commission is never taken, `w.c.folded` is never assigned, no grapples land,
   `Vyto_scan` no-ops, no mirror, nothing to fold. Every symptom from §6a collapses into this.
 And the thing that rescues step 4 — `rekick` on `idle:1.50s` — **cannot fire for step 3, because a
  ttlilt HOLD IS NOT IDLE.** This is `wake ≠ hold` (Coding_guide) biting at the one place it is fatal:
   a step whose expectation waits on something that itself needs a belief cycle can never get one.
 It also explains the earlier puzzle cleanly: nothing is special about `folded=1`. What differs is
  whether the step's expectation lets the House reach idle. Step 4's does; step 3's does not.

**Still not proven, and worth one more reading before any fix:** `VytoStaple_await` calls
 `this.main()` on every 200ms poll expressly to "NUDGE a belief cycle each poll" — and the trace shows
  those nudges producing **no** cycles under the hold. Either `main()` is a no-op while a ttlilt holds,
   or its cycles are not traced. That distinction decides the fix:
 · if `main()` is genuinely suppressed → the await needs a wake that survives a hold, or the beat must
    not arm the hold until the commission has landed;
 · if it merely goes untraced → the elvisto is being dropped for a different reason and the hunt
    continues from there.
 VytoDepth passing is consistent with this either way: its expectation settles fast enough to reach
  the idle rekick, so it never sits in the starved state.

### 6c. The fix was TRIED and REVERTED — and both halves of the result matter

`VytoStaple_await`'s nudge is `this.main()`, and `main()` opens
 `if (this.c.no_ambient && !ambient_anyway) return`. A Story run sets exactly that —
  `Run.c.no_ambient = true` (`Story.svelte:1463`, *"story_drive owns the clock; suppress ambient
   tick"*). **So every one of those ~90 polls per wait returns immediately and nudges nothing**; the
    comment above it describes an intent the code has never carried out.

Swapped to `feebly_ponder()` (bypasses no_ambient, respects Runtime — its stated purpose), compiled,
 measured, and then **reverted**. Two findings, and the second is why it is reverted:

**① The diagnosis was RIGHT.** With real nudges landing, `board-folded` went from ABSENT to **SWORN**
 — sworn 1 → 2. So the commission genuinely was being starved of the belief cycle that delivers its
  elvisto, exactly as §6b said, and that half is now proven rather than argued.

**② `feebly_ponder` is NOT the fix — it WEDGES the Book drive.** VytoDepth stopped completing at all
 (`phase:"begun"`, no progress, runs timing out). Which reframes `no_ambient`: it is not an oversight
  to route around, it is **load-bearing** — story_drive owns the clock, and forcing ambient ticks
   through it breaks the cadence the flag exists to protect. Reverted; all three Books verified back
    at baseline (VytoDepth 3/3 c0 · VytoNeed 4/4 c0 · VytoCrush ok_pct 1 c0 with its three gaps).

**③ And it would not have been enough anyway.** Even with nudges landing, `crushed` and
 `crest-counts` stayed ABSENT. So the fold now *runs* and still does not produce three crest cells —
  **there is a second, independent cause underneath.** My §6b claim that every symptom collapses into
   the starved cycle was only partly right: `board-folded` did; the other two did not.

**Where that leaves it.** Two real defects, stacked:
 · **the starved nudge** — `main()` inside a Book is a no-op, so `VytoStaple_await` has never nudged
    anything. The fix must give a held step a wake that does not fight story_drive for the clock —
     `ponder_now()` is the interesting candidate (it is unthrottled and deliberately bypasses
      no_ambient *for a genuine settle*), but its own header says "use ONLY on a genuine settle —
       never on a poll", so this wants the owner's eye, not a 6am swap.
 · **the crush itself** — with the commission landed, three crests still do not appear. Fresh ground,
    and now reachable: seed the rig, get past the commission, and read `Vyto_fold_scope` directly.
