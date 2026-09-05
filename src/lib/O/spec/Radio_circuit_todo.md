# Radio_circuit_todo — the wires behind the radio, haggled down to one shape

The owner, 2026-09-04: *"think long and hard about the datasplatter behind Radio… mature!"* and then *"run
 a series of subagents to haggle you down to a smoother shape… scan the same nest of wires many times,
  differently."* Six lenses scanned it — ego-death, lifecycle, persistence, the wire, the human, the Mag
   model. §8 records what each won. This is the shape that survived. A `_todo` for you to preen.

---

## 0. WHAT IS BUILT — and what to get on with next (2026-09-04)

**BUILT AND GATED.** The circuit below is in the working tree, uncommitted, gated on the live runner by
 **`MusuHeard`** — 9 beats, 15 sworn, caveat 0. The rulings §7 owed were taken as this doc's own
  recommendations so the owner vetoes in the diff rather than answering a questionnaire: **♥ only, no
   ambient road** (`take_after`/`album_after` are not read in v1.0); the per-holder group is a **query**;
    **no phone→laptop frame**; `Mag:heard` **replaces `radio.c.heard`**.

**The new ghost: `Ghost/M/Heard.g`** (registered in `LiesLies.svelte`'s GhostList where `Jam.g` was; compile
 with `GFILES="Ghost/M/Heard.g Ghost/M/Heist.g Ghost/M/Radio.g Ghost/M/Ra.g Ghost/S/Swarm.g Ghost/N/Repli.g Ghost/Story/Heistation.g Ghost/Story/Radiation.g Ghost/Story/Swarmation.g Ghost/Story/Sounditron.g"`
  or LocalGen silently skips it; esbuild-parse each `.go` after; reload the runner before trusting a red).
- **the Mag** — `Heard_home/_mag/_mag_at/_mag_find/_mag_near` (find vs find-or-create kept strictly apart:
   the dial reads this on every pump tick and a reader built on `oai` mints by being asked),
    `Heard_page` (one `Cloud,page:N,created_at` per sitting, `mag.c.sitting` latch), `Heard_cards/_find/_card`.
- **the events** — `Heard_mark` (from `Radio_open`), `Heard_through` (from the `went='finish'` seam in
   `Radio_pump_tick`, humdinger-gated, **no bump**), `Heard_take` / `Heard_untake` / `Heard_taken`,
    `Heard_set` (the dedup map every `radio.c.heard` read became).
