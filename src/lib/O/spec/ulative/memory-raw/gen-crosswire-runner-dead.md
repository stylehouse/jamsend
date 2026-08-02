---
name: gen-crosswire-runner-dead
description: "every runner \"relay down\"/no ws dial while the editor is green = suspect a cross-wired gen/N/Tribunal.go (another ghost's compile output under Tribunal's Ghostmeta); Creduler \"ready\" does NOT prove the right methods deposited"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7c5e219e-263f-4fd3-a50f-4a89b3394618
---

2026-07-03: every runner (plain `?I=` and `&remoteWormhole=1`) sat "relay down" and never even
 attempted the `/relay` websocket. Root cause: `src/lib/gen/N/Tribunal.go` was byte-identical to
  `Peeroleum.go` except the Ghostmeta name — Peeroleum's compile output written to Tribunal's gen
   path (came in with commit 9491c518). So Creduler read "12 ghost(s) live" (Ghostmeta answers a
    dige) but `Socket_real` was never deposited, and `Lies_channel_up`'s guard returned silently
     forever. The editor stayed green because it rides the frozen `p2p/pinned_stable/` copy — that
      asymmetry (editor green, ALL runners down) IS the tell.

**Why:** "Creduler ready" only proves each `Ghostmeta_<name>` method answers — the compiler stamps
 the requested path's Ghostmeta onto whatever body it was handed, so a cross-wire passes every
  existing gate. The upstream cause (UNCAUGHT): the editor's ghost-compile round pairing one dock's
   text with another's gen_path — suspect the compile-source-as-param seam ([[lakerace-compiler-fast]]).

**How to apply:** full ladder + stack map in `src/lib/O/spec/Cluster_spec.md` §3.3 (Runner_network.md folded there + deleted 2026-07-06). Short form:
 `grep -c Socket_real src/lib/gen/N/Tribunal.go` (≥3 healthy, 1 = cross-wired); duplicate-dige sweep
  across `gen/**/*.go`; recompile via LocalGen ([[localgen-browserless-compile]]) — HMR re-deposits
   into live tabs, no reload needed. Also that session: `Lies_channel_up`'s standup moved to the TOP
    of `LiesPersist` (connection must not wait on disk — a remoteWormhole runner's disk IS the
     channel, [[remotewormhole-mutex-deadlock]]); the missing-Socket_real guard now rings the Relay
      Brink after a 15s grace; OPEN: `LiesStore_land_good` lands a `{error}` reply as content `''`
       (a broken disk reads as empty files — the "Waft:Cluster empty" registry lie). See also
        [[runner-wedge-begun]] (the adjacent tab-level wedge, different mechanism).
