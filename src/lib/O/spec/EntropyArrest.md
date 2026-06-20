# EntropyArrest — taming acknowledged snap-diff noise

> **في غيابها كوّنتُ صورتها** — *in her absence, I formed her image* (Darwish).
> The motto of a spay: the noisy value is absent, and what we compare against in its
>  place is the image we formed — the expected snapshot's own value, read live.

The Story snap diff is the test signal (`On_the_artchitecture.md`: "this codebase's
 safety rests almost entirely on snap-diff vigilance"). Non-determinism drowns it —
  counters, timestamps, timings, signatures churn every run and bury the one line that
   actually regressed. **EntropyArrest** lets you acknowledge a noise source by clicking
    the noisy diff line: it stores a `Snapcap` (a locator + a tolerance rule), and at
     compare time the noise is forgiven without rewriting the fixture. The snap on disk
      stays honest; the churn is reconciled when got and expected are compared.

It is the acknowledged-non-determinism half of controlling entropy in a test; `prandle`
 (Housing) is the other half — injected determinism, a seeded PRNG. They sit side by side
  in Hovercraft's `//#region entropy`.

---

## 0. The problem, exactly

From a `Step:2` diff:

```
self,round=15            {"mung":["age"]}     ← counter, value-key
want=1781935793885,kind:cold                  ← timestamp, MAINKEY value (identity!)
time,compile=0.008,all=0.259                  ← timings, value-keys
```

The old tool was `story_matching` munging — but mung is **drop-the-key**: it removes the
 key from the diffed stringies entirely. That works for `age` (pure-noise sidecar) but
  fails the three above:

- `want=<ts>` — the timestamp *is the mainkey value*. Drop it and the particle loses its
   identity; the line can't be matched to its prior self at all.
- `time,compile=…` — drop them and you lose the timing signal you may want to watch.
- `round=15` — drop it and you can't assert it; keep it and it churns ±1 every tick.

What was missing is a **third option between keep and drop**: tolerate the noisy *value*
 in place while keeping the line's shape and identity. That is **spay** — and it must be
  authored *from the diff*, not hand-coded, because you are already staring at the line.

---

## 1. The model — captures + surgical graft

A `%spayer`'s regex (`re`) matches **context** — meaningless edges, anchors — and carries
 **capture groups** that are the actual noise. One `re` can hold several captures.

```
want=1781952245057,kind:cold
   →  (?:want=)(\d+(?:\.\d+)?),kind          one capture; ",kind" is a trailing anchor

time,compile=0.161,all=1.836,write=0.001
   →  time,compile=(\d+(?:\.\d+)?),all=(\d+(?:\.\d+)?),write=(\d+(?:\.\d+)?)
                  └ cap 1 ┘          └ cap 2 ┘          └ cap 3 ┘
```

Forgiveness is **two-sided and reconstructive** (`spay_graft`). For each aligned got/exp
 line pair:

1. run each spayer's `re` on both lines (its Nth got match pairs with its Nth exp match);
2. for each capture pair, if the got value is within the spayer's **tolerance** of the exp
    value, **graft the exp capture into the got line** (replace got's span with exp's);
3. after all grafts, require the rebuilt got line to be **`===`** the exp line.

A step relaxes to **OK-with-caveat** only if *every* differing line fully reconstructs into
 exp using only sanctioned graft-spans. Anything left over is a **real surprise** and the
  step stays a mismatch — you cannot accidentally bury a structural change, because the
   leftover won't reconcile. Line alignment is **positional**: a differing line count is
    structural drift (reordering, added/removed rows), which spay does **not** forgive (that
     is the deterministic-child-sort problem, separate). This is the §2.4 ordering caveat
      landing correctly.

The graft model needs **no marker, no stored baseline, no step multiplier**: the baseline
 *is* the expected snapshot's own capture, read live, so a value that legitimately advances
  per step is already carried by the fixture.

---

## 2. The `%spayer` schema

```
spayer,re:<regex-with-captures>,tol:band,factor:1.5    within factor× of exp's value (both ways)
spayer,re:<regex-with-captures>,tol:any                graft wholesale, any value
```

- **`tol:band`** + `factor` — numeric captures; graft iff `max(got,exp) ≤ factor·min(got,exp)`
   (and the both-≈0 case). A capture that blows the band does not graft → the line fails to
    reconstruct → real surprise survives. No blow-out flag needed; the failure is the signal.
- **`tol:any`** — graft every capture unconditionally. The **hash / signature / timestamp**
   case, and the seam to prepub-subjectivity testing: swappable Alice+Bob sets on one PeerJS
    make pubkeys/signatures/timestamps vary; `tol:any` relaxes a whole span — yet the
     reconstruct-must-equal-exp rule still proves nothing else moved.
- A spayer with **no** capture groups treats the whole match as capture 0 (so a bare
   whole-match regex still works under `tol:any`).

`spay_within` parses a band capture with `parseFloat` → `NaN` for a non-numeric token, which
 never grafts. So a hash/signature **must** be `tol:any`; only numerics may be `band`.

**Codec reality:** capture regexes contain `:` (every `(?:…)`) and usually `,`, so a
 `%spayer`/`%means` line serialises as **JSON** in `toc.snap` (`encode_stringies` fallback).
  This round-trips fine; regex legibility lives in the editor field, not the snap.

---

## 3. The store — `The/EntropyArrest`

A per-test bucket, beside `The/Styles` and `The/TimeSpool`. It lives in `The`, so it
 round-trips through `toc.snap` and travels with the Book. Absent until the first cap is
  authored.

```
The/EntropyArrest                       per-test; lazily minted on first author
  Snapcap:<slug>                        one acknowledged-noise entry
    lematch,<sc…>                       outer locator segment — the node's OWN sc IS sc_has
      lematch,<sc…>                     nested descent (→ thence_matching at compile)
        means,spayer,re:…,tol:band,factor:1.5     the handler, INSIDE the leaf lematch
    scope,step:N                        optional; omitted ⇒ ALL steps
    note:…                              optional human reason
```

Two storage decisions make this snap-safe and extensible:

- **`%lematch` carries its matcher as its OWN scalar sc** (the mainkey `lematch` stripped off
   *is* the `sc_has`) — not the object-valued `sc_has` that `i_scheme_req` writes on a live
    `w` (an object in `.sc` is fatal at toc encode). Nested `%lematch` children are descent
     (`thence_matching`).
- **`%means` is a prefix mainkey** like `%lematch`: the rest of its sc follows in the *same*
   particle (`means,spayer,re:…,tol:band`), and a kind-flag (`spayer`; later `omit_sc`,
    `munging`) names which handler it is. The handler rides **inside the leaf `%lematch`**, and
     a leaf may hold **several `%means`** — so the store is a tree of matches with any handler
      at any node.

`The/EntropyArrest` is itself never spayed and never the test subject — it is metadata about
 the test, like `Styles`.

---

## 4. The compile — `entropy_rules`

`entropy_rules(The)` reads `The/EntropyArrest/Snapcap**` and emits one **matching rule** per
 cap — the same `{ matching_any, means }` shape `story_matching` uses, so they concatenate
  straight on. `snap_H(Run, w)` compiles `story_matching ∪ entropy_rules(w.c.The)`; the cost
   is zero extra walks — spay is a richer `means` on the `n.lematch` call `enLine` already
    makes per node.

`lematch_to_rule(lm)` is a pure **structural walk that names no handler**:

- the node's own sc (minus `lematch`) → `matching_any:[{ sc_has }]`;
- every `%means` child → merged into the rule's `means` via `means_of` (which maps
   `%means,spayer,…` → `means.spay` through `spayer_of_sc`; new means-kinds slot in there);
