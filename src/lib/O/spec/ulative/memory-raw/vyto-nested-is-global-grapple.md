---
name: vyto-nested-is-global-grapple
description: "Vyto nested render is LIVE (Vyto agent, VytoNestRest green) but w.c.nested is GLOBAL — every grapple's WHOLE subtree draws + recurses. A nested parent renders BARE (face suppressed). Heist can't flip nested blind: %Keep's %Pick children + the Heist organ's constraint/Lead/filing children would surface as stray/grey cells."
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**The nested Vyto renderer now works** (the Vyto agent, 2026-07-29): `VytoNestRest` green 3/3; `Vytui` descends
 the C** tree and paints each scope's child polys. My display side is unblocked. But nesting the Heist is
  **sourcing work with a hard constraint**, not a free flip.

**The contract (from Vyto.g / Vytui.svelte, read this before wiring):**
- `w.c.nested` is **GLOBAL** — set once on the commission (`e_Vyto_commission` reads `req.sc.nested`;
   `Vyto_commission_on(w, cogs, fresh, priced, nested, folded)` 5th arg). Sounditron builds its OWN commission
    req (`Sounditron.g` ~line 295, `new TheC({sc:{Scannable, client_w, grapples}})`) so today it never sets it.
- `Vyto_scan_walk` mirrors **every** grapple's whole subtree ALWAYS (depth 40); only a nested glass SOLVES +
   draws the children (`Vyto_solve_scope` recurses to any depth, `Vyto_express_rows` sizes every row).
- A scope PARENT (has kids that tile it) renders **BARE** — Vytui suppresses its own label + face
   (`Vytui.svelte` ~line 83). So a `%Keep` with children shows NO KeepFace; controls must move to a CHILD cell.
- **No per-source skip.** There is no `invisible`/`skip`/`system` marker on scan — a mainkey'd child is walked
   and, under nested, drawn. A faceless child renders as a labelled/grey bubble, not hidden. `.c.folded` filters
    it but is set Vyto-side on the mirror row, unreachable from the source ghost.

**Why the Heist can't flip nested blind** (the blast radius when a keep is active):
- `%Keep` has `%Pick` children (the kept-track model, `keep.o({Pick:1})` — engine reads them flat). Under
   nested they'd each draw as a grey `Pick` cell.
- The grappled `Heist` organ carries `constraint`/`Lead`/`filing` children (`Heist.g` 612/665/690) → stray cells.
- Radio/Tuner/Beat/Door/Uptime/Diag organs ARE leaves (verified) and %Stoker/%MusuThem are NOT grappled — those are safe.

**So a safe nested Heist needs a coordinated change (do it WITH a live Sounditron to verify, not blind):**
1. **Decouple the pick set** from the keep's C-children (store off `.c`/sc, or make picks live under a faced
    node) so `%Keep`'s only drawn children are faced display nodes. Touches `Heist_keep_step` pull loop +
     `Heist_keep_default_pick`/`pick_all`/`pick_none`/`pick_toggle` (all read `keep.o({Pick:1})`) — reload-
      semantics matter (picks are snapped today; a `.c` move loses them on reload, but default=whole-album re-derives).
2. **Move KeepFace controls to a `%KeepBar` child** (the Keep parent goes bare). Human's words: "one for the
    hierarchy, one for the list of tracks" ⇒ ~2-3 tidy child cells (bar + tree + list), NOT one-cell-per-track.
3. **Guard the flip**: commission nested only when a keep is active (`anyKeep`), and DROP the `{Heist:1}` organ
    grapple then (its children would draw; the %Keep cells ARE the heist UI). Flat/byte-identical when no keep.
4. **Prove in isolation first** with a Book off the `VytoNestRest` template (rest nested at done → shootable).

Deferred this session (runners were Book-only, no live Sounditron to verify the pick-decouple). See
 [[heist-keep-chooser-built]], [[verify-via-live-runner]], [[story-step-false-flags-encode]] (the Story.svelte
  encode-flag fix that rode in alongside the nested work).

