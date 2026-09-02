# Consolidation_todo — spec/ audit (2026-09-02)

A READ-ONLY consolidation audit of the `~40` `*_todo.md` docs that accumulated over the last
 hectic week, EXCLUDING the ceremony/addressing cluster owned by another agent
  (`Ceremony_*`, `ClusterAddressing_todo`, `Reach_todo`, `Presence_todo`, `Division_todo` — SKIPPED).
   *[2026-09-03: that cluster consolidated itself — `Crew_todo.md` absorbed CrewLink/Division/Ferry/
    Ferry_rebuild/Inv_ferry, all now `spec/history/`.]*

Verdicts follow the repo convention (CLAUDE.md → "Docs: specs, todos, and the history/ shelf"):
 retiring means moving the WHOLE file into `spec/history/` with a prepended historicity notice
  (no forwarding stub); only the HUMAN promotes a doc to `_spec`. **This doc changes nothing** —
   it is a proposal for the human to approve.

Verdict key: **LIVE** (still a working doc) · **LANDED** (work done, safe to retire) ·
 **SUPERSEDED** (a later doc replaced it — named) · **EXPLORATORY/DUP** (parallel brainstorm; which won).

---

## The Cello scheme-variant sprawl (the headline finding)

Eleven Cello docs exist. They are **one built renderer + one design tournament of 8 strikes +
 a meditation + a judge**. The tournament is CLOSED — do not treat the 8 strikes as live todos.

| Doc | Verdict | Reason |
|---|---|---|
| `Cello_todo.md` | **LIVE** | The ACTUAL third renderer — BUILT AND LIVE, owner-approved (`Cello.svelte`/`Cellui.svelte`/`cello_blob.ts`, boot-green). This is the keeper; open work is the durable-refusal wire. |
| `Cello_synthesis_todo.md` | **LIVE (the verdict doc)** | Task #42 judge over the 8 strikes. Names the winner: render the **RESIDUAL (prediction error)** as a **LENS**, not a 9th scheme. This is the one design doc worth keeping from the tournament — it supersedes the 8 strikes below. |
| `Cello_meditation_todo.md` | **EXPLORATORY** | The launch of the dialectic (the "five beings"); its hinge (compress by SURPRISE) was absorbed into `Cello_synthesis`. Retire once synthesis is blessed. |
| `Cello_mesh_scheme_todo.md` | **EXPLORATORY/DUP** | Strike (field/decodable texture). Survived farthest per synthesis (§R.6 names Mesh as the template to wear the lens on) — worth keeping as an appendix reference, else retire. |
| `Cello_tree_scheme_todo.md` | **EXPLORATORY/DUP** | Strike (bracket/nesting). Design-only, no code. Superseded by synthesis verdict. |
| `Cello_universal_scheme_1_todo.md` | **EXPLORATORY/DUP** | Strike ("snap IS the rendering", scored column). Design-only. |
| `Cello_universal_scheme_2_todo.md` | **EXPLORATORY/DUP** | Strike (fibre-band field). Design-only. Synthesis (§R.6) also flags scheme-2 as a lens-carrier candidate. |
| `Cello_universal_scheme_3_todo.md` | **EXPLORATORY/DUP** | Strike (The Weave / fibre strip). Design-only. |
| `Cello_universal_scheme_4_todo.md` | **EXPLORATORY/DUP** | Strike (fibre-bundle reading). Design "COMPLETE", no code. |
| `Cello_universal_scheme_5_todo.md` | **EXPLORATORY/DUP** | Strike (snap as living score / staff). Design-only. |
| `Cello_universal_scheme_6_todo.md` | **EXPLORATORY/DUP** | Strike (Woven Membrane textile). Design-only, open questions unanswered. |

**Which one won:** none of the 8 strikes won as a scheme. The tournament's OUTPUT is the
 **residual lens** (in `Cello_synthesis`), realised in `InkSurprise_todo` (see below). Recommendation:
  KEEP `Cello_todo` (built) + `Cello_synthesis` (verdict). The 8 strikes + `Cello_meditation` are a
   closed brainstorm — retire the 8 strikes + meditation together to `history/` as one batch, OR fold
    a one-paragraph pointer to each into `Cello_synthesis` first. Mesh (and maybe scheme-2) may be
     worth keeping as named appendices since synthesis points back at them as lens-carriers.