- nested `%lematch` → `thence_matching` (recurse);
- a branch with no `%means` anywhere beneath it compiles to `null` — **pruned**.

`entropy_mint` writes the inverse: it nests the locator segments via `oai` (find-or-create, so
 a shared prefix reuses a `%lematch` node) and drops `host.i({ means:1, spayer:1, …})` on the
  leaf. Re-minting a slug **overwrites** (drops the prior cap first), never piles.

### The global layer is code, not data

The defaults are the in-code `story_matching` rules. A `means.spay` rides them exactly as it
 rides a Snapcap — the same compile turns either into a matching rule. The default `self,round`
  rule carries `spay:{ re:'(?:round=)(\d+)', tol:'any' }` (a per-tick counter — graft
   unconditionally). So every Book gets global spaying for free; it only grows a
    `The/EntropyArrest` once you author something test-specific. The UI reads the merged set
     (defaults ∪ this Book's caps) and need not care which half a spay came from.

---

## 5. The verdict — compare-time forgiveness + caveat

Forgiveness happens at **compare**, never at encode — the snap on disk keeps the true number a
 human reads.

- **Runner** (`scripts/Story_cli.spec.ts`) is **lenient** (`w.c.lenient`): it never halts and
   forgives at its own text compare.
- **Live app** is **non-lenient**: a dige mismatch HALTS the drive and queues
   `fetch_snap`/`check_snap`, which loads the expected fixture text. Forgiveness lands in that
    `check_snap` block (Story.svelte): `H.entropy_forgive(w, got, disk, n)` runs
     `collect_spayers(story_matching ∪ entropy_rules(The))` + `spay_graft` over both sides. On
      agreement the step is demoted to **OK with a caveat** (`step.sc.caveat = 1`,
       `step.sc.ok = true`), the halt is cleared (`failed_at`/`paused`/`frontier`/`open_at`), and
        the drive resumes — the eventually-ok signal goes through, no re-record. The verdict
         `delete`s `step.sc.caveat` on each fresh snap so it re-derives.

Both paths share the same `collect_spayers` → `spay_graft` core, so the in-app and headless
 verdicts agree line-for-line (both apply the `mo:main` stale-fixture hide + `trimEnd`).

A step that passes only because it was forgiven is "virtually OK, with a caveat"
 (`match && !exact`) — distinct from an exact match, surfaced as a `≈` badge in Storui.

`drop` is the one handler that would bite at **encode** (`enLine` → `mung`): removing a key
 entirely is a structural omission, value-free and deterministic, an encoder concern not a
  value to forgive. It is deferred (see TODO).

---

## 6. The authoring UI — `ui/EntropyArrest.svelte`

Shows when the test has caps **or** a draft is in flight, mounted under the Storui diff body
 scoped to the open step. Authoring is a click on a noisy diff cell, not a standing panel.

**One in-flight draft, breadcrumb discipline.** A click on a `.sr-spayable` `Dif:change` cell
 sets `ea_seed` (`{ left, right, parent }` from Storui's `seed_spay`/`diff_parent_line`), which
  **re-points** the single draft (DevTools-Elements style — a new click never accumulates).
   Nothing reaches `toc.snap` until **OK**, so you can poke around the diff without drowning in
    caps.

**The locator (`at`)** is one text field of peelables split by ` / `, outer→leaf (e.g.
 `A:Lang / self,round`). Plain text ⇒ Ctrl-Z for free, no segment widget. Each chunk
  `peel()`s into one `%lematch` segment's sc (`self,round` → `{self:1,round:1}`; `w:Lang` →
   `{w:'Lang'}`). Seeded including the **parent** line.

**The slug (`cap`)** auto-derives from the form beneath (parent match + noisy key) and keeps
 re-deriving until the user edits the field.

**The spayer editor** is a `tol` band|any toggle (rendered as an overlapping mutex switch) +
 `factor` + a capture `re`. `H.entropy_suggest(right, left)` proposes them: changed keys become
  captures, stable text stays a literal anchor, and `tol` autodetects — any number → `band`
   factor **1.5** (even a unix timestamp: seconds of drift sit far inside 1.5×); a non-numeric
    hash/signature token → `any`. All fields stay editable.

**OK** hands the draft across the elvisto seam as a JSON string —
 `H.i_elvisto('Story/Story', 'entropy_commit', { cap_json })` — because elvisto args ride as
  scalar sc and a nested locator would be a fatal object-in-sc. `e_entropy_commit` parses,
   calls `entropy_mint`, then `story_save()`. Compiled rules are read at snap time, so a
    **restart re-reads the caps to apply them** — the panel says so. The CRUD list edits
     (`edit_cap` loads the draft) and deletes (`entropy_delete` → `entropy_unmint`) existing
      caps; `cap_spayer` reads the handler from the leaf `%means`.

We deliberately do **not** live-test the locator/regex in the panel — verification is the next
 run's diff, not an inline preview.

---

## 7. Code map

- **Text.svelte** — the compare. `spay_graft(got, exp, spayers, step_n)` (positional line zip,
   returns a graft log), `spay_graft_line` (per-capture graft), `spay_within` (band/any
    tolerance), `_spay_flags`. `collect_spayers(rules)` flattens every spayer carrying a `re`
     out of the merged rule set (recursing `thence_matching`). (`spay_line`/`spay_normalize`/
      `SPAY_MARKER` are the pre-graft marker model, off the compare path — see TODO.)
- **Hovercraft.svelte `//#region entropy`** — `entropy_rules` / `entropy_rule_of` /
   `lematch_to_rule` / `means_of` / `spayer_of_sc` (the compile); `entropy_forgive` (the in-app
    verdict); `entropy_suggest` (the generator); `The_EntropyArrest` / `entropy_mint` /
     `entropy_unmint` (the store). Sibling to `prandle` (Housing).
- **Story.svelte** — `snap_H` (`story_matching ∪ entropy_rules`); the default `story_matching`
   `self,round` rule; `e_entropy_commit` / `e_entropy_delete`; the `check_snap` forgive block.
- **Storui.svelte** — the `<EntropyArrest>` mount, `ea_seed` + `seed_spay` + `diff_parent_line`,
   the `.sr-spayable` clickable `changed` cells, and the `≈` caveat badge/pip.
- **ui/EntropyArrest.svelte** — the editor (draft, `at` field, slug, tol/factor/re, CRUD).
- **scripts/Story_cli.spec.ts** — the lenient runner; gates got-before vs got-after.

---

## 8. Non-goals (decided)

- **The §1 "Lines" encoder merge** (unify `snap_H`'s loopy pass with `encode_wh_lines` into one
   `enLines` walker) was deliberately **skipped**: its purpose was to give spay one bite-point,
    but the compare-time pivot already makes `spay_graft` a single text pass per snap. A
     cosmetic walk-unification with no behaviour payoff — left alone unless a concrete need
      appears.
- **Encode-time forgiveness** is rejected (it would make the on-disk fixture a mirage and still
   churn the raw dige). Forgiveness is compare-time; the snap stays honest.
- **Cross-cap shared `%lematch` forest** — caps stay per-`Snapcap` (flat), each with its own
   locator tree, because CRUD identity (slug/edit/delete) is per-cap. `oai` in `entropy_mint`
    already dedups within a cap and is ready for a shared forest if it is ever wanted (see TODO).

---

## 9. TODO

- **§4.3 diff index.** The **glow is built**: a changed diff line a Snapcap reaches is marked
   in Storui — teal+steady when the captures are within tolerance (acknowledged noise that would
    forgive), amber+pulsing when a capture blew its variance band (a watched line that still
     diffs badly). Driven by `spay_classify_line(got, exp, spayers)` (Text.svelte) over
      `collect_spayers(story_matching ∪ entropy_rules)`. **Still to build:** the *index* proper —
       a **link to the other end, like a shared ref / loopy zipline**: each glowing line carries a
        ref to the exact `%spayer` that touched it (and the `%spayer` back to its lines), so
         clicking one end pulses the other — the same two-way binding the snap's `hid:1`/`loopy:N`
          shadow stubs already model for shared-C refs. Fed from `spay_graft`'s graft log, not the
           dead `SPAY_MARKER` text-scan.
- **Locator polish (§4.4/§4.5).** Superscript widen/narrow on each `at` chunk (token ↔ `{k:1}`
   wildcard ↔ dropped); gone-parents shown at `opacity:0.5` while awake, never stored.
- **Multi-segment seed.** Grow `seed_into_fields` from `parent / leaf` to a real parent-descent
   reduction (à la `Lang_def_at_offset`, LangRegions ~431).
- **Hot vs restart.** New caps need a restart to apply (compile reads them at snap time).
   Recompiling `entropy_rules` + re-diffing in place is the eventual nicety.
- **`drop` means-kind.** Remove a key (or a whole row) as a `%means` handler that bites at
   encode (`enLine` → `these_sc` mung). Deferred — "maybe later".
- **Shared `%lematch` forest.** One tree across all caps, `oai`-deduped, dead branches pruned —
   if per-cap chains prove redundant in real use. Changes delete semantics (a cap delete must
    prune only the branches no other cap needs).
- **Promotion to defaults.** A per-test cap you want everywhere → a `story_matching` snippet to
   paste into source (the EncodingSplatter copy-to-source gesture).
- **Retire the marker model.** If `spay_line`/`spay_normalize`/`SPAY_MARKER` are confirmed
   unused on every path, remove them; the graft compare needs no marker.
