# Seen_split_todo.md — split `%see` into `%seen` (latched assertion) and `%log` (one-snap note)

The one living doc for the decided-but-unbuilt three-way split of today's overloaded `%see`.
 Design is settled (owner, `see-vs-seen-vs-log`); the build is deferred and touches Story core,
  so it is runner-in-the-loop work — headless verification is banned here (`verify-via-live-runner`).

This file is destination + the bombs + the next move. Correct anything that has drifted; the
 code cites below were read live 2026-07-12.

---

## 0. What to get on with next

**Design-decided, build-deferred.** The primitive to build is small in code but lands on the
 test machine's spine (the fixture-dige gate + Accept). Do NOT batch it with unrelated work, and
  prove every step on a LIVE `:9091` runner via `runner_ask.mjs` — a green in `Story_cli` is a
   bubble (`verify-via-live-runner`, CLAUDE.md).

Three concrete moves, sized honestly:

1. **Add the `%seen` writer + the assertion roster on ONE Book, isolation-first.** Pick a Book that
    already carries a durable-by-luck claim — `SwarmSteal` is ideal: its 5 authored sentences
     (`Ghost/Story/Swarmation.g:159-184`) are all `n`-gated observations that today drop, and one
      (`identity is not address…`) is exactly the kind of "this happened by beat K" fact that WANTS
       a latch. Stand `%seen` beside the existing `%see` (do not remove `%see` yet), latch it, and
        add a `The/Assertions` roster entry naming it + the beat by which it must hold. Prove the
         latch survives to the last snap on a live runner. This is one Book, one new mechanism,
          fully reversible. **~½ day if the runner cooperates.**