---

## Full audit table (non-Cello, in-scope)

| Doc | Verdict | One-line reason |
|---|---|---|
| `Arrival_todo.md` | **LIVE** | Toplevel arrival state machine; "LIVE CONFIRMED" but multiple live-test items still open (Crew ceremony, eed wedge). Actively worked; adjacent to the skipped ceremony cluster. |
| `Onboard_todo.md` | **SUPERSEDED** by `Onboarding_todo.md` | 2026-07-22 first-run funnel doc; mostly LANDED (invite/FSA-warning/funnel-into-glass all done). The 2026-08-31 `Onboarding_todo` re-owns the same boot→share→name→link arc with current state. Overlap is heavy; retire the old one. **Note the cross-ref debt:** `Portability_*`, `Solo_todo`, `Sharing_design` still cite `Onboard_todo` as the funnel owner — flip those to `Onboarding_todo` when retiring. |
| `Onboarding_todo.md` | **LIVE** | Current first-run funnel doc (§0 has a live, PAUSED, greenlit-in-order plan). Keeper of the arc. |
| `Ferry_todo.md` | **RETIRED 2026-09-03** | Absorbed into `Crew_todo.md` (the owner-called crew-cluster consolidation); now `spec/history/`. |
| `Ferry_rebuild_todo.md` | **RETIRED 2026-09-03** | Absorbed into `Crew_todo.md`; now `spec/history/`. |
| `Inv_ferry_todo.md` | **RETIRED 2026-09-03** | Absorbed into `Crew_todo.md` (§6/§7); now `spec/history/`. `Network_procedures_todo` remains its parent recipe. |
| `Statemap_todo.md` | **LIVE** | Map of account/ceremony/surface state + push to predictable structure. §0 sibling-sync gap open. Companion to `Arrival`/`Statehome`. |
| `Statehome_todo.md` | **LIVE** | The LAW ("where a datum lives, and why" — `.c` vs `.sc`/particle). Mostly-read grounding doc; several items LANDED (`%Focus`, `%Owed`, `%Body` caveat) but it's canon-in-progress, candidate `_spec`. Keep. |
| `Networky_directions_todo.md` | **LIVE** | The one-bet transport arc (split data plane from control plane); explicitly a working `_todo` stating an arc, delegating detail to `Backpressure_todo`/`Cluster_spec`. Keep. |
| `Network_procedures_todo.md` | **LIVE** | Builder-facing recipe for multi-party features (extracted from the ferry pain); explicitly not self-promoted, candidate `_spec`. Parent of `Inv_ferry`. Keep. |
| `Repli_idspace_todo.md` | **LANDED (near-retirable)** | `repli_no_idspace` BUILT end-to-end, knob-gated default-OFF, boot-green, MusuHeist 2× green. Only residue: live-tab verify + flip-on. Nobody else references it. Once the owner flips it on and confirms, retire; until then keep as a thin open item. |
| `Everything_todo.md` | **LANDED/SNAPSHOT** | Self-declares "a snapshot, not canon" — a cross-spec sweep dated 2026-07-27/29. It is an INDEX of other docs' state, now ~5 weeks stale. Retire to `history/` (its content is a dated triage, not a working thread). |
| `InkSurprise_todo.md` | **LIVE** | The population renderer — the CONTINUOUS-FIELD realisation of the residual lens from `Cello_synthesis`. Prototype live at `/ink/islands`. This is where the Cello tournament's verdict actually lands in code. Keep; it is the successor thread to the 8 strikes. |
| `SoundPooling_todo.md` | **LIVE** | The OPFS pool (press + reach); data LANDED 2026-08-30/09-02, cells Book-gated. §0.5 Reach chapter delegates the cross-body primitive to the skipped `Reach_todo`. Keep. |
| `Radio_todo.md` | **LIVE** | Explicitly THE one living doc for the main conceptual spring (music-piracy cluster). 300KB, actively handed-over (latest 2026-08-24). Never retire; it's the destination doc. |
| `Homethink_todo.md` | **LIVE** | The toplevel posture ("the one bet"). Mostly-read, candidate `_spec` (not self-promoted). Referenced by CLAUDE.md as the place to stand. Keep. |

