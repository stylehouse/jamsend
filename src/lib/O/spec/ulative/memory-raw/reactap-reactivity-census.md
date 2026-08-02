---
name: reactap-reactivity-census
description: "reactap = live reactivity census CLI (scripts/reactap.mjs) — which particles/Wafts keep bumping, with a first-sighting stack naming who bumps them; the socklog sibling for the tree"
metadata: 
  node_type: memory
  type: project
  originSessionId: 73007100-a4d3-4417-8b4f-6df411f18d6b
---

`node scripts/reactap.mjs [ms] [--runner] [--json]` asks a LIVE tab (editor by default) to arm
the `REACTAP` bump tap for a window (default 5s, cap 30s) and prints: window/thinks/bumps totals,
per-habitat (nearest Waft, else w, else root) rollup, top-60 bumpers each with path + trimmed
first-sighting stack.

Pieces: `REACTAP` + `TheX.host` backpointer in `src/lib/data/Stuff.svelte.ts` (taps ROOT-X bumps
only — the sole serial a `void C.version` subscriber sees; disarmed cost = one property read per
bump; host stamped in `Xify` and re-stamped in `resume_X`); `Lies_reactap_recv` (LiesFunk) arms +
walks X.z for the parent map + replies; editor registers `on('runner_ask')` serving ONLY
op:reactap (LiesLies editor branch); `Housing.beliefs()` counts thinks while armed.

**Why it rides the runner_ask/runner_ack corr rails**: relay.ts corr-remembers only
ghost_compile + runner_ask asks — an own frame type means a relay edit + dev-server restart.

**Editor delivery bug this uncovered (FIXED, Peeroleum.g)**: `Peeroleum_deliver` routed CLI asks
through `Peeroleum_route(w,h,'to')` then `if (!pier) return`. A CLI's `from` is an ephemeral reply
addr, never a Pier — so on the EDITOR (holds N runner Piers → `piers.find(pub===from)` misses) the
frame was DROPPED; the single-Pier runner only matched by luck via the `length===1` arm (then booked
into its inbox). Fix = dispatch `runner_ask`/`ghost_compile` by TYPE, BEFORE routing, ephemeral-style
(`on(w, null, frame)`, no inbox/ack-back). This ALSO silently broke `ghost-compile` whenever ≥2
runners were connected. PROVEN live on the runner (census still green through the new path); needs the
tab to load the new gen. `ghost-compile` is NOT a clean test of it — its `pollServed` disk-poll
false-passes if the .go on disk already matches (e.g. LocalGen wrote it); reactap has no disk
fallback, so it's the pure ack-path probe.

Editor target rides `:9092` (staging relay) not `:9091` — acks are corr-routed per-relay and do NOT
cross the r2r bridge, so the CLI must hit the same relay the target tab is bound to (`--runner`→9091,
editor→9092). See [[relay-r2r-reconnect]].

Gotchas: a tab serves the census only after it loads the code (channel-up registration); a stale/
frozen (backgrounded, Page-Lifecycle) editor tab receives the frame but never replies → CLI timeout,
looking identical to the drop bug — foreground + HARD reload to be sure. Report walk reads X.z off the
beliefs mutex (mid-replace() can mislabel a path — diagnostics-grade); `(off-tree)` = counted but
unreachable from Mundo/watch roots (e.g. %Se via Selection's many_fn).

**The finding (idle runner, 5s, repeatable)**: ~1500 root-X bumps from ONE idle beat, top stacks all
`r() → replace() → empty()` — a full empty-and-refill of EVERY world each beat, unconditionally:
w:Thangs ~372, w:Lies ~303 (+req:Store ~81), w:Auto ~72, w:Wormhole ~60, %Se ~61 (via
Selection.svelte many_fn:264, the `Se.process()` D-tree rebuild = the organise phase). This IS
Perf_todo §3 ("organise = full C-tree walk every pass, no dige gate") + lever #4 quantified, and the
root of the 30%-idle CPU. Fix = dige-gate `Se.process()`/organise (same digest-gate pattern as
DocGhostList / Lang_Map_report). [[robustness-plan]]-adjacent §5 disease; sibling of
[[socklog-scaffold]].
