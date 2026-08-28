# Siphon_todo.md — whole tracks in your pocket: siphon, tag, playlist

The working doc for the DELIBERATE SoundPool experience — the owner (2026-08-28, three hours late
 and wanting the soundland pulled together): *"I want to be able to go somewhere with my phone,
  load an Invite to the daemon running back home, and randomly siphon entire LOFI tracks to
   SoundPool to try out in their entirety, in a more controllable Radio experience... and I want
    to add tags to them! once a tag is defined it can be applied easier... they become playlists
     too. this is just to be hidden in the 'from $who' button, which should go local|SoundPool
      when"* (sentence ended there; read as: the chip names the live SOURCE and flips between
       them when more than one stands).

**The doctrine: this is a SPIN-OUT, connect-up-when-99%-ready** (the owner's words).  Build it in
 NEW FILES ONLY — a new ghost, a new Book, a new face — touching nothing that stands, and leave the
  single connect-up seam (the RadioFace source chip) as a PROPOSED patch at the bottom of this doc,
   applied by hand after review.  Portability_todo keeps the ambient economy (press-what-you-
    streamed, quartermaster, smuggle); THIS doc owns the deliberate act: *I see a track over there,
     I want the whole of it here, and I want to say what it is.*

---

## 0. Where to start, and the arc

**The destination.**  Away from home with a phone: load an Invite that friends you to the daemon
 running back home → its whole library is browsable → tap tracks to SIPHON them entire (whole-thing
  LOFI copies into the OPFS SoundPool, not radio quarters) → play them in their entirety, offline,
   in a Radio that obeys you (next/prev/pick, not just the jam's drift) → stamp TAGS on them —
    defined once, applied cheap — and a tag IS a playlist: play it, and the radio walks it.

**What already stands (audited 2026-08-28, Portability_todo §"LIVE WIRING GAP"):**
- `Ra_press` (v1 byte-copy + v2 ogg128), `Ra_quarter` (goal/diff/cap), `Ra_quarter_serve` (the
   dispose loop) — all in `Ghost/M/Ra.g`, Book-proven (MusuPress/MusuQuarter/MusuSteward), and
    DORMANT: no live caller.  The siphon is a new deliberate caller beside them, not a rewrite.
- The pool MOUNT (`pool/…` → OPFS, listen-only wrap) stands for the shareless phone.
- `Heist_catalog_land` → `Ra_rec_pool` (the pool catalog branch) is in and proven inert.
- The daemon (jamserve, :9099) stocks `/music` and speaks the relay; a phone that friends it can
   already STREAM its library.  The FSA rule holds: the app knows only the user's one FSA handle —
    the daemon is the thing that points at /music (CLAUDE.md; the owner's single-FSA ruling).
- The `%Invite` autovivify rails are audited generic (Portability_todo §7).

**The model, under the identity rules (CLAUDE.md "identity is per-shelf"):**
- A **Tag is a thing** — it exists ONCE: `%Tag,name:lofi` on a `%Tags` shelf in the radio world.
   Defining it once is what makes applying it cheap (the owner's ask).
- An **application is a referring particle wearing `of:`** (the many:1 rule): `%Tagged,of:<origId>`
   as a CHILD of its `%Tag` — never a second particle impersonating `%Record`.  So the tag's
    children ENUMERATE its tracks, which is why **a tag IS a playlist** with no extra machinery:
     play the tag = walk its `%Tagged` children.
- A **siphon in flight** is legible state: `%Siphon,of:<origId>` with plain sc phases
   (`asked → pulling → landed`), dropped once landed (transient reqs are scaffolding, not ledger —
    the awaitbuf lesson).  Booleans ride as `1` or absent, never false/0.

**The rungs (build bottom-up, each Book-provable headless before any face exists):**
1. **Recon** — read `Ghost/M/Ra.g` (press/quarter/steward regions), `Ghost/M/Heist.g` (pull/land),
    Portability_todo §3/§4 (the unresolved `lib` mapping — the siphon SIDESTEPS it: its lib is
     explicitly the befriended share the user is browsing, so nothing blind is wired), the daemon's
      serve path.  Write findings into §recon below.
2. **The tag model** — `Siphon_tag_def(w, name)` (find-or-create the `%Tag`), `Siphon_tag_apply(w,
    tag, origId)` / `_unapply` (oai/drop the `%Tagged,of:`), `Siphon_playlist(w, tag)` (the ordered
     walk).  Pure model, Book-proven with zero IO.
3. **The siphon verb** — `Siphon_pull(w, shelf, pool, lib, origId)`: the deliberate whole-thing
    press of ONE named track from a friend's share into the pool (compose Ra_press; whole-thing =
     the entire body, not a quarter goal).  Idempotent the Ra_quarter way; a landed siphon drops
      its `%Siphon` req.
4. **The Book** — a new Story Book (own .g in Ghost/Story/, own toc) proving 2+3: def a tag, apply
    twice, unapply once, siphon o1 from a lib into a pool, re-siphon is a no-op, playlist walk
     yields the tagged order.  `%see:` assertions, no commas in the sentences.
5. **The controllable radio + the face** — a source notion in the radio world (`local | pool |
    <friend>`), pick/next/prev over the pool or a playlist; a face (new .svelte) listing pooled
     tracks with tag chips and a define-a-tag affordance.  HIDDEN behind the RadioFace "from $who"
      chip — which is the connect-up seam, LAST.
6. **The connect-up seam (proposed, not applied)** — the RadioFace chip becomes the source
    selector.  Write the exact patch here; the human or the resident session applies it after
     review.

**The bombs (in force here as everywhere):**
- A cold tab RUNS NO BEATS (Solo_todo) — nothing may live in a Story beat; live behaviour rides
   the commission seam, `Radio_nudge` callers, or a face's own effects, all humdinger-gated.
- Books record on runner tabs WITHOUT humdinger — gate every live-tab behaviour on it and the
   fixture set stays byte-identical by construction.
- `.g` compiles via LocalGen with an explicit `GFILES=` (the silent-skip trap); braced if/else
   only; never edit the `.go`.
- Do NOT wire the ambient press economy (Portability §3/§4) — the siphon's explicit lib choice is
   what keeps this doc out of that delicate area.

## recon (the spun-out agent writes here)

*(written 2026-08-28 by the spun-out session that built rungs 2–4; file:line refs are to that
 evening's tree.)*

**1. The press machinery (Ghost/M/Ra.g — all DORMANT, Book-proven, exactly as §0 says):**
- `Ra_rec_pool(shelf, origId, lofiId, path, grade)` (~:895) — the pool's own catalog door beside
   `Ra_rec_home`: mints through the paged-Mag landing door; `of:`/`grade` stamped ONLY when
    supplied (the undef-mint law); a v1 press coincides (`lofiId === origId` ⇒ both elided).
- `Ra_press(w, nav, lib, shelf, origId, opts)` (~:925) — v1 byte-copy: find the Original in
   `lib` (`Ra_rec_find`, needs `sc.path`), `nav.bin_read` the bytes, land at the pool-relative
    path (source path minus its base segment — `music/a/one.wav` → `pool/a/one.wav`, card path
     `a/one.wav`), `nav.bin_write`, then catalog through **`Heist_catalog_land(nav,'pool',…)`**
      — never a parallel minter.  Mints a `%press,of:<id>` job on `w` and LEAVES it standing
       (its comment nominates "the pool-steward's sweep" as the drop seam).  Stamps `body_hash`
        of exactly what was written.  Returns `{card} | {fail:'why'}`, no throw.  v2
         (`opts.lofi` + injected `opts.render`) → own enid, `of:`, `grade:'ogg128'`, `.ogg` path.
- `Ra_quarter_tally/goal/diff` (~:1012–1059) — Jam-ledger taste (Like 3 · Grab 2 · Spin 1),
   goal sorted score-desc-then-id-asc capped, diff → `press` (lib-held) / `pull` (reputation
    only) / `evict` (stale pooled).
- `Ra_quarter` (~:1064) — `%Provisions`/`%Want,of,do` oai-idempotent: an unchanged world
   re-sits to the SAME rows; a want whose reason left the diff is dropped.
- `Ra_quarter_serve(w, nav, shelf, pool, lib, cap)` (~:1093) — re-sits, then enacts only what a
   lone body owns: `press` via `Ra_press`, `evict` via `Ra_rec_drop`; `pull` stays standing.
    **Its `lib` argument is exactly the unresolved §3/§4 mapping — the siphon SIDESTEPS it by
     taking `lib` explicitly (the befriended share the user is browsing).  Nothing ambient wired.**

**2. How a heist pulls and lands (Ghost/M/Heist.g):** `Heist_beat` (~:448) walks the quarantine
 mirror each pass; an arrived record LANDS via `Heist_land` → `Heist_land_stream` → the shared
  tail **`Heist_catalog_land(nav, mardir, job, own_lib, mir, rec, rel, size)`** (~:950): the
   newlyadded ledger note (`nav.read_file`/`write_file`), then the POOL BRANCH behind
    `Heist_is_pool(mardir)` — `Ra_rec_pool` with the lofi enid (`body_hash.slice(0,16)`) or the
     coinciding id — else `Ra_rec_home` + `path`; guarded stamps (title/artist/bytes/ext/
      body_hash/album), `job.sc.landed++`, a `took` display row, `mir.rm` the spent mirror card.
       ONE door for every landing, however the bytes travelled — which is why the siphon
        composes `Ra_press` and never mints its own catalog row.

**3. Book anatomy (Ghost/Story/Heistation.g `MusuPress` @~4741 — the family the Siphonation
 Book copies):**
- No `Run_A_` recipe: the world MUST be named `<Book>` — `do_fn_for` dispatches by `w.sc.w`
   (Housing.svelte.ts:1533) or the wrangle silently never fires.
- Shape: `Book(A,w):` installs `w oai %req:wrangle,eternal` whose body awaits a `_drive`;
   the drive fires ONE scene per beat off `req.c.did_step` vs `(this.c.run)?.c.step_n`, runs
    the witness EVERY pass, then `await this.Musu_float(w)` (snap order).
- The test's voice hangs under one `w/%testing` subtree (notes via `t.i(sc)`); `%see` claims
   are `story_swear(w, 'sentence')` — once-per-run latch, gated on TRUTH not beat number, no
    commas (the peel splits on them).  Evidence lands on `ave/%Assertioning` (snap-invisible).
- **Step COUNT comes ONLY from the recorded toc** (the hollow-Book lesson): Story.svelte:1873
   `mode = step_count > 0 ? 'check' : 'new'`, and do_step ends check at the first step with no
    `dige` in The (Story.svelte:2320).  A 1-step toc runs NO beats.  Fixtures live in
     `wormhole/Story/<Book>/toc.snap` (+ `NNN.snap`), recorded by an EDITOR authoring pass /
      live-runner Accept — the CLI cannot bootstrap a Plan.

**4. Headless reality (learned by running, not reading):** a `Story_cli` boot mounts NO Otro, so
 the Creduler's `watched:UIs` enrolment never renders and **CREDULER_GHOSTS never deposit** — a
  Book run headless with only its own ghost dies with `this.Ra_rec_find is not a function` in
   the Errlog (seen on this Book's first run).  The `INCLUDE=` shim is the door: mount the gen
    components directly (`scripts/Siphon_include.svelte` mounts Ra.go / Heist.go / Jam.go /
     Musuation.go + the two new gens; each only calls `H.eatfunc`, so the spec's M shim serves
      as H).  Fixture "mismatches" against the placeholder toc are baseline noise — the headless
       verdict is boot-green + the %testing notes + the sworn shelf
        (`scripts/Siphonation_asserts.spec.ts`).

## built (rungs 2–4, 2026-08-28 — the spun-out session; NEW FILES ONLY)

- **`Ghost/M/Siphon.g`** (→ `src/lib/gen/M/Siphon.go` via LocalGen) — the tag model + the verb:
   `Siphon_tags/tag_def/tag_apply/tag_unapply/playlist` (a %Tag once on the %Tags shelf;
    `%Tagged,of:` children; the playlist IS the child walk in application order) and
     `Siphon_home` + `Siphon_pull(w, shelf, pool, lib, origId, nav)`.
- **`Ghost/Story/Siphonation.g`** (→ `gen/Story/Siphonation.go`) — the Book: setup (2), tags (3
   — def twice / apply twice to one track), unapply ×2 (4), siphon o1 (5), re-siphon (6); six
    `%see` claims, `%testing` notes pinning every truth.
- **`wormhole/Story/Siphonation/toc.snap`** — a placeholder 6-step skeleton, every step carrying
   dige `0000000000000000`.  It exists ONLY so a runner walks beats 2–6 (mode=check needs step
    rows); the zeros are deliberately unmistakable as unrecorded.  **Replace via a live
     recording pass before this Book can gate anything**: `?B=Siphonation`, Resume ×5 (steps
      2→6), Accept-All, check → `n:1..6`.
- **`scripts/Siphon_include.svelte`** — the headless INCLUDE shim (see recon §4).
- **`scripts/Siphonation_asserts.spec.ts`** — the assertions-fired gate: runs the Book headless
   and expects all six sworn sentences on the Assertioning shelf.

**Deviations a reviewer should look at:**
- `Siphon_pull` grew a SIXTH arg `nav` (falls back to `w.c.ra_nav`, the Ra_shuffle_cull
   precedent) — `Ra_press` needs a nav and reading one implicitly would have hidden the IO seam
    the whole verb exists to make explicit.
- A landed siphon drops BOTH its `%Siphon` row and the served `%press,of:` job Ra_press left on
   `w` (an owner drops its finished transient reqs; for a DELIBERATE siphon this verb is the
    sweep seam Ra_press's comment nominates).  A FAILED `%Siphon` stays standing with
     `fail:<why>` — in-flight state worth seeing — and a retry sweeps it before the fresh mint.
- Re-siphon is a TRUE no-op (the standing card answers before any IO) — a raw re-`Ra_press`
   would re-read + re-write the same bytes; the Book's write-ledger claim discriminates this.

**Verification (headless only — the live tabs were the human's all evening):**
- LocalGen (`GFILES="Ghost/M/Siphon.g Ghost/Story/Siphonation.g"`): both compile clean, wrote
   `gen/M/Siphon.go` (8138c) + `gen/Story/Siphonation.go` (10585c).
- esbuild parse of both gen script blocks: clean.
- `BOOK=Siphonation INCLUDE=Siphon_include` Story_cli run: **6/6 steps walked, Errlog clean**;
   final snap shows the lib, the pooled card (`Record,id:o1,path:a/one.wav,…,body_hash:…` in the
    paged Mag, no `of:`/`grade` — the v1 elision), `Tag,name:lofi › Tagged,of:o1`, and an EMPTY
     `%Siphons` shelf.  `match: 0/6` vs the placeholder toc = expected noise, not a verdict.
- `Siphonation_asserts.spec.ts`: **all six sworn sentences latch.**
- NOT proven headlessly: real fixture diges (needs the live recording pass), the OPFS `pool/…`
   mount routing (the Book's nav is a stub — proven by the mount's own machinery, not here),
    and everything in rung 5.

## proposed patches (NOT applied — apply by hand after review)

**P1 — register the ghosts with the Creduler** (`src/lib/O/LiesLies.svelte`, the
 `CREDULER_GHOSTS` list).  Insert after the `'Ghost/M/Radio.g',` line:

```ts
        'Ghost/M/Siphon.g',             // the deliberate SoundPool act — tags-as-playlists + Siphon_pull (Siphon_todo.md; composes Ra_press, never the ambient §3/§4 economy)
```

and after the `'Ghost/Story/Errchannelation.g',` line:

```ts
        'Ghost/Story/Siphonation.g',    // the Siphon* tests — Siphonation: a tag is a playlist + the idempotent whole-thing siphon
```

(No GhostList edit is needed: `wormhole/GhostList/toc.snap` is the dirlist Funkcion's own walk —
 it notices new `Ghost/**/*.g` files itself.  `scripts/Siphon_include.svelte` stays useful for
  headless runs even after P1 lands, since a Story_cli boot never runs the Creduler.)

**P2 — the connect-up seam: the RadioFace "from $who" chip becomes the source selector**
 (`src/lib/O/ui/RadioFace.svelte`, the provenance badge at ~lines 152–160).  This depends on
  rung 5's `Radio_source_next(n)` verb (cycle `local → pool → <friend>` by stamping `sc.source`
   on the %Radio particle for the dial to obey) — do NOT apply before that verb exists.  The
    exact edit, replacing the current `{#if face.by}…{/if}` provenance block:

```svelte
    <!-- THE SOURCE CHIP (Siphon_todo: "this is just to be hidden in the 'from $who' button,
         which should go local|SoundPool when…" — the chip NAMES the live source and flips
         between them when more than one stands).  Pressing it cycles local → SoundPool →
         <friend> via Radio_source_next (rung 5), which stamps sc.source on the %Radio
         particle; the dial obeys it.  Reads exactly as before until the verb exists. -->
    {#if face.by}
        <button class="rf-src rf-src-remote" onclick={() => (H as any)?.Radio_source_next?.(n)}
            title="the source — press to flip local | SoundPool | friends">from {face.byName || 'a friend'}</button>
    {:else if face.source === 'pool'}
        <button class="rf-src rf-src-local" onclick={() => (H as any)?.Radio_source_next?.(n)}
            title="the source — press to flip local | SoundPool | friends">♪ SOUNDPOOL — your pocket copies</button>
    {:else if face.solo && face.title && face.state !== 'off' && face.state !== 'digging'}
        <div class="rf-src rf-src-local">♪ LOCAL · {soloWhy(face)}</div>
    {:else if face.title && face.state !== 'off' && face.state !== 'digging'}
        <div class="rf-src rf-src-local">♪ LOCAL — your own record</div>
    {/if}
```

plus one line in the `face` derived (beside `own:`):

```ts
            source: (sc.source as string) ?? '',   // rung 5: '' | 'pool' | a friend's pub — what the dial obeys
```

(The two ♪ LOCAL branches stay `div`s here on purpose — flipping them to buttons belongs with
 the verb, and the peerless invite line beneath them must not move.)

**P3 — the recording pass** (not a patch, the ritual): once P1 is applied and a live runner
 stands, record the Book from the editor — `?B=Siphonation`, Resume ×5 (steps 2→6), Accept-All,
  then check → expect `n:1..6`, caveat:0 (the Book is stub-nav deterministic, no wall clock, no
   entropy).  Commit only `wormhole/Story/Siphonation/` NNN.snap + toc.snap step/dige rows;
    revert any Credulate/Credulation churn as usual.