2. **Wire the verdict complaint.** Make `Cred_run_outcome` (`Auto.svelte:680`) — or a sibling check
    it calls — read `The/Assertions` and, for each declared assertion, confirm the matching `%seen`
     latched in the run. A missing one is a NAMED red ("«identity is not address» expected by n≥5 —
      ABSENT"), surfaced in Storui and dragging `ok` false. This is the "labels complain when they
       go missing" the owner wants, and it is the part that CANNOT be masked by entropy tolerance
        (see §4 — the roster check is a presence check on a labeled fact, orthogonal to the
         dige-fuzz forgiveness that today swallows a vanished proof).

3. **Migrate the fleet + retire `%witnessed`.** Convert the load-bearing `%see:'sentence'`
    assertions across the ~25 Books (§5 inventory) to `%seen` + a roster line, re-record each LIVE,
     and diff the assertion SET against the prior fixture before Accept (`accept-drops-proof-in-entropy-zone`).
      The legacy `%witnessed:step_N` latches (`Lake_witness`/`Lake_proof_witness`, `Peregrination.g`)
       become roster entries too — they were always latched facts, just opaque ones; the roster
        gives them a sentence.

**The arc / destination:** one emission kind (`%see`) is doing two jobs with opposite lifetimes,
 and the wrong one silently wins under traffic changes and entropy fuzz. Split them so each has the
  right lifetime and the right gate: `%seen` = a latched labeled fact the run must prove (roster
   complains on regress, entropy can't mask it); `%log` = an honest one-snap note that is never a
    gate. Leave `%see` alive as the ephemeral per-beat observation it was corrected to be
     (`see-is-not-a-latch`) — the split does not kill it, it stops OVERLOADING it.

**BOMB — `%log` already exists (the memo is stale on this).** `see-vs-seen-vs-log.md` says "%log
 doesn't exist yet; tiny to add." It DOES exist and is built: `w_noproblemo(particle, {log:1})`
  (`Hovercraft.svelte:1052`) drops `%log` children at the step boundary, driven from the
   `Runstepped` chain (`:1025`) on each `A/w` AND under every `%req` beneath it
    (`Runstepped_reqy_pageturning`, `:340`), so a `%log` "appears in exactly one snap then is gone"
     — Peeroleum uses it (`Peeroleum_spec.md §12.3`, marked BUILT). So step of the split's `%log`
      half is ALREADY DONE. The remaining `%log` work is only doctrinal: bless it as the sanctioned
       home for "just show me this value at beat K", and make sure it is NEVER read as an assertion.
        The real build is the `%seen` latch + roster.

**BOMB — this is a DIFFERENT axis from `Story_future_directions.md §1.** That doc's "%see-everywhere
 sweep" fixes the HARVEST DEPTH (a `%see` buried in a `req**` subtree isn't collected). This doc
  fixes the LIFETIME/GATE conflation (a `%see` used as a durable assertion is fragile). They are
   orthogonal and composable: the sweep decides WHERE observations are collected; this split decides
    WHICH KIND of thing an emission is and how its absence is caught. Build them independently; do
     not let one block the other.

---

## 1. How `%see` works today, precisely (read before designing)

There are TWO unrelated uses of the key `see` in the machine — do not conflate them:

- **The runner's own status `%see`** — `w.i({ see: 'snap_step...' })`, `w.i({ see: '⏳ verify…' })`
   etc., stamped all over `Story.svelte` (`:1526,1539,1603,1645,1707,1750`, and the `post_do` tags
    `{ see: 'story_snap' }` at `:2114`). This is a live status line the runner shows itself; it is
     wiped by `w_forgets_problems` (below) each beat. Not a test assertion. Leave it entirely alone.

- **The authored assertion `%see:'sentence'`** — a Book emits `i %see:'a readable claim'` from its
   per-beat `.g` handler (compiles to `w.i({ see: 'a readable claim' })`). It is the once-noticed,
    self-describing successor to `%witnessed:step_N` (`see-assertion-layer`). This is the overloaded
     one the split addresses.

**Where it is emitted.** Inside a Book's per-step handler, guarded idempotent against re-firing
 within a pass: `if (<n-gate> && <live truth> && !(oa %see:'sentence')) i %see:'sentence'` — see
  `Ghost/Story/Swarmation.g:159`, `Radiation.g:150`, `Peregrination.g:1047`. The `!(oa %see:…)`
   guard only prevents a double-emit inside ONE pass; it does NOT make the claim persist across
    beats.

**Where it is dropped.** `Hovercraft.svelte:63` `w_forgets_problems(w)` runs `await w.r({see:1},{})`
 — clearing every `%see` on `w` — and Housing calls it before every handler dispatch
  (`Housing.svelte.ts:1288`; `see-is-not-a-latch` traces this as `_Aw_think` → `w_forgets_problems`).
   So a `%see` lives for exactly the beat it is (re)minted. A `=== K` gate lands it in EXACTLY ONE
    snap; a `>= K` gate persists it only because the guard re-mints it every subsequent beat.

**Where it hits the fixture.** A `%see` on `w` is an ordinary particle, so `snap_H`
 (`Story.svelte:1106`) encodes it into the step's `got_snap` string via `story_process_node`
  (`:1063`) → `enLine`. It appears as a plain `see:<sentence>` line (sample fixtures:
   `wormhole/Story/SwarmSteal/*.snap` `see:identity is not address — the key never moved…`). There
    is one special `story_matching` rule (`Story.svelte:1051`) for a `%see` carrying a raw `string`
     payload (encode dumps) — cosmetic blockquote formatting, not relevant to the sentence claims.

**Where it becomes (or fails to become) a verdict.** The gate is a DIGE COMPARISON, not a
 line-presence check. `snap_H` produces `got_snap`; its dige is compared against the recorded
  fixture's dige (`Story.svelte:1631-1690` `check_snap` block: `disk_dige === exp_dige`). A `%see`
   line is just bytes inside that hashed string. So:

- **A dropped `%see` changes the got_snap bytes → dige mismatch.** Normally that mismatch would be a
   hard red. BUT `entropy_forgive` (`Hovercraft.svelte:794`, via `spay_graft`) can absorb it: if the
    only differences fall inside acknowledged noise spans, the step passes `ok=true, caveat=true`
     (`Story.svelte:1657-1672`), which READS GREEN. And `Cred_run_outcome` (`Auto.svelte:689-691`)
      counts a caveat step as ok (`steps.filter(s => s.sc.ok)` includes `ok && caveat`). **This is
       the `accept-drops-proof-in-entropy-zone` bug: a vanished proof drops as a caveat, invisible on
        Accept.** MusuReplica's `folded >= 24` proof died exactly this way — trimmed traffic pushed
         the count under the magic constant, the `%see` stopped firing, and Accept baked in its
          absence because the beat sat inside the EntropySamples fuzz zone.

So today the ONLY durable trace of an authored `%see` is a `see:` line inside a hashed fixture
 string — and its disappearance is caught only if it happens to fall OUTSIDE every entropy span. A
  labeled, presence-checked assertion is what closes that hole.

---

## 2. `%seen` — the latched, labeled assertion

**The lifetime is the whole point: `%seen` LATCHES.** Written ONCE the first beat its gated truth
 holds, NEVER cleared by `w_forgets_problems`. Because it is a fact-that-happened ("X was true by
  beat K"), latching is CORRECT — this is the distinction `see-is-not-a-latch` draws: the old
   `%witnessed` fear was about latching OBSERVATIONS (recurring truths that flicker), not
    assertions (facts that, once true, stay true forever by definition).

**Where the latch lives.** Two homes, and the choice matters:

- **The live latch rides `w` (not wiped).** `w_forgets_problems` (`Hovercraft.svelte:63`) must NOT
   clear `%seen`. Simplest: it clears `{see:1}`, `{waits:1}`, `{error:1}` by exact key — `%seen` is a
    different key, so it survives untouched already. Confirm no sibling sweep catches it. A `%seen`
     minted on `w` then lands in every subsequent `got_snap` (it is a live child), so it is robust: a
      regression = a stable, predictable ABSENCE from its beat onward, not a one-snap flicker.

- **The declared roster lives on `The`, off the live world.** `The/Assertions` (canonical storage,
   like `The/Steps`) carries one entry per declared assertion: `Assertion:<slug>, sentence:'…',
    by_n:<K>`. This is authored (hand-written in the toc.snap or seeded by the Book), NOT harvested —
     it is the CONTRACT the run must satisfy, separate from the `%seen` EVIDENCE the run produces.
      The verdict check joins the two: for each `The/Assertions` entry, was the matching `%seen`
       latched by beat `by_n`? (`This`/`The` split mirrors the existing `step_c` pattern,
        `Story.svelte` header.)

**"Complains on regress" — concretely.** In `Cred_run_outcome` (or a check it calls before
 returning): walk `The/Assertions`; for each, look for a `%seen` whose sentence matches, latched at
  or before `by_n`. Missing → push a named complaint particle (e.g. `w.i({ assertion_absent:<slug>,
   by_n:K })`) that Storui renders as a red line, and force `ok:false` for the run. This is a
    PRESENCE check on a labeled fact — it does not go through the dige comparison at all, so entropy
     forgiveness (§4) cannot swallow it. That is the load-bearing property.

**Emission shape (author-facing).** `if (<n-gate> && <live truth> && !(oa %seen:'sentence')) i
 %seen:'sentence'` — same idiom as `%see` today, just the durable key. The guard still prevents a
  double-mint; the difference is it is never wiped, so once latched it stays. The sentence is still
   the identity.

---

## 3. `%log` — the one-snap ephemeral note (already built)

`%log` is the honest home for "just show me this value at beat K" — NOT checked, NOT an assertion.
 It already works: `w_noproblemo(w, {log:1})` (`Hovercraft.svelte:1052`) drops `%log` at the step
  boundary AFTER the snap commits, on each `A/w` and under every `%req` (`:1045-1046`,
   `Runstepped_reqy_pageturning:340`), so a `%log` shows in exactly one snap then vanishes
    (`Peeroleum_spec.md §12.3`, BUILT). Under a `%req` it uses `.c.gc_fn` (forward design) but the w
     case is live.

The split's `%log` work is doctrinal only: it is the third bucket so an author has a clear place for
 an ephemeral value-dump that is NOT a claim. The rule to enforce: NOTHING reads `%log` as a verdict
  input; the roster (§2) never consults it. If you want a value CHECKED, use `%seen` + a roster line.

---

## 4. The no-mask invariant (why the split beats the entropy bug)

Today: proof lives as a `see:` line inside a hashed fixture; a dropped proof is a dige mismatch;
 `entropy_forgive` (`Hovercraft.svelte:794`) can forgive that mismatch as value-noise → the step
  reads green with a caveat → the proof is silently gone. `accept-drops-proof-in-entropy-zone` is
   this exact failure, and its stated fix — "state fold/compression claims as a RATIO not a magic
    constant, and diff the see: SET before Accept" — is a workaround, not a fix.

The split fixes it structurally: **a `%seen` regression is caught by the ROSTER check, not the dige
 comparison.** The roster asks "did assertion «X» latch by beat K?" — a boolean presence test on a
  labeled fact. It never touches `got_snap`'s dige, so no entropy span can absorb it. A vanished
   `%seen` = a NAMED red, whether or not the byte-difference falls in a fuzz zone.

**Explicit invariant to enforce in the build:** the roster verdict must run OUTSIDE and AFTER the
 entropy-forgive path, and must not itself be forgivable. A step can be `caveat:true` (value-noise
  forgiven) AND still red because a declared assertion is absent. Never let `caveat` short-circuit
   the roster. Add a global test (the owner has asked for the twin, a global no-live-`ttlilt`
    assertion, `ttlilt-in-snap-means-timeout`): a green run with any `The/Assertions` entry
     unsatisfied is a contradiction the machine should refuse to call green.

---

## 5. Migration — the Books using authored `%see:'sentence'`

Inventory (live, 2026-07-12 — the assertion emitters, distinct from the runner's status `%see`).
 Authored in these `.g` sources:

| Source | count | notes |
|---|---|---|
| `Ghost/Story/Swarmation.g` | 42 | SwarmSteal/Wire/Door/Got/Policy/Invite/Staple — identity + crypto facts, prime `%seen` candidates |
| `Ghost/Story/Radiation.g` | 39 | MusuRa* family (Cast/Chase/Stock/Stream/Term) — streaming facts |
| `Ghost/Story/Voronation.g` | 17 | VoroScape/Mitosis/Clinic/Radio |
| `Ghost/Story/Musuation.g` | 5 | MusuReplica/MusuReco/MusuHeist — INCLUDES the `folded>=24` proof that died in the entropy zone |
| `Ghost/Story/Peregrination.g` | 3 | PereProof steps 31-33 (the combinatory braid) |
| `Ghost/N/Tyrant.g` | 1 | the `yyyyar!` idiom |

Fixtures carrying prose `see:` lines (the recorded evidence, by Book, top of the list):
 MusuRaChase 55, MusuRaStream 39, MusuHeist 29, Understandication 14, Understandium 13, LakeNets 12,
  LakeSurprise 10, MusuRaCast 9, LakeTiles 9, SwarmStaple 7, LakeFlush 7, PeeringLive 6, SwarmSteal 5,
   SwarmGot 5, MusuRaTerm 5, plus one-line tails on ~25 more Books (VoroScape, SwarmWire/Policy/Invite/Door,
    MusuRaStock, PereTyrant, PereProof, LakeSurfer, Snaptesting, PortPlanet, MusuReplica, MusuReco, etc.).

**Not every authored `%see` becomes a `%seen`.** Some are genuinely per-beat observations that SHOULD
 drop (e.g. LakeTiles `see:🗂 1 doc · 2 Wafts` is a live census readout, not a happened-fact) — those
  stay `%see` or become `%log`. Only the ones asserting "X happened / holds by beat K" migrate to
   `%seen` + a roster line. Judge per sentence; the tense is the tell ("the pair sealed", "identity is
    not address", "the Idzeug is single-use" = facts → `%seen`; "1 doc · 2 Wafts" = a value → `%log`).

**`%witnessed:step_N` legacy → roster entries.** `Lake_witness`/`Lake_proof_witness`
 (`Peregrination.g`) latch opaque `step_N` markers. They were always facts-that-happened, just without
  sentences. Convert each to a `%seen:'sentence'` + a `The/Assertions` line; the sentence is the
   documentation the `step_N` never carried. Keep the already-recorded ones as gates until re-recorded
    (they still ride the snap-fixture diff).

**Migration mechanic — NEVER `CredRunner ACCEPT` to install a new assertion** (`see-assertion-layer`
 gotcha, `see-assertion-layer` memory): Accept re-records ALL steps and can corrupt the canonical
  dige gate, and (the `accept-drops-proof-in-entropy-zone` twin) can bake in a DROPPED assertion. Per
   Book: add the `The/Assertions` roster line + the `%seen` emitter → run a plain CHECK run on a live
    runner → confirm the roster verdict goes green → manually install the fixture from the CHECK run's
     `got_snap`. Diff the assertion SET against the prior fixture before committing.

---

## 6. Constraints carried forward

- **No commas in a `%seen` / `%log` sentence** (same as `%see`): the peel parser splits key:value on
   commas (`credence-board-desc-brandnew` states the same rule for `desc:`). Use em-dashes — the
    `Tyrant.g` / Radiation idiom. A comma in a sentence munges into a spurious extra sc key.
- **Snapped boolean discipline:** a latched `%seen` rides as a particle with the sentence as its
   value; do not stamp a `%seen:true`/`0` companion flag — presence IS the latch (CLAUDE.md snap-bool
    rule). Prefer a C method over a raw `delete` on the rare un-latch path.
- **`%seen` is snapped (it is on `w`, reachable in `H**`), so it re-records fixtures** — every Book it
   touches is a live re-record (the human's, on a `:9091` runner). `The/Assertions` is also snapped
    (under `The`, encoded by `encode_toc_snap`'s Travel), so the roster rides the toc.snap like the
     step lines.
- **Verify LIVE only.** The whole split lands on the fixture gate + Accept; `Story_cli` greens are
   bubbles (CLAUDE.md, `verify-via-live-runner`). Every proof is a Book run through `runner_ask.mjs`
    against a live runner.

---

## Cross-references

- **Decision memos:** `see-vs-seen-vs-log` (the three-way split), `see-is-not-a-latch` (why `%see`
   drops — the invariant the split preserves), `see-assertion-layer` (the once-noticed doctrine +
    the never-Accept-a-new-assertion gotcha), `accept-drops-proof-in-entropy-zone` (the bug this
     closes).
- **Live code:** `Story.svelte` (`snap_H:1106`, `check_snap` gate `:1631`, status `%see` sites);
   `Hovercraft.svelte` (`w_forgets_problems:63`, `w_noproblemo:1052`, `entropy_forgive:794`,
    `Runstepped:1025`); `Auto.svelte` (`Cred_run_outcome:680` — where the roster check hangs);
     `LiesFunk.svelte:2191` (the `accept` op).
- **Sibling axis (do not conflate):** `Story_future_directions.md §1` (the `%see`-everywhere HARVEST
   sweep — orthogonal to this lifetime split).
- **Entropy machinery:** `EntropyArrest.md` (§2.3' compare-time forgiveness, `spay_graft`), the
   invariant §4 must sit outside.
