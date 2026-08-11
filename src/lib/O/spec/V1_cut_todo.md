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

**Status, end of 2026-08-11.** Of the five: **Q2** (the wormhole) and **Q5** (the download ledger)
 are answered and Q5 is **built**; **Q1** is answered in mechanism — the stash is a mount, not a
  mode — leaving one sub-question, what `.jamsend` defaults to, which is where the whole security
   property actually lives; **Q4 is withdrawn as doc noise** and the withdrawal is worth reading,
    because it is a specimen of §0 manufacturing a decision nobody asked for; **Q3** (watches
     outliving Books) is untouched. So: **one and a half questions left, not five.**

### Q1 — ✅ LARGELY ANSWERED 2026-08-11: the stash is a MOUNT, not a mode

**The owner, closing Q1 and Q2 with one mechanism:** *"I kinda addressed Q1 and Q2, making virtual
 wormhole/ that isn't on disk and virtual .jamsend at another share, but seeming to be there with
  the one unified w:Wormhole interface."*

That dissolves the expensive part of the stash. There is no second MODE to persist, no
 `MyJamsendData` convention to teach, no separate "open stash" flow to sequence against onboarding
  — **`.jamsend` is simply a mount that can point somewhere other than the music folder**, resolved
   through the same unified `w:Wormhole` namespace as the virtual `wormhole/`. One mechanism, two
    problems. The three cures I costed below are superseded: this is a better (c).

**The one thing still to decide, and it is the whole security property: what does `.jamsend`
 DEFAULT to?** The mount makes the fix *possible*; only the default makes it *true* for a user who
  never configures anything. If `.jamsend` still defaults to inside the granted share, every
   non-configuring user keeps the leak.
 **My recommendation: default `.jamsend` to OPFS** (per-origin browser storage, invisible to any
  file manager, never inside a folder the user might sync or hand around), and treat *mounting it
   to a real directory* as the explicit, opt-in choice that buys disk portability and
    new-browser recovery. That makes the leak impossible by default and keeps your recovery story
     intact for anyone who wants it — the same shape as the old (c), now expressed as a mount.

> **Answer with: `.jamsend` defaults to OPFS (recommended) / defaults inside the share.**

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
**Still to settle when built** (was Q2's sub-questions, now scoped by the ruling): the staleness
 story for a lazily-filled mount against a newer build, and whether writes under `wormhole/` go to
  disk immediately or stay in the lazy layer.

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
5. **Hollow Books [memory]:** MusuSelf/MusuThem have no fixtures; four Vyto Books are `dige:lie`.
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
