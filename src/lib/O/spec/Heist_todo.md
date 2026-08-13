# Heist_todo.md — heisting music off a friend

You hear a track on a friend's radio, you press ⇊, and the original file lands in your collection
 under a folder you chose. That is the whole feature. This doc states how it works now, straight —
  the dated build strata it replaces are at `spec/history/Heist_todo_strata.md`, kept for the
   reasoning (the census rewrite, the `music/` teardown, the seven-bug adversarial review, the
    %Stream starve) rather than for anything current.

**Vocabulary settled 2026-08-09, after three goes.** The intent particle — one nab of one album — was
 `%Keep`; the human ruled it "too weak a word" (2026-08-05). It became `%Haul`, but only because
  `%Heist` was already taken by the JOB particle a keep condenses into, and two shapes under one
   mainkey is the tell CLAUDE.md warns about. `%Haul` was always a consolation and the wrong SCALE —
    a haul is the whole take, not one album (the owner: *"I actually intended for the Heist to be
     each nab of an album, and the Haul to be the larger collective"*).

Fixed by moving the blocker rather than the blocked:

| particle | is | was |
|---|---|---|
| **`%Heist`** | ONE NAB OF ONE ALBUM — the ⇊ keep, pier field `pub:` | `%Haul` (and `%Keep` before that) |
| **`%Caper`** | the OPERATION — soft `wish:` hardening into hard `at:`, plus the posed flow organ | `%Heist` |
| **`%Haul`** | *free* — reserved for the larger collective, the What Heisted ledger | — |

`Heist_soft()` is why the operation is ONE name and not two: soft (`wish`, no `at`) and hard (`at`
 stamped) are the same particle in two phases, never two kinds. Method names stay `Heist_keep_*` —
  and they now MATCH the particle they drive, which they never did while it was called `%Haul`.
   `Heist_job`/`Heist_wish` still mint what is now a `%Caper`; renaming ~50 methods and their elvisto
    call sites is a churn with no reader benefit, so it was left. ~~**The ledger is not built yet** —
     `Heist_flatten` still deletes a finished operation, so nothing accumulates into `%Haul`. That is
      the next move, and it is what "a list of What Heisted" means.~~
   **⇒ CORRECTED 2026-08-13 (see §0V): the ledger WAS built, under another name.** The newlyadded log has
    recorded every landed file durably for weeks — `of` the path, `dir` the folder, `at` when it first
     landed — and `Heist_newlyadded_grouped` folds it per album. What was missing was a surface, not a
      store, and the sentence above sent two readers looking for the wrong thing. `%Haul` stays free.

---

## 0. Next move (read first)

### THE ARC — where this is going, in one page (2026-08-13 evening, written to be steered)

**The destination.** A heist stops being an event you supervise and becomes a *standing appetite*: you
 hear something, press ⇊, and walk off. The app knows what a folder IS before it asks anyone, queues as
  many as you like, runs them in an order you can say out loud, and tells you afterwards what arrived.
   Today closed most of the gap. What is left splits into three tracks, ordered by what actually
    threatens the work.

**Track A — make the machine trustworthy again. Do this first, and it is mostly the owner's half.**
 Today's real lesson was not about heists: *the verification path was broken for hours and nothing said
  so*. Every runner read as dead, the whole flock was actually alive, and `relay-test.ts` had been red
   the entire time with nobody running it. Concretely:
   A1. **Restart the dev server** (the relay fix is server-side; `attachRelay`'s double-attach guard
        means an HMR will not re-attach it). Then `runner_ask runners` should list real roles again.
   A2. **Run the owed Books** — Heistation, Sounditron — and **re-record MusuHeist**, which the blag
        genuinely changes (no describe-ask on the first beat, picks refed by content-id, `blag:1`).
   A3. **Un-gate the unity** (`src_size`/`un_n`/`un_size` are humdinger-only so today's fixtures could
        not move) and re-record the affected Books in one attended sitting. Until then **no Book can
         cover the unity at all** — the unit specs are standing in for it.
   A4. **One command that runs everything a commit can break**: the three vitest specs *and*
        `relay-test.ts`. The relay test is not wired to anything, which is exactly why it went unread.

**Track B — finish the heist experience.** Each is self-contained and none blocks another.
   B1. **Speculative pre-stage of the seed** — you press ⇊ on a track that is *already streaming*, yet
        the seed re-materialises from nothing like any sibling. Pre-warm at the press; land nothing
         until ▶ (the "no transfer before consent" ruling stands).
   B2. **A disk-space floor** — now finally possible, because the unity knows the MB *before* you start.
        Needs an honest free-space source; `navigator.storage.estimate()` may be all there is, and if it
         cannot see the granted directory then say so rather than guess.
   B3. **Path mining beyond sections** — years, editions, disc numbers, `[FLAC]` tags. Tags stay the
        artist|title truth (2026-07-28 ruling); this is about the rest of what a path knows.
   B4. **The queue's next rung** — one place that shows every heist at once, and "pause all". `sc.pri`
        and `sc.paused` already exist; this is a surface, not a mechanism.

**Track C — what the unity unlocks past heists** (speculative; worth a conversation before any code).
 `un_n`/`un_size` is a general fact that now rides every %Record over the wire: *this track belongs to a
  12-track, 84MB folder*. Nothing but the heist form reads it yet. It would let the radio offer "the rest
   of this album" as one gesture, let a friend's crate be browsed in albums with real weights, and let
    shelf eviction reason in albums rather than tracks — [[window-shelf-fairness-lives-in-eviction]]
     is about exactly the unit problem this fixes.

**The through-line, and the thing to hold on to:** every item above is the same move that made today
 work — *get the app the missing fact, rather than putting the uncertainty on screen as a question*.

0Z-verify. **⇑ 2026-08-13 (evening) — THE WHOLE DAY IS NOW UNIT-COVERED, since no runner would answer.**
    `scripts/HeistUnity.spec.ts` (9) + `scripts/MultiHeist.spec.ts` (5), beside the existing
     `KeepMemoDurable.spec.ts` (8) — **22 green**, and **nine mutants, every one caught**. Run all three:
     `node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/{HeistUnity,MultiHeist,KeepMemoDurable}.spec.ts`
   **Why unit tests and not a Book.** No runner answered all day (two dead registry rows; three of the
    owner's music tabs, which must never be Booked) and Playwright cannot stand one up from here — the
     claude container is non-root with no `libglib-2.0.so.0`, so its bundled chromium will not launch, as
      `pw_drive.mjs` §B already says. But this day's work is almost all pure C-tree logic, and
       `KeepMemoDurable`'s harness — mount a compiled `.go` on a stub House and get the REAL verbs bound
        to it — reaches it directly. Two things it needs that the original did not: a real `TheC` as the
         House (the blag mints `%BlagLib` on `top_House()`), and `mainkey` bolted on (it is House's own,
          nothing in `M/` provides it, and `Ra_recs_deep` throws without it).
   **Mutate on a COPY, never in place** — `scripts/.mutant-*.go` plus a throwaway spec that imports it. A
    `.g` compile and a `.go` edit both HMR straight into the owner's live music tabs, so a deliberately
     broken build reaches a real listener mid-song.
   **What no unit test can reach**: that any of it is CALLED. The beat wiring — the 40-per-pass unity
    re-stamp, the ask now running beside the blag, the loop skipping a paused keep, the gesture-path
     re-commission — is `Heist_keep_beat`'s and `Sounditron_commission`'s, and only a live runner proves
      it. **Still owed: Heistation, Sounditron, and a MusuHeist re-record** (the blag genuinely changes
       what MusuHeist does — no describe-ask on the first beat, picks refed by content-id, `blag:1` in
        the snap), plus the dev-server restart for the relay duplicate-fanout fix.

0Y. **⇑ 2026-08-13 (evening) — THE UNITY: every %Record now knows how big its folder is, and the blag
    stopped pretending to be an answer.** The owner ran §0W live and it was bad: *"it was short, only
     showing 1 track, etc etc. seemed fussy and crappy."*
   **Two faults, one of them mine from that morning.**
   1. **The ask was suppressed, not merely beaten.** §0W gated the describe-ask on `Heist_rummage_recs`
       — the blended list, which the blag itself fills — so ONE husk we happened to hold counted as a
        complete answer and the wire ask never went out at all. The blag was only ever meant to kill the
         WAIT, not the question. The gate is now `Heist_rummage_wire` (the wire census alone), so both
          run: form populated on the ⇊ beat, ask in flight behind it, answer supersedes.
   2. **A blagged folder was priced from the wrong number.** A husk's `bytes` means *the file* (the wire
       census stat-stamps it), but a %Record's `bytes` is the sum of its PREVIEW's opus chunks — tens of
        times smaller. The blag copied it straight across, so the cost line understated a folder by
         25–70× and called it a total.
   **The fix the owner named:** *"so every track|Record knows how many MB its surrounding heistable unity
    is?"* — exactly right, and it turned out to be nearly free. `info.src_size` (the true file byteLength)
     has been written into every radiostock card since the format existed and was the one field that never
      reached the %Record. Stamp it (`Ra_record_from`), then group a shelf by dirname and stamp each record
       with its folder's census — `un_n` tracks, `un_size` bytes (`Ra_unity_stamp`). Because it rides the
        %Record it **crosses to a friend's mirror for free**: their track arrives already knowing it belongs
         to a 12-track 84MB folder. So a listing can KNOW it is short, on the ⇊ beat, before anyone is asked.
   **What it changed on screen** *(revised the same evening, and the revision is the point — the owner:
    "I want to know how many tracks are involved and how big they all are, banish `looks short?` that's
     ridiculous")*. **How many** and **how big** are properties of the FOLDER, not of however much of its
      listing has arrived, so the count line is now driven by the unity and stands up on the ⇊ beat without
       changing its mind afterwards: `12 tracks · ~48m · 84 MB`. Reading them off the husks had made both
        numbers a function of network timing — 1 track / 8 MB one second, 12 / 84 MB the next, with nothing
         admitting the first was provisional. While the two disagree a quiet `naming them — 1 of 12 so far`
          trails the line and then vanishes. When no unity rode in (an older friend) it falls back to
           counting husks and says **`size unknown`** outright rather than omitting the clause, because an
            absent size reads as free.
   **`looks short?` is banished, and `Heist_keep_reask` with it** — hours after being built, correctly.
    Asking a human to eyeball whether a file listing is complete is the app declining to do its own job,
     and it is not even answerable: the only thing on screen was the very list whose completeness was in
      question. The two facts that replaced it are ones the app can hold itself (the ask is no longer
       suppressed; the unity says how many there are), and both land with no control at all. A headstone
        comment stands where the verb was, so the next person to hit a partial listing finds out a button
         was tried here and why it was wrong instead of inventing it again.
   **`Heist_wire_supersede` is the new load-bearing seam.** When the real census lands mid-form, the human's
    ticks have to survive it — and the two censuses cannot share ids (source keep-id vs friend content-id).
     **PATH is the join.** Every blagged pick is re-pointed at its wire twin and drops its `blag` mark; one
      with no twin is dropped, because the source has just said that file is not there.
   **VERIFIED — `scripts/HeistUnity.spec.ts`, 9 green, and every load-bearing claim seen to go red.** No
    runner answered all day (two dead registry rows, three of the owner's music tabs, which must not be
     Booked) and Playwright cannot help: the claude container is non-root with no `libglib-2.0.so.0`, so
      its bundled chromium will not launch — exactly as `pw_drive.mjs` §B documents. But all of this is
       pure C-tree work, so it is unit-testable, and `KeepMemoDurable.spec.ts`'s mount-a-.go-on-a-stub
        harness reaches it directly (with a real `TheC` as the House, since the blag homes `%BlagLib` on
         `top_House()`). **Four mutants, each caught:** copying a %Record's preview `bytes` onto a husk
          (reproduces the original 25–70× underpricing exactly — `40000` where `7000000` is owed); joining
           the supersede on `ref` instead of `path` (drops all three picks instead of re-pointing one);
            letting `Heist_rummage_wire` fall back to the blag (the conflation that suppressed the ask);
             and removing the humdinger gate. **What this does NOT prove: that any of it is CALLED** — the
              beat wiring (the 40-per-pass unity re-stamp, the ask running beside the blag, the loop
               skipping a paused keep) is `Heist_keep_beat`'s, and only a live runner proves that.
   **Owed.** `src_size`/`un_n`/`un_size` are **humdinger-gated**: a new %Record sc key moves every Book
    fixture that snaps a record, and no runner has answered all day. That is a holdback, not a design —
     un-gate + re-record in one attended sitting, the same shape as Repli.g's `sc.from` twin. Until then
      the unity does not exist inside a Book, so no Book can gate it. Still unverified live.

0U. **⇑ 2026-08-13 — the owner asked *"any other features you can think through that we might want?"*.
    Thought through, ranked, none of them started.** Ordered by "what does the app now need that it did
     not need yesterday", because §0W/§0X/§0V changed what the app IS: heists run in the background now,
      several at once, and the folder arrives instantly. That moves the weak points.
   1. ~~**"Ask them properly" — the blag's escape hatch.**~~ **BUILT, then BANISHED the same day.** The
       problem was real (a half-mirrored folder reading as half an album, silently); a **control** was the
        wrong answer to it, and the owner said so within hours — *"banish `looks short?` that's
         ridiculous"*. The silence deserved a FACT, not a button. See §0Y for what replaced it and why the
          distinction is worth keeping in mind for the rest of this list: when a subsystem cannot tell the
           truth, get it the missing fact — do not put the uncertainty on screen as a question.
   2. ~~**A queue you can reorder.**~~ **BUILT 2026-08-13 evening.** `sc.pri` (lower first, absent = 0) is
       read at the one place the order exists — `Heist_keep_beat`'s loop — with a **stable** sort, so a
        world where nobody touches the queue behaves exactly as it did. `Heist_keep_first` renumbers the
         shop 0..n-1 rather than handing out ever-smaller numbers: total ordering, small legible values,
          no drift to bound. The face counts its live siblings and says **"3 ahead of it"**, offering
           **↑ first** — the only control a rim cell's position implies.
   3. ~~**Pause, not just cancel.**~~ **BUILT 2026-08-13 evening**, as a **flag, not a state**: a paused
       keep must resume into exactly the state it left, and a `paused` state would have to remember which
        one that was. The beat loop simply does not step it — which is also what makes a paused heist
         hand its turn on instead of idling in front of the queue, since it never spends the global
          allowance. It refreshes `pull_progress_ts` on the way past, or the stall watchdog would bark
           "the SOURCE may have crashed" about a heist you deliberately stopped. Snapped `1`-or-absent so
            a heist you paused and walked away from does not restart itself on a Berth resume.
      **Neither touches a Book**: `pri` and `paused` are only ever written by a human press.
   4. **Speculative pre-stage of the seed** *(named in §0Z, still unbuilt)*: you pressed ⇊ on a track
       that is ALREADY STREAMING — its chunks are in hand — yet the seed re-materialises from nothing
        like any sibling. *"begin Heisting the one track we know the full filename of super quick."*
   5. **Path mining beyond sections** *(§0Z)*: years, editions, disc numbers, `[FLAC]` tags. Tags stay
       the artist|title truth (2026-07-28 ruling); this is about the REST of what the path knows.
   6. **A disk-space floor.** Unattended background heisting can fill a disk and nothing checks. Under
       FSA the real free space is not visible, so this is honest-estimate-and-warn, not a hard gate —
        which is why it is low, not because filling the disk is a small problem.
   **Considered and rejected:** a second "recently added" surface (it is §0V's list, already built); a
    notification when a haul lands (that IS the `%Hauls` bud — a second channel would be noise);
     raising heist concurrency (the serial bound is hard-won, and queueing is what was actually asked
      for); klepto (parked by ruling, 2026-07-27).

0V. **⇑ 2026-08-13 (day) — WHAT HEISTED, at last — and the ledger turned out to already exist.**
   The owner, asked whether to build it: *"yeah build something aye"*. **The finding matters more than the
    feature: this doc has said "the ledger is not built yet" for a week and it was wrong.** The newlyadded
     log records every landed file durably (`of` the path, `dir` the folder, `at` when it first landed,
      `feeling` its probation) and `Heist_newlyadded_grouped` already folds it per ALBUM — which is exactly
       the unit "a list of What Heisted" wants. What was missing was a **surface**, not a store. Minting a
        parallel `%Haul` store beside it would have been two ledgers for one fact — the "there's only one
         of anything" mistake this project keeps having to un-make. `%Haul` stays free.
   **Landed:** `Heist_haul_look` mirrors the ledger onto a dontSnap `%Hauls` bag on the radio world, on a
    20s beat inside `Heist_keep_beat` (the one place per beat already holding `nav`; humdinger-gated — a
     Book has no business reading a collection ledger off a timer). `HaulFace.svelte` reads the bag:
      albums newest first, track count, folder, "2h ago", registered in `glass_kinds`/`glass_faces`.
   **It buds, and only while it is news** — the sanity cell's law, not the Door's. A permanent "things you
    downloaded" cell is furniture within a day, and the glass has spent this month getting smaller. But the
     reason it exists is the same reason heists now run in the background (§0X): you set three going and
      wandered off, so something has to say they landed. So it appears when an album arrived in the last
       24h and goes away on its own.
   **It cannot say who gave it to you, and that is a ruling** — the newlyadded log deliberately never
    records a source (its header states it; the owner restated it 2026-08-11: *"just the destination
     directory and when, not who it came from"*). A heist-scoped ledger that DID know the friend would be
      a different thing and needs asking for.
   **Owed:** unverified — no runner (see §0X). The probation verdict (love/drop) is reachable from
    `Heist_feel` but this face does not offer it; the owner parked that UI 2026-08-11 (*"I don't want to
     see the %Probation yet"*) and this respects it — the `fresh` tint is the only nod.

0W. **⇑ 2026-08-13 (day) — THE BLAG: the folder comes from the %Records we already hold. No describe-ask.**
   The owner, and he had said it the night before: *"stop having to be 'asking S for the folder', know that
    already from the %Record, like we used to. we used to have the file listing as well, we can blag that."*
   **Why it sat unbuilt is a lesson worth keeping.** The comment at `Heist_rummage_ask` states flatly that
    the folder *"can ONLY be resolved by the SOURCE, off its own radiostock card"* — and that was TRUE when
     it was written, because the asker's mirrored heads carried no path. Since `rec.sc.path` started
      carrying the crate-root-relative path (`Ra.g`, build `4938d5f5`) it has been false. Nobody re-read the
       comment against the data. **A friend's `%MusuThem` mirror card carries `path`, `title`, `artist`,
        `ext` and a stat'd `bytes` — that IS a file listing** (see any MusuBay fixture, line `Record,id:…,
         title:…,path:Fourier Four - Echo E.wav,ext:wav,bytes=960104`).
   **Landed** (`Heist.g`, compiled): `Heist_blag_folder` takes the seed's own mirror card, takes
    `dirname(path)`, and mints one husk per mirror card sharing that directory into a dontSnap
     `%BlagLib,<seed>` on Mundo. `Heist_rummage_recs` unions it in **behind** the wire set — a wire answer,
      whenever it arrives, supersedes the guess completely — so all five call sites (three faces, both
       defaulters) got it with no signature change. Runs once per keep, on the first beat after ⇊; the
        describe-ask now fires **only when the blag comes up empty**.
   - **Ids are content-ids, not keep-ids** — we cannot mint the source's keep-id (it hashes THEIR crate
      base, which no card carries) and we do not need to: `Heist_materialise_one`'s stocked-content-id
       branch already resolves id → card → base+path and serves the original under a fresh keep-id wearing
        `re:<content-id>`. **The trap that costs bytes:** the opus stream we heard is sitting in the mirror
         under that very content-id, already full — so a blagged pick binding by `{id: ref}` would sail past
          the materialise ask and land a *lofi radio preview* under the original's filename, against a hash
           that never matches. Hence `pick.sc.blag` (snapped, so it survives the Berth) and a `re`-only
            lookup for those picks. Wire picks take the old path unchanged.
   - **What the blag cannot do:** it sees only tracks the friend has actually cast to us, so a folder we
      hold half of reads as half a folder. The wire census walks their disk and cannot be short. If a
       listing ever looks short, the fix is a "ask them properly" press wiring the existing
        `Heist_rummage_ask` — **not built; the obvious next move on this thread.**
   ⚠ **MusuHeist WILL be red and that is the change, not a regression.** Its mirror cards carry paths, so
    the Book now takes the blag route: no describe-ask, picks refed by content-id, `blag:1` in the snap.
     It needs re-recording on a live runner, and once re-recorded **it is the gate for this feature**.
      Unverified here — no runner was answering (see 0X).

0X. **⇑ 2026-08-13 (day) — SEVERAL HEISTS AT ONCE. The engine already did it; the glass forbade it.**
   The owner: *"we also need to make multiple Heists doable, I can't be hanging around waiting for each one
    in fullscreen"*. Measured before touching anything, and the ENGINE was never the blocker —
     `Heist_keep_beat` has walked every standing keep per beat since the start, and since 2026-08-06 the
      track allowance is GLOBAL and z-ordered (`rw.c.heist_budget`, one track in flight across all keeps,
       oldest first). Two heists have always drained correctly, serially. **The glass was the blocker, in
        two places, and both were right when they were written:**
   - **The belly ladder promoted ANY open keep** (`if (anyKeep) fmain = keeps[0]`), so a heist that had
      nothing left to ask you still owned the screen until it finished.
   - **Pressing Radio or Door called `Sounditron_leave_keep` → `Heist_keep_cancel` on EVERY keep.** Going
      back to the music to find the next track killed the download. That ruling (2026-08-10, *"only the
       Door and Radio as two other locations to go to, which cancel the Heist"*) was correct while every
        open keep owned the screen — "somewhere else" could then only mean "abandon this".
   **The cut (all landed, compiled):** a keep owns the belly only while it is a FORM
    (`primed|wanted|asking|choosing` — the `setups` split, computed once beside `keeps`). Press ▶ and it
     becomes a bud; the Radio takes the belly back on the gesture (`Heist_keep_start` now fires the
      `Sounditron_keeps_look` twin `Heist_keep_cancel` has had since 2026-08-09, and the keep fingerprint
       gained the setup count — a role change IS a re-commission). Radio/Door press cancels **only the
        belly's own unstarted form**, nothing else; started heists carry on and other queued forms stay
         queued. Cancel stays reachable on the running strip (✕ stop / 🗑 undo) and on HeistBarFace.
   - **A heist bud is a place, not a mainkey.** Every %Heist wears the same mainkey, so `w.c.focused`
      cannot name one of three; a keep bud pins the particle on `w.c.focused_keep`, which sits above
       `focused` on the ladder and is released by `Sounditron_focus_to`. Press a running heist to inspect
        it in full (pose `big`, not `stretched` — stretched takes the aspect away from the face, right for
         a folder tree, wrong for a one-line progress strip).
   - **HeistFace reads `.c.pose`.** A bud draws title · N/M · flow bar and nothing else — no destination
      breadcrumb, no exits (a ✕ beside a 🗑 at rim size is a misclick waiting to happen). `.kf.bud`'s
       max-width IS the layout rule: Vytui measures the natural box and floors the seat at need × 1.15.
   - **Waiting your turn is not a stall.** A keep stepped after the global budget is spent reads
      `INFLIGHT === 0`; the watchdog only asks whether `landed` moved, so a correctly-queued heist would
       have barked `⇊☠ heist NO PROGRESS — the SOURCE may have crashed/gone` every 10s, once per queued
        heist, for as long as the first ran. A shout that fires when the machine is working as designed
         teaches you to ignore the real one. `keep.c.queued_ts` holds the progress clock fresh and the
          face says *"waiting its turn — one track downloads at a time"*.
   **NOT VERIFIED ON A RUNNER.** No runner was answering (★claude 58517b48 down; the other three rows are
    the owner's live music tabs and must not be Booked). The `.g` side HMR'd into the live tabs; the
     HeistFace change is `.svelte` and needs a reload before it exists anywhere. **Heistation + Sounditron
      are owed a run.** Both new gates are humdinger-only (the focus cut, the fingerprint's setup count,
       the start nudge) precisely so no Book should see any of it — that is the claim to test, not assume.
   **RULED, same day:** *"nah I think we make the Cancel prominent, and auto-Start them when wandered away
    from"*. So `Sounditron_leave_keep` → `Heist_keep_start`, not `Heist_keep_cancel`: wandering off is
     CONSENT. That restores the 2026-07-28 instinct (*"you don't have to click start, it'll assume that at
      some point"*) without the bug it was withdrawn for — the trigger is a deliberate press elsewhere, not
       the seed's track ending, which used to fire on a Radio skip and skip the form under you. And with
        leaving reassigned there was no way left to say "don't", so **✕ cancel is back on the form**,
         prominent, sized against ▶ start (`.kf-cancel`). It is not a return to the old regime; it is the
          control the new one needs.

0Y. **⇑ 2026-08-13 (deep night) — the persistence audit: a Berth Heist was a SHADOW; it now carries its
    substance.** The owner ("f469 seems to have forgotten its Heist… is it all a bit fake there?") had it
     right — an adversarial audit found the persisted %HeistSeed was a resumable *gesture* (opaque
      refs + tag titles) whose resolution leaned entirely on SOURCE runtime state, and the durable
       KeepMemo rail was never consulted from the one path a resumed heist exercises. Landed (all in
        Heist.g/Repli.g, compiled):
    - **Picks carry substance now**: `path`/`ext`/`bytes` at every mint door (adoption, toggle, commit),
       `body_hash` stamped at land — and all of it persists per-%Pick and replays on rehydrate.
    - **Self-certifying wants**: a materialise ask carries its pick's `path`; the source re-derives
       `sha256(pub|base|path)` and serves iff it equals the asked ref (`Heist_want_path_ok` hard-gates
        shape: audio ext only, no dot-segments/`..`). A reloaded source needs NO memory beyond its files.
    - **`Heist_materialise_one` now consults `Heist_reheal_id`** (the durable rail, audit F1) before the
       stock fallback; an unresolvable want tells the sink (`Repli_tell_miss`) instead of silence.
    - **Persist on mutations** (`Heist_keep_persist_nudge`, 1.5s debounce, started-states only): pick
       toggles, genre/dirs/lofi edits, late-husk adoption — the "resumed a 1-track shadow of a 10-track
        intent then forgot the other nine" hole.
    - **resume_sync** no longer burns its latch against a boot-empty mirror, verifies from the picks' own
       substance, and skips the boundary digest when no hash was ever promised.
    - **Waiting is a state**: the route-gate bow-out stamps `no_route_ts` + throttled shout + trace mark;
       HeistFace's folded strip says "waiting for S to come back — resumes on its own". `landed_n/total_n`
        are derived at rehydrate so a resumed heist never renders 0/N over real landings.
    - **The lost-heist mechanism itself**: the keep detach's single-flight latch had no stale breaker — a
       hung first beat (FSA/Berth await) silently retired the WHOLE heist machinery for the tab life.
        `Swarm_latch_stale` (cap 120s + epoch guard + hang cursor `keep_beat_at`) now covers cull|tour|keep.
    Same night, the serve side (separate audits, landed): head serves detached from the beliefs mutex
     (a 68s hold measured), the PCM sweep got its own ambient clock, a decode concurrency bound
      (`ra_pcm_maxfly`, default 2), the ceiling keeps grace till 3×CAP, Radio_head_ahead gated +
       de-head-of-lined, `Repli_serve_want` self-heals a missing serve source, and the beat skip line
        forks QUEUED-behind-the-mutex from genuinely running. **Not yet built (next):** inbound
         express/bulk lanes (chunk bytes and control share one FIFO under one mutex hold — the 15s
          freezes), presence `heard_at` stamped at socket receipt (the 20s gate shuts on healthy
           friends), `Ra_bake`'s synchronous per-sample loop (14.8s single frames), pcm refcount
            (head + continuation share `rec.c.pcm` with no shared lifetime), demand-as-reranking in
             admit, and the account-mirror mark stamped before its await.

0Z. **⇑ 2026-08-13 (late) — live-heist night: three defects fixed in the flow, and the ZOOMIER thread.**
   Fixed live while the owner heisted between two dev tabs (all compiled, in gen/):
   - **"10 tracks in setup, 1 in the running bit"** — the describe STREAMS, and `Heist_keep_default_pick`'s
      `defaulted` latch fired on the first husk (the seed's own) and never looked again. Adoption is now
       continuous: all of setup, and past a fast ▶ for a keep set up this session (`keep.c.adopting`,
        runtime-only so a Berth-rehydrate still never re-derives). The human's first pick-touch stamps
         `keep.sc.pick_edited` and adoption stands down for good.
   - **Section shed on landing** ("'- r&b' was there, but ignored… saves without it") — filings are keyed by
      the PICK's artist, frozen at pick time; the meta-from-tags re-stock (a34b4086) moved `rec.sc.artist`
       overnight, the lookup missed, and the some(genre) guard skipped the source fallback too → naked at
        the root. `Heist_rel_for` now borrows the job's category when every pinned filing agrees on one.
   - **`keep` detached from the share beat** (`Swarm_keep_detached`, the cull|tour pair's third sibling) —
      keep=2602ms beats with 280 skips were why "asking S for the folder takes aaages"; the one-writer law
       moved into the `keep_flying` latch (stricter than before). `keep_bg` rides the split + beat trace.
   **The ZOOMIER thread (the owner, same night — direction, not yet built):**
   - *"setting up multiple Heists without waiting for each one to land"* — mostly unblocked by the detach
      (the driver already walks every standing keep per beat; the wedged beat made them FEEL serial). Watch.
   - *"begin Heisting the one track we know the full filename of super quick"* — the seed pick exists from
      beat one now; a true speculative pre-stage (the seed is already streaming — its chunks are in hand)
       is the unbuilt half.
   - *"perhaps we move back to a 2/3 Heist 1/3 Radio interface at the point, to promote drifting back over
      there interactively"* — layout direction for daylight.
   - *"the path structure leading into the music might have a lot of interesting info in it"* — path mining
      beyond sections (years, editions, disc numbers, `[FLAC]` tags). Tags stay the artist|title truth
       (the 2026-07-28 ruling); this is about the REST of what the path knows.

00. **⇑ SESSION CLOSE 2026-08-07 — four live defects found, two fixed, and ONE THING BLOCKS A GREEN GATE.**

  **A known, DEFERRED redness: 8 Books disagree with the code and that is the fixtures working.**
   `rec.sc.path` now carries the crate-root-relative path (`Ra.g`, build `4938d5f513f1067e`) — see the
    §0c entry below. 73 fixtures across **MusuBay, MusuBreach, MusuBuddy, MusuHeist, MusuMag, MusuOgg,
     MusuReap, MusuSoft** still hold the old bare-filename form.
   ⚠ **THE LIST IS MOSTLY WRONG. All eight were run on live runners 2026-08-08; here is what is true:**

   | Book | measured | reading |
   |---|---|---|
   | MusuHeist | **22/22 green** | unaffected |
   | MusuBay | **9/9 green** | unaffected |
   | MusuBreach | **10/10 green** | unaffected |
   | MusuSoft | **6/6 green** | unaffected |
   | MusuOgg | red | **path-only, as claimed** — its five failing steps have ZERO non-`path:` diff lines |
   | MusuMag | red 1/10 | **NOT path-only — see below** |
   | MusuReap | red 1/4 | shape unverified |
   | MusuBuddy | — | first attempt invalid (two jobs on one runner); re-run owed |

   **So half the list is green and the re-record it asks for is largely unnecessary.** More important,
    the two solid reds do NOT have the clean shape the entry promises:
   - **`MusuMag` is a MIX.** Step 3 shows `req:unemit … body_len=751 → 784` with a different
      `body_hash` — the `testsounds/` prefix leaking into **hashed and length fields**, not just into
       `path:` lines. **That breaks the "assert only `path:` lines moved" test outright**: any Book that
        hashes a payload containing a path will show the change as an opaque hash diff. Alongside that it
         drifts `self,round=6 → 5` and loses `Preview,seq:*` chunks at step 2 — the same pacing
          instability the Radiation family has ([[radiation-books-red-at-baseline]]).
   - MusuMag's fixtures already carry `now=`, so unlike MusuRaStream its trouble is **not** the missing
      clock pin that `Mag_todo` §0.2c blames. That entry needs correcting too.

   **MusuMag's nondeterminism is now MEASURED, not suspected.** Two clean runs at one unchanged build:

       steps 1-3   identical
       step  4     f3a646d8248eefdb  vs  7bdd6a1b4f182440
       …           every step 4-10 differs

    So **MusuMag cannot be safely re-recorded** — whichever run is accepted, the next run contradicts it
     from step 4 on. Exactly the Radiation-family verdict, reached the same way. (The two runs were on
      two different runner tabs, which is if anything the stronger test: a fixture has to hold on any
       runner, not just the one that recorded it.)
   MusuBuddy is red 1/14 on a clean run, and its fixture also already carries `now=` — so like MusuMag
    it is NOT the missing clock pin `Mag_todo` §0.2c blames. **That §0.2c entry wants correcting**: of
     the four Books it names as needing the pin, MusuRaStream genuinely lacks it while MusuMag and
      MusuBuddy already have it and are red for other reasons.

   **Consequence: do not treat this as a bulk re-record.** Four Books need nothing; MusuOgg is the one
    clean assertable case; MusuMag is proven unsafe to accept and MusuBuddy/MusuReap are unverified but
     suspect. The bulk re-record this entry has been waiting on the human to authorise would, if run
      today, have baked noise into at least one Book and touched four that did not need it. Roll the re-record into any later
      testing round — it does not rot, and deferring is if anything SAFER: the stale fixtures still hold
       the old truth, so if the human reads the path change and disagrees with it, the revert is trivial
        and nothing has been overwritten. Re-record once the belief is agreed, not before.
   The only live cost is that a *new* regression inside those 8 Books would hide in this known redness.
    Bounded, and now written down — which is what makes it safe to leave.
   When it is done, the diff is *assertable rather than reviewable*: every changed line must gain
    exactly the prefix `testsounds/` on a `path:` field and **nothing else may move**. Verified on
     MusuOgg step 2:

        - path:DJ Oscillo - Cosmic C.wav
        + path:testsounds/DJ Oscillo - Cosmic C.wav

  **Assert that shape over the whole diff rather than eyeballing it** — if any other field moves, the
   change did more than it claims and the re-record is the wrong response.

  **A SECOND STALE-FIXTURE FRONT, found while trying to gate the above: `MusuRaStream` is 0/40 red at
   BASELINE.** Proven by controlled revert — my Ra.g hunks stripped, recompiled to `4938d5f513f1067e`
    (the build hash §0c already records as current), re-run: still 0/40. So it is not the PCM work.
   The tell is in step 1 and it is one key: the live snap carries `w:MusuRaStream,now=1751980010` and
    the fixture carries a bare `w:MusuRaStream`. `Radiation.g:78` pins the swarm clock
     (`w.sc.now = 1751980000 + 10*n`) — the value matches *exactly* at n=1 — and that pin has been in
      since commit `7935704a` (**2026-08-05**), while the fixtures were last committed `7640a284`
       (08-07). So the fixtures postdate the pin and still lack it, which means **they were not recorded
        from a live runner** — the CLAUDE.md headless-boot trap, whose fixtures match themselves and go
         all-red on the real runner. Downstream the divergence widens (the pinned clock feeds every
          signature, `since` and grant — `Radiation.g:824` says so in words), so by step 2 the live run
           is a whole round behind the fixture and missing the `%Record` + its `%Preview` chunks.
   **Consequence for anyone reaching for a gate: MusuRaStream currently gates nothing**, and the same
    doubt hangs over its Radiation.g siblings (`MusuRaChase`, `MusuRaStock`, `MusuRaTerm`, `MusuRaCast`).
     Re-record from a LIVE runner before trusting any of them. ⚠ And note this Book is **not provably
      deterministic run-to-run** — two runs at the same build agreed on steps 1–13 and diverged from 14
       on. Until that is settled, *"diges differ"* is NOT sufficient to attribute blame on this Book;
        the determinism check (same build, twice) has to come first. That check is itself the next move
         here, and it is cheap.

  **The live bug still open — "finding the folder…" forever.** Measured on Righto: 16 %Records in the
   friend mirror, and **zero occurrences of `rummage` anywhere in the radio world** — no tag, and no
    `%Rummage` ask particle at all. So the folder-describe round trip is never *sent*; the face is
     honestly reporting `nTracks === 0`. **The trap that cost this session an hour: the DIRECTORIES row
      renders from the persisted `keep.sc.dirs`, not from husks** (`dirsRaw` falls back to `sc.dirs`
       first), so the cell looks like it is filling while nothing has arrived. Do not read that row as
        evidence of husks. **The short read HAPPENED (2026-08-07) and the worlds MATCH** — with one
         correction to the premise above: `Heist_rummage_ask` mints its bay in the **STATION world**
          (`Heist_keep_step:1762` passes the beat's `w` = w:Swarm down; `Ra_home_bay(w,…)` homes there),
           so "zero `rummage` in the radio world" is what a HEALTHY run looks like too — my asks live in
            w:Swarm, only the described husks' `rummage:` tags land in the radio-world mirror. Mint vs
             scan: `Radio_keep` mints `Ra_home_shop(n.c.w, Radio_pub)`; the beat scans
              `Ra_home_shop(top_House().c.radio_w, ident.sc.prepub)` — same world (both stamped from the
               dial's world, Radio.g:38/1148), same `me` (both off `Swarm_live_self`). So the discriminating
                probe is now LIVE, not static, and it forks three ways on the stuck tab:
                 · %Heist absent everywhere → the mint/drop is the bug (or `Radio_pub` fell to `'me'`);
                 · %Heist present, `sc.asks` never climbs → `Heist_keep_step:1732`'s silent
                    `if (!route) return` (no station `%Peering` named my prepub — streaming does NOT prove
                     this, wants ride pre-registered `playing.c.rx`), or the beat dies pre-GO
                      (`w.c.heist_beat_why` on the station world holds the throw);
                 · `sc.asks` climbing → asks ARE sent; search the STATION world for `%Rummage` and chase
                    the answer/mirror side (`w.c.repli_mirror_w`, Repli.g:860).
                `sc.asks` snaps, so a plain world snap of the stuck tab answers the fork.

  **Both of the below are now BUILT (2026-08-07 evening) — compiled, not yet live-verified.** Ra.g
   `47f469ccf6cb4fc2`, Radio.g `081cb7f75201bca4`. What each turned out to be:
   · the **11 GB tab** is `rec.c.pcm` — whole-file decoded PCM, ~92 MB per 240s track. The write-up
     named three exits that never free it; there was a **FOURTH, and it is the dominant one in a live
      tab**: `ra_hot` is **per-WORLD and there are two**. `Radio_supply_go` drives the encode with the
       RADIO world (`radio.c.w`), `Swarm_share_beat` drives the pump with the STATION world — and the
        eviction belt lives *inside* `Ra_transcode_pump`, which in prod is only ever called with the
         station world. So every locally-played track's PCM landed on a registry **nothing sweeps**,
          freed only if its encode ran to completion. Skip a track mid-play and its 92 MB is pinned for
           the life of the tab. That is "climbs monotonically with uptime", and it is exactly what a
            listener does all day.
     **The cure is an owner, not a fourth patch.** `Ra_pcm_hold` / `Ra_pcm_sweep` / `Ra_pcm_bytes`
      (Ra.g, beside `Ra_source_pcm`): the registry is **tab-singular** — the top House's `.c`, like
       `c.radio_w` — so it cannot be escaped by minting in the other world, and it is joined at
        **acquisition**, so no exit between decode and encoder-open can slip past it. The sweep frees on
         idle (30s, `M.c.ra_pcm_idle`) with an open encode as an absolute veto, then a ~384MB belt
          (`M.c.ra_pcm_cap`) oldest-touched-first that is deliberately **un-vetoable** — a belt that can
           be vetoed is not a belt. `ra_hot` keeps its old meaning untouched (the open-encode lead list);
            this is a second, orthogonal list about bytes. All `.c`; zero fixtures and zero Books name
             any of it. New `pcm-free` trace mark (`why:idle|cap`, with MB) so a live tab can be *shown*
              freeing rather than asked to prove a negative.
     ⚠ **CORRECTION 2026-08-08 — the owner + belt was HALF the cure, and on its own it livelocked.**
      The belt is a **memory** bound; it is not a **rate** bound, and "un-vetoable" is exactly what made
       that bite. With 8 parked wants standing up ~736MB against the 384MB cap, the sweep shed open
        encodes, the next pump pass found `rec.c.pcm` null and re-kicked a full 92MB decode, forever —
         and `Ra_pcm_backoff` never braked it, because that ladder arms on FAILED decodes and every one
          of these SUCCEEDED. Measured: 28 decode-starts of the same 8 records against TWO heist serves
           in 136s; every track dead at 0:32; the CPU pinned; the inbox over its 2000 cap DISCARDING
            `repli_lines`. **The missing organ was admission** — a census gate in `Ra_transcode_pump`
             plus `Ra_pcm_admit` at the decode kick. The rule: *an eviction bound and an admission bound
              are two different organs, and a belt with no admission upstream of it is a livelock
               generator for any working set larger than the cap.* Full write-up: `Backpressure_todo`
                §3.1e and `Composition_todo` §3.12. Everything above about the *registry* (tab-singular,
                 joined at acquisition) stands unchanged — it was the belt's sufficiency that was wrong.
   · the **"own tracks cut at 32s"** was `Radio_supply_go` (Radio.g) reading the FIRST `null` from
      `Ra_transcode_ensure` as a verdict — capping the track at its preview and writing the note
       *"source unreadable"* about a source it had not finished reading. It is **deterministic, not
        flaky**: ensure returns null on its first call for any track whose PCM is not already decoded
         (it kicks the decode off detached and bows out, by design since 2026-07-28). It only ever
          *looked* intermittent because a track whose PCM was warm from an earlier play sailed through.
       Now only a KNOWN death caps, and each has its own tell: `rec.c.pcm_dead` names the two silent
        ones (no card / no nav), `rec.c.pcm_why` a decode that actually threw, and pcm-present-yet-still-
         null means `Ra_encode_open` refused. Anything else is the decode still running, so it waits
          (bounded `w.c.ra_decode_wait`, 60s, and the enclosing loop is era|rec-gated so a skip exits at
           once). Capping at the bound now says *"too slow"*, not *"unreadable"* — at that point slow is
            all we actually know. `MusuOgg`'s driver had the identical bug and cure (`Heistation.g`,
             2026-08-05); this is the same fix at the live-playback seam.
     **No Book drives `Radio_supply_go`** (its only caller is `Radio.g:354`, live playback), so this
      half is Book-inert by construction and can ONLY be verified by ear: play an own track and hear it
       pass 32s. That is the one thing owed on it.
   · **boot is ~35s before any music can move** — see the new TODO at the tail of `Radio_todo.md`.

  **The pattern worth carrying forward: "not yet" reported as "never".** Three instances in one day —
   `Radio_supply_go` saying *source unreadable* when it means *still decoding*; the boast sending
    `records:0` when it means *census not built*; and the skeleton animating *finding the folder…* for a
     request that was never sent. Each writes down a false fact and moves on, and each self-heals only
      by luck. When something reads as flaky-but-eventually-fine, look for this shape before timing.

  **Still unjudged:** the `Heist_census_heads` `body_hash` guard (§ below). It was misattributed once
   already and reverted. MusuHeist is now a *trustworthy* gate — the step-2 flake was a real race in
    `Heistation.g` (census settled outside the belief loop; a wake is not a hold), fixed with a one-shot
     ttlilt gate, 7 consecutive greens, no fixture footprint — so the guard can finally be tested.

0. **"LOFI" — a `.ogg` heist for phones. BUILT 2026-08-07, source-side, ONE ATTENDED HAUL STILL OWED.**
    The human: *"transcoding to ogg for people's phones will be important."* What landed, and why in
     this shape:
    - **The bomb below was dissolved, not defused.** Nothing muxes the radio crate's chunks. The
       SOURCE decodes its own file and encodes from **sample 0** (`Orig_ogg_from_source`, Orig.g:
        decode a *copy* — `decodeAudioData` detaches — → `Ra_lufs`/`Ra_gain_for`/`Ra_bake`, the same
         loudness the stream gets → `Ra_encode_*` → `Orig_ogg_mux`). `pv_off` never enters the path.
    - **The swap rides inside `Heist_materialise_one`**, between "read the whole file" and "chunk it".
       So per-chunk cids, `body_hash`, `total`, the wire, backpressure, resume and the sink's
        read-back verification are all **byte-agnostic and unchanged** — the source hands back a head
         whose `path`/`ext` already say `.ogg`, and the sink's landing needed no edit at all.
    - The ask carries `lofi` as a **plain prop, not a loc key** (`Heist_rummage_ask`) — one keep picks
       one mode, so a lofi and a plain ask for the same ref are the same particle. Idempotence is
        mode-aware (`Heist_materialise_one` re-materialises when the held mode differs); a failed
         transcode falls back to the original and says so on the console rather than serving nothing.
    - **UI: both doors.** `HeistFace` (the ⇊ glass cell — this is the one the human actually uses) via
       `Heist_keep_set_lofi`, and `HeistSetup.svelte` (the fullscreen Panel funk) via its checkbox and
        `Heist_keep_commit`'s `lofi` arg. Both write the same `keep.sc.lofi`, which
         `Heist_keep_step`'s want-ask reads — so the mode is settable right up to ▶ start and inert after.
    - **The gap: `Orig_ogg_from_source` has no Book.** `MusuOgg` gates `Orig_ogg_export` (mux from
       opus chunks), a *different* entry point. Green there says nothing about this path. It needs one
        attended two-tab heist with the box ticked, and that is the only thing standing between this
         and done.

   The original design note follows, kept because the bomb it names is still live for anything that
    ever *does* try to mux the radio crate:

   **The good news: the codec work is DONE and Book-proven.** `Orig_ogg_export` (Ghost/M/Orig.g) already
    collects a Record's opus packets, muxes a real RFC-7845 Ogg/Opus stream (`Orig_ogg_mux`, with the
     un-reflected CRC-32 in `Orig_crc_table`), writes it via `nav.bin_write` and mints
      `%Blob,id:<rec id>,grade:ogg128` beside the Record. `Orig_ogg_parse` re-reads it structurally and
       `MusuOgg` gates the lot. Nothing new needs writing at the codec layer.

   **The seam: a lofi heist is a DIFFERENT PULL, not a post-step on the normal one.** A heist pulls the
    ORIGINAL file's byte chunks out of `srcmir` and gates them on `rec.sc.body_hash` (`Heist_land_stream`).
     The opus segments live on a *different* mirror — the radio's `%MusuThem` crate. So lofi should not
      download the original at all: take the opus already streamed (or finish streaming it, far cheaper
       than a FLAC), mux, and write `<rel with .ogg extension>`. That is the whole appeal — a phone-sized
        heist that is mostly already on disk.

   **⚠ THE BOMB, and it is one I planted today: `pv_off` collides with this head-on.** The %Preview offer
    now starts **30–70% into the track** (`Ra_preview_offset`, so the shuffle game jumps into the middle
     — Radio_todo §0). The mirror card carries `pv_off`, and its chunk 0 is therefore NOT the start of the
      music. Muxing that crate's chunks straight through `Orig_ogg_export` would produce a file that
       **begins mid-song**, silently, and land it in the collection looking correct. So lofi needs a way to
        ask for the opus **from segment 0** — the source holds the full encode in its own stock, only the
         OFFER is offset. Options, unranked: a `want` that names `from_idx:0` against the source's own
          record rather than the offer's window; or a distinct "full" offer minted on demand. **Settle this
           before writing any UI** — a tickbox wired to a path that truncates tracks is worse than no
            tickbox.

   *(The wiring sketched here — carry the flag to `Heist_keep_pull` and branch per pick — was NOT what
    got built. Branching at the SINK would have meant a second landing path to keep correct; branching at
     the SOURCE's materialise means there is only ever one.)*

0b. **A MARKER-PREFIXED FOLDER IS A SECTION (2026-08-07).** The human: *"it still isn't noticing the '0
     spawn' and '0 folks' are sections."* The shelf reads
      `0 spawn/- folks/- arabia/<album>/<track>` — the leading run of `- `|`0 ` segments is the source's
       own filing, said in exactly the vocabulary the heist uses for the destination. So:
    - `Heist_sections_of(path)` → the leading run as a normalised category (`0 folks/0 arabia`);
       `Heist_sections_strip` → the rest, which is what a cp copies. `Heist_cp_path` goes through the
        strip, so manifest, preview and landing agree by construction. (Was `Heist_spawn_strip`,
         literal `0 spawn` only.)
    - `Heist_keep_default_section` stamps the **common** section run across the husks as the keep's
       category when it has none — the section only *some* of a keep lives in would be a lie. Guard on
        `.c`, so a keep with no sections grows no snapped key and no fixture moves.
    - **`HeistFace`'s `directories` row now reads the CP, not the raw path.** That was the visible bug:
       the sections got swallowed into `directories` and then *also* prepended under whatever category
        you chose, so the keep landed filed twice.
    - **HeistSetup stopped mirroring the ghost** and calls `Heist_cp_path` / `Heist_genre_norm` /
       `Heist_sections_of` directly. The hand-copied re-implementations are what drifted the moment the
        ghost learned about sections, and a destination preview that is wrong is worse than none.
    - Book-inert by construction and verified: **no recorded fixture anywhere carries a marker-prefixed
       path segment**. MusuHeist 22/22 · MusuRename 9/9 · MusuVend 11/11 · MusuOgg 6/6 · MusuStock 5/5
        (control), and the only fixture churn across the batch is `TimeSpool` samples + `GhostInclude`
         diges.
    - **The landing fallback is the load-bearing half** (added after the first real sectioned heist landed
       naked at the music root): `Heist_rel_for` falls back to `Heist_sections_of(rec.sc.path)` whenever
        no category is pinned. Stripping sections without that is not "not noticing" them — it is
         *destroying* them. `Heist_keep_default_section` is now only the UI courtesy that lets HeistFace
          show and edit the section; the landing no longer depends on it having run.
    - `Heist_defaults_get()` IS read — from **`Radio_keep` (Radio.g)**, not from anywhere in Heist.g, which
       is why a grep scoped to this file says "no callers". It stamps the remembered category onto a keep
        at mint. Currently `''` on this machine, so it is inert here, but a keep minted with a remembered
         category will (correctly) beat the source's sections.

1. **The two-pier live test HAPPENED (2026-08-06) and it was worth it — read §4.1 first.** The human
    ran a real 8-track heist between two tabs. It wedged twice, at two different rungs, and both were
     real bugs invisible to every Book: an intra-page hole that was never re-asked
      (`Backpressure_todo.md` §3.1b, fixed — the heist went from frozen at 254/255 to landing the
       track) and then the source going **permanently deaf after three answers** (§4.1, fixed). What
        this says about the shape of the coverage: **no Book anywhere mentions `rummage`**, so the
         whole materialise-ask protocol is untested, and both bugs needed a real multi-track heist
          against a real peer to appear at all. The 2026-08-05 batch (the `%Heist` rename, §7's resume
           fix, §5's `- `→`0 ` land rule, §6's four HeistFace fixes) rode along in that run without
            surfacing anything, but none of them was checked *individually* — treat them as exercised,
             not as verified.
   **Next on this thread:** the regression gate §4.1 says is owed, and the repeated
    `heist-release` in §4.2.
1b. **Three rummage realisations from the §4.1 session (2026-08-06), parked here so they survive it:**
    - **Derive, don't remember.** `Heist_keep_id(me, base, path)` is a pure sha256 — the source's
       keep-id map is a *cache of a pure function*, not unknowable state. If the ask carried `path`
        (already a scalar riding the husk, `Heist.g:166`), the source could VERIFY instead of look up:
         recompute the id, check it matches, check the path sits inside a granted base. Stateless
          across reloads — it obsoletes the 20s re-census, the 3-strike counter, `keep_memo`, and the
           §4.1 answer budget in one move. The strongest candidate for the "source reload mid-heist is
            still a cliff" complaint; needs a human look at the path-disclosure surface (the asker
             already holds the path, so nothing new crosses the wire).
    - **`RummageLib` → `RummagedThrough`** (the human's name, 2026-08-06): the census result is
       distinct from both `%Rummage` (the ask) and `%Library` (the holding), and the current name
        falsely claims kinship with the latter. The rename is FREE — the string appears in zero
         fixtures and zero Books. (`Census` as a mainkey is taken, `Sounditron.g:462`.)
    - **The `dontSnap` blind spot needs a flag, not a UI.** `dontSnap` prunes at ONE encoder seam
       (`Text.svelte:809`); an opt-in "descend dontSnap" mode on `runner_ask world`'s snap would
        expose every `%RummageLib` and parked `.c` want through the CLI that already exists — no
         Vyto stretch.
2. **`%pub` standardisation, part 2.** `%pub` means a pier's prepub — true everywhere except four
    identity carriers that put a FULL key under `pub`: the roster `%Identity` row (`Swarm.g:1946`),
     `%Peering` (`Swarm.g:1171`), `%HostedIdentity` and `%Runner` (`LiesLies.svelte:1593/1607`).
      Those want `fullpub`. Deliberately NOT in the same batch as the heist rename: it lands in the
       grant-verification path (`prepubOf(pub) === the HostedIdentity key`) and churns the Cluster
        fixtures, so a red there would have two suspects. Reads must fall back to `pub` for
         migration; the WIRE `page.pub` should stay as-is (renaming it breaks an older peer).
3. **The inter-track rest** (§4) — the pre-ask is supposed to hide the source's materialise behind
    the tail of the current track, and observably doesn't always. The `ev:'pulls'` electrode was
     added to show `cap` vs `drove` per heist; it needs a run with the trace armed (§9).
4. **A general `Dexie/$somewhere ↔ .jamsend/$somewhere` sync.** Heist persistence (§7) is one bespoke
    pipe; identity has its own bespoke half (`Identity_persist_todo.md` steps 3-4, `Swarm_spec.md
     §171`, both `[want]`). The human's read: these want to be ONE named-store-each-side mechanism.
      Not started, likely the next drift.
5. **`marrauding` is a typo** (double-r) living in the on-disk dir name, the verb, and literals in
    `Heistation.g` / `Berthation.g`. No recorded fixture contains the string, so the rename is safe
     whenever wanted — left alone only because those Book files are open in another thread.

---

## 1. The arc — ⇊ to bytes on disk

`RadioFace.svelte:84` → `Radio_keep` (`Radio.g:1477`) mints
 `%Heist:<title>,seed:<content-id>,pub:<their prepub>,state:'primed'` under my own loading zone
  (`Ra_home_shop`). Idempotent: a second press on the same seed no-ops. Own tracks are already held,
   so ⇊ only shows on a friend's track.

The states:

- **primed** — the seed is still the track you are listening to. LINGER: describe the folder
   (metadata heads only, cheap, no reads) so the face can show a track tree to tweak, default-keep
    the whole described folder, and dose the cell up so it is space-favoured in the clutter. Never
     ask for bytes while the seed is playing — that fights the live stream for the same wire.
- **wanted / asking** — legacy entry points, route into the same branch as primed.
- **pulling** — the seed stopped playing. Fold down (dose deleted), then materialise + pull + land
   every `%Pick` through the window in §4.
- **done** — the ✓ lingers ~8s, the Berth entry is forgotten immediately, then the heist drops
   itself. A finished heist is scaffolding, not ledger.
- **choosing / committing** — the dormant `HeistSetup.svelte` chooser path. See the landmine in §4.

## 2. The particles

    %Heist:<title>,seed:<content-id>,pub:<their prepub>,state:…   the standing intent, under Ra_home_shop
      %HeistBar,dontSnap                                          the controls cell (HeistBarFace)
      %Pick,ref:<id>[,artist,title,genre,landed]                 one track, one chip
      %Caper,at:<their prepub>                                   the JOB — filing decision + landing
    %Rummage                                                     an ask, in the mirror of whoever asked
    %Record,husk:1,rummage:<seed>                                a described folder track, not yet materialised

`%Heist` is imposed a face by mainkey (`glass_faces.ts`), so no snap ever changes because the glass
 chose to dress it. Under the nested glass a `%Heist` goes BARE and tessellates into its `%HeistBar`
  plus one `%Pick` chip per track.

A **heist-id** (`Heist_keep_id(me, base, path)`, sha256 of pub+path) is deliberately DISTINCT from the
 streaming content-id, so a materialised original can never upsert onto the seed's opus record.

## 3. The pump — there is no req pile

The heist is **not** driven by the req machine. No ttlilt, no maz level, no todo gate. It rides
 `Swarm_share_loop` (`Swarm.g:1578`): a plain detached `setTimeout` chain at **~600ms**,
  era-guarded, and **busy-guarded** — if the previous beat is still running the tick is SKIPPED, not
   overlapped (added 2026-07-30 after two concurrent steps double-wrote a landing).

Each tick: `post_do` → `Swarm_share_beat` → `Heist_keep_beat` (`Swarm.g:1742`, typeof-guarded and
 try-wrapped so a heist bug cannot break the radio share) → `Heist_keep_step` per heist.

**600ms is the heartbeat of the whole feature.** Every state transition costs at least one tick, and
 a beat that overruns costs more than one.

`Heist_keep_beat` also does the source-side housekeeping each beat: prune the `%Transfer` HUD's stale
 entries, sweep aged serve-libs (30min TTL, DETACHED so their `%Body` bytes GC), release
  after-serve any rec whose every page has crossed and whose last want is idle, and a ~256MB
   byte-cap belt that releases oldest-served-first. Those three together are what killed the 3GB
    source-side cliff.

## 4. The window — backpressure, and the rest between tracks

In the `pulling` branch (`Heist.g:~1528`):

- `heist_inflight` = **2** — at most two picks being worked at once.
- `heist_overlap` = **24** — open the second slot when the active track is within 24 chunks of done,
   so the next track's materialise starts while the current one finishes.
- A pick whose husk has no `total` fires `Heist_rummage_ask`, **throttled 4s**, and shuts the window
   (a pending materialise is one whole source-side file read).
- 45s bench watchdog, 5s breach cooldown.

**Why it still rests between tracks.** Three costs, each at least one 600ms tick apart:

1. The landing runs INSIDE the beat. A big track's land (read-back + hash) overruns 600ms, and the
    busy guard then skips ticks — so the beat that should have pre-asked track N+1 is the beat still
     finishing track N.
2. N+1 then has no `total`, so it must ask and wait for the source to materialise. That is the
    "filehandle takes time to start retrieving".
3. That ask is throttled 4s, so a mistimed one costs four seconds flat.

The fix is not a bigger `OVERLAP` — it is making the pre-ask independent of the landing beat.

**LANDMINE.** There are two pulling loops. `state:'pulling'` uses the gated one above.
 `state:'committing'` (`Heist.g:1670`) calls `Heist_keep_pull` — the legacy **ungated** loop that
  drives `Ra_pull_beat` for every un-landed pick every beat, which is the all-parallel behaviour
   that ate 3GB on the source. Only reachable from `HeistSetup.svelte:139`, the chooser path the
    code itself calls dormant. If every progress bar ever advances at once, that is where you are.

### 4.1 The source went permanently deaf after three answers
 *(FOUND + FIXED 2026-08-06, on the human's live two-pier heist)*

The ask above is only half a round trip. The other half — `Heist_rummage_answer`, driven from the
 source's `%Rummage` sweep (`Heist.g:~1461`) — bounded its work with

```
let n = +(ask.c.answers || 0)
if (n >= 3) continue                 // "re-answer a FEW times"
```

whose comment says it exists to heal **one lost answer frame**. That is an *episode*-scoped
 concern, but it was keyed to a **session**-scoped particle:

- `Heist_rummage_ask` is **idempotent by key** — `bay.o(key)[0]`, and only `.bump()`s an existing ask.
- It carries `repli_loc ['Rummage','want','pier']`, so at the source each re-ask **upserts onto the
   same mirror particle**. By design; the header says so.
- `.c.answers` therefore lives on a particle that is never replaced and never reset.

So the bound was really *"answer this peer about this ref three times per session, ever"*. Ask #4
 onward was silently dropped while the asker re-asked every 4s and re-censused every 20s **forever**.

**The evidence.** Sink trace: `reheal [088fda97] unanswered=51 … 121` climbing, and
 `heist-noprogress asked=124 landed=1 of=8 secs=267`. Source trace over the identical window:
  **nothing** — no `heist-serve`, no census, no answer of any kind. One track had completed; the
   other seven could never start, because a pending materialise shuts the window (§4 above), so the
    whole 8-track heist was held by one deaf ref.

**Why nothing caught it.** Grep the tree: **no Book anywhere mentions `rummage`.** The entire
 describe-folder / materialise-one-file protocol — the path by which every real multi-track heist
  gets its tracks — has *zero* fixture coverage. It only manifests past the third ask, i.e. only on
   a real multi-track heist against a real peer, which is exactly what no Book does.

**The fix.** The asker now stamps a monotonic attempt number, `ask.sc.n`, and the source re-arms its
 ≤3 budget when that number moves (`ask.c.answered_epi`). The ≤3 / ≥5s throttle still holds *within*
  one episode, which is all it was ever for. An asker too old to stamp `n` pins at `'0'` and keeps
   the old behaviour, so it is safe against a stale peer. No fixture carries a `%Rummage`, so this
    moved no snap; the seven-Book transport set is at exact parity across the change.

**The standing rule:** *a bound meant to survive one lost frame must be scoped to the ask, not to
 the particle the ask lands on* — because an idempotent-by-key ask **has no arrival event** to hang
  a reset on. An upsert whose `sc` did not change does not even bump a version, so "the peer asked
   again" and "nothing happened" are the same observation unless the asker makes them different.

**Still owed:** a regression gate. It needs a Book with two piers that asks the same ref four times
 and requires the fourth to be answered — the shape `MusuBuddy`'s deliberate shed punch uses for
  §3.1b of `Backpressure_todo.md`. `MusuHeist` has the two piers but never touches the rummage path.

### 4.2 `heist-release` fired four times for one record — THRASH BOUNDED 2026-08-07
 *(observed 2026-08-06; the loop is now self-damping, the root cause still stands)*

**What landed (Heist.g `7cae4e10633c653c`).** The diagnosis below was right and needed no revision: the
 bodies DO come back between releases, because a parked want re-materialises the file. Two lines make the
  loop notice itself:
- `Heist_materialise_one` stamps `rec.c.remats` when it re-materialises a rec that carries `rec.c.released`.
   Reaching that line after a release IS the thrash event, and it is the expensive one — everything past it
    is the 65MB whole-file read plus a hash.
- the release sweep gives each record its OWN idle requirement, `RELEASE_IDLE * 2^min(4, remats)` — 45s,
   90s, 180s … capped at 16× (~12 min). A record that has already been released and re-materialised has
    proved *by evidence* that the previous release was premature, so it earns patience in proportion.
It stays a release and never becomes a veto: memory is still bounded, the byte-cap belt is untouched and
 can still shed anything, and a record nobody wants goes quiet and falls off exactly as before. What dies
  is only the tight loop.

**The root cause is UNCHANGED and still owed.** The gate asserts *"I have sent it all"* (`sent >= tot`, a
 high-water frontier) where it means *"they have got it all"*. That guess is now cheap to be wrong about
  rather than pretending to be right; the actual cure is a confirmed term — `Backpressure_todo.md` §5.6's
   ack-clock. Do not consider this closed, consider it de-fanged.

The original diagnosis, kept because it is the reasoning:

The source's trace carried `heist-release [54fef1fc] of=255` **four times** for the one record,
 28s / 20s / 14s / 62s apart. `Heist_release_rec` returns early when the rec has no
  `%Original`/`%Lossy` children, so for it to fire again the bodies must have come **back** between
   releases — i.e. A3's parked-want producer re-materialised the file (`pcm-read bytes=66631692`,
    a 65MB read plus hash) and the 20s idle sweep dropped it again, repeatedly.

That is a plausible second contributor to the human's *"burning CPU!"* which §3.1b does **not**
 explain: a track the sink has already completed being re-read off disk every 20-60s.

Check it against the two fixes above before chasing it — with intra-page holes healed (§3.1b) and
 the source no longer deaf (§4.1), the re-ask that re-parks the want may simply stop, and this with
  it. If it survives, the release gate (`sent >= tot && want_ts idle > RELEASE_IDLE`) is asserting
   "I have sent it all" where it means "they have got it all", and wants a confirmed term — which is
    `Backpressure_todo.md` §5.6's ack-clock, not a local patch.

## 5. Landing

`Heist_land` → `Heist_land_stream`, per chunk: cid gate, `bin_write`/`bin_append`, release the buf.
 Then the wire digest, then a whole-file read-back + hash against `body_hash`. A mismatch lands
  nothing and stamps the breach.

**Paths.** A heist is a **cp**: the source's own filename and folder layout survive unchanged — tags
 catalog and display a track but never rename the file. `Heist_rel_for` picks the dest-root from the
  filing decision and the source's relative path rides underneath. If the heist carries a frozen
   `dirs`/`dirs_auto` pair, `dirs_auto` → `dirs` is substituted at the FRONT of the cp path **only
    when that record's own leading segments still match** — never a blind rename, so a multi-disc
     heist's CD1/CD2 divergence below the shared prefix survives.

**Segment safety** (`Heist_safe_seg`, directory levels only — `Heist_cp_path` does not come through
 it, per the cp ruling): `/` and NUL become `-`; everything else — spaces, punctuation, unicode,
  mixed case — is KEPT, because the tree should read like a record shelf. And since 2026-08-05, a
   **leading dash becomes `0 `**: a file or folder whose name starts with `-` cannot be handed to a
    shell command as a non-flag. `- chill` lands as `0 chill`, matching what the face already shows.

There is no `music/` prefix and no per-job root. Landing is the true FSA root, unconditionally, in
 dev and prod — except for the mardir seam in §8.

**Categories** sort topward with the same `0 ` marker (`Heist_cat_path`, nests via `/`). Both `-`
 and `0` still READ as a category everywhere, so nothing on disk needs touching; a collection
  migrates one touched category at a time.

## 6. The face

`HeistFace.svelte` (was `KeepFace.svelte`). Two separate, never-merged, never-enclosing hierarchies:

- **section** — mine. The category. Stamps its marker automatically, never typed.
- **directories** — theirs. The shared source-folder prefix across the described tracks. Wired into
   landing via `Heist_keep_set_dirs`, which freezes BOTH the override and the auto-detected value at
    edit time.

At rest each is a calm `/segment/segment/` breadcrumb. Click to edit: a row of chips, one per
 segment, each with its own × and now **editable in place**; a "+" gap before/between/after every
  chip (N segments ⇒ N+1 gaps) inserts at exactly that position. The ✓ **commits whatever is in the
   boxes** — it used to only close the editor, silently dropping typed-but-not-ENTERed text.
    Directories chunks word-break inside a name so one long source folder cannot set the cell's
     width. Group labels in the track tree no longer restate the directories row: the prefix match
      is MARKER-BLIND, so `- chill` / `0 chill` / `chill` are one directory.

`Heist_known_categories` / `Heist_known_dirs` scan the library's own `%Record.sc.path` to feed each
 breadcrumb's datalist, so a near-duplicate folder is a visible choice rather than an accident.

Global remembered defaults (`Heist_defaults_get/_set/_rehydrate`): the category a heist is set to
 becomes the next heist's default, dual-homed in `H.stashed` (Dexie) and a `HeistDefaults` Berth
  Waft. `directories` deliberately does not feed this — it is source-specific and means nothing for
   a different friend's structure.

A folder group of more than 5 tracks collapses by default (a real `<details>`).

**The face used to snap shut, and that was never a heist bug.** `replace()` publishes the empty half
 of its own transaction, and `agency_officing` (`Hovercraft.svelte:133`) replaces every actor's `w:`
  children every tick — so Vytui's `{#each vyto_worlds() as w (w)}` got a 0-length list once per
   tick and destroyed every face in the glass. Fixed at the READER: `ui/micro/hold.ts` plus both
    Vytui structural gates. Full chain and the three cures: `reactivity_docs.md`, first section.
     Confirmed live by the human 2026-08-05.

## 7. Persistence and resume

`Heist_keep_persist` writes `%HeistSeed,seed:` with real `%Pick` CHILDREN into the Berth at
 `.jamsend/berth/<prepub>/Heists`. `Heist_keep_rehydrate` replays them on boot straight into
  `pulling` (the human already confirmed the heist, before whatever reloaded), then
   `Heist_resume_sync` does the honest work of finding what is already correctly on disk. Resume is
    at the LIST level, never inside a file.

**The 2026-08-05 resume bug, and why it matters beyond itself.** Rehydrate ran once per radio-world
 life, and burnt that one shot on its FIRST LINE — before the Berth read. `nav` comes from
  `Crate_nav()`, and on the first beat after a reload it is null: the FSA handle restore is async and
   a fresh grant waits on a human click. So the first beat spent the single shot against a null nav
    and resume was dead for the entire page life, silently. Now: `if (!nav) return` without burning
     the gate, the gate burns only after the shelf is actually READ, and a throwing `Berth_open`
      counts to 10 rather than latching. Same treatment for the caller's `catch`, which had the
       identical shape.

The general lesson: **a one-shot gate must be spent on success, not on attempt.** Anything gated
 `if (x) return; x = 1` at the top of an async boot-order-sensitive function has this bug latent.

**SWEPT THE WHOLE TREE FOR THAT SHAPE, 2026-08-07 — and it had two more live instances, both here.**
 The lesson above was written as folklore; it is mechanically searchable, so it got searched:

    awk '/^async |^[A-Za-z_][A-Za-z0-9_]*\(/ {fn=$0}
         /if *\(.*\.c\.[a-z_]+\) return/ && g=="" {match($0,/\.c\.[a-z_]+/); g=substr($0,RSTART+3,RLENGTH-3); gl=NR}
         g!="" && NR<=gl+4 && $0 ~ ("\\.c\\." g " *= *1") {print FILENAME":"NR"  "fn; g=""}' Ghost/*/*.g

 Nine hits across the tree. Seven are sync one-shots whose work cannot fail (`prng_seeded`,
  `Stoker_wake`, `Stoker_preheat`, `stir_pending`, …) — the bug needs an **async** body that can fail
   after the gate is burnt. The two that qualified were both in this file, and both are now fixed:
- **`Heist_defaults_rehydrate`** — it guarded the Dexie-not-hydrated case beautifully and then burnt the
   gate one line before an `await Berth_open` whose `catch` just returned. A null `nav` (the same async
    FSA restore as above) killed the remembered-default disk fallback for the whole House life. Now: bow
     out unspent while preconditions are absent, spend once the shelf is READ, count 10 strikes on a throw.
- **`Heist_resume_sync`** — the worst placement of all, since resume IS the boot-order path §7 is about.
   It spent the gate on line 2 and dereferenced `nav` on line 3, so a first-beat-after-reload null nav
    threw a TypeError with the shot already gone, the caller swallowed it into `keep.c.last_why`, and
     resume was dead for that job's life. Now the precondition is tested before the gate is spent.
 Worth re-running that awk after any batch of new async boot code; it costs seconds.

Berth entries write `pub` from 2026-08-05 and READ `pub || at`, so a heist already persisted under
 the old key still resumes.

## 8. The test namespace — mardir and sweep

`Heist_mardir(w)` returns `w.c.mardir` or `''`. **`''` means the collection root** — production, and
 every existing path. Every live landing / newlyadded / resume-sync call routes through it.

This is a seam, not machinery. There are three small things and nothing schedules any of them:
 `Heist_meta_dir()` (returns `'.jamsend'`), `Heist_marrauding(runid, nick)` (builds
  `.jamsend/test-marrauding-of-<runid>/<nick>`), and `Heist_sweep()` (14 lines: recurse,
   `deleteEntry` every file, keep the dir skeleton). Books hand-call the sweep at start and end.

Until 2026-08-05 the marauding header claimed the app passed a real run uid. It did not — both live
 landing calls passed a literal `''`, so a heist from a live tab landed indistinguishably in the real
  collection, unsweepable. Setting one runtime knob now buys a sweepable namespace with landing,
   newlyadded and sweep all unchanged. Runtime-only (`.c`), so no snap moves and production is
    byte-identical.

`Heist_spawn_swap(job, rel)` rides alongside for the human's own app-testing: any path segment equal
 to `spawn` (marker-blind, so `- spawn` / `0 spawn` / `spawn` all match) is rewritten to
  `0 heisted-<from8>-<to8>`.

**Sweeps do not delete directories, on purpose.** A deleted-then-recreated directory strands the
 nav's cached FSA handle — "the landing that never lands". Aborted runs therefore leave an empty
  skeleton. Changing this means chasing the handle cache first; it is a real ask, not a one-liner.

## 9. Verifying

Books, always on a LIVE runner (`scripts/runner_ask.mjs`), never `Story_cli_run.mjs`: **MusuHeist**
 is the end-to-end heist, **Sounditron** the resident-session picture, **MusuLossy** the sweep. The
  snap-fixture diff is the gate; when a run goes red, diff the actual mismatch with
   `story_repl.mjs diff` rather than stopping at "red" — the last two reds were both pure fixture
    staleness.

The supply/heist trace ring (`Radio_trace` → `M.c.supply_trace`, capped 300, ~1 Hz `dial` mark, so
 only ~4.5 min of history) carries `land` and `pulls` marks for this feature. It flushes to
  `wormhole/_trace/` via `Lies_dump_supply`, armed by the **same** `socklog_armed()` flag as socklog
   (the 🪪 hatch toggle / `?socklog` / `?watch`), no reload needed.

**Caveat that will waste your afternoon:** both dumps early-return unless `Lies_role(w)` is `editor`
 or `runner`, and a plain app tab has no role. Marks pile up in memory and never reach disk. Heist
  in a runner-booted tab, or drop the role gate on the supply dump.

`scripts/runner_shot.mjs` is the only way to see the render — pixels never round-trip a fixture.

## 10. Performance, as of 2026-08-05

Two real fixes landed after the human reported the downloader burning CPU and the uploader holding
 comparable memory:

- **O(N²) gone.** `Heist_land_stream` called `Ra_chunk_map(rec)[s]` per chunk — rebuilding the whole
   map for every chunk of every file. Now `Repli_chunk_bytes(ch)` off the chunk directly. Two
    sibling probes in `Radio_play_id` went to `Repli_chunk_at(x, 0)` for the same reason.
   **The "still open elsewhere" note that stood here was STALE — re-checked 2026-08-07.** The
    deal-shelf probe is already fixed: `Riffle_deal_shelf` (now `Radio.g:~2106`) reads
     `Repli_chunk_at(r, 0)`, with the swap written up in its own comment. A tree-wide sweep of
      `Ra_chunk_map` leaves one caller that looks loop-ish and is not — `Ra_term_decode_pulled`
       (`Ra.g:~2118`) builds the map once per record for a real decode that genuinely needs the
        bytes, which is the legitimate use. **No known O(N²) chunk-map probe remains in the tree.**
- **Native hashing.** `Heist_hash` and the per-chunk cid gate use `sha256_hex_fast` (crypto.subtle)
   rather than the pure-JS noble path that was 51.8% of the frame. The FORMAT CONTRACT is
    byte-identical between the two — see `Hashly.ts`. There is no native STREAMING api, so the
     incremental wire digest is still the one pure-JS pass; whether to drop it is an owed ruling.

## 11. Parked

The klepto engine (scope B, `Heist_design.md`) stays BUILT and PARKED. Production is scope A, above.
 `HeistSetup.svelte` — the fullscreen chooser Lens — is orphaned; nothing raises it, and the
  `choosing`/`committing` states exist only to serve it. Retire both together, mind the §4 landmine.