- **the query** — `Heard_takes` · `Heard_landed` (two id-spaces: `id` or the learned `keep`) · `Heard_gc`
   · `Heard_gave_up` · `Heard_word` · `Heard_landed_ids` · `Heard_tally` / `Heard_latest` (the pool's taste).
- **the byte-lane seam** — `Heard_keep` · `Heard_haul_beat` (from the share beat, `w.c.keep_beat_at='heard'`)
   · `Heard_clone_beat` · `Heard_haul_piers`. `Heist_keep_like_go` → `Heist_keep_take_go`, keyed `take`.
- **persistence** — `Swarm_restash_heard` + `Swarm_heard_rehydrate`, the **eighth stash pillar**, in
   `Swarm_restash_all` and the `Swarm_station_up` boot ladder, gated by **SwarmReboot**. It carries the
    TAKES ONLY: a bare hearing is a 30-day dedup mark, worthless after a reload and (× every track ever
     played) the hoard §6b forbids. `Repli_identity_keys` `Card: ['id','pub']`; `Swarm_graft` gains
      `Mag/Cloud/Card` rows.

**One thing the build FOUND that the doc had not** (§3's middle row): `held` · `unvouched` · `landfail` all
 `mir.rm` the husk out of the mirror, so the keep is left pulling a record that no longer exists — `left`
  never reaches zero, the keep never reaches `done`, and **that holder's one live slot is wedged forever**.
   `Heard_clone_beat` copies the verdict onto the Card and ends the keep, so the queue moves on; a re-press
    of ♥ clears the verdict and asks again, which is the retry road.

### What went, and what it became

| gone | became |
|---|---|
| `Jam.g` entire (`%Jam/%Spin/%Like/%Grab`, `Jam_home/_seq/_event/_mark/_spin/_like/_grab/_ledger/_tally`) | `Mag:heard`; ♥ = `take` |
| `Heist_wants_cap/_want_shelf/_want_liked/_want_open/_want_jams/_want_settle/_want_off/_want_keep/_want_beat` | `Heard_keeps_cap/_shelf/_taken/_takes/_landed/_untake/_keep/_haul_beat` |
| `Heist_haul_piers/_haul_carrying` | `Heard_haul_piers/_carrying` |
| `Heist_newly_mirror/_newly_keep/_newly_ids` + the `%Hauls>%Newly>%Fresh` dontSnap mirror | `Heard_landed_ids` (the Mag is durable AND in memory, so there is nothing to mirror) |
| `Radio_heard_cap/_heard_add` + `radio.c.heard` | `Radio_heard(radio)` → `Heard_set` |
| `Radio_unlike` + the ♥ toggle | `Heard_take`'s own ±10s window |
| `Ra_quarter_tally`'s %Jam walk; the `liked/kept/latest` policies' %Jam reads | `Heard_tally` (take 3 · keep 2 · mire 1) / `Heard_latest` (the last %Cloud page IS the last sitting) |
| `Jam_grab`'s keeper copy | `Ra_rec_copy` (the useful half, re-homed; the ledger half was the cursed part) |
| `MusuLikeHaul` (Book + fixtures) | `MusuHeard` |

**Survived, re-homed:** the whole byte lane (Rummage · the bay · Repli · materialise · quarantine · vouch ·
 land), `Heist_keep_flight`, `Heist_keep_solo`, `Heist_haul_look`/`%Hauls>%Haul` (the landed-album rows),
  `Heist_want_path_ok` (unrelated — the serve-side path gate).

### Where the VERIFICATION stands (2026-09-04, end of day)

**The circuit is green and the fleet is green around it.** `MusuHeard` 9/9 caveat 0, re-confirmed after
 every change below. Also green, count-checked, on the live runner: `MusuBay` · `MusuBreach` · `MusuCursor`
  · `MusuDoor` · `MusuFreeze` · `MusuHeal` · `MusuHeist` 22/22 · `MusuLossy` · `MusuNeGrind` · `MusuPoolBytes`
   · `MusuPoolRadio` · `MusuPoolRandom` · `MusuRaChase` 56 · `MusuRaStream` 40 · `MusuRecast` · `MusuReco`
    11/11 · `MusuRename` · `MusuReplica` · `MusuResume` · `MusuSoft` · `MusuStanding` 12/12 · `MusuVend` ·
     `Sounditron` · `SwarmGot` · `SwarmReboot` · `SwarmShare` 9/9.

**ONE red is ours, and it is the gate working.** `MusuBuddy` declared an assertion naming the deleted
 ledger — *"the jam ledger reads spin like grab in order…"* — which deleting `%Jam`/`%Spin`/`%Like`/`%Grab`
  made unmeetable. Beat 11 already SWEARS the replacement (`Radiation.g:1196`); only the toc line was stale,
   and it has been rewritten to that sentence verbatim. ⚠ **`MusuBuddy` is still red for an unrelated,
    upstream reason**: it stamps `jam_fail:nothing heard` because `w.c.term` is never set — this diff
     touches neither `term` nor `pick_id` — and the tell is that it runs all 14 steps in **27 seconds**,
      nowhere near enough for a Book that must play real audio and measure loudness and gaps. Its LISTENING
       beat is not engaging at all. Own session.

**`MusuOgg` + `MusuReap` — a REAL transcode change, not entropy. Do not silence it.**
 Both are red on chunk `cid`s. I first called this a non-reproducible "entropy bomb" and recommended
  forgiving it. **That was wrong three ways, corrected here so nobody re-derives it:**
 1. *"The Book breaks its own ENTROPY LAW"* — **no.** The law ("never the ogg bytes|hash|size") is about the
     ogg EXPORT file, and the `%Blob` line carries `path` only — no bytes, no hash, no size. The Book obeys
      it exactly. The chunk `cid`s are a different artifact the law never covered.
 2. *"Not bit-reproducible"* — **no.** `MusuOgg` gave byte-identical cids across **three** runs spanning
     ~1.5 hours with dozens of other Books in between; `MusuReap` identical across two. It is deterministic.
 3. *"`lufs` is run-volatile"* — **no.** That came from comparing `MusuReap`'s `lufs` against `MusuMag`'s —
     different Books, different stocking. Within a Book it is stable.
 So EntropyArrest is the WRONG tool here (a `tol:any` on `cid:{TOK}`, or a `drop`, would silence either Book
  in one line — and permanently blind it to chunk content, the one thing it exists to verify). A blind
   re-record does the same thing quietly. **Two distinct fingerprints, so possibly two causes:**
 - `MusuOgg` — `lufs`/`gain` UNCHANGED, Preview chunks (seq 0-15) MATCH, only the **Stream** chunks
    (seq 16-38, the continuation encode that opens a fresh head at `preskip=312`) differ.
 - `MusuReap` — `lufs` −7.33→−7.38 and `gain` −6.67→−6.62 moved, and every Preview chunk moved with them.
 Not from this work, on strong but non-bisected evidence: the whole `Ghost/` diff has **zero** matches for
  `Ra_encode_open|Ra_transcode_advance|Ra_transcode_ensure|nat.encode|Ra_bitrate|Ra_seg_secs|configure(`,
   and its `Ra.g` edits are confined to `Ra_home_*`/`Ra_pool_*`. A month of commits touched `Ra.g`/`Radio.g`
    while these fixtures sat untouched since **2026-08-08** — these two Books are simply the only thing that
     noticed. Note `Ra.g` has TWO encode paths, native `nat.encode` (2464, 3260) and WebCodecs
      `AudioEncoder` (320/333); both take `gain.db`, so `lufs → gain → bytes → cid`. **Bisect it.**

**`self,round` — RULED (the owner, 2026-09-04): keep it in the snap.** *"self,round is fine to include, it
 shouldn't wobble unless our ttlilt is not functioning well — Story step-times should be predictable."*
  I had muted it with a test-scoped `Entcase:Round_noise` (`means,drop`) on MusuHeist/SwarmShare/MusuReco;
   **that has been reverted and the three re-recorded.** The reasoning that matters: a wobbling `self,round`
    is not noise to be hidden, it is a READING ON TTLILT. The sharpest instance — `MusuHeist` gave
     **caveat 13 then 21 on two consecutive warm runs** — means the belief loop took a different number of
      rounds to reach the same step twice running. That is the signal, and muting it deleted the instrument.
 Still true and worth keeping: `Composition_todo.md` §2.3 measured cold→warm as red/20 → 22/22 with 14 →
  22/22 with 1 on IDENTICAL code, so **`ok`/`ok_pct` is the gate and a caveat COUNT is not a regression
   signal** — but per the ruling above, a caveat count IS a symptom worth reading, not noise to arrest.
 ⚠ Mechanism worth knowing: `self,round` is ALREADY globally spayed (`Story.svelte:1074`, `tol:'any'`), and
  a spay forgives at COMPARE — which is *why* it produces a caveat rather than a pass. Only a structural
   means (`drop`/`dontSnap`, encode-time) removes it. Recipe + costs in `Story_hygiene_todo.md` §0.

**Resolved and off the board:** the `Download_stall_handover.md` debt *"re-record SwarmShare (005-009) +
 MusuReco (005-011)"* is **NOT owed** — Fix A is in the tree (`Peeroleum.g:435`), there are zero
  source-outbox `emit,type:repli_lines` rows in either Book, and both pass. (An earlier note here blamed
   `MusuReco` on cert-crew debt; that was wrong too — it was never anything but `self,round`.)

⚠ **Before trusting any sweep, read `spec/Story_hygiene_todo.md` §0** — the faults that all fail toward a
 FALSE GREEN (a hollow run reads `ok:true`; `ok` hides `caveat`; TaskStop does not kill a sweep shell), the
  six Books whose COMMITTED toc diges disagree with their own snaps (`SwarmBody` 22/23), and the discovery
   that removes most sweeps: **`dige` == `sha256(<whole snap file>)`[:16]**, so a provably content-preserving
    fixture change needs no runner at all — 319 stale diges over 30 Books were settled locally that way.
⚠ **A red is not a red until it reproduces on a fresh runner.** `MusuFreeze` went red→GREEN untouched;
 `MusuStanding` collapsed 12-red→GREEN; `SwarmShare` went from a total standup wedge (`phase:begun`,
  `n:null`, `steps=0`, 96s of console silence after "▶ Story subHouse created") to 9/9 green on
   byte-identical files. That wedge is real, transient, and NOT diagnosable from the fixtures.

### Next — where this is going

**The circuit itself is done.** What remains is not circuit work; it is (a) one honest unknown about the
 RUNNER, (b) one real bug this work uncovered but did not cause, and (c) the two rulings still owed.

1. ✅ **Is the runner deterministic? — ANSWERED, see `Story_hygiene_todo.md` §0a.** No, for 3 of 5
    Books — but **the entire flap is `self,round` and nothing else** (`MusuHeist` step 22 over three runs:
     304 lines, ONE differs, `39` vs `38`). The world state is reproducible; only the number of belief
      rounds taken to reach it jitters by one. Verdicts never moved: `ok_pct:1` in all 30 runs. Two
       hypotheses died there too — it is NOT the wire/peer Books (`MusuStanding` is peer-heavy and stable),
        and ttlilt explains the worst case (`MusuHeist`, the only ttlilt user, 21/22 steps) but not the
         class (`MusuReco`/`SwarmShare` flap with zero ttlilt). ⚠ Practical bite: a Book whose round count
          differs between `story_accept`s write-run and its verify-run CANNOT be re-recorded green —
           `MusuHeist` and `SwarmShare` both failed for exactly that reason. **Next: find why the loop takes
            a different number of rounds.** The owner's standing design (`Story.svelte:79`) is to hide the
             value but ASSERT on a jump of more than one — not built.

2. ✅ **The transcode drift — BISECTED 2026-09-05 (a subagent, static, no runner): it is the BROWSER, not a
    commit.** Function-body diff of `Ra.g` from a63e14c0 (08-08) to HEAD, comments stripped: `Ra_encode_open`
     `_feed` `_drain`, `Ra_chunk_cut` `_pack`, `Ra_opus_samples`, `Ra_bake`, `Ra_lufs`, `Ra_gain_for`,
      `Ra_bitrate`, `Ra_seg_secs`, `Ra_preview_*`, `Ra_decode_packets`, `Ra_enid` are **byte-identical**; the
       only changes are scaffolding (`Ra_bake_gentle` skips a ×1.0 within ±0.01 dB — not taken at -6.67; a
        `need_secs` prefix read gated on `humdinger`, unreachable in a Book). The on-disk shelf DATES it:
         `.jamsend/radiostock/` cards for Cosmic C / Dorian D with identical enid, pv_off, lufs, gain and packet
          `sizes[]` carry one cid set through **2026-08-12 10:53 UTC** and another from **2026-08-21 01:56**
           on. Same samples, same config, same packet sizes, different payload ⇒ Chrome's `AudioEncoder`/libopus
            updated in that window (commit 0473e26b 08-19 "chrome sucks…" is the circumstantial nod).
    Why MusuOgg's previews matched and its Streams didn't: it STANDS on the 08-07 card (`stocked,…,stood`) so
     preview bytes come off disk un-re-encoded, and only the %Stream continuation opens a fresh encoder
      (`Ra.g:3439`) on today's Chrome. MusuReap sweeps its shop first and rebuilds, so all 64 previews move.
    And `lufs` is **run-volatile on unchanged code** — 3139f0c0… measured -17.49 (08-07) vs -17.62 (08-08),
     same cid — and a stood record REPORTS the stored August number rather than measuring (`Ra_record_from`),
      which is the "-7.33 again" I saw. `gain` follows lufs into the baked PCM, a second reason preview cids
       cannot be stable. So: **re-swearing is honest** (it is a dated environment change, not a masked bug),
        but the cids stay a bomb for the next Chrome. The owner's call stands as written in §0 class 3.
    Cheap instrument for next time: stamp `navigator.userAgent` into a `%see` note so a snap DATES the
     encoder instead of shelf archaeology doing it.
3. ✅ **`MusuBuddy`'s listening beat — FIXED 2026-09-05, two faults.** (a) The race: beat 10 fires off
    `step_n`, the pull lands on its own flow leg (LEG 3, every pass), and a fast runner reached step 10 before
     `pull_ok` stood — `hear_fail:nothing pulled` → `jam_fail:nothing heard`, the whole Book in 27s. Now
      `MusuBuddy_hear` WAITS for the pull inside its off-mutex `expecting()` (the wrangle keeps pumping the
       flow while it yields — MusuOgg's detached-decode idiom), bounded in the 240s ttlilt, stamping nothing.
        (b) A stray of my own from the beat-11 rewrite: `Heard_mark(w, me, rec)` reads the pub off the RECORD
         (`Ra_pub_of` → the mirror's label) and this Book keys its mirror by the LISTENER, so it minted a second
          heard Card wearing my own pub beside the DJ's. `Heard_take` mints the DJ's card itself; the mark is
           gone. (Live mirrors are keyed by the caster, so it was a Book-topology quirk, not a Heard.g bug.)
    (c) later the same day, the flow legs themselves: they fired on their preconditions alone, so a fast run had
     the whole stand→browse→pull inside step 4's quiescence window and a slow one snapped step 4 mid-pull with
      eleven parked wants — the same Book, two fixtures, neither wrong. The legs are now STEP-GATED (stand 5 ·
       browse 6 · pull 7). A ttlilt hold on the pull was tried and WEDGED the step: a req that arms a ttlilt bows
        out and `level.some(needs_work)` halts descent, so the legs the hold waited on stopped being pumped
         (Coding_guide; MusuOgg can hold only because it drives its work inside the async). The residue is the
          pull's mid-flight snap at step 7. **Measured:** two consecutive runs agreed exactly at steps 5, 7 (eleven
           parked wants) and 8 (`pulled,chunks=38,healed`); re-sworn; an independent check run then read
            **`ok:true`, 14/14, caveat 7** (the `self,round` class). The residue that remains: the pull can land at
             step 8 OR 9 depending on the run, so that one boundary can still go red — the accept's own verify pass
              saw 8/9 red while the very next run saw them ok. The real cure is a pull that drives itself inside an
               `expecting()` (MusuOgg's shape), which is a rewrite of LEG 3, not a gate; left for a deliberate pass.
    **Re-sworn 2026-09-05 with `--force`, and here is exactly what the force absorbed** — five classes, each
     read off the uncapped residual on a run whose `.go` mtime preceded the reload (both printed in the log):
      (1) `unemit:`/`req:unemit` reseq — `repli_parked` frames now interleave (`parked=9→11`) and the
       `repli_lines` header grew 22 bytes since 08-08; wire staleness, the pull still reaches `done,chunks=38,healed`.
      (2) `Stream,seq:16..37` cids — the Chrome encoder drift, bisected under Next 2. (3) `Record`/`Card`
       `path:` bare → `testsounds/…` — Ra.g:2060's dual-shape radiostock. (4) `pulled,chunks` parked/unparked
        counts — wire timing. (5) the intended change: `Jam,with > Spin/Like/Grab` + `jammed,spins,likes,grabs`
         + the old `see:the jam ledger…` → `Mag:heard > Cloud > Card,id,pub:<dj>,take` + `Mine,pub` + `jammed,took,
          card_names_the_dj` + the owner's re-declared `see:the listener remembers…`. Nothing else. 26 live
           `Card` lines = 22 catalog cards (class 3) + 4 heard cards (class 5); no own-pub card remains.
4. ✅ **§7.8 — RULED 2026-09-05** (owner's words under §7.8): SoundPooling is always the one thing, only its
    BACKING varies (OPFS on a phone, the FSA folder on a laptop); no gate, no second pile. The unison below
     makes that free.
5. **§7.5 — RULED, not built** (owner's words under §7.5): the handoff is CREW work (a ♥ on a Cave is a job the
    Captain hands to the crew body with the folder), and the FIRST ♥ is the consent sheet for the whole
     scheme — three checkboxes that are the three roads. **This is the next feature cut**: one frame kind +
      one `oai` at the landing over the same-soul body↔body frames, plus the first-♥ sheet.
    ✅ **THURSDAY — BUILT 2026-09-05, Book `MusuHandoff` 6/6 on its first run, every `%see` fired.** The
     wish travels, not the bytes: `Heard_hand_beat` (the phone's pass, nav-less, in `Heist_keep_beat`) sends
      ONE `take` frame to the first roster body wearing `%Organ,kind:trove` (organs already replicate on the
       roster mile); `Heard_hand_land` on the laptop mints the SAME Card on its own heard Mag — taken, `via:Phone`
        — and its ordinary `Heard_haul_beat` keeps it (beat 5: one `%Heist,seed,pub,take`); `take_got` comes back
         and the phone's Card wears `handed:Laptop`, so `Heard_word` turns `waiting` into `handed to Laptop`.
          Store-and-forward like %Suggest: the Card is the queue, sent once per session (`card.c.hand_sent`),
           re-offered when a sibling announces itself (`Heard_hand_wake` off `Swarm_roster_heard`), retired by the
            ack; beat 6 proves away-waits / back-hands and that the laptop's own ♥ finds the one Card. Both roads
             behind one door, `Swarm_sibling_reach` (crew mile live, in-process mail in a Book — keyed by body
              address vs identity prepub, which a %Body row carries both of).  Every road is a scalar on the Card
               (`into:pool` · `handed` · `via` · `held` · `landfail`) so the owner's patchbay — *"engine bits the
                user can put wires between… illegal paths glow white hot then melt"* — can be drawn straight off
                 the Mag with no state of its own.
     NOT built on purpose: un-taking does not travel (a heart handed then taken back within 10s stays handed;
      the laptop's ✕ is the way back — §C's law).
    ✅ **HEART-SETTINGS — BUILT 2026-09-05** (the owner: *"long-press the heart to open heart-settings"*). The
     sheet IS the one-sentence explanation the owner asked for — **"♥ keeps it."** — then the roads a ♥ can take
      on THIS device, one line each: *a copy this phone can play* (reads the SoundPool yes) · *the real file,
       into your music folder here* (a folder stands) or *fetched by your linked device when it's around — Laptop*
        (no folder; a switch, `Heard_hand_set`) · *the whole album it came from — not yet* (greyed until §C).
         Opens itself ONCE after the first ♥ ever (`Heard_tipped`/`Heard_tip`, a scalar on the heard Mag: durable,
          stashed with pillar 8, never re-asked across reloads or devices); long-press (450ms) or right-click on ♥
           is the way back forever. Scalars: `Mag:heard%tipped`, `%no_handoff` (absent = on) — the beat honours the
            switch (`Heard_hand_on`). RadioFace only; no state beyond open/closed. svelte-check clean.
    ⚠ **A bug the SwarmReboot gap exposed, fixed the same day: `Heard_seed` keyed the Mag by the CARD's pub**
     (`Mag:heard,pub:Cave`) while restash, the wipe, rehydrate and every reader key it by the OWNER's prepub —
      so a seeded wish sat where nobody looked: zero rows stashed, nothing back, and the idempotence swear blocked
       on a count of ZERO (the fixture at HEAD already carried `idem_heard_doubled`, so this predates today).
        The Mag wears its owner's pub; the Cards wear the holders'. Also: `story_accept` reads per-step `ok` and
         never `outcome.gaps`, so it called SwarmReboot GREEN with a declared assertion unmet — read `state` after
          every accept and require `"ok":true` with no `gaps` (memory + Story_hygiene_todo).
5b. ✅ **The SoundPooling unison — LANDED 2026-09-05** (SoundPooling_todo §0): one `%SoundPooling,pub:<me>`
    home holding consent · compartments · `%Provisions` · the material shelf. `%Pools` and `%SoundPile` are
     gone as mainkeys; faces read through `Ra_pool_stock`/`Ra_pool_provisions`, probed. Gated by the four
      Pool Books + SwarmReboot + MusuHeard (residuals read: exactly the move) — re-sworn with `--allow`.
6. **Hygiene, when someone owns it:** six Books' COMMITTED toc diges disagree with their own snaps
    (`SwarmBody` **22/23**, the `%Want` W1 gate) — no runner needed to fix, see `Story_hygiene_todo.md` §0.
7. ✅ **Committed** — `shbam` (2026-09-04 22:38) took the circuit, the rename, the fixtures and the docs. The
    2026-09-05 work (unison, MusuBuddy fixes, rulings, bisect) is the next commit point.

**The one thing that would detonate for a fresh session:** a red here is not evidence until it reproduces
 on a warm runner, and a caveat count is not a regression — but per the `self,round` ruling it IS a
  symptom. Read §0's last two ⚠ blocks before believing any sweep, and never mute a value to make a
   Book green — that is how the instrument gets deleted (I did it once; the owner reversed it).

---

## A. FOR A PERSON — what this is

You listen to the radio. Some of it is yours, some of it is a friend's, and once in a while something on a
 friend's radio is good enough that you want it to be yours too. This is the part of the app that notices
  that. It watches nothing but what you already do: let a track play out, press the heart. From that it
   works out what you'd keep, asks the friend for it quietly, and puts it on your disk under the artist's
    folder as if it had always been there. You never search, never name a file, never wait on a download
     screen. The one control you'll ever touch is the heart. Everything else is the app remembering, on
      your behalf, that you liked something — and forgetting, on your behalf, the things you shrugged past.

## B. ONE EVENING

Tuesday, the kitchen phone, the chip says *from Maya*. A track plays through while you cook; you touched
 nothing and nothing on screen changed. Next track, halfway in, you press ♡. It fills to ♥. Under the
  download glyph a small line says *1 waiting*. That's it — the phone has no music folder, so it holds
   the wish.

Thursday you open the laptop, the one with the drive, while the phone is still on the shelf and awake.
 On the phone the *1 waiting* line changes to *handed to laptop*. On the laptop the Haul shows *Maya ·
  Cosmic C · waiting* — Maya is not around yet. Friday night she is; the row grows a bar, then slides down
   into *landed*. Flip the chip to LOCAL: it's there, in *DJ Oscillo/*.

What you did not do: remember the title, ask Maya, open a folder picker, choose a format, keep a tab
 alive, or think about it once between Tuesday and Friday.

**What this evening actually needs, honestly.** Two overlaps, not one. The wish moves phone → laptop
 only while both are online at once (there is no ongoing crew road today — §5 — but same-soul body↔body
  frames already dispatch pier-less, so this is a small frame, not a new transport). The bytes move
   Maya → laptop only while those two are online at once. The phone's Haul is what makes the pathway
    legible: each wish says where it is — *on this phone only* → *handed to laptop* → *laptop is fetching
     from Maya* → *landed on laptop*. A phone can also act alone: a ♥ on a phone with no laptop pools the
      lofi rendition into its own browser pile the moment Maya is around, so the track plays on the phone
       offline; the original still waits for a body with a disk. The handoff frame is the one network
        piece in this doc (§7.5) — you said leave the radiator alone, so it is stated, not built.

## C. THE WORDS A PERSON MEETS

| on screen | means |
|---|---|
| **♥** | I want this. Press it again within a moment and it's un-pressed — a fat thumb, not a second vote. |
| **waiting** | the app is holding your wish until a friend with it is around and a device of yours has a disk. |
| **coming** | it is being fetched now, from that friend. |
| **landed** | it is on your disk. |
| **gave up** | nobody has had it for a long while; you can let it go or leave it. **You can't lose a heart** — only you retire one. |
| **the Haul** | the screen that shows waiting / coming / landed, grouped by who is bringing it. |
| **the pool** | a bounded pile of friends' music kept in the browser so the radio has surprises offline. |

Words a person never meets: `mire`, `take`, `Card`, `Cloud`. The heart *is* the score. (The human lens's
 verdict on `mire`: *"it sounds like a swamp, it's a score, and a person never needs the number — only its
  consequences."* Agreed: it stays in the snap and the rule table, never on a face.)

**Three decisions that stay yours** — press the heart or don't (Radio); let the pool exist and how big
 (the SoundPool cell — the number is the consent); call a fetch off, pause it, push it first (the Haul
  row's ✕ ⏸ ↑ — the only place a wish is withdrawn after the fact). The rule numbers in §2 are a fourth
   decision with no screen yet; say so rather than hide it.

---

## 0.5. THE ONE SHAPE — a disposable edge, and durable references into it

The owner, 2026-09-04, arriving at it from the other side: *"we need to mirror metadata at the edge of our
 kingdom of continuity… then these other structures refer to it? is that the thing?"* — **yes, that is
  the thing**, and everything below is a consequence of it. It is written here rather than discovered
   again in §4, because every place this doc did not cohere was two of these tiers being mixed.

**The `%Them` mirror IS the edge, and it is deliberately disposable.** Friend Mags never berth (Mag_todo
 §6b): session matter, re-exploded on every connect and shaved off after. It is the ONLY place foreign
  matter is held, and nothing in it survives a reload.

**Everything durable REFERS into it and holds nothing.** All four, by the same key:

| durable thing | how it refers |
|---|---|
| the dial's lineup card | `Card,id` (+ `.c.rec`, a §7.6 smear) |
| **a heard Card** | `Card,id,pub` |
| a keep in flight | `Heist,seed:<id>,pub` |
| an ask on the wire | `Rummage,want:<ref>,pier` |

`(id, pub)` is the whole address: `pub` → the Pier (`Swarm_peering(ident).o({Pier:1, pub})[0]`, what
 `Radio_friendly` already does), `id` → the mirror if it is up (`Ra_rec_find`), else a fresh
  `Rummage,seed:<id>` re-asks. **A lookup, never a search** — which is the whole reason no epoch is
   needed anywhere in this doc: nothing but the wire's CURRENT answer is ever trusted for bytes.

**And the one exception is the consent moment.** A heard Card is oblique — `id, pub, mire`, nothing else.
 On ♥ it clones the listing (`title, artist, dir, path, bytes, body_hash`, then `keep`). That is not an
  inconsistency: it is the border moving. Before the act you REFER to something foreign; after it you
   DESCRIBE something about to be yours. The first draft cloned at hearing — that was the hoard §6b
    forbids, and it was also impossible, since a shuffle Card often carries no `path` at all
     (`Ra_record_from` omits it).

**Four tiers, and mixing any two of them is the mistake:**

| | what | continuity |
|---|---|---|
| the collection (`Mine,pub > stock`) | my files, on disk | forever — the disk is the truth |
| `SoundPile,pub:<me>` | bytes that crossed, kept as cache | policy in, budget out (nobody chose a track) |
| **the mirrors** (`Theirs,pub > stock`) | **foreign metadata + preview chunks** | **none — this is the edge** |
| `Mag:heard` · the keeps · the asks | **references into the edge** | durable, and oblique until you act |

---

## 1. THE SHAPE — one Mag, two stages, no operation particle

```
Identity
  Mag:heard,pub:c0de                          ← MINE. `Mag,pub` is the Mag's primary key (ruled 2026-08-05):
    Cloud,page:41,created_at=1788400000          the name is unique PER pub, pub = who created and serves it.
      Card,id:r1,pub:f00d,mire=3,take,at=…    ← STAGE 2: taken — the listing is cloned in at this moment
        title:Cosmic C,artist:DJ Oscillo,dir:DJ Oscillo,path:…,bytes=51744301,body_hash:…,keep:9a3c…
      Card,id:r3,pub:f00d,take,at=…           ← its album sibling, taken with it (cloned from the describe)
        title:Blue Trane,dir:DJ Oscillo,path:…,bytes=…,body_hash:…
      Card,id:r2,pub:f00d,mire=1              ← STAGE 1: heard — OBLIQUE: id, who, how much. Nothing else.
    Cloud,page:40,created_at=1788313600
      Card,id:q2,pub:beef,mire=2

Mine,pub:c0de                             ← my music home (the names are §7.4's — `Musu` leaked from Books)
  stock,pub:c0de
    Mag:shuffle,pub:c0de > Cloud,page:N > Record,id   ← MY DISK read as a Mag: the generator (Mag_design)
  bay,pub:f00d                                ← what is left of `shop`: my asks OF f00d, and theirs of me
    Rummage,want:r1,pier:f00d,path:DJ Oscillo/Cosmic C.flac   ← transient: a describe|want ask; dropped when answered

Theirs,pub:f00d                             ← THEIR music as I hold it: the MIRROR. Session matter, never berths
  stock,pub:f00d
    Mag:shuffle,pub:f00d                      ← their generator Mag, arrived as ONE husk fragment (Ra_offer_stock)
      Cloud,page:7                            ← their page numbers, upserted by (Cloud,page)
        Record,id:r1,title:…,total=…,stage:previewed    ← a head + its preview chunks; `stage` is the fill state
        Record,id:r2,…
    Record,id:9a3c…,re:r1,path:…,total=1580,body_hash:…,by:f00d,vouch_sig:…   ← a materialised ORIGINAL (flat)
      Body,seq:0 … Body,seq:611               ← the wet partial, quarantined here as today
```

(The listing keys are drawn on a second line only to show the two stages; in a snap they ride the Card
 line like any other sc.)

### 1a. The Mag population — and where Repli operates

You asked whether there are tons of Mags to filter through, ours against replicated ones. There are
 exactly these, and nothing is ever filtered — the CONTAINER says whose (`Mine` | `Theirs,pub`)
  and the KEY says whose again (`Mag,pub`), so a container fault is misfiling, never merging:

| Mag | where | what | crosses? |
|---|---|---|---|
| `Mag:shuffle,pub:<me>` | `Mine > stock` | my disk read as a Mag — the `prandle` meander mints `Cloud,page:N` of 6 at the BACK, on demand; era-GC drops off the FRONT | yes — the Repli unit, husk-first, to every granted Pier |
| `Mag:shuffle,pub:<them>` | `Theirs,pub:<them> > stock` | the MIRROR of a friend's generator: heads + previews, chunks pulled by page on demand | it IS the crossing — never re-offered |
| `Mag:Lineup` (of `%Card`) | on `w` | the dial's 20-ahead: Cards referring by `id` into any of the above | no |
| `Mag:Streams` | on `w` | the dial's peek — what's playing next, fixed at prime time | no |
| the pool's Mag | `SoundPile,pub:<me> > stock` | my pressed lofi copies at `pool/…` (OPFS); same paged shape | no |
| `Mag:Musica` (culture draws) | `Mine > radiostocking` | ephemeral handfuls, keep-8, GC fodder | no |
| **`Mag:heard,pub:<me>`** (this doc) | `Identity` | what I heard of whom + what I took | **never** |

**Where Repli operates**, in one breath: a `%Record` appearing under a shelf is noticed by that shelf's
 Seem (`Repli_sent_se`), and the notice IS the offer — nobody says "offer this". `Ra_offer_stock` ships
  each Mag as ONE husk fragment (Mag head, its Cloud pages, every Record head, no chunk bytes). The far
   side lands it with `Repli_merge`: every line is a serialised find-or-create keyed by its `loc`
    (`Mag,pub` / `Cloud,page` / `Record,id`), so the mirror wears the sender's exact shape. `Ra_mag_warm`
     then pulls the first two records' opening chunk pages; `Ra_pull_beat` pulls further pages with
      `repli_want` on demand; `Ra_stage` stamps each mirrored Record's fill state
       (`husk|pulling|landing|previewed|parked|whole`). Absence is not deletion on this wire — a retired
        record is an `op:delete` line. That is the entire Repli surface this doc touches.

**No epoch, and why there is none to want.** The mirror is never versioned. Friend Mags never berth
 (Mag_todo §6b): they are session matter, re-exploded on every connect and shaved off after. So the only
  coordinate a mirrored Mag has is the friend's own `Cloud,page:N`, which only ever grows at the back. A
   Card's `id` therefore does not point at "their Mag as of Tuesday"; it points at a content hash, and
    the way back is a lookup, never a search (§6b again): `pub` → the Pier
     (`Swarm_peering(ident).o({Pier:1, pub})[0]`, what `Radio_friendly` already does), and `id` → the
      mirror if it is up (`Ra_rec_find(Ra_home_them(w, pub), {Record:1, id})`), else a fresh
       `Rummage,seed:<id>` re-asks the Pier (§4). **So yes: any structure may refer to a Card by
        `(id, pub)`, and from any such pair the source Pier is two lookups away — no epoch required,
         because nothing but the wire's current answer is ever trusted for bytes.** The Lineup already
          refers this way; its Cards carry the Record on `.c.rec`, which is one of the `.c` smears §7.6
           would make visible by carrying `pub` instead.

### 1b. The shuffler, in five lines — what really matters

There is a shuffler, and it is nearly clean; it is just spread over four homes. Today:

1. **Generate**: `Mag:shuffle` (mine, and each friend's mirror) mints six-record pages on demand
    (`Ra_mag_page`, `prandle`-seeded, 200k-safe — never enumerates).
2. **Choose**: `Radio_lineup_fill` keeps `Mag:Lineup` 20 Cards ahead by round-robining the contributor
    pools — mine, each `Theirs` mirror with a playable record, the pool — skipping ids that are lined
     or heard.
3. **Dedup**: `radio.c.heard`, a 100-cap set of bare ids, `.c`, gone on reload. Mag_todo §8 already ruled
    the cursor **"ABSOLUTELY durable — keep OBLIQUE track of Records heard"**, and `Radio_mag_cursor`
     (how far through a Mag you are) is derived from the same set. That ruling has had no home for six
      weeks.
4. **Dial**: `Radio_dial` ranks the rungs (a join in flight holds everything; then Lineup; then Streams
    peek; then pool; then own shuffle) and `Radio_peek_next` answers "what's next" once, at prime time.

**The unification this doc buys**: `Mag:heard` IS line 3. The heard Cards are the durable oblique cursor
 §8 asked for, the dedup set the fill skips by, the per-Mag cursor `Radio_mag_cursor` reads, AND the
  taste ledger §2 scores. One Mag, four readers, no `.c`. The Lineup stays a Mag of `%Card` on `w` (it is
   the right shape already); the only change there is `Card,id,pub` instead of `Card` + `.c.rec`. Nothing
    else in the shuffler moves.

**A Card has two stages, and the second is the consent moment.**
- **Heard** — `id, pub, mire`. Bare ids. This is Mag_todo §6b, ruled 2026-07-19 and never overturned:
   *"listening history… keep it OBLIQUE — bare ids, no titles|paths."* The first draft cloned every
    heard track's listing into account matter; that was the hoard the ruling forbids, and it was also
     impossible — a shuffle Card often has no `path` at all (`Ra_record_from` omits it).
- **Taken** — `take` plus the listing (`title, artist, dir, path, bytes, body_hash`) cloned from the
   friend's answer to a describe, plus `keep:` once the original is materialised. Acting is when it
    becomes yours to hold. Everything a later reader needs to find the way back is on the line: `pub` is
     the Pier, `id` is the content hash, `keep` is the original's own id on their side.

**One Card per `(id, pub)`, find-or-create, never re-minted.** All six lenses landed on this. "Heard
 again" bumps the Card that exists; nothing ever duplicates an `id` across pages; a heist holding a Card
  can never be handed a corpse.

**No `landed` key.** Four lenses, independently: "do I have it" is `id` on my shelf — derived, one home.
 The `Newlyadded` ledger stays the disk's own answer to *when and where*. What a Card DOES carry are the
  failures, which no shelf can derive: `held` (already had it by artist+title), `unvouched`, `landfail,why`.

**No operation particle.** A heist in progress *is* the query: `take` Cards whose `id` is not on my
 shelf, grouped by `pub`, oldest `at` first, one holder pulled at a time. `%Caper`, `%Heist`, `%Pick`,
  `%Jam/%Like/%Grab`, `keep.c.blagged`, `%Provisions/%Want` all dissolve into it. (The Mag lens argues
   the per-holder group deserves the ruled word `%Caper` as a container — §7.3.)

**No `era`, no `open` counter, no promotion, no move.** `Cloud,page:N,created_at` is the model's own
 coordinate; a page is one sitting, which is what a human reading the snap wants ("Tuesday's page"). GC is
  per-Card (§3); a Cloud goes when its last Card does. Nothing is ever re-minted or relocated.

## 2. THE RULES — one table, on the Mag, not in verbs

```
Mag:heard,pub:c0de,take_after=3,album_after=8,heard_ttl=30,take_ttl=90
```

| scalar | plain words |
|---|---|
| `take_after=3` | a track you let play through three times, present, gets taken as if you had pressed ♥ (the ambient road — §7.1 asks whether it exists at all) |
| `album_after=8` | eight play-throughs across one friend's folder and the whole folder is taken |
| `heard_ttl=30` | a heard-but-never-taken Card is forgotten after thirty days |
| `take_ttl=90` | a taken Card no holder has answered in ninety days reads *gave up* |

| event | effect | why (the human lens) |
|---|---|---|
| a track plays through **with a person present** | `mire +1` | a kitchen phone playing to an empty room is not attention — the `humdinger` predicate already exists for exactly this |
| ♥ | `take` — directly. Not `+5`. | the heart is a decision, not a vote; a score that "reaches" a threshold is magic nobody can see |
| ♥ again within ~10 s | un-`take` | a second press means *undo* on every phone there is; mashing is not a behaviour, mis-tapping is |
| skip | nothing | people skip songs they love — wrong moment, heard it this morning, the phone rang |
| `mire ≥ take_after` | `take` | the ambient road: you never pressed anything, you just kept letting it play |
| Σ `mire` over `(pub, dir)` ≥ `album_after` | `take` the folder | and the Haul row says **album**, not just the track — the verdict must be visible or it is creepy |
| `mire` in the ambient band | bias the dial toward `pub` | with a tell on the chip — *more Maya* — or it feels either clever or creepy depending on nothing you control |

Every number is a scalar on the Mag line — visible, snapped, Book-gated, no `%Rules` particle. When they
 are ever per-account, they already are.

## 3. HOW IT FORGETS

(This was called "the protein machinery" and the owner called it, correctly: *"do you really understand
 `PROTEIN MACHINERY`, how will that work… it decides when Mags are discardable? or what?"*.  It does not.
  It is not about Mags and not about Heists. It is about ONE thing — **heard Cards, and when they go**.
   The metaphor was reaching for turnover: the Mag is a steady-state pool, synthesised on hearing and
    degraded on a clock, so it stays flat instead of growing forever. That is a BOUND, not a machine, and
     the bound is stated below in its own words.)

One query, run on the tick, per Card:

```
drop  if  ¬take  ∧  created_at < now − heard_ttl          (a heard track nobody wanted: gone in 30 days)
keep  if  take                                             (a heart is never dropped by a clock)
```

and one human-facing state instead of an exit:

```
gave up  if  take  ∧  ¬keep  ∧  at < now − take_ttl        (90 days with no holder ever answering)
```

A given-up Card is *shown* (the Haul row I already built) and offers ✕; it is never deleted by the
 machine. This is the lifecycle lens's "a take with no exit is immortality" and the human lens's *"you
  can't lose a heart"* reconciled: the clock can change what a heart *says*, never whether it exists.

**THREE DIFFERENT GIVE-UPS, and conflating them is half of why this doc did not cohere** (the owner:
 *"or Heists are give-up-able?"*). They live at three different layers and only the third is new:

| give-up | whose | what happens |
|---|---|---|
| the **transfer stalls** — bytes stop arriving | the keep | already built: `Heist_keep_gist`'s *"given up — 4h, nothing landed"*, and `Heist_pull_giveup` for a pick the source demonstrably cannot serve |
| the wire **answers, and the answer is not the track** | the keep → the Card | `held` (you already had it by artist+title) · `unvouched` (the offer's signature did not verify) · `landfail,why` (three throws at the landing). The verdict is copied onto the Card and the keep is ENDED |
| **nobody has ever had it**, 90 days | the Card | the display word *gave up*. No deletion, no machine act; the ✕ is the only exit |

The middle row is the one that was actually broken, and it is a WEDGE, not a cosmetic gap: all three of
 those engine verdicts `mir.rm` the husk out of the mirror, so the keep is left pulling a record that no
  longer exists — `left` never reaches zero, the keep never reaches `done`, and that holder's one live
   slot is occupied forever. Copying the verdict onto the Card and ending the keep is what lets the queue
    move on; a re-press of ♥ clears the verdict and asks again, which is the retry road.

**Bound.** With no immortals and no promotion the Mag is (tracks heard in the last 30 days) + (hearts not
 yet landed). The lifecycle lens priced a heavy listener at ≤ ~1,000 Cards ≈ 250 KB, flat.

**A Cloud with a `take` Card in it is pinned by construction** — the model's "never drop a Cloud any
 position sits on", where a want is a position. No re-mint needed to honour it.

## 4. THE SEAM TO THE BYTE LANE — what the wire lens found

**How a heist is asked for: it is a Repli thing, all the way down.** There is no heist protocol. There
 are three asks, each a particle offered over the granted wire, each answered by particles offered back:

| ask | particle, minted in MY `bay,pub:<them>` | their answer, landing in MY mirror |
|---|---|---|
| **describe the folder** this track came from | `Rummage,seed:<id>,pier:<them>` | the folder's `%Record` heads — metadata only, no reads on their disk (`Heist_rummage_answer` → `Heist_offer_all`) |
| **materialise one file** (the original, or `lofi` the ogg128) | `Rummage,want:<ref>,pier:<them>,path:<hint>` | that one `%Record,re:<id>` with its FULL head — `total`, `body_hash`, vouch — the only read-side cost, bounded to chosen tracks |
| **pull the pages** | `repli_want` frames, a want-once cursor re-asked every 4 s | `%Body,seq:N` chunk particles under that Record until `stage:whole` |

So the answer to "per file, after we enumerate?" is: **enumerate by Repli, then per file by Repli, then
 per page by Repli.** The first ask is the enumeration; the second is per chosen file; the third is
  `Ra_pull_beat`, the same pump that fills a preview. The ask is idempotent by key (a re-ask upserts onto
   the same mirror particle; `n=` counts the episode so the source can tell a fresh ask from an echo).

**Two id-spaces — why the first ask is not optional.** The Mag `id` is the enid of the *streamed*
 rendition. The original a heist lands is materialised on their side under a keep-id (`Heist_keep_id`)
  with `re:<enid>` pointing back. So a `take` cannot `repli_want` by `id` and get the flac — it would get
   the opus. The sequence, every time:

1. `take` mints `Rummage,seed:<id>` (describe) — or straight to `Rummage,want:<id>` when the Card already
    holds a listing (a re-heist after *gave up*, or a sibling taken by the album rule).
2. The answer lands `%Record,re:<id>` heads in the mirror — the album's siblings among them.
3. The Card clones its listing off that head and stamps `keep:<their keep-id>`; siblings become sibling
    Cards with `take` if the album rule fired, else nothing (an untaken sibling is not an interaction).
4. `Heist_beat(…, cards, …)` joins `mir.o({Record:1, re:card.sc.id})` and pulls; the wet partial
    quarantines under that mirror record exactly as today; land verifies `body_hash`.
5. Done-ness is `id` on my shelf. Failures stamp the Card.

**Friend offline** ⇒ the Card waits with `take` and no `keep`. Honest, and the row says *waiting*.

**The Card must not be offered back as a holding.** `Mag:heard` hangs under `%Identity`, which is never
 a Repli source; and the export protocol strips `mire`/`take` so a ferried Card cannot read as a
  `%Record`. Add `Card:['id','pub']` to `Repli_identity_keys` and to `Swarm_graft`'s ID table before the
   first Card exists, or every re-import twins every Card whose `mire` moved (persistence lens, §5).

**The job's scalars find homes**: `into:<category>` on a Card **only when a human chose** (absence =
 land under `dir`; "any sibling in this group carries `into`" is what "the human spoke" means now);
  `disbelieve_directories` is a Mag scalar; the tally rows become the failure keys above.

## 5. PERSISTENCE — the corrected matrix

`Mag:heard` files under **S3**: hung under `%Identity` (the account export is a skip-list, so it rides
 free) **plus** a `Swarm_restash_heard` stash pillar (a phone has no folder, so the stash is its only
  durable home). The pools are the precedent. Three corrections from the persistence lens:

- **Never bump the account on a `mire` tick.** `Swarm_persist` rewrites the whole account file on every
   `%Identity` bump, inside the beliefs mutex. Bump on `take`, un-`take`, and a page roll — never on a
    play-through.
- **There is no crew road.** The ferry is a one-shot bootstrap at link; afterwards each body writes its
   own account file and nothing merges. So "pools ride the crew ferry by design" was wrong, and "the
    Cave lives out the Captain's hearts" is real work (W2 `ferry_want` / a `%Reach`), not one line.
     State the merge law now anyway, because two bodies will write: **`mire = max`, `take = OR`, keyed
      `(id, pub)` with no device key.** Where it lands first is the pillar's `oai`.
- **`take` rides the ferry; the haul is body-level.** A new device inheriting your wishes is the
   feature. A body hauls a `take` Card only into the share *it* mounts, gated by `/Crew` membership
    (never the `%Body` roster). A phone hauls nothing. No `into:<share>` on the Card.

Truth model: the C tree is truth; both homes are write-through mirrors; on a healthy boot the stash wins
 and the disk is read only when Dexie is empty.

| thing | reload | data cleared | new device | FSA gone | crewmate | friend offline |
|---|---|---|---|---|---|---|
| `Mag:heard` | ✓ stash | ✗ unless account | ~ account, once graft has ID rows | ✓ stash | ✗ — no road yet | ✓ |
| `take` | ✓ | ✗ unless account | ✓ inherits the queue | ✓ waits | ✗ — no road yet | ✓ waits |
| the wet partial | ✗ (resync re-verifies bytes on disk) | ✗ | ✗ | ✗ | ✗ | ✗ |
| berth · the collection · `pool/` · the mirror | unchanged from before | | | | | |

Two policy facts, once: **berth is per-share** — a crewmate mounting the same NAS would inherit anything
 there, which is why a want is account matter and not a berth tenant; and **a `dontSnap` bag is S0
  wearing a hat** — fine for a face's mirror of a ledger, wrong for anything a human decided.

## 6. WHAT THIS DELETED, AND WHAT SURVIVED

**The actual list is §0's two tables** — written from the diff rather than from the plan, so it is the one
 to trust. What follows is only the part of the original plan that did NOT happen, and why, because a
  deletion list that quietly shrank is how a doc starts lying about the code:

| planned to go | what actually happened |
|---|---|
| `%Heist` (the keep) and `%Pick` | **KEPT**, deliberately. The keep is now TRANSIENT SCAFFOLDING: the beat mints one per holder from the oldest take Card, lets it finish, reads it back (`Heard_clone_beat`) and ends it. The Card is the intent and the ledger; the keep only carries bytes. Ripping the shop/keep/Pick machine is a separate multi-day job and this circuit does not need it to be true. |
| `%Caper` (the job) and its `filing/took/held/denied` rows | **KEPT** as the job — but its VERDICT rows (`held`/`unvouched`/`landfail,why`) are now copied onto the Card before the job flattens, which is what §0 found: without that copy the keep wedges its holder's slot forever. |
| `%Hauls/%Haul` (the landed-album rows) | **KEPT**. Only the `%Newly>%Fresh` arrivals MIRROR inside it went (→ `Heard_landed_ids`). `Heist_haul_look` still answers "what landed, by album, when" off the disk's own ledger, which nothing else answers. |
| `%Provisions > %Want` | **KEPT**. It is the pool steward's want-list, not the heart's — a different question with a different answer, and folding it in would have been the one-of-anything mistake in reverse. |
| `keep.c.blagged`, `rec.c.unity`, `w.c.keep_beat_at` | **KEPT** (`keep_beat_at` now stamps `'heard'` where it stamped `'wants'` — it is the hang cursor `Swarm_latch_stale` reads, not a design statement). |

## 7. RULINGS OWED (yours)

1. **The four numbers** — `take_after`, `album_after`, `heard_ttl`, `take_ttl` — and whether the ambient
    road (`mire ≥ take_after` ⇒ `take`, no heart pressed) exists at all in v1.0. Recommendation: ship
     v1.0 with ♥ only and the two TTLs; the ambient road is the squishy zone and wants a screen first.
2. **A page per sitting** — or per day. Sitting is the most legible; day is the most predictable.
3. **The per-holder group: a query or a container?** Five lenses say query (no particle). The Mag lens
    says the ruled word `%Caper,pub:<them>` should name it. My recommendation: query — a container that
     holds nothing the Cards don't already say is the splatter coming back.
4. **Names** — ✅ **RULED AND DONE 2026-09-04** (the code, the faces, the scripts and the fixtures; the
    living docs followed after). The leaked Book prefix is gone. `MusuSelf` → **`Mine`**,
    `MusuThem` → **`Theirs`**, `MusuPool` → **`SoundPile`**; each still wears `pub` and still keeps its `stock`
     child, and the two mainkeys stay DISTINCT (merging mine-and-theirs into one keyed by `pub` is the
      exact bug fixed 2026-08-05 — `Ra_home_them` cannot answer "is this me?"). Measured blast radius:
       the estimate was "322 references"; the MEASURED figure with word boundaries was **159 in code**,
        and the sweep touched **896 occurrences across 351 files** once fixtures were included. The gap is
         the trap below, and it is the whole reason this was worth measuring before doing.
     ⚠⚠ **`MusuPool` MATCHES 170 TIMES NAIVELY AND 8 TIMES CORRECTLY.** The other 162 are the Book names
      `MusuPoolRadio` · `MusuPoolRandom` · `MusuPoolBytes` · `MusuPoolFill` and every one of their
       `_T/_note/_drive/_stand/_witness` helpers, plus seed strings like `'MusuPoolBytes-Cap'` and paths
        like `'pool/MusuPoolBytes'`. A bare `s/MusuPool/…/g` destroys four Books. **The rename is only ever
         safe with a word boundary** (`MusuPool\b`). Same shape, smaller blast, for the other two. `heard` / `take` stand. `shop` still goes and `bay,pub:<them>` still
          moves up under the home — both are shape changes, not renames, and neither is in this build.
     ⚠ **`Pool` was the owner's third word and it CANNOT be used**: `%Pool,name:<compartment>` already
      exists — the SoundPooling declaration on the identity (`%Pools > %Pool,name,take,cap,salt`, Ra.g:1053,
       the seventh stash pillar, gated by SwarmReboot). Taking it for the HOME as well would put two
        different shapes under one mainkey, which is the one-of-anything fault CLAUDE.md names. `Pile` is
         free, and the owner asked the pool home be "more descriptive … two or three words shoved together"
           and asked what is actually in it: **my pressed lofi copies of friends' tracks**, at `pool/…`
            OPFS paths (`grade:ogg128`), a bounded browser-side sediment so the radio still has surprises
             offline. So **`SoundPile,pub:<me>`** — tied to the feature that fills it (SoundPooling), "pile"
              being §C's own word, and honest when the pooled bytes are NOT lofi (`Ra_rec_pool` keeps the
               original when no press happened, so `LofiPile` would sometimes lie). The `%Pool,name`
                compartments stay exactly where they are: they are the DECLARATION ("keep this much of this
                 kind"), the SoundPile is the sediment — two different things, two mainkeys, as it should be.

     **The SoundPile is LIFECYCLE; the heard Mag is DECISIONS. That line is what this whole doc is about**
      (the owner, asking the right question of the name: *"what's in it? what's it for? it's lifecycle?"*):

     | | who decides what is in it | how a thing leaves |
     |---|---|---|
     | `SoundPile,pub:<me>` | the machine, by policy (`%Pool,name,take,cap`) | the machine, by budget — eviction (`Ra_quarter` press·pull·**evict**) |
     | `Mag:heard,pub:<me>` | you heard it — or **you pressed ♥** | a hearing ages out at `heard_ttl`; a **heart only ever leaves by your ✕** |

     Concretely the pile holds transcoded LOFI copies of friends' tracks in OPFS under `pool/…`
      (`Record,id:<lofi enid>,of:<orig id>,grade:ogg128`) — not files, not your collection: browser storage
       the person will never see in a files app. It exists so the radio still plays when nobody is online,
        which on a phone (no folder, §5) is the difference between a radio and silence.

     **It is NOT a staging area in front of the `%Them` mirrors** (the owner's next question, and the
      answer separates three homes that this doc kept letting blur into one):

     | home | how many | what it is |
     |---|---|---|
     | `Theirs,pub:<them> > stock` | **one per friend** | the mirror of their generator Mag — heads + preview chunks. Session matter, swept between sessions, never berths |
     | the **quarantine** (`Record,re:… > %Body,seq` under that mirror) | **one per friend** | ← THIS is the staging area in front of a `%Them`: the wet partial, verified against `body_hash`, then moved out into the collection and gone |
     | `SoundPile,pub:<me>` | **one, keyed by ME** | a DESTINATION, not a way-station: bytes land and stay until evicted |

     The pile sits BESIDE the mirrors, not in front of them — the dial reads it as one more contributor
      pool alongside each `%Them` and my own shuffle. And it is not fed only by them: `Ra_quarter_diff`
       decides per track `held[id] ? 'press' : 'pull'` — **press** = transcode from MY OWN library,
        **pull** = fetch through a friend's mirror. Both roads end in the same pile.
     **Is the pooled material tracked, and should the home just be called `SoundPooling`?** It is tracked,
      and the pile IS the tracking — no second ledger: each pooled track is a `%Record` on the pile's own
       stock shelf (`id:<lofi enid>, of:<orig id>, grade:ogg128, path:pool/…`), which is both the holding
        and the record of it (identity-is-per-shelf: a pool %Record is a DIFFERENT holding from the library
         one, never a dupe), and `Ra_quarter` reads exactly that shelf for `pooled[]`.
     But the FEATURE is three parts in three places — the **declaration** (`%Pools > %Pool,name,take,cap`
      on the identity), the **activity** (`Ra_quarter`, the steward), and the **material** (the pile). Name
       the material after the feature and a reader seeing `SoundPooling,pub:c0de` in a snap will go looking
        for the compartments underneath it and not find them. `-ing` names an activity; a mainkey names a
         thing. **Recommendation: `SoundPile` for the material, and the feature name stays free.**
     ⤷ There IS a version where `SoundPooling` becomes the right name: move the compartments UNDER the home,
        so `SoundPooling,pub:<me> > %Pool,name:… + stock,pub > Mag:shuffle > Record` is the whole feature in
         one place. Real cohesion gain, but a SHAPE change rather than a rename — it moves the seventh stash
          pillar and SwarmReboot's fixture. Owner's call; not in this build either way.

     **⚠ IS THE PILE WORTH HAVING AT ALL? The owner, and he is half right** (*"a cache of Radio that
      happened? maybe… to make smuggleable to peers? it's a little contrived. I just don't see the
       point."*). Two facts settle the shape of the answer:
     - **It is NOT for smuggling.** Checked on the wire: only `Ra_home_self` — my own library — is ever
        registered as a caster or offered (`Swarm.g:4462`, `:5075`). The pile is never re-offered to
         anybody. It is purely local playback.
     - So the whole justification is local, and it is exactly one sentence: **the SoundPile is the PHONE's
        library.** A phone has no `showDirectoryPicker` — no folder, no collection, ever — so everything it
         can play is either streaming from a friend who is online RIGHT NOW, or in the pile. Without it a
          phone's radio goes silent the moment its friends go to bed.
     **And where he is right that it is contrived**: on a laptop with a real disk the pile is a WORSE
      DUPLICATE OF THE HEIST. A ♥ there lands the ORIGINAL, in the collection, under the artist's folder,
       yours forever; the pile lands a LOFI copy into obscure browser storage the browser may clear unasked,
        under a different id. Same track, second copy, strictly worse. And `take:'radio'` ("keep what
         played") is the most contrived compartment of all — sediment with no decision anywhere in it.

     **RULING WORTH MAKING (§7.8, not in this build):** *the pile should exist only where there is no
      folder.* FSA ⇒ a heart lands the original in the collection and there is NO pile; no FSA ⇒ the pile
       IS the collection. One rule, and the contrived case disappears: a laptop stops keeping a second
        worse copy of music it already owns, and the phone keeps the only thing that makes it a radio.
     Today it is ungated — a laptop pools too. That is a change to SoundPooling, not to this circuit.

     One-per-me is the right shape because the pile is a BUDGET: "keep 200MB of music on this device" is a
      fact about the device, not about any friend, and splitting it per friend would invent N budgets
       nobody set. Checked the same way: `Mine` and `Theirs` are both free as mainkeys and as non-first
           keys; mainkeys are NOT namespaced per paradigm, so the check is over the whole tree.

     **Where all this lives, for a reader who has lost the thread**: `H:Mundo > A:Sounditron > w:Sounditron`
      — the resident /BigSoundland world, which is a NAMED BOOK world that the whole music app runs inside
       (the reason `Radio_prod_seed`'s old `if (w.sc.w) return` gate misfired on the one surface it was
        written for). The beacon is `top_House().c.radio_w`, stamped in exactly ONE place — `Stoker_ensure`,
         Radio.g:2521 — and read by the share, every face, Repli and Sounditron.
5. **The handoff road** — the phone → laptop `take` frame (§B). Same-soul body↔body frames already
    dispatch pier-less, so this is one frame kind + one `oai` at the landing, not a transport — but it is
     the network layer you said to leave alone, so it waits for your word. Without it a phone's ♥ can only
      pool lofi on the phone itself.
    **RULED 2026-09-05 (the owner, verbatim):** *"the Captain needs to handover jobs to the Crew, basically…
     and I'm thinking after you press heart the first time, you might get popped up asked about '[x] stash
      tracks on your phone, then later from a Linked Device [x] downloading the [x] the whole album they're
       from' — maybe… maybe that would be annoying. that might be the clearest way to present the whole
        sound-trafficking-scheme."*
    Read: (a) the road IS crew work — a ♥ on a Cave is a JOB the Captain hands to whichever crew body has the
     folder, so it rides the same `/Crew` membership and the same-soul body↔body frames, not a friend wire;
      (b) the FIRST ♥ is the consent moment for the whole scheme, presented as three checkboxes that ARE the
       three roads — stash on this phone (the SoundPooling yes), let a linked device download it (the
        handoff), and pull the whole album (the §C widen). One sheet, once, and every later ♥ is silent.
         The owner's own doubt ("annoying") is real: keep it to the first heart only, never re-ask, and make
          the ✕ on the Door the way back. Not built — the frame kind + the first-♥ sheet are the next cut.
6. **`.c` → a visible sphere** — assumed by §6, not built here (`Repli_design` §5). First candidates from
    this doc: `radio.c.heard` (becomes `Mag:heard`), Lineup's `Card.c.rec` (becomes `Card,id,pub`).
8. **Does the SoundPile exist on a device that HAS a folder?** Recommendation: no — FSA ⇒ hearts land
    originals in the collection and there is no pile; no FSA ⇒ the pile is the collection. See §1a's
     ⚠ block: on a laptop the pile is a strictly worse duplicate of the heist, and `take:'radio'` is
      sediment nobody chose. Not in this build; it is a SoundPooling change.
    **RULED 2026-09-05 (the owner, verbatim):** *"I'm guessing no… when others wanted our SoundPooling they'd
     cause fresh encodings, we'd simply listen to our folder… don't let this get weird though, maybe we're
      always supposed to have SoundPooling, and sometimes its in FSA, sometimes OPFS, I don't know… or random
       FSA tracks can transparently be SoundPooling as well? because SP doesn't have directory structure
        right, it's just the Pool and then a big list of tracks…"*
    Read: the leaning is NO pile where a folder stands — but the shape the owner reaches for is better than
     a gate: **SoundPooling is always the one thing, and only its BACKING varies** (OPFS `pool/…` on a phone,
      the FSA folder on a laptop). It has no directory structure of its own — one home, a flat list of
       tracks — so a folder track can stand in it transparently and nothing is duplicated. The unison landed
        2026-09-05 (SoundPooling_todo §0) makes that possible for free: the home is one particle either way,
         and "which nav holds the bytes" is a property of the record's `path`, not of the shape. "Don't let
          this get weird" is the constraint: no second pile, no per-backing mainkey, no gate that flips the
           feature off — just a home that is always there and a path that says where the bytes are.

7. **`Mag:heard` as the durable cursor** — §1b makes the six-week-old §8 ruling real by construction. Nod
    or veto: it means the dedup set survives reload and grows by `heard_ttl`, not by a 100 cap.

## 8. THE HAGGLE — what each lens won

| lens | won | lost |
|---|---|---|
| **ego-death** | flat GC by `created_at`; ♥ *is* `take`; `mire` counts plays only; `landed` derived; `%Rules` → scalars on the Mag; don't clone untaken siblings | "keep the full clone at heard" — overruled by §6b |
| **lifecycle** | one Card per `(id, pub)`, never re-minted; no timer-driven pages; the harvester's receipt is `take` itself; the growth bound | promotion, promote-cost, `born=` — unnecessary once nothing is re-minted |
| **persistence** | no crew road exists; graft ID rows; never bump on a `mire` tick; the merge law; haul is body-level | — |
| **the wire** | two id-spaces (`re:`/`keep:`); Rummage first, always; failure keys on the Card; strip `mire/take` at export | `landed` as a stamp — outvoted 4–1 |
| **the human** | §A–C verbatim; second ♥ = undo; skip = 0; presence-gated play-through; the verdict word on the row; *you can't lose a heart* | — |
| **the Mag model** | OBLIQUE heard (§6b); `of:` → `pub:`; `Cloud,page,created_at`; a Mag wears `pub:<me>`; `landed` derived | `%Caper` as the group's container — left to you (§7.3) |
