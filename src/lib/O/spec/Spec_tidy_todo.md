# Spec_tidy_todo — finishing this era's docs before the Atheory era starts

**What this is.** A read-only survey of `spec/` (148 docs, ~5.6 MB, 2026-10-15) and the owner's rulings on how to tidy it.
 The project is turning from this development era into the next one, which starts with Atheory (`Atheory_todo.md`) and
  is expected to get a new directory of specs. The tidy sorts what carries forward from what is finished history.

## 0. What to get on with next

1. ✅ **The `Tend_todo.md` name clash — resolved 2026-10-15:** the live doc was renamed `Signed_call_todo.md`. Was: the live doc (the signed-call grant design, 2026-10-13) and `history/Tend_todo.md`
    (the retired attention design) are unrelated. That breaks CLAUDE.md's "a missing spec/X.md is history/X.md" rule.
    Rename the live one when the grant's name is chosen (Tend / Operate / Steward …).
2. ✅ **Trust — merged 2026-10-15:** `Trust_audit_handover.md` + `Trust_todo.md` are now one `Trust_todo.md` (§0 both
    plans, §1–§2 the wire audit, §3 trust-as-substrate, §4 where they meet, §5 pointers); `Trust_audit_handover.md`
     retired to `history/` with a notice. Citations updated everywhere except `Radio_todo.md`, `App_todo.md`,
      `Crew_todo.md`, `Mag_todo.md`, `Glassbeast_todo.md` (other agents' files — owed). The stale "transport is a
       deliberate mock" lines in `Sharing_design.md` (36/94/102/122) and `Frontier.md:35` were also fixed; `Radio_todo.md:1916`
        is owed (out of scope here).
3. ✅ **§2 executed 2026-10-15** (owner: "yeah keep going!"): batches A–E retired, `Lies_handover` renamed, the catch-ups done, the global sweeps done. Front door for the whole shelf is now **`DocIndex.md`** (19 topics, one front-door doc each). Owner steer that shaped it: *"lose more wave-of-work descriptions like Download_stall for permanent uncreased descriptions of the wider scope of developments in that field... like App or Radio is"*.
4. **Left, small, yours or next:**
   - `Vyto_spec.md` → `Vyto_design_todo.md`? (a `_spec` it never earned; `Vyto_todo` is taken in history/.)
   - `Peeroleum_handover.md`: annotated, not rewritten. Retire into `Peeroleum_spec` once someone reads it whole.
   - `ClusterAddressing_todo`: trim to its live §2/§4.5/§6, or retire.
   - `Cluster_spec`'s two `Tyrant` namespace mentions: intentional?
   - `Frontier.md`, `Sharing_design.md`: annotated; both are retire candidates once their pointers are read.
   - ✅ `Consolidation_todo.md` retired (its verdicts carried out; its bless-toward-`_spec` list is still yours).
   - The front-door pass wants repeating on the other topic docs (Crew, SoundPooling, Daemon, Glassbeast…): a standing "what the field is" §0 above any log.

## 0.5 THE COOKING PLAN — ✅ RAN and EXECUTED 2026-10-15 (§2)

Owner, 2026-10-15: *"go ahead and do the rest of the doc cooking… perhaps use lots of sonnet subagents to report on
 various subfields and check for consistency with the code"*.

One **Sonnet** subagent per subfield, in parallel, READ-ONLY.  Each reads its docs, then checks every concrete claim
 (file:line, function names, "built"/"unbuilt", "mock", counts) against the code.  It returns:
- a table of claims, each marked true / stale / false, with evidence;
- the doc's §0 freshness;
- for retire candidates, the ideas worth scraping and where they should land.

Nothing is moved or edited by a subagent.  The owner rules per batch, then the moves are made (scrape, then move the whole
 file into history/ with its notice, per CLAUDE.md).  Never stage or commit.

Subfields (one agent each):
1. **Cello / glass:** the Cello scheme family + `Cello_todo`, `Cello_synthesis_todo`, `Glassbeast_todo`, `Meaningfold`.
    Scrape the "historical genius" (§1).
2. **Voro / Cytui / Vyto:** the 7 Voro docs, `Vyto_spec`, `Vyto_sizing_todo`, `Vyto_client`.
3. **Radio:** `Radio_todo` (305 KB), `Radio_spec`, `Radio_design`, `Radio_lowlevel`, `Radio_multicast_todo`,
    `Radiobuddies_handover`, `Radio_circuit_todo`.  Proposes a rewritten §0.
4. **Mag / Heard / Heist / SoundPooling:** `Mag_*`, `Heist_todo`, `Heist_design`, `Download_stall_handover`,
    `SoundPooling_todo`, `RemoteHeist_todo`.
5. **Wire and trust:** `Peeroleum_spec`, `Peeroleum_handover`, `Sharing_design`, `Covenant_design`, `Trust_*`,
    `Cluster_spec`, `ClusterAddressing`, `Presence`, `Reach`, `Repli_design`.  The "mock" claims; `Tyrant.g` mentions.
6. **Crew / onboarding / phone:** `Crew_todo`, `Onboard_todo`, `Onboarding_todo`, `Portability_todo`, `LinkDevice_leak_todo`.
    Catch them up to the Crew reality (§1).
7. **Lies / Lang / Story / perf:** `Perf_todo`, `Coding_guide`, `Story_hygiene_todo`, `Seen_split_todo`, `Lies_handover`,
    `Composition`, `Backpressure`.
8. **Sweep snapshots and dead links:** `Everything_todo`, `Frontier`, `Loose_ends_todo`, `V1_cut_todo`,
    `Consolidation_todo`, `Speeches_todo`, plus the ~15 citations to docs that exist nowhere.

Then merge the eight reports into the batch table (§2) and bring it to the owner.

## 1. The owner's rulings on HOW (2026-10-15)

- **Scrape the genius before retiring.** *"keep eg Cello's historical genius scraped together out of those going docs."*
   A retiring family is first read for its best ideas, and those land in the doc that carries forward (for the Cello
    schemes: `Cello_todo.md` / `Cello_synthesis_todo.md`). The whole file then moves to `history/` with its notice
     (CLAUDE.md). Retiring without the scrape loses the reasoning; scraping without retiring keeps the sprawl.
- **Leave explosive vocabulary where it is.** The retired Tend design's language (qua/grain/accord) stays in history
   undrained. Only §7 ("Why not LE, why not Repli") was worth carrying, and it now lives in `Atheory_todo.md` →
    "The merge organ".
- **`MobilenoFSA_todo` became the Crew feature.** It was "a shock revelation that it wasn't going to be such a useful app
   until android+chrome policy changes": no folder on a phone. Its phone and listen-only arc folded into
    `Portability_todo.md` (2026-08-26), and its linked-devices half became Crew (`Crew_todo.md`). Its citations in
     Onboard/Onboarding/Whitehole are annotated (2026-10-15). **The attendant docs (Onboard, Onboarding, Portability)
      want catching up** to the Crew reality: owed, ideally not too hairy.

## 2. The batches — audited against the code 2026-10-15 (eight Sonnet reports, read-only); each needs the owner's OK

The audit changed the survey's table in four places:
- `Cello_meditation` **stays**: it's the prose seed of the residual lens.
- `Radio_lowlevel` and `Radiobuddies_handover` **stay**: you overrode their retirement on 2026-07-27.
- `Everything_todo` **stays**: it gained a gap audit after Consolidation's verdict, and 8+ docs point at it.
- "Mag.g named as live" was **wrong**: `Mag.g` never existed.
`Consolidation_todo`'s own 2026-09-02 verdicts (retire Onboard, the Cello strikes, Everything) were **zero for four
 carried out**; batches A, D and E below are those verdicts, re-checked.

### Retire (scrape first → whole file to `history/` with a notice)

| batch | docs | scrape → lands in |
|---|---|---|
| ✅ **A. Cello schemes** | `Cello_tree_scheme`, `Cello_mesh_scheme`, `Cello_universal_scheme_1..6` (all design-only; none of their mechanisms exist) | Mesh's atom vocabulary (mainkey pill + sc pebbles + `.c` feathers) → `Cello_synthesis_todo` "durable core" + `InkSurprise_todo` as prior art; Weave's ancestry colour braid → `Cello_todo` next moves (Cello has no navigation-at-scale story); footnote each synthesis row with its source scheme |
| ✅ **B. Voro** | `Voro_todo`, `Voro_render_todo` (waves ③④ never landed; Cytui grew to 5,878 lines instead), `Voro_render_faults_todo` (self-declared spent), `Voro_vtuffing`, `Cytui_cleave_todo`; **merge** `Voro_svg_stuffing` | all → `Glassbeast_todo` §0.6 item 1 (stained-glass taste, arc-river engineering, Vtuffing north-stars, cross-wall row alignment = the open task); Cytui_cleave's Layer A/B/C map → §0.6 item 2. Glassbeast's doc-map already says `history/Voro_*`; this makes it true |
| ✅ **C. Mag** | `Mag_design` (its kinds vocabulary is FALSE since 08-05), `Mag_v1_handover`, `Mag_vs_flatstock_preen` | into `Mag_todo` §1: the `Mag : Waft :: Cloud : What` lineage, the GC carve-out, the `[LIVE]/[BOOK]/[OWED]` convention, and the still-open Cloud nesting-depth question (preen §4) |
| ✅ **D. one-offs** | `Download_stall_handover` (fix landed, `Swarm.g:3059`), `Covenant_design` (its subject `Tyrant.g` was deleted 2026-09-16, `c04544d5`), `Speeches_todo` (the `chop?` column is empty and half its lines have drifted) | Covenant's M0–M3 minima ladder / `%req:join` admission → `Peeroleum_spec` as a parked alternative; Speeches' *method* (grep 8+-word strings, longest first) → one line in `App_todo` |
| ✅ **E. Onboard** | re-ruled by the owner: BOTH `Onboard_todo` and `Onboarding_todo` rolled into `App_todo` §0.7 "Arriving" (+ Crew_todo §4/§7), both retired | "%Idzeug becomes the issuer" + the old-garden migration → `Crew_todo` §3/§4; the invite-robustness audit (three door holes) → `Crew_todo` §7; repoint its 4 citers (Portability_doc, Portability_todo, Solo_todo, Sharing_design) |

### Rename (no content loss)

| doc | to | why |
|---|---|---|
| ✅ `Lies_handover.md` (done 2026-10-15) | `Lies_attention_todo.md` | a live design (P7 cursor collapse and the §8 decisions are open); needs a §0; its §6 item 1 ("`LE_spawn {LE:1}` is dead") is now FALSE: it's a deliberate multi-reason scheme (`LangHold.svelte` ~1038) |
| `Vyto_spec.md` | `Vyto_design_todo.md` (NOT `Vyto_todo`: that name is taken in history/) | self-declared "unpreened" for three months; Slope/Mesh/Sunpit/`%Situation` still unbuilt; parts disowned by `Meaningfold` §4 |
| `Peeroleum_handover.md` | catch-up, then decide | calls `Tyrant.g` "BUILT" 15 times; `Peeroleum_spec` §11 already has the correction |

### Catch up (keep; the listed fixes are mechanical unless marked)

| doc | fix |
|---|---|
| ✅ `Radio_todo` | new §0 (the log stops 08-30): Stoker audience gate, `Radio_like` toggle, Heard Mag, remote heist; `:3347` ActionButtons claim is fixed already. ⚠ The auditor's draft §0 says "the wire is still `Lake_link` loopback", which is wrong (prod serves real listeners on other machines); rewrite, don't paste |
| ✅ `Radio_spec` / `Radio_design` | apply Radio_design's own ruled `[built]`→`[BOOK]` relabel of §5B (never done); refresh "settled design" with Heard/audience gate/`Radio_like` |
| ✅ `Radio_circuit_todo` | "unlove frees a cache, never a possession" / "unlove does not propagate" (§9.3/9.4) → `Love_todo` §0 |
| ✅ `Mag_todo` | §0 (08-05) reads as next but is baseline; open = §9 writeable Mag / share-as-invite + the remote-Pier-cursor skip; point to RemoteHeist/SoundPooling |
| ✅ `Heist_todo` / `Heist_design` | §0 changelog is done (torch → `RemoteHeist_todo`); Scope A chooser is dead after the 10-07 whole-album ruling |
| ✅ `Portability_todo` | §1/§2 "the soul keypair travels" and §7/§8 the `%Sibling`-roster graft are FALSE under cert-crew (`%Body` under `/Crew`; `%Sibling` is same-browser only). **Not mechanical: wants a rewrite pass** |
| ✅ `Onboarding_todo` | retired into `App_todo` §0.7 (open items listed in App_todo §0) |
| ✅ `Sharing_design` | lines 36/94/102: `Tyrant.g` mock rows FALSE; 122 true but predates the from-check; it recommends retiring `Trust_audit_handover`, which is now the most load-bearing trust doc. Eventual retire |
| `Frontier.md` | frozen 07-27; ":35 per-frame crypto is a mock" true but predates the from-check; "Peerily retired" → deleted |
| `ClusterAddressing_todo` | flags most of its own body dead; only §2/§4.5/§6 live. Trim or retire |
| ✅ `Cello_todo` / `Cello_synthesis_todo` | TAKEOVER now includes Wikipedia; "residual not in Cello yet" misleads: `ResidualMote`/`InkSurprise` are built at `/ink`, just not in Cellui; the synthesis §0/R.5 slice shipped |
| ✅ `Vyto_sizing_todo` / `Vyto_client` | cite `Ghost/Story/VoroTesting.g` and `VytoTesting.g` (not `Voronation.g` / `Vytonation.g`) |
| `Backpressure_todo` | the §9.6b stale-comment callout is already fixed; item 00's Tier 1-3 plan isn't what shipped (MusuNeGrind became the janitor instrument; `heist_selfclock` still opt-in) |
| `Cluster_spec` | two `Tyrant` mentions as a future namespace: intentional? (yours) |

### Trust (§0 item 2), refined — ✅ done 2026-10-15

`Trust_todo` (Grant-as-substrate ceremonies) and `Trust_audit_handover` (is the wire real) were **different subjects**, not
 duplicates. Merged as a restructure: `Trust_todo.md` now runs opening → §0 (both plans, WT1–4 first) → §1–§2 the wire audit
  (re-verified, not pasted verbatim — one row improved: the voucher-cache-vs-revocation ⚠ is now a confirmed ✅) → §3
   trust-as-substrate → §4 where they meet (WT1's session key *is* one reusable trust ceremony; so is `Signed_call_todo.md`)
    → §5 pointers.

### Global sweeps (mechanical)

- ✅ **`Musuation.g` → `Ghost/Story/MusuTesting.g`** (done 2026-10-15 for the whole `*ation.g` → `*Testing.g` family: Atlantation, Electrodation, Lagoonation, Berthation, Errchannelation, Heistation, Musuation, Peregrination→PeerTesting, Radiation→RaTesting, Siphonation, Swarmation, Vytonation; stale `:NNN` dropped) (renamed 2026-09-09, `ca0e4fb4`) in: `Radio_todo`, `Mag_todo`, `Repli_design`,
   `Radio_spec`, `Radiobuddies_handover`, `Swarm_spec`, `Backpressure_todo`, `Composition_todo`, `Supervisor_todo`, `Voro_vtuffing`,
    `Seen_split_todo`.  (`Clerkdesk_todo:142` is a deliberate `HEAD:` blob ref; leave it.)
- ✅ **`Tyrant.g` named as live** (annotated 2026-10-15): `Covenant_design`, `Peeroleum_handover`, `Sharing_design`, `Seen_split_todo`, `Cluster_spec:330`.
- ✅ **Truly dead citations** (fixed 2026-10-15) (not self-explained): `Agency_to_Hovercraft_plan` (`Everything_todo:228` → `Hovercraft.design.md`),
   `Cluster_design` (`Keeping_spec:15,330` → `Cluster_spec.md`), `MobilenoFSA_todo` (deleted outright, never shelved; the
    unannotated cite is the `Onboard_todo` heading, plus `Lagoon_todo` and `Loose_ends_todo`).  All other missing names
     (`Runner_network`, `ClusterTrust_handover`, `Lens_handover`, `Mag_spec`…) are self-documented folds or forward
      references: fine, but note **CLAUDE.md's "missing X.md is history/X.md" rule doesn't hold for deletions before
       2026-07-06**.
- ✅ **Path rot:** `Acquisition_todo`, `Vyto_todo`, `Snap_depth_todo` cited without `history/`.

### Keep as they are (audited clean)

`Coding_guide` (every mechanic re-checked), `Perf_todo`, `Composition_todo`, `Seen_split_todo`, `Story_hygiene_todo`,
 `Crew_todo`, `LinkDevice_leak_todo`, `RemoteHeist_todo`, `SoundPooling_todo`, `Trust_todo` (merged, see above), `Signed_call_todo`,
  `Peeroleum_spec`, `Presence_todo`, `Reach_todo`, `Repli_design`, `Radio_multicast_todo` ("nothing built" still true),
   `Radio_future`, `Glassbeast_todo`, `Meaningfold`, `Cello_meditation`, `Voromay_todo`, `V1_cut_todo`, `Loose_ends_todo`,
    `Everything_todo`, `Consolidation_todo` (as the queue these batches drain).
Unaudited, small: `Glass_reduction_todo`, `InkSurprise_todo`.

## 3. What seeds the Atheory-era directory

- **The core:** `Atheory_todo.md`: the load-list inventory, the A** shape, the serving-box case study, the merge organ.
- **Measured cases:** `Daemon_todo.md` §0.000 (the weight), `Perf_todo.md` §7 (re-running vs noticing change).
- **Its named twins:** `Focus_todo.md`, `Wordland_todo.md`, `Lagoon_todo.md`.
- **The bet and its laws:** `Homethink_todo.md`, `Statehome_todo.md`, `Whitehole_todo.md`, `Cstructures_todo.md` (the
   readable C** language; "what the Se wants").
- **Measuring tools:** `Electrode_todo.md`, `Verbs_todo.md`.
- **Imagination ledgers:** `Radio_future.md`, `Story_future.md`.
- **Reference, no §0 needed:** `Coding_guide.md`, `stho_primer.md`, `NOTATION.md`, `reactivity_docs.md`,
   `Hovercraft.design.md`. These suggest a `reference/` area.
