---
name: entropyarrest-spay-design
description: "EntropyArrest/spay — snap-noise-taming. NOW v2 (spec §8): captures+surgical-graft (re has capture groups=noise, graft tolerated exp-caps into got, rebuilt-got==exp → caveat); %spayer = re+tol(band|any)+factor (first/glyph/blank/add_step_mult GONE). Engine+UI BUILT. v2.1 (2026-06-20b): commit guard was checking dead v1 `kind` → fixed to `re` (form minted NOTHING before); storage GENERALISED — handler now a FLAT %means PREFIX-MAINKEY (means,spayer,re:…,tol — fields inline like %lematch, ≥1 per leaf) INSIDE the leaf %lematch (was cap-level sibling), lematch_to_rule is handler-agnostic (means_of maps each %means→means obj via spayer_of_sc), prunes means-less branches, oai-dedups chain; NO legacy adaptation (cap-level %spayer fallback removed per user). entropy_suggest defaults band factor 1.5 even for unix-ts (any only for hash/sig tokens). Docs BAKED to final (spec rewritten to current/simpler reality, TODOs at end, UI_v2.md folded in + deleted). Diff GLOW built (Storui: Snapcap-matched changed line glows teal/steady=within-tol, amber/pulsing=blew-band; via spay_classify_line). Remaining: §4.3 index CROSS-REF — line↔its %spayer as a shared-ref/loopy 'zipline' (click one end pulses the other), fed from spay_graft graft log"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4427a87d-e605-49d0-af62-748cf9897c7c
---

