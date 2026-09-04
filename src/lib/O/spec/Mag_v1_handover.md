# Mag v1.0 — handover (2026-08-05)

Continuation brief. Written at a resting point mid-push; **production is a week late**, so the
 organising question for everything below is *does this lose a user's music, or merely disappoint
  them?* Only the first kind is v1.0.

> ## NIGHT LOG — 2026-08-05, overnight
>
> Read this box first; it supersedes parts of the body below and says which parts.
>
> **Four changes are in the working tree, all verified. One more was written, costed and backed out
>  on purpose — that one is the Mag's `pub` key, and the reason is worth reading before you land it.**
>
> - **Bomb 1 is DEFUSED (verified).** `Ra_home_them`'s self-guard is deleted (`Ghost/M/Ra.g`, with a
>    comment saying why it can never come back). SwarmShare's mirror law goes green on the live
>     runner: the `%Theirs,pub:<them>` crate mints again, the `see:` sentence *"the mirror lands
>      keyed by the caster prepub"* notices at step 4, and **all four of SwarmShare's `see:` claims
>       now notice** (zero gaps). The body's **"DO NOT ACCEPT SwarmShare"** is RETIRED — it was right
>        when written (the failure then was an unearned `story_swear`), and that failure is gone.
> - **The identity table is IN and verified** (`Ghost/N/Repli.g`: `Repli_identity_keys` +
>    `Repli_loc_for`; `Repli_loc_keys` deleted). This is §0.1 item 5's ruled v1.0 step. Zero
>     regressions across the green set. **Read `Mag_todo.md` §0.2 for why it matters more than the
>      body suggests** — and read the honest limit on that verification, which is that no Book can
>       currently fail if the table is wrong.
> - **The Mag's `pub` key was NOT landed** — written, compiled, costed, backed out. It is a 21-Book /
>    ~250-snap re-record and five of those Books can't be re-recorded until their clock is pinned. The
>     exact one-line stamp is preserved in comments at both mint sites. Next-move step 3 has the case.
> - **The suite was STALE, not broken.** Four dated, deliberate rulings that every fixture predates
>    explain nearly every red Book. This is the single biggest correction to the body's picture:
>     `Mag_todo.md` **§0.2**–**§0.2c**, summarised under "Book state" below.
> - **Bomb 2 is BIGGER than the body says** — not three collisions but an entire vocabulary, and it
>    is losing data in shipped code today (`%Spin`/`%Like`/`%Grab` in a friend's `%Jam` ledger).
>     Census and evidence: `Mag_todo.md` §0.2. (`Jam.g`, `%Spin`, `%Like`, `%Grab` were deleted entire
>     2026-09-04, replaced by `Mag:heard,pub:<me>` — see `Radio_circuit_todo.md`.)
> - **MusuOgg was actually BROKEN, and is fixed.** Not staleness — the whole-track ogg128 export had
>    produced nothing since 2026-07-28, because `Ra_transcode_ensure` went non-blocking that day and
>     MusuOgg is a one-shot driver, not a pump. It took the `null` and never encoded a single `%Stream`
>      chunk. Controlled against the identity table (fails identically with the table bypassed), fixed
>       in `MusuOgg_stock`, and the Book's OWN unchanged expectations now pass. **§0.2d — read the
>        general lesson there, it is the most reusable thing found tonight.**
> - **Accepted, each audited so every changed line is one of the dated causes and nothing else:**
>    MusuFreeze, SwarmShare, MusuRename, MusuSoft, MusuVend, MusuBay, MusuDoor, MusuReco, MusuOgg —
>     all re-run green afterwards. Audit any of them with
>      `git diff -U0 -- 'wormhole/Story/<Book>/0*.snap' | grep '^[+-]' | grep -v '^[+-][+-]' | sort | uniq -c`.
> - **The swarm clock is PINNED** in all five Books that ran on the wall clock (§0.2c) — landed last,
>    as its own change, once everything above was verified. **MusuBuddy and MusuHeist are now green**;
>     both had been structurally incapable of it. The other three are blocked on things that are not
>      the pin (see "Book state").
> - **23 Books green**, from 12 at the start of the night. 2 need an FSA-live runner, 1 has a progress
>    race, 1 left alone deliberately. Full tally under "Book state".
> - **A caution about the runners.** Two were used that should not have been (`96d0cf88…`,
>    `f5da6599…` — the human's manual BigSoundland tabs, not in the editor's runner list). One was
>     hijacked into running MusuDoor and wants a reload. **Nothing was accepted from either.** Use
>      `58517b48…` / `a67a5d04…`. And read the SIX verification traps below — four of them are new and
>       every one of them cost this session real time.

Pairs with `Mag_todo.md` **§0.0** (the human's design rulings) and **§0.1** (the questions those
 rulings opened, closed the same day — including the `%Mag:shuffle` identity tension, which is a
  regression hiding inside a simplification) — READ BOTH FIRST. Also `Download_stall_handover.md`
   (the live two-tab download work this interrupted).

---

## Destination

Two live BigSoundland tabs, mutually sealed. One presses ⇊ on the other's collection and the tracks
 **pull over the wire and land on disk**. On the way there, a friend's collection should EXPLODE onto
  the scene as Mags — bounded, curated, already playing.

## The bomb — read this or you will chase ghosts

> **STATUS 2026-08-05 overnight — BOTH ARE NOW ADDRESSED; this section is kept because its diagnosis
>  is still the best account of WHY they mattered.** Bomb 1 is **fixed** (the guard is deleted, and
>   `Ra_home_them` now carries a comment saying why it can never return). Bomb 2's ruled v1.0 fix —
>    the sender-side identity table — is **in and verified**, and the census in `Mag_todo.md` §0.2
>     shows it was several times larger than described below. Read on for the reasoning; do not act
>      on the instructions.

**Two live, silent data-mashings are in the tree right now.** Both merge two different things into
 one particle, both are invisible to a passing glance, and both violate the identity-per-shelf law
  (CLAUDE.md: *"a thing exists ONCE under a given container as its mainkey"*). Neither is
   theoretical — each is visible in a live fixture diff today.

1. **`Ra_home_them`'s self-guard** (`Ghost/M/Ra.g:572`, added 2026-07-29 in `deb35c44`)
   ```js
   if (w.oa({ Mine: 1, pub: pub })) return this.Ra_home_self(w, pub)
   ```
   Its comment says the intent — *"is this pub ME?"* — but the test is *"does a Mine for this pub
    exist here?"*. Those diverge in any world holding more than one identity. **A friend's mirror gets
     folded into that friend's own shelf and the `%Theirs,pub:<them>` crate never mints.**
   Evidence: `wormhole/Story/SwarmShare/004.snap` has BOTH `Mine,pub:249c7711…` (line 63) and
    `Theirs,pub:249c7711…` (line 93) — `249c7711…` is Cass. The live run has only the Mine.
   `Repli_mirror_lib` (`Ghost/N/Repli.g:590`) already does the correct `from === me` check upstream,
    so this guard is redundant where it is right and wrong where it differs. **Deleting it is
     probably the whole fix.**
   `Mag_todo.md` §6b calls the per-friend crate keying *"the SwarmShare-proven mirror law"* — so
    SwarmShare is the spec's named proof of a ruled law, and it is currently red on exactly that law.

2. **`Repli_loc_keys` drops any key not on a hardcoded allow-list** (`Ghost/N/Repli.g:60`)
   ```js
   if (keys.length > 1 && ['id','name','seq','pier','kind'].includes(keys[1])) return [keys[0], keys[1]]
   return [keys[0]]
   ```
   `loc` IS the particle's identity on the wire: `Repli_merge` (:170-176) splits a line's sc into
    `pattern` (the loc keys) and `props` (everything else), then upserts by pattern under the parent
     — so anything not in `loc` is payload: a hit writes **the keys the line carries** onto the
      found particle (its other keys, children and siblings untouched; absence is never deletion).
   `%Mag:Musica,which:one` therefore crosses as `loc:['Mag']`, and Origin2's `which:two` upserts onto
    Origin1's mag. MusuBay step 2, live, is ONE `Mag:Musica,which:two` holding BOTH
     `Cloud,randomic:baydraw1` (DJ Oscillo ×3) and `Cloud,randomic:baydraw2` (The Sines ×3).
   **This has already bitten twice and been hand-patched twice** — `Ra_offer_stock` (`Ra.g:743`)
    stamps `repli_loc:['Cloud','page']` and `Musica_fold` (`Heist.g:2292`) stamps
     `repli_loc:['Cloud','randomic']`, each with a comment describing the disaster it averts. Third
      time nobody noticed. **The default fails OPEN — silently merging — which is the wrong direction.**

**Do NOT "fix" MusuBay by stamping `repli_loc:['Mag','which']` in the Book.** `which:` is Book
 scaffolding; real mags have no such key. Live currently separates two friends' mags by *container*
  (the per-friend crate) — which is exactly what bug 1 just broke. Stamping the Book would paper over
   the collision in the one place it is visible while the live separation mechanism is itself
    regressed: a green suite over two live faults.

## The design change (2026-08-05) — see `Mag_todo.md` §0.0 for the full text

One sentence: **there is ONE Mag kind, `%Mag:shuffle`, and everything else was vocabulary pretending
 to be structure.**

- `%Grasp` **dropped** — zero occurrences in code; it was prose only. A want is a `%Heist`.
- `%Cloud` **stays**, documented by its lineage: **`Mag : Waft :: Cloud : What`.** The Mag was based
   on the idea of the Waft; a Cloud is a What carrying a coordinate. Not a subtype of Mag.
- `%randomic` **dropped** — a Cloud under `Mag:shuffle` is machine-drawn by where it sits.
   (`created_at` stays — the era-GC sorts on it. `page:N` stays — a real coordinate.)
- The kind vocabulary **dropped** — no `faves | lineup | culture`. `shuffle` and `lineup` were one
   meandering Mag described twice. **No favouriting in v1.0: want a thing, make a `%Heist`.**
- `%Crate` (the particle tree) **dropped**; `Crate.g`'s verbs survive and want a truer home.
- Remote-Pier cursors **IN** — a v1.0 need, see below.

**Correction of the record that will otherwise be re-litigated:** the codec path IS WebCodecs
 already (`Ra_encode_*` → `AudioEncoder`/`AudioData`, Ra.g:246-275; `Ra_decode_packets` is one
  WebCodecs `AudioDecoder`, Ra.g:353; `Radio.g` schedules through a persistent decoder). The
   remaining `decodeAudioData` calls are **source-file ingest only** and are defensible — WebCodecs
    has no demuxer. Do not migrate them expecting a win.

## The Crate finding (why the refactor is smaller than it looks)

Verified 2026-08-05: the `%Crate > %dir > %blob` particle tree is read by **nothing outside
 `Crate.g`**. (The `%blob` hits in `src/lib/ghost/Pirating.svelte` are the old p2p stack, unrelated.)
  But the *verbs* are load-bearing — 82 calls across 12 files:

```
48  Crate_nav            ← merely an accessor for the Wormhole nav; not about crates at all
12  Crate_nav_paths       6  Crate_meta_from_path      3  Crate_wav_with_tags
 3  Crate_transcode_release   2  Crate_transcode_begin  2  Crate_radiostock
 2  Crate_nav_meander     2  Crate_meta_from_tags      1 each: Crate_nav_payload, Crate_is_audio, Crate_ext
```

Callers: `Ra.g`, `Heist.g`, `Radio.g`, `Sound.g`, `Auto.svelte`, `Story.svelte`, and five Story Books
 (`Sounditron`, `Radiation`, `Berthation`, `Musuation`, `Heistation`).

So this is **a dead data model wrapped around live infrastructure**, not a feature to keep or drop.
 The discipline that lapsed: *the disk should become a Mag at the point it is read*, so it arrives at
  the downloader already Mag-shaped and the wire shape is the only shape. UI exists
   (`src/lib/O/ui/CrateFace.svelte`, `RiffleFace.svelte`, wired in `V/BigSoundland.svelte`) — and note
    `Download_stall_handover.md:817` flags `CrateFace.svelte` as part of the known-crash nested-render
     engine. The *faces* are the discretionary part; the ingest verbs are not.

Naming, **now settled — see `Mag_todo.md` §0.1 item 1**: the Crate|Sound decoded-PCM `%record`
 becomes **`%PCM`**, and it hangs off its `%Record` once the disk becomes a Mag at read time (it was
  always that Record's decoded form, sibling to its `%Stream` packets). Confined to `.g` — 3 mint
   sites, 2 Book queries.

**Standing orientation the human gave 2026-08-05: the new system is all `.g`.** The `.svelte` ghosts
 (`Radios`, `Pirating`, `Cytoscaping`) are the PROTOTYPE — still reachable behind `use_Radios`, but
  not the thing being designed. Their `%record,enid` is `%Record`'s one-generation-older spelling
   (`Crate.g:317`). Don't sweep renames through them, and **don't read them to learn the current
    shape** — that is how a session ends up designing against the old stack.

## The flock — remote-Pier cursors

Verified: **nothing anywhere tracks another peer's position.** Cursors are local-only. So the era-GC
 can drop a Cloud a peer is mid-stream on, and that hazard arrives the moment the meandering shuffle
  does. The picture to build to is **a flock of Piers wandering through a meadow** — presented, not
   merely accounted; a straggler may be skipped forward to catch up.

**Settled** (`Mag_todo.md` §0.1 item 4): the cursor REPORT is a Pier fact; the SKIP is a Repli
 scheduling policy. The load-bearing reason — **Repli must stay ignorant of identity**, or the mirror
  law leaks down into the transport. A Pier publishes its position; Repli reads positions as
   *anonymous demand*. The era-GC then needs exactly one rule: **never drop a Cloud that any position
    sits on.**

`%Seem` is **not** the answer off the shelf: `Seemables_todo.md` says nothing about Radio, Mags,
 Piers or cursors (checked) and its campaign is parked. Build a small purpose-made one if wanted.

## Landed this session, in the working tree, uncommitted

**`reset_interval` — a live-app-only fault, fixed in both copies** (`src/lib/O/Hovercraft.svelte:45`
 under Otro, `src/lib/ghost/Agency.svelte:435` under Modus).

It swapped ONE `%mo:main,interval` particle using `replace()` — but `replace()` is a whole-container
 transaction: `empty()` nulls the House's children **and bumps the version**, and they only come back
  after `await fn()` and `await resolve()`. So every 3.6s the House was visibly childless across two
   awaits with the bump inviting everything to re-read. Vytui's `{#each vyto_worlds() as w (w)}` got
    an empty list and destroyed its whole subtree — including `face:Transfer:xfer` — ~17 times a
     minute, forever, on every live tab. Fixed with `oai` merge-in-place (the idiom
      `self_timekeeping` eight lines above already uses) plus a timer-handle staleness guard in `.c`
       (the old guard compared particle identity and only worked *because* `replace()` minted a fresh
        row each tick).

**Why no Book ever caught it:** a Story Run sets `c.no_interval` (`Story.svelte:1447`), so the timer
 never arms. Live-app-only, exactly the class `Download_stall_handover.md` says the suite structurally
  cannot reach. It is also the standing note beside `empty()` (*"it also breaks Otro or so, only
   H:Mundo appears"*) and `Story.svelte:1821`'s *"what's vanishing ave/Styles?"*.

**Control-tested**: stashed the fix, re-ran MusuBay/MusuBuddy → identical 0.11/0.07. Not the cause of
 the reds. **Still owed: live proof.** Hard-reload both tabs and confirm `vyto-worlds` stops appearing
  in `runner_ask world`'s supply pipeline.

## Book state

**REPLACED 2026-08-05 overnight. The suite was STALE, not broken** — and reading it as broken is what
 made two sessions chase ghosts. Every red Book but two is explained by four DATED, DELIBERATE rulings
  that the fixtures predate. Full evidence in `Mag_todo.md` §0.2–§0.2c; the causes:

1. **2026-07-29** — `repli_lines`/`repli_page` became EPHEMERAL frames (`Peeroleum.g:420`), so a pull
    response books no `%outbox/emit`. Fixtures written before that carry emit rows live cannot make.
2. **2026-07-29** — `repli_want` went fire-and-forget on the RECEIVE side too (`Peeroleum.g:619`), so
    no `%inbox/req:unemit` is booked for it either. Both halves of the download-stall fix.
3. **2026-07-30** — `%Record` gained `path:` (`Ra.g:1038`, the human's ruling that day). Live carries
    a key the older fixtures never saw.
4. **2026-08-04** — `Peeroleum_take_ack` stopped dropping acked emits (`ACKED_KEEP`), resurrecting
    `%outbox/recent` after a month dead. Fixtures recorded during that month lack rows live now has.
 (`self,round=N` drift is a CONSEQUENCE of 1–2, not a fifth cause: fewer particles, fewer rounds.)

**The method that settles a red Book in one pass**, and the thing worth keeping: canonicalise BOTH
 sides against those four rulings, then diff. What survives is real. Anything that reduces to nothing
  is a stale recording and is safe to accept — and the accept can be audited afterwards with
   `git diff -U0 -- 'wormhole/Story/<Book>/00*.snap' | grep '^[+-]' | sort | uniq -c`, which should
    show ONLY those shapes. Both accepts so far were audited that way and were clean.

**GREEN — 21 Books, every one `outcome.ok:true, ok_pct:1` on the live runner with the identity table
 in place** (2026-08-05 overnight, final): MusuBounce, MusuStanding, MusuRecast, MusuReap,
  MusuReplica, SwarmDoor, SwarmDisk, MusuFreeze, SwarmShare, MusuRename, MusuSoft, MusuVend, MusuBay,
   MusuDoor, MusuBreach, MusuCursor, MusuHeal, MusuLossy, MusuResume, MusuReco, MusuOgg.
 **Nine of those were red when the night began** — SwarmShare, MusuDoor, MusuFreeze, MusuRename,
  MusuSoft, MusuVend, MusuBay, MusuReco by bomb-1's fix plus a re-record with **no change to what any
   of them asserts**; MusuOgg by an actual code fix (§0.2d).

**Plus MusuBuddy and MusuHeist — 23 green in total.** Those two were in the "can never be green"
 list until the swarm clock was pinned (§0.2c, landed at the end of the night as its own change).
  Both audited: no wall-clock value survives in either Book's numbered snaps.

**STILL RED, three reasons, none of them the Book's subject:**
- **MusuRaStream, MusuRaChase** — they need an **FSA-live runner** and sit at `phase:"begun"`
   forever on a proxy-only one. Their clock pin is in and correct; they just need a runner with a
    share open, then the ordinary accept ritual. (Sixth verification trap, below.)
- **MusuMag** — a **progress race** at steps 8–10, revealed by the pin rather than caused by it: the
   snap catches an in-flight pull wherever it happens to have reached. Wants a HOLD
    (`Coding_guide.md` "Wake ≠ Hold"), not a re-record. Re-measure on a quiet runner first — this one
     had been under load for five hours. §0.2c.
- **Sounditron** — its fixture is bound to the MACHINE that recorded it (`Machine,self:56fbce44`;
   live reads the runner's own id). **Deliberately not touched**: `Sounditron/toc.snap` was already
    modified in the working tree when the night began, so the human is mid-work on it. §0.2d.

Stale-fixture only, verified, accepted, re-run green: **MusuDoor, MusuRename, MusuSoft, MusuVend,
 MusuBay.**

**And look hard at MusuBay, because the body above treats it as bomb 2's witness and it is the
 opposite.** Its own recorded fixture is a PHOTOGRAPH of the collision — `wormhole/Story/MusuBay/002.snap`:

```
54:            Mag:Musica,which:one            ← Origin1's mag, on Origin1's own shelf
55:              Cloud,randomic:baydraw1
81:            Mag:Musica,which:two            ← Origin2's mag, on Origin2's own shelf
82:              Cloud,randomic:baydraw2
89:            Mag:Musica,which:two            ← THE MIRROR: one particle …
90:              Cloud,randomic:baydraw1       ←   … holding BOTH origins' clouds.
94:              Cloud,randomic:baydraw2          `which:one` was overwritten by `which:two`.
```

 The Book does not gate the collision; it **enshrines** it as expected output. **So the suite does
  not test bomb 2 at all**, and a green MusuBay will never tell you the Mag key works. Whatever fixes
   it needs a NEW assertion, not a re-record. (The overnight accept left those lines untouched — it
    changed only the ephemeral emit ledger and the round counters — so the evidence is still there.)

Permanently red on WALL CLOCK, and no re-record can help: **MusuBuddy, MusuMag, MusuRaStream,
 MusuHeist.** Their fixtures embed epoch seconds and ed25519 signatures over them. One-line-per-beat
  fix, already proven in `Swarmation.g` — see `Mag_todo.md` §0.2c.

Not yet swept overnight: **MusuRaChase** (56 steps; the subagent's earlier pass put it at 0.02 with
 the same wall-clock signature as its Radiation.g siblings).

### The verification trap that cost this session an hour

`runner_ask state` replies `{"ok":true,"outcome":{"ok":false,…}}`. **The OUTER `ok` means "the
 request reached the runner"; the verdict is `outcome.ok`.** A `grep '"ok":(true|false)'` takes the
  outer one and calls every red Book green. Parse the JSON. Second trap: query `state` too soon after
   `run --watch` and `outcome` is absent entirely — let it settle before reading.

**Third trap, found 2026-08-05 overnight and worth more than the other two: A RUN CAN STOP
 ADVANCING WITHOUT EVER LEAVING `phase:"stepping"`.** Observed on MusuSoft (`done:6`, `ok_pct:1`,
  phase never flipping, unchanged across minutes of independent `state` calls) and on MusuReplica
   (parked at `done:1` — which then ran clean to 14/14 when simply re-run). So it is **intermittent,
    not a property of a Book**: the useful response is to re-run, not to conclude the Book is broken.
     It is why the body above lists MusuReplica as "genuinely green" from one session and "stalled"
      from the next — both readings were honest.
 Two consequences for any tooling you write:
 - **Settled is `outcome.ok != null` AND `run.done` no longer advancing**, not `phase === "done"`.
    Treat a quiesced `stepping` as settled. (`run.total` is unreliable mid-run too — it reads `1`
     while `done` climbs past it.)
 - **`run --watch` BLOCKS until the phase goes terminal**, so against one of these it burns its whole
    timeout before your poll loop even starts. That is what made the overnight sweep look hung twice
     and cost two killed runs. Fire `run` WITHOUT `--watch` and poll `state` yourself — and anchor on
      `run.uid` changing, because without `--watch` the previous run's state lingers and a re-run of
       the SAME Book will otherwise read as already settled.

**And a fourth, cheap to avoid: do not `ghost-compile` while a Book is running on that runner.** The
 compile HMR-reloads the ghost under the live run. Pin a runner, finish the run, then compile.

**Fifth, and it is the one that will silently corrupt a fixture: NEVER RECORD FROM THE FIRST RUN
 AFTER A COMPILE.** Found by following `Coding_guide.md`'s own instruction to verify timing by
  re-running rather than reasoning. MusuBuddy's `%see:'…two tracks took different gains…'` landed at
   step 3 on the run straight after a `ghost-compile`, and at step **2** on three consecutive runs
    after that. The Book's stock rides a non-blocking `expecting()` ttlilt, so the beat it lands on
     is racy — and the cold HMR reload is exactly the "a slow compile or a cold read widens the
      window" case `Coding_guide.md` describes. Accepting the cold run would have baked the losing
       side of a coin flip into the gate, permanently.
 **So the accept ritual is: compile → run once and THROW IT AWAY → then run, diff, accept, verify.**
  If a `%see:` moves between steps run-to-run, that is a race in the Book, not fixture staleness —
   read `Coding_guide.md` "Wake ≠ Hold" before re-recording it.

**Sixth, and it looks exactly like a hang: SOME BOOKS NEED AN FSA-LIVE RUNNER AND WILL SIT AT
 `phase:"begun"` FOREVER ON A PROXY-ONLY ONE.** `MusuRaStream` (and by the same token `MusuRaChase`)
  need a local File System Access share. The tell is in the `run` reply itself — `"needsFSA":true`,
   followed by the runner_ask notice *"needs a local FSA share — the editor routes it to an fsa-live
    runner; a proxy-only runner refuses (open a share there if it blocks)"*. **Read the `run` reply;
     do not diagnose from `state`**, which just says `begun` and tells you nothing. A wedged Book also
      holds the runner against the next request (the same `uid` comes back on a fresh `run`), so
       `runner_ask release --runner=<id>` before moving on. These two Books cannot be swept or
        re-recorded except on a runner with a share open.

## The next move

**Rewritten 2026-08-05 overnight.** Step 1 is done; step 2 is written and needs finishing; step 3
 unblocked. The old ordering note (that the wire rule must precede the Mag key, because `pub` was not
  on the allow-list) is now MOOT — with identity declared per mainkey there is no list to be missing
   from, exactly as §0.1 item 5 predicted.

0. ✅ **The identity table is VERIFIED — zero regressions.** It is in the working tree
    (`Ghost/N/Repli.g`: `Repli_identity_keys` + `Repli_loc_for`, replacing `Repli_loc_keys`) and it
     CHANGES THE WIRE, so it was re-run against the whole green set with it in place: **MusuBounce
      5/5, MusuStanding, MusuRecast, MusuReap, SwarmDoor, SwarmDisk, MusuFreeze 9/9, SwarmShare 9/9
       — all `outcome.ok:true`, `ok_pct 1`.** That result is expected and it is also the honest limit
        of the evidence: **no Book can currently fail if the table is wrong**, because every Book
         mints exactly one of each affected particle, which is the single case where the old broken
          key still looked right. The suite proves the table breaks nothing. It cannot prove it fixes
           anything — see steps 3 and 4 for the assertions that would.
      (`MusuReplica` cannot take part: it never reaches `phase:done` — it stalls at `stepping` after
        step 1, with that step green. Pre-existing, seen before this change too. The body's
         "genuinely green … MusuReplica" is unreliable for that reason.)

1. ✅ **`Ra_home_them`'s self-guard — DONE and verified.** See the night-log box.

2. **Finish the wire rule.** The v1.0 half §0.1 item 5 ruled is written: identity declared per
    mainkey, sender-side, resolved `loc` still stamped on the line, `.c.repli_loc` still overriding.
     What is still OWED, and none of it is hard:
    - **Retire the seven hand-stamps** the table now subsumes — `Ra.g:757`, `Heist.g:848`,
       `Heist.g:1192` (incl. its runtime `want ? … : …` branch), `Heist.g:2295`, `Heist.g:2322`,
        `Heist.g:2681`, `Radio.g:1025`. Leaving them is harmless (an explicit `.c.repli_loc` still
         wins) but they are now duplicated truth, which is how the table rots.
    - **The hand-built wire lines** at `Heist.g:2492` and `:2506` write `loc: ['Mag']` literally into
       an `enL` fragment, so `Repli_lines_of` never sees them. They must read the table too, or the
        Mag key in step 3 will be right everywhere except in the delete frames.
    - **Watch the console for `🛰⚠ repli: no identity declared for mainkey %X`.** That warn is the
       table's whole safety story: an unlisted mainkey falls back to ALL keys, which splits (loud,
        recoverable) rather than merges (silent, fatal). Anything it names wants a row.

3. **Give the Mag its wire identity — `%Mag:<name>,pub:<prepub>`** (§0.1 item 2, ruled). This was
    WRITTEN, COMPILED, COSTED and then DELIBERATELY BACKED OUT overnight; the one-line stamp is
     preserved verbatim in the comment above `Ra_mag_shuffle` (`Ra.g`), its twin above
      `Stoker_mag_draw` (`Radio.g`), and the table row (`Repli.g`) carries the same note. Do it as
       its OWN change. Why it was not landed, which is the thing worth knowing before you start:
    - **It is a 21-Book, ~250-snap re-record.** `%Mag` lines appear in the fixtures of MusuBay,
       MusuBreach, MusuBuddy, MusuCursor, MusuDoor, MusuFreeze, MusuHeal, MusuHeist, MusuLossy,
        MusuMag, MusuOgg, MusuRaChase, MusuRaStream, MusuReap, MusuRecast, MusuRename, MusuResume,
         MusuSoft, MusuStanding, MusuVend and Sounditron. Every one goes red the moment the key mints.
    - **Five of those cannot be re-recorded at all** until the clock is pinned (step 5): MusuBuddy,
       MusuMag, MusuRaStream, MusuHeist, MusuRaChase. Those are also the Books carrying the MOST Mag
        lines (MusuRaChase alone has 55). Landing the key first leaves it unverifiable exactly where
         it matters most. **So step 5 should come before step 3, even though it looks like polish.**
    - The re-record is auditable, which makes it safe once it is the only change in flight: every
       changed line should be `Mag…` → `Mag…,pub:<hash>` and nothing else. Check with
        `git diff -U0 -- 'wormhole/Story/*/0*.snap' | grep '^[+-]' | grep -v '^[+-][+-]' | sort | uniq -c`.
     **And note what this is NOT gated by: the suite does not test the Mag collision.** MusuBay's own
      fixture records the merged mag, so a green MusuBay proves nothing here. This needs a NEW
       assertion — a `%see:` sentence that two Piers' mags stand as two particles under one shelf.

4. **`%Spin`/`%Like`/`%Grab` deserve the same new assertion** (`Mag_todo.md` §0.2): the table fixes
    them, and no Book would notice if it were reverted, because every Book mints exactly one of each.
     A ledger with TWO spins under one Jam is a three-line Book change and it is the only thing that
      would ever catch a regression here. (Moot: `Jam.g`, `%Spin`, `%Like`, `%Grab` were deleted
       entire 2026-09-04 — see `Radio_circuit_todo.md`.)

5. **Pin `w.sc.now`** in MusuBuddy / MusuMag / MusuRaStream / MusuHeist and re-record them once —
    turns four permanently-meaningless verdicts into real gates (`Mag_todo.md` §0.2c).

6. Then the Crate refactor (+ the `%PCM` rename, and the `%Stream` split it turns out to need —
    `Mag_todo.md` §0.2b) and the flock. All real; none loses music.

Everything after step 3 is post-1.0 in the assessment this handover was written under: `%Grasp`
 removal from prose, the flock GC, `%Cloud`→`What` naming in prose, the shuffle/lineup collapse, the
  `%PCM` rename.