---

## Retire to history/ NOW (human to approve)

Highest-confidence, lowest-risk first:

1. **`Onboard_todo.md`** — SUPERSEDED by `Onboarding_todo.md`; work mostly LANDED. ⚠ Before/at retire,
    repoint the 4 external cites (`Portability_doc`, `Portability_todo`, `Solo_todo`, `Sharing_design`)
     from `Onboard_todo` → `Onboarding_todo`.
2. **`Everything_todo.md`** — self-declared stale snapshot/index (2026-07-27/29), superseded by the
    living per-subsystem docs it points at.
3. **The 8 Cello strikes + the meditation** (`Cello_universal_scheme_1..6`, `Cello_tree_scheme`,
    `Cello_mesh_scheme`, `Cello_meditation`) — closed design tournament; verdict lives in
     `Cello_synthesis` and code lives in `Cello_todo`/`InkSurprise`. Retire as ONE batch.
      *Caveat:* consider keeping `Cello_mesh_scheme` (and possibly `_scheme_2`) since `Cello_synthesis`
       §R.6 names them as the templates to wear the residual lens on — or fold a one-line pointer to
        each into `Cello_synthesis` before retiring, so the winner-doc is self-contained.

**Near-retirable, hold one beat:** `Repli_idspace_todo` — retire once the owner flips the knob on a
 live tab and confirms (only residue is that verify).

**Do NOT retire** (all LIVE with open threads): `Arrival`, `Onboarding`, `Ferry`, `Ferry_rebuild`,
 `Inv_ferry`, `Statemap`, `Statehome`, `Networky_directions`, `Network_procedures`, `InkSurprise`,
  `SoundPooling`, `Radio`, `Homethink`, `Cello`, `Cello_synthesis`.

---

## Direct contradictions / tensions noticed between docs

- **Onboard vs Onboarding own the SAME arc.** Both claim the first-run funnel. External docs still
   cite the OLDER (`Onboard_todo`) as owner while the newer (`Onboarding_todo`) is the current plan —
    a reader following the cites lands on stale state. Resolve by retiring `Onboard_todo` + repointing.
- **The Cello tournament has no single winning scheme, but three docs imply theirs is "the" third
   renderer.** `Cello_tree_scheme`, `Cello_universal_scheme_2`, and `Cello_todo` each open by calling
    themselves/their sibling "the third renderer / third projection / third visual language." Only
     `Cello_todo` is built; the schemes are strikes. The synthesis verdict (residual LENS, not a
      scheme) resolves this but is not cross-linked FROM the strikes — a reader opening any strike
       cold won't know the tournament closed. (Fix belongs in the retire notices.)
- **`InkSurprise` and `Cello_synthesis` agree** (ink ∝ surprise, the residual lens) — no contradiction,
   but they are two docs for one idea (verdict + field-realisation). Fine to keep both; just note
    `InkSurprise` is the code-bearing successor and `Cello_synthesis` the rationale.
- **`Networky_directions` explicitly demotes its own audits' "keystone."** Not a cross-doc
   contradiction, but a live reversal a fresh reader must catch: the three audits' item-2 (move bulk
    onto WebRTC) is downgraded by the human's NZ-residential reality check to OPPORTUNISTIC-only. Any
     doc still treating WebRTC-bulk as the keystone is stale against this.

---

## 0. What to get on with next (for the human)

- Approve/deny the three retire batches above (Onboard, Everything, the 8 Cello strikes+meditation).
- Decide the Cello mesh/scheme-2 keep-or-fold question before batch-retiring the strikes.
- Bless `Cello_synthesis`, `Homethink`, `Statehome`, `Network_procedures` toward `_spec` if/when preened
   (all four are self-flagged candidates, none self-promoted).
- Flip `repli_no_idspace_on` on a live tab so `Repli_idspace_todo` can retire.