`spec/EntropyArrest.md` (in `src/lib/O/spec/`) tames Story snap-diff noise. **PIVOTED
 2026-06-20 (spec §2.3', supersedes §2.3): forgiveness moved from encode-time to
  COMPARE-time.** Snaps persist HONEST (real noisy number stays on disk + in dige);
   noise is forgiven when got vs expected are compared, by normalizing BOTH sides.

**Why the pivot wins:** the regex captures the number on each side, so a churning span
 collapses to the same thing on both → the line matches regardless of value, and —
  the killer property — because the EXPECTED side normalizes live too, a stale fixture
   recorded at a different number still compares equal → **no re-record needed.** A
    step that passes only via forgiveness is "virtually OK, with a caveat"
     (`match && !exact`). A `band` blow-out keeps its real value + `‼` on one side → a
      real surprise still survives.

**Built + runner-proven (Text.svelte + Story.svelte + Hovercraft.svelte):**
- `spay_line` (one blank|band spayer over a line) + `spay_num`; consts `SPAY_MARKER`
   (Darwish **في غيابها كوّنتُ صورتها**), `SPAY_BLOWOUT` (`‼`).
- `collect_spayers(rules)` flattens blank|band spayers out of `story_matching ∪
   entropy_rules` (recursing thence); `spay_normalize(snap, spayers, step_n)` runs them
    over snap TEXT line-by-line. Applied to BOTH got+expected before compare.
- `drop` stays at encode (`enLine`→mung) — structural omission, not value forgiveness.
- global default: `story_matching` `self,round` carries `spay:{kind:'blank',
   re:'(?<=round=)\\d+'}`.
- per-test store+compile: `entropy_rules(The)`/`entropy_rule_of`/`lematch_to_rule`/
   `entropy_spayer_of` in Hovercraft `//#region entropy` (beside `prandle`);
    `snap_H(Run,w)` = `story_matching ∪ entropy_rules(w.c.The)` (encode contributes only
     drop). 
- PROOF: `scripts/Story_cli.spec.ts` forgives at its text compare — a step whose
   fixture differs from got only in a `round` value now reports `match:true,
    exact:false, caveat:true` (was a surprise), NO re-record. Synthetic stale-by-value
     fixture, reverted after.

**Storage decision (UI must follow):** `%lematch` stores its matcher as its OWN scalar
 sc keys (mainkey stripped = `sc_has`), NOT object-valued `sc_has` like `i_scheme_req`
  (fatal at toc encode); `%spayer` flat (kind/re/glyph/first/factor/add_step_mult/floor),
   `drop` names key as `key:`. Nested `%lematch`→`thence_matching`. At compare you have
    LINES not particles, so the REGEX self-locates (lookbehind names the key) — the `re`
     must carry enough discriminator; lematch only scopes the author's got-side view.

**MATCHING v2 BUILT 2026-06-20 (spec §8 — captures & surgical graft; SUPERSEDES blank/band
 + normalize-both).** A `%spayer.re` matches edges and carries CAPTURE GROUPS = the noise;
  each got capture pairs with its exp capture. Compare = `spay_graft` (Text.svelte): graft
   the tolerated exp captures into got line-by-line (positional zip; differing line count =
    structural drift = not forgiven), then require rebuilt-got `===` exp. `%spayer` schema is
     now `re` + `tol:band|any` (+`factor`); `first`/`glyph`/`blank`/`add_step_mult`/`floor`
      GONE (exp's capture IS the live baseline). `tol:any` = graft wholesale (hashes/sigs/
       timestamps — the swappable-Alice+Bob driver). Built: `spay_graft`/`spay_graft_line`/
        `spay_within`/`_spay_flags` + `entropy_suggest(gotLine,prevLine)→{re,tol,factor?}`
         (changed-keys→captures, autodetect tol); `entropy_forgive`→`spay_graft.forgiven`;
          `collect_spayers` pulls any spayer with `re`; `entropy_spayer_of` accepts v2 (was
           requiring `kind`); default `self,round`→`{re:'(?:round=)(\\d+)',tol:'any'}`; runner
            →`spay_graft`. Legacy kind:blank/band still honored (no-capture re → whole-match;
             kind→tol fallback). Codec: capture res have `:`/`,` → `%spayer` line encodes as
              JSON in toc.snap (round-trips fine). UI v2 BUILT too (see below). Full baked record:
               `spec/EntropyArrest.md` (UI_v2.md folded in + deleted 2026-06-20b).

**Live-app forgive verdict BUILT 2026-06-20 (engine, Story+Hovercraft).** The runner is
 LENIENT (`w.c.lenient`) — never halts, forgives at its own compare. The live app is
  NON-lenient: a dige mismatch HALTS + queues `fetch_snap`/`check_snap` (loads the disk
   fixture text). Forgiveness landed in that `check_snap` block: `H.entropy_forgive(w,got,
    disk,n)` (new, Hovercraft entropy region) = `collect_spayers(story_matching ∪
     entropy_rules(The))` + `spay_normalize` over BOTH got+disk (mirrors runner's mo:main
      hide + trimEnd); on agreement → `step.sc.ok=true`/`step.sc.caveat=1`, clear halt
       (failed_at/paused/frontier/open_at), drive resumes (line ~1407 re-drives, do_step→
        n+1) — eventually-ok signal goes through, no re-record. Band blow-out keeps ‼ on got
         side only → real surprise still halts. Verdict also `delete step.sc.caveat` on each
          fresh snap. The restructured check_snap is ADDITIVE: else-if/else branches
           byte-identical, `forgiven` needs `ok===false` (never true on snap_checking-ok),
            so only the non-lenient mismatch path changed. NOT exercised by the lenient
             runner — verify live on :9091. **Still TODO (UI session, do NOT touch):**
              surface `step.sc.caveat` as a Storui badge (`sr-plabel` ~1042); §4.3 diff
               index; §4.4/§4.5 locator polish; multi-segment seed.

**Authoring UI BUILT 2026-06-20 (`ui/EntropyArrest.svelte`)** — spawn+CRUD of a
 `%Snapcap` from a diff click. Click a `Dif:change` cell in Storui → seeds ONE in-flight
  draft (DevTools-Elements-breadcrumb discipline: a new click RE-POINTS the single draft,
   never accumulates; nothing reaches toc.snap until OK — so you don't drown in caps).
    **v2 UI (current):** the locator `at` is ONE `' / '`-split peelable text field (Ctrl-Z
     free; the PeelInput-segment breadcrumb + its mutation bug are GONE); seeded incl. the
      PARENT line (Storui `diff_parent_line` passes it); `cap` slug AUTO-DERIVES until edited;
       the spayer editor is `tol:band|any` + `factor` + a capture `re` from `H.entropy_suggest`.
        Storui shows a `≈ caveat` badge + pip for `step.sc.caveat`. (v1 had a PeelInput
         breadcrumb + blank/band/drop kind-picker + `(?<=key=)\d+` autogen — superseded.)
          OK elvistos `Story/Story` `entropy_commit`
        {cap_json} (JSON string — elvisto args ride as scalar sc, a nested locator would be
         fatal object-in-sc). New Story handlers `e_entropy_commit`/`e_entropy_delete`
          (beside `e_story_accept`) + Hovercraft `The_EntropyArrest`/`entropy_mint`/
           `entropy_unmint` (in `//#region entropy`); mint builds %lematch chain + %spayer,
            `story_save()` re-encodes The/**. Restart to APPLY (compile reads caps at snap).
             Codec verified: `re:` colon-split always wins over embedded `=`; `:`/`,` in a
              regex trips encode_stringies' JSON fallback → round-trips. svelte-check clean
               (only baseline `does not exist on type House` ghost-method noise).

**v2.1 fixes + generalisation 2026-06-20b (Story+Hovercraft+ui/EntropyArrest):**
- **commit was dead**: `e_entropy_commit` guarded on `draft.spayer?.kind` (v1) but the v2
   form sends `{re,tol}` — guard always returned, so OK minted NOTHING (no The/EntropyArrest,
    no Snapcap). Fixed → guard on `draft.spayer?.re`; log prints `tol`.
- **storage generalised** (user ask): handler is a FLAT `%means` PREFIX-MAINKEY particle —
   `%means,spayer,re:…,tol:band,factor:1.5`, fields inline like `%lematch`, ≥1 per leaf —
    nested INSIDE the leaf `%lematch` (`%lematch**/%means,spayer,…`), not a cap-level sibling.
     `lematch_to_rule(lm)` is a pure structural tree-walk naming NO handler: node's own sc →
      sc_has, nested %lematch → thence_matching, EVERY %means child merges via `means_of(mn)`
       (`{means,spayer,...rest}` → `spayer_of_sc(rest)` → means.spay; omit_sc/munging slot in
        later). Returns null for a branch with no %means (the prune). `entropy_mint` nests
         segments via `oai` (find-or-create → shared-prefix reuse) and drops
          `host.i({means:1,spayer:1,...draft.spayer})` on the leaf. `entropy_spayer_of` split:
           `spayer_of_sc(rest)` is the shared builder. `%means` encodes/round-trips like
            `%lematch` (generic enL, no allowlist; JSON line because re has `:`/`,`).
- **oai/%req FOOTGUN (fixed)**: `entropy_mint` built the locator chain with `oai({lematch:1,
   ...seg.sc})`, but a locator key like `req:wants` made `'req' in s` true → `oai`'s %req branch
    rebuilt the node as a real `%req` (mainkey `req` not `lematch`, + c.up/serial/initialdo), which
     the req machine then pumps & CLEANS AWAY (likely also why the LakeSurfer caps "vanished" on a
      runner run). Symptom: cap doesn't apply + outer renders `req:wants,lematch` (req-first).
       Fix → plain `i()` (fresh cap, nothing to dedup against; lematch stays mainkey). ALSO fixed
        at source: `oai` now triggers the req machine only when `req` is the MAINKEY (first key),
         not merely present — see [[oai-req-mainkey-only]]. So oai is safe for the chain now too.
- **diagnostics**: `H.c.entropy_debug=1` gates a log in `entropy_rules`; `H.entropy_diagnose(w[,
   got,exp])` (Hovercraft) dumps The→caps→rules→spayers→per-line classify→forgiven.
- **NO legacy adaptation** (user: "no legacy adaption needed"): removed `lematch_to_rule_legacy`
   + the cap-level-%spayer fallback in `entropy_rule_of` + `entropy_spayer_of(sp)` + the UI
    `cap_spayer` fallback. Old cap-level-%spayer caps no longer compile — re-author them.
- **NOT done (decided non-goal, user mused then deferred)**: cross-cap SHARED %lematch** forest
   (one tree, caps share nodes). Kept per-Snapcap/flat (CRUD identity per cap); `oai` ready for
    it. Listed in spec §9 TODO; changes delete semantics (prune only branches no cap needs).
- **entropy_suggest + UI defaults**: any number → `band` factor **1.5** (incl unix timestamps —
   seconds of drift sit far inside 1.5×); only a non-numeric hash/sig token → `tol:any` (band
    parseFloats→NaN→never grafts, so a token MUST be any). UI: tol defaults band, factor 1.5;
     band|any buttons OVERLAP (`-1em`, active on top) like a physical mutex toggle.
- **%scheme answer**: `i_scheme_req`/`follow()` (Hovercraft ~406/469) is the original "build a
   %lematch chain + descend it" pattern, but it WALKS imperatively (reads object-valued
    `lm.sc.sc_has`, transient on live w) — it does NOT convert to a {matching_any,means} rule.
     `lematch_to_rule` is the only %lematch→rule converter, and the snap-safe one (own sc = sc_has).

**v2.2 polish 2026-06-20c (Text+Hovercraft+Story+Storui+ui/EntropyArrest+spec):**
- **{NUM}/{TOK} re sugar**: an authored re carries legible tags not raw captures; `{NUM}`→
   `(\d+(?:\.\d+)?)`, `{TOK}`→`(\S+?)`, each ONE capture group. `Text.spay_desugar(re)` expands
    at EVERY `new RegExp(sp.re,…)` (spay_graft_line/classify_line/spay_line); tags ride to disk
     (snap legible too). `entropy_suggest` emits tags; UI `resugar()` shows stored raw caps as
      tags on edit. Default `self,round` rule now `round={NUM}`,tol:any (was `(?:round=)(\d+)`).
       NOTE: a literal `{NUM}` in Svelte MARKUP is an expression — placeholder must be `{'round={NUM}'}`.
- **entropy_suggest flag-bareword fix**: a stable flag (peeled value `1`) was emitting `time=1`
   in the re because the `typeof number` branch ran before the `===1` branch. Reordered to match
    `depeel` (Y.svelte): value 1/true → BARE key, else `k=N`, else `k:v`. Now `time,compile={NUM},…`.
- **{TOK} bug fix**: was `(\S+?)` — non-greedy + `\S` includes `,`/`:`. At END of a re (the common
   `k:{TOK}` hash case) non-greedy matched ONE char → graft grafted 1 char → never forgave; greedy
    `\S+` would gobble across the comma into the next key. Fixed to `([^,\s]+)`: a whole PeelVal
     bounded by the `,` field-sep + objecties-tab whitespace (a value MAY hold `:`/`/`/`=` so those
      stay in). Resugar recognizes both new+legacy forms. band tol is SYMMETRIC (max/min<=factor,
       allows down as much as up); factor 1.5 forgives ratios up to 1.5 either direction.
- **in-value sub-tokenization + {INT} (v2.3)**: entropy_suggest now captures churn INSIDE a string
   value, not just numeric value-keys. A changed string mainkey value (timestamp/path like
    `Waft:Ting/2026-06-21/034032`) is split on numeric runs (`/(\d+(?:\.\d+)?)/`); stable text AND
     stable numbers stay literal, only DIFFERING numbers → capture → `Waft:Ting/2026-06-{INT}/{INT}`.
      New `{INT}` sugar = `(\d+)` (integer run: dates/times/ids/counters); {NUM} reserved for decimals
       (has `.`). Any in-value/token capture forces whole spayer `tol:any` (can't band a date; ONE tol
        rules all captures). Skeleton-differs or no-number-moved → fall back to whole `{TOK}`. Dropped
         the old `/^[0-9a-fA-F]{8,}$/` hex special-case (subsumed). LOCATOR: nk = first key whose value
          changed (ANY type, was numeric-only) → wildcards the mutating mainkey VALUE → locator is
           `w:Lies / Waft,takes` (keys), not the literal value. derive_slug dedupes leafmk===nk.
            {INT} added to SPAY_RE_SUGAR + spay_desugar + UI resugar (`(\d+)`→{INT}). Verified graft.
- **JSON target lines NOT spayable (decided non-goal)**: forgiveness matches a regex on the snap
   LINE TEXT and the re is built peel-shaped; a particle that trips encode_stringies' JSON fallback
    (object-in-sc) snaps as a `{"…":…}` blob the re can't cleanly capture. Constraint: to be spayed,
     a C must encode non-JSON-ically (scalar sc). Documented in spec §2 codec-reality.
- **locator wildcards trailing keys**: `loc_chunk(line, wildcard_from)` now barewords the changing
   key AND every key after it (was just the noisy key) — a trailing churner (`all=…,write=0`) no
    longer over-anchors. Default `at` leaf = stable-keys-then-barewords.
- **graft glow now RECEDES**: `.spay-graft` cell `filter:contrast(0.6) brightness(0.45)` (user-
   asked), hover→none; acknowledged noise fades, blown stays loud amber-pulse. (Storui CSS.)
- **copied diff carries spay**: `enDif(rows, depth, spayers?)` tags `Dif:change`→`Dif:change,spay:graft|blown`
   via spay_classify_line; collect_range passes `spayers`. deDif reads only sc.Dif → round-trip safe.
    Untagged `Dif:+`/`Dif:-` in a paste = real structural surprise.
- **drop/dontSnap means-kinds BUILT** (§5; were deferred): `%means,drop`→`means.skip` (omit whole
   line, proven self,est path), `%means,dontSnap`→`means.dontSnap` (keep line, prune subtree:
    enLine sets q.dontSnap→story_process_node T.sc.dontSnap→snap_H T.sc.more=[]). means_of maps
     drop/dontSnap; entropy_mint+e_entropy_commit generalised to a `{kind,...fields}` means
      descriptor (kind: spayer|drop|dontSnap; back-comat draft.spayer still ok). UI `means` mutex
       is now 4-way band|any|drop|dontSnap (structural ones hide re/tol, show a note). Per-KEY drop
        (mung one these_sc key) still deferred. Single-sided `Dif:+`/`-` rows not yet click-to-seed.
- **doc TODO added**: TimeSpool-like number-wander stats (per-cap spool of a spayed capture's
   value over runs — count/min/max/mean/spread; fed from spay_graft graft log; band factor seen
    not guessed; `≈` caveat could carry n/range/μ). Engine clean on check + MundaneStation runner.

**v2.4 vaguer-locator + fuzz tub 2026-06-20d (ui/EntropyArrest + Hovercraft + spec + Everything_todo):**
 root complaint = seeded `at` far too specific (parent `loc_chunk` pinned the churny `waft:Ting/
  2026-06-21/042649` value literally → over-anchor; LakeSurfer `lematch,Interest:Ting,waft:Ting/…`
   is the witnessed suspect). Three fixes, all "err vague after the mainkey" (a loose locator no-ops
    where it over-matches; the spayer re does the precise work):
 - **vaguer locator**: `loc_chunk` now also barewords any NON-mainkey key whose value `noisy_val`
    (`/\d{5,}|\d+[-/]\d+/` — long-id/time or dated path; ≥5-digit floor spares stable port/year/small-count) even BEFORE the clicked key; first key (type tag)
     + stable short values stay literal. `Interest:Ting,waft:Ting/…,lens:DocTing,…` → `Interest:Ting,
      waft,lens:DocTing,…`.
 - **`.` separator**: `entropy_suggest` joins anchors with `.` (any-char) not literal `,` — matches
    the single `,` field-sep 1:1 but tolerates drift; escaped literals keep `\.` so the join `.` is
     unambiguous. Only affects NEW suggestions; existing `,` caps still match.
 - **fuzz tub**: underslung drawer (`|_O_fuzz_O_|`) under the re field, 2 sliders (head|tail) winding
    anchors down toward greedy. `entropy_suggest` now RETURNS `parts: string[]`; ui `fuzz_model`
     splits head|capture-core|tail, `fuzz_seq(side)` builds the wind-down, `compose_re` renders at
      (h_fuzz,t_fuzz). Notch model = **strip-value-then-trim** (user-chosen): `want={INT}.kind:cold.
       resolved`→`…kind.+resolved`→`…kind`→`want={INT}`. **head/tail `.+` asymmetry (fixed v2.4b)**:
        the `.+` absorbs the stripped value, which peel renders to the RIGHT of the key — so for a
         TAIL token it's the far side (`kind.+resolved`) but for a HEAD token it faces the CORE
          (`compile.dige.+secs={INT}`, NOT `compile.+dige.…`); each notch carries its own core-facing
           bridge (Notch{str,bridge}; bridge `.`→`.+` once near value stripped). An $effect recomposes re_text while live;
        hand-edit latches `re_dirty` → tub RETIRES (and edit_cap retires it: no parts; re-suggest to
         get sliders back). Tail slider `transform:scaleX(-1)` so handles converge on `fuzz`. Wheel
          nudges; page-scroll-vs-wheel "traffic jam" guard pushed to Everything_todo §7 (Not nailed
           down). svelte-check clean (only baseline deL/entropy_suggest/House ghost-method noise).
            Caps still need a RESTART to apply (compile reads at snap). Existing over-anchored snapped
             caps don't retro-vague — re-author from a fresh diff click.

**v2.4c polish 2026-06-20e (ui/EntropyArrest + sed across 9 files + spec + snaps):**
 - **bare-flag fuzz fix**: a value-less near token (`time`, `dim` — mainkey flag, peel value 1) has
    NO value to strip, so the `.+` notch was spurious (`time.compile`→`time.+compile`→`compile`).
     fuzz_seq now gates the `.+`/strip notch on `valued = /[:=]/.test(near_tok)`: bare → full→greedy
      directly (`time.compile={NUM}.all={NUM}`→`compile={NUM}.all={NUM}`); applied symmetrically so
       bare tail `dim` no longer emits `dim.+pending`. Valued cases unchanged.
 - **MAINKEY RENAME Snapcap → Entcase** (user, "be Darwish about it"): the per-entry mainkey under
    The/EntropyArrest is now `Entcase:<slug>` (an "entropy case" — a case encasing an anomaly, held
     for safety, forgiven-not-forgotten; spec §3 carries the Darwish epigraph ما لا يُسكَّن، يُؤوى).
      `sed s/Snapcap/Entcase/g` across Text/Story/Storui/ui-EntropyArrest/Hovercraft + spec + the 3
       Lake snaps (LakeNets/LakeSurfer/LakeTiles toc.snap — pure metadata mainkey, keeps caps valid).
        NO back-compat — old `Snapcap:` would orphan. The FEATURE/bucket name stays EntropyArrest.
 - **fuzz tub MOVED to footer** (was "underslung under re", too long): compact pill `|_O_fuzz_O_|`
    (`.ea-fuzz-wrap`, 3rem sliders) in the ea-foot row between `only step N` and cancel/OK; dropped
     the "restart to apply" hint. `.ea-tub`/`.ea-re-row.tubbed` CSS gone.
 - **header de-dotted**: title literal `EntropyArrest` (greppable, no 🛑), `{caps} cap` tally REMOVED
    (just `drafting` when active).
 - **collapsible (v2.4d)**: header carries a block-mode `<Vexpandy bind:expanded>` (ui/Vexpandy);
    panel STARTS CLOSED (`expanded=false`), cap-list+draft gated behind `{#if expanded}`; a diff-click
     (seed_into_fields) auto-opens it so authoring isn't hidden; `expanded` persists across commit/cancel.
      noisy_val floor raised \d{3,}→\d{5,} (spares stable port/year/small-count from locator wildcard).
 - svelte-check: ui/EntropyArrest clean (only House ghost-method baseline); Storui/Story errors are
    pre-existing baseline (TraceEvent/Step-null), untouched by the comment-only rename there.

**v2.5 diff-click authoring discipline 2026-06-24 (Storui + ui/EntropyArrest + spec §6/§7), browser-UNVERIFIED:**
 the diff cell `onclick` is now ROUTED (`diff_click`), not a blind `seed_spay`:
 - **selection guard**: a non-collapsed `window.getSelection()` bails — selecting regex source no
    longer spawns a stray `+Entcase` that clobbered the in-flight draft (the root complaint).
 - **covered line reveals, doesn't author**: a changed cell with `row_spay_class ≠ ''` routes to a
    `covered` prop (token-bumped) instead of seeding — never duplicate a cap that already bites.
     First covered-click GLOWS the owning LOCAL cap's row ~2s (`hl_slug`/`.ea-cap-hl`); a second
      while it glows `edit_cap`s it (`on_covered`). Shared/default-only owned line → reveals nothing,
       still never seeds. Only an UNcovered changed line seeds a new draft.
 - **per-cap match tally** beside edit|×: `cap_tally` = how many of the open step's changed diff
    lines a cap reaches, via its OWN compiled spayers (`cap_own_spayers` = `collect_spayers([entropy_rule_of(cap)])`);
     gated on `diff_changed?.length` (Storui passes the step's changed pairs). `0×` dimmed.
 - **delete is two-stage**: swapped the bare `×` for `ui/micro/DeleteX` (first click arms red
    `delete?`, second within ~2s fires `entropy_delete`). (NB user said "ui/mini/" — it's `ui/micro/`.)
 typeclean (only baseline House ghost-method noise). Verify on :9091.

**v2.6 ±slack absolute band + structural-anchor lesson 2026-06-24 (Text+ui/EntropyArrest+spec §2/§6), browser-UNVERIFIED:**
- **`slack` field (absolute ± band slack)** — RENAMED from `pm` 2026-06-24 (user: "better human word
   than pm"; `pm` read like p.m./private-message, `±` is fine as the UI glyph but a poor identifier).
    `spay_within` band is now `max(a,b) <= factor*min(a,b) + slack` (was `max <= factor*min`). `slack`
     is an absolute wiggle ADDED after the ratio factor; `slack=0` (default) is exactly the old band —
      the formula even subsumes the old 0/0→in, x/0→out special-cases (deleted them). FOR: a value that
       swings in absolute but not ratio terms — **compile ms** (100↔600 = 6× blows any sane factor, but
        "within 500 of 500" is fine): set `slack` + drop `factor` toward 1. Plumbing was tiny:
         `spay_within(g,e,tol,factor,slack)` + pass `sp.slack` from `spay_graft_line`/`spay_classify_line`;
          `spayer_of_sc`(`...r`) and `entropy_mint`(`...fields`) already spread arbitrary means keys, so
           `slack` rides to/from snap with NO compile-path change. UI: a `± slack` num input beside
            `factor` (band only), `slack` $state, commit omits it when 0, edit_cap loads it. `tol:any`
             ignores slack (always grafts). The shared `Compile_time-compile` profile cap carries
              `slack:0.5`. Typeclean.
- **STRUCTURAL-ANCHOR GOTCHA (the "why isn't it catching" debug)**: a re must not anchor on a token
   that's only present in LATER steps. LakeTiles `Ting_Point-last` had `Point:theCompiledStuff.+weight=4.last={INT}…`
    — but step 3's Point line is `…,n,weight,last=…` (n/weight BARE before the Point accrues weight),
     so the literal `weight=4` made the whole re miss step 3 (matched 4-9 only; verified vs all 9 NNN.snap).
      Fix: anchor on the STABLE noise keys + bridge the step-evolution with `.+` →
       `Point:theCompiledStuff.+last={INT}.+first={INT}.+heat={NUM}`, and `tol:any` (last/first are wall-clock
        timestamps — can't band a date, and one tol rules all caps). Lesson: structural diffs between steps
         are expected step-evolution (in the diges); the spayer should match the line at ANY step and only
          forgive the run-noise tokens (timestamps/decay) — so bridge with `.+`, don't pin step-specific values.
- **NEXT (user direction, NOT built):** pull `EntropySamples.snap` (§10.2 sidecar) at the SAME time as the
   `EntropyProfile` (same Lies_open_Waft hook, cached on w.c, resident before step 1) → substitute-and-redige
    LIVE per step → diff goes green AS it steps → lenient-by-default. See [[entropy-samples-fuzzok.md]] §10.2.

**v2.7 shared caps editable inline + generator TODO 2026-06-24 (ui/EntropyArrest+Story+Hovercraft+spec §9/§6), browser-UNVERIFIED:**
- **shared caps now EDIT in place** (user: "lose the not-working 'open' button in the SHARED profile,
   inter-component scroll-linkage is beyond us, have the shared set editable right there"): the `open ⇗`
    button + `open_profile()` GONE; shared cap rows get `edit` + a confirm `DeleteX` like local rows
     (`ea-cap-ro` read-only styling dropped; a teal `editing shared · <ref>` banner shows on the draft).
      A shared edit WRITES THROUGH to the profile Waft: `edit_cap(cap, ref)`/`del_cap(cap, ref)` tag the
       draft with `edit_ref`, commit/delete carry `ref` in the JSON, and `e_entropy_commit`/`e_entropy_delete`
        (Story) branch on it → `entropy_profile_loc(ref)` (new, Hovercraft — the WRITE sibling of
         `entropy_profile_waft`, returns `{lies_w, waft, ea}`, find-CREATES the EA bucket) → `entropy_mint_into`/
          `entropy_unmint_from` (new bucket-level cores split out of `entropy_mint`/`entropy_unmint`) →
           `loc.waft.bump_version()` + `Lies_waft_save(loc.lies_w, loc.waft)` persists the profile's OWN
            toc.snap for every borrower. Local path (no ref) unchanged (story_save). scope (only-this-step)
             never rides onto a shared cap. Live C edit + story_analysis re-bites this run immediately; the
              disk save is for persistence/other borrowers. Typeclean (baseline House-ghost noise only).
- **GENERATOR-PERFECTING TODO added (spec §9)** — `entropy_suggest` is serialization-aware on INPUT
   (`deL` parses peel+JSON) but BLIND on OUTPUT (always renders peel `k=N`/`k:v`), so on a JSON-blobbed
    line it emits anchors that match nothing, and `{TOK}`=`[^,\s]+` can't bridge a comma-bearing value
     (the say,at bug, [[entropy-samples-fuzzok]]). Ladder logged: (1) SELF-VERIFY before emitting (graft
      the suggestion back against its own got/exp, widen+retry on miss — never hand back an untested re;
       `seed_spay` persists unverified today); (2) serialization-aware output (thread the `str_raw[0]==='{'`
        bit, render JSON-shaped anchors); (3) make the `{TOK}` limit KNOWN to the generator (a bounds table
         per sugar + new `{ANY}`=`.+?`, pick the narrowest token that can cross a span). Next-level engine:
          multi-sample anti-unification/LGG over the `EntropySamples` corpus instead of pairwise diff +
           discrimination vs negatives + the ceiling = STRUCTURAL spayers over `deL` stringies (predicate on
            parsed C, serialization-agnostic, dissolves peel-vs-JSON; regex stays fallback for in-value churn).

**Still NOT built (UI follow-ups):** live-app forgive+caveat verdict (the prerequisite
 ENGINE slice above — `snap_step_after_wave`), diff index (mirage-scan→`%spayer`, glowy
  pulse §4.3), superscript widen/narrow buttons §4.4 (segments only PeelInput-editable +
   `*` wildcard for now), gone-parents @0.5 §4.5, multi-segment parent-descent reduction
    (single-segment locator from a click for now). Verify v1 live on :9091 (can't gate
     headlessly). **§1 Lines walker-merge deliberately skipped** (no payoff).
      Gate methodology: got-before vs got-after, NOT got-vs-fixture (fixtures stale).
       Related: [[story-step-lines-drive-steps]], [[snap-inclusion-vs-pump]],
        [[story-cli-runner-boot]], [[todo-docs-overstate]].
