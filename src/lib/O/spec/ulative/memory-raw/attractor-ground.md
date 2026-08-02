---
name: attractor-ground
description: "the ATTRACTOR GROUND (2026-07-17, Cytui.svelte): the render dev-ground/competition housing — KNOBS (vknob(name,def), live $state overrides, stash Cyto_knobs, rail --face=knob:name=value / --face=knobs), MOMENTS (named face+knob snapshots, --face=moment_save/load/list/drop:name, stash Cyto_moments), FACES ($state vsub_face tuples|star|phi — faces ADD never replace; buried faces revive off spec/voro_modes/README.md). Design doc = spec/Attractor_todo.md (knob table lives there). The human's frame: 'a massive development ground... part of a programming competition to build the new attractor'"
metadata: 
  node_type: memory
  type: project
  originSessionId: 12f2682d-1c3e-4f5e-ba2c-7e09ee65b139
---

**The Attractor Ground** — the human's rearchitecture ask (2026-07-17): "there's a bunch of lovely
 moments we've passed by that I'd love to be able to just reconfigure back to, instead of constantly
  burying whatever... rearchitect so this can become a massive development ground, not a particular
   little mode of this. it's going to be part of a programming competition to build the new attractor."

**The inversion: variants become DATA, not code replacements.** Three primitives in Cytui.svelte:
- **Knobs**: `vknob(name, def)` — registry `vknob_defs` + live `vknobs` $state overrides; persisted
   `sts.Cyto_knobs`; set over the face op rail `--face=knob:phi.pitch=20`, list `--face=knobs`.
    Adding a knob = reading it at the call site. Read ONCE per function into a local (hot paint paths).
- **Moments**: named `{face, knobs}` snapshots in `sts.Cyto_moments`; rails `--face=moment_save:name`
   / `moment_load` / `moment_list` / `moment_drop`. The "reconfigure back to" — no git archaeology.
- **Faces**: registry frame — a face is a builder (cells, Vtuffing descs, knobs) → layers; the harness
   owns data + geometry helpers + paint plumbing. Competition entrants ADD faces.

**Why:** every prior variant OVERWROTE the last (the voro_modes ledger of commit anchors = a
 graveyard). Knob-space + moments make the lovely moments recoverable live.

**How to apply:** knob table + rails + not-built list = `spec/Attractor_todo.md`. New tunables MUST be
 knobs, not consts. ϕ v2 rides this (see [[tuples-face-snap-notation]]): off-screen pole, C-block
  claims, stable pathids (the post-drag blink was global-seq pathids recreating every DOM node),
   hysteresis `phi_prev`, gap-determines-size text maxing, title = vsub_grab handle. Crater why-not
    telemetry (`crater: {ok, small, header, geo, nofold}` on the vsub vlog) answers "why is a
     subcell sometimes missing" — the gates are size-gated + size is entropic; gates are knobs now.
