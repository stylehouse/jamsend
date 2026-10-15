# Spec_tidy_todo — finishing this era's docs before the Atheory era starts

**What this is.** A read-only survey of `spec/` (148 docs, ~5.6 MB, 2026-10-15) and the owner's rulings on how to tidy it.
 The project is turning from this development era into the next one, which starts with Atheory (`Atheory_todo.md`) and
  is expected to get a new directory of specs. The tidy sorts what carries forward from what is finished history.

## 0. What to get on with next

1. ✅ **The `Tend_todo.md` name clash — resolved 2026-10-15:** the live doc was renamed `Signed_call_todo.md`. Was: the live doc (the signed-call grant design, 2026-10-13) and `history/Tend_todo.md`
    (the retired attention design) are unrelated. That breaks CLAUDE.md's "a missing spec/X.md is history/X.md" rule.
    Rename the live one when the grant's name is chosen (Tend / Operate / Steward …).
2. **Trust:** merge `Trust_audit_handover.md` + `Trust_todo.md` into one `Trust_todo.md`. Fix the stale "transport is a
    deliberate mock" lines in `Sharing_design.md` (36/94/102/122), `Frontier.md:35`, `Radio_todo.md:1916`, and the
     audit's own body below its §0.
3. **Then retire in batches, owner OK per batch** (§2). Every retirement follows §1.

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

## 2. The batches (from the survey; each needs the owner's OK)

| batch | docs | carry-forward home (scrape first) |
|---|---|---|
| Cello schemes | `Cello_universal_scheme_1..6`, `Cello_mesh_scheme`, `Cello_tree_scheme`, `Cello_meditation` | `Cello_todo` / `Cello_synthesis_todo` |
| Voro / Cytui | `Voro_todo`, `Voro_render_todo`, `Voro_render_faults_todo`, `Voro_svg_stuffing`, `Voro_vtuffing`, `Voromay_todo`, `Cytui_cleave_todo` | `Glassbeast_todo` / `Meaningfold` / `Cello_todo` |
| sweep snapshots | `Everything_todo`, `Frontier.md`, `Loose_ends_todo`, `V1_cut_todo`, `Consolidation_todo`, `Speeches_todo` | (do Consolidation's verdicts first) |
| Mag | `Mag_v1_handover`, `Mag_vs_flatstock_preen`; fold `Mag_design` into `Mag_todo` | `Mag_todo` (its §0 dates from 08-05) |
| Radio | `Radiobuddies_handover`, `Radio_lowlevel`; decide `Radio_design` vs `Radio_spec` | `Radio_todo` (§0 needs a rewrite: 305 KB, refreshed 08-24) |
| one-offs | `Download_stall_handover`, `Covenant_design` (names the deleted `Tyrant.g`) | `Heist_todo` / `Trust_todo` |
| naming | `Vyto_spec` (calls itself unpreened), `Peeroleum_handover`, `Grantwalk_handover`, `Lies_handover` | rename to `_todo` or retire |

**Also:** ~15 docs are cited that exist nowhere (live or history), e.g. `Runner_network`, `Mag_spec`, `ClusterTrust_handover`.
 Re-point or delete each citation. `Tyrant.g`, `Musuation.g` and `Mag.g` are named as live in several docs and are gone.

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
