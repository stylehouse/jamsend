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
    call sites is a churn with no reader benefit, so it was left. **The ledger is not built yet** —
     `Heist_flatten` still deletes a finished operation, so nothing accumulates into `%Haul`. That is
      the next move, and it is what "a list of What Heisted" means.

---

## 0. Next move (read first)

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