**2026-07-29 — v1 SHIPPED (the ZERO-engine-risk variant — picks stay as-is, no decouple needed).** The pick
 problem dissolved once I realised the picks ARE "the list of tracks" the human wants: don't hide them, FACE
  them. Under nested, each %Keep goes bare and tessellates into a %KeepBar controls cell + one %Pick chip per
   kept track. Files: `PickFace.svelte` (chip: ✓/♪/⇊, click un-keeps via Heist_keep_pick_toggle) +
    `KeepBarFace.svelte` (genre · dest · all|none · ▶start · ✕ · fold-down progress) — BOTH registered in
     glass_faces.ts (FACE_MAINKEYS: KeepBar, Pick) + glass_kinds.ts. Engine: `Heist_keep_step` mints
      `keep.oai({KeepBar:1,dontSnap:1})` + `.c.up=keep` (idempotent; dontSnap → one pruned marker line if ever
       snapped, like `Diag,dontSnap`). Commission: `Sounditron_commission` computes keeps ONCE, drops the
        `{Heist:1}` FLOW-organ grapple when anyKeep, sets `commission.sc.nested=1` when anyKeep. Heist.go
         @5597ebc0, Sounditron.go @7a25863d.
**Why it's safe without a live keep to shoot:** (1) nested renderer PROVEN (VytoNest green 3/3, Vyto agent);
 (2) the two faces call ONLY methods KeepFace ALREADY calls live (Heist_keep_pick_toggle/all/none/start/
  set_genre/cancel · Ra_home_them · Heist_rummage_recs · post_do · top_House · radio_w) — a re-slice of a
   working face, zero new failure surface; (3) organs Radio·Tuner·Diag·Beat·Uptime·Door confirmed LEAVES in
    the REAL Sounditron 007.snap (no stray cells; Mag:shuffle sits under MusuThem, never grappled); the
     dropped-Heist organ's children NEVER draw (no-keep→nested off→flat; keep→dropped); (4) both .g compile
      clean + both faces transform clean via vite; (5) **Sounditron Book GREEN** post-change (flat path
       byte-safe). The ⇊-to-keep gesture is on RadioFace (always up), so dropping the Heist grapple loses
        nothing. NO fixture has a Keep/Pick line (keeps need a friend; Books run at 0 piers) → zero drift.
**2026-07-29 EVENING — nested is GATED OFF (it crashed) + the renderer perf is handed off.** The human: "can
 you do branchy Vyto ... seems to burn CPU then crash when we do." A focused diagnosis confirmed WHY: the
  renderer's `power_cells` is O(M²) per scope, recomputed EVERY rAF frame with ZERO memoization, and a
   whole-album keep (12-20 picks) is far over the ~12-cell budget → CPU pegged → OOM. Plus the layout never
    settles (crowd-out flicker pins the drift guard → rAF at 60fps forever) and child radii are absolute/depth-
     blind (overlap/too-small). So I **gated nested OFF**: `Sounditron_commission` now `if (anyKeep && M.c.heist_nested)
      commission.sc.nested = 1` — default unset ⇒ flat KeepFace (works, no crash). KeepBar/Pick faces stay
       registered+dormant. Flip `M.c.heist_nested` to test nested ONLY after the renderer fixes land. Also cut
        the per-beat re-stir churn: `Heist_keep_step` bumped the grappled keep ROOT every ~600ms with progress-
         only writes → re-stirred the whole glass ("adjusts every few seconds"); now bumps only when `landed`
          advances. The four renderer fixes (memoize power_cells, relative child sizing, settle-drift guard,
           per-scope ceiling) are the VYTO OWNER's — written up with exact line refs in
            **`src/lib/O/spec/Vyto_perf_todo.md`**. See [[perf-cliffs-latent]] (#1 power_cells was the flagged cliff).

**Owed:** the PIXELS/face-interaction — inherently a real-tab thing (a synthetic-keep Book + runner_shot --svg
 shows only cell polygons/idents, NOT face HTML; and needs new-file+CREDULER_GHOSTS+Credence scaffolding).
  Human live test: HARD-reload the Sounditron tab → ⇊ a friend track → the Keep cell should split into a
   KeepBar + track chips (was one flat cell). A durable `Keepnest` regression Book (synthetic keep like
    VytoNest builds a synthetic Rig, no piers needed) is the right follow-up but low marginal value over the
     above. See [[music-cluster-kickoff]] (world-named-after-Book), [[shared-runner-bleed]] (49dee91d shared —
      came back on Peeroleum after reload).
