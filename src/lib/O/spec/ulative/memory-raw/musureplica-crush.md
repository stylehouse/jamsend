---
name: musureplica-crush
description: "The data-crusher — Repli_crush_scan folds MANY-and-homogeneous containers behind ONE %stuff chunk (Cyto overlay ×N) + %Crush_Tree report card; verified green live 2026-07-03, fixtures owed a re-record after the human's Repli_sent_se lift"
metadata: 
  node_type: memory
  type: project
  originSessionId: f4eec47c-5092-4a7d-a304-39f88375f249
---

**The crush (2026-07-03): MusuReplica's confetti (16 emits + 16 unemits per pier side, Records, Sents) folds into ~7 readable Cyto chunks.** Two layers:

- **Generic (Cyto.svelte)**: `%stuff` node → descent suppressed + `n.c.cyto_folded` stamped + `mainkey ×N` label — see [[cyto-node-stuffings]].
- **The crusher (Musuation.g, `//#region crush`)**: `Repli_crush_scan(w)` walks w** each beat; rule = `Repli_crushable`: ANY non-structural container with ≥1 child folds ("scoop up all the C**" — user relaxed it 2026-07-04 from the first-cut ≥3-children + one-mainkey-≥80% gate) → stamp `stuff:1` + `c.stuffy` + a `Crush:<ident>,kind,n=` D under `%Crush_Tree` (hand-rolled Selection.process shape, snapped so the Book diffs it; the tree itself is stuffed at birth and never self-counted). `ident` threads name-ish keys down the walk (`DJ.Crowd.outbox`); structural mainkeys (w/H/A/Peering/Pier/req/Opt) walk through, never crush — Opt is equipment and folded as a phantom chunk until excluded. **GATED (2026-07-04) behind Book opt `crushCyto`** (toc `Opt/For/w:MusuReplica/crushCyto`; scan bails without it — the whole machinery off for every other Book). Wired in MusuReplica_drive at `n >= 2`.

**Witness = 4 `%see` claims** (step 12): traffic folds / libraries fold / dozens-into-single-digit-chunks / `cyto_folded` live-graph proof. The last one is the load-bearing test: only a real browser Cyto walk stamps it (dies headless — by design), and the kill-test (suppression disabled → step-12 red) proved it can fail.

**Verified**: full 12/12 GREEN on the live flock runner (uid 53d4a26d) with fixtures + toc diges recorded from that run. **Why:** the green run pre-dates the human's same-day `Repli_sent_se` lift (real Selection.process, `Sent_Tree,pier:<pier>,dontSnap` per side, offer-via-neu-hook; runs now go 14 steps) — **fixtures are stale against the merged code and owed one live re-record once their refactor settles**. **How to apply:** don't re-record while the human's editor is live-iterating the same Book; the crush layer itself needs no re-proving.

**RISK — the husk can MASK a dropped frame (2026-07-05, MusuReco live-diff).** The crushed `outbox,stuff`/`inbox,stuff` render their emit/unemit children through a LEAN `recent` husk — just `emit=N,type,seq`, DROPPING `body_hash`/`body_len`/`sent`/`acked`/`done`/`finished` (the gen still computes them; the husk just doesn't print them). So a frame that FAILED to ack renders IDENTICALLY to one that succeeded → the crush that tames confetti can also hide the exact "silent-success-over-dropped-work" ([[robustness-plan]] Organ 2) that a *replication* Book most needs to see. `%Crush_Tree` counts are only a PARTIAL guard (a drop changes `n`). For a Repli Book the hash IS the claim → the husk should KEEP `body_hash`+`acked` on the retained recent-window items and lean only the crushed-away tail. **DECIDE this BEFORE re-recording MusuReco** — its committed fixtures pre-date the crush reaching it (full body_hash lines vs live lean lines = the whole step-7 diff), so they're stale; re-baking now FREEZES the ack-blindness into the fixture. Also: `repli_want` bodies are `body_len=4` and all hash identical (`8656…`) — fine IF the want's target rides the header/seq not the body (confirm, don't assume).

**Gotcha discovered**: `runner_ask.mjs run --watch` bails RED after one 8s state-poll timeout, but the tab was only BUSY — see [[runner-watch-false-red]].
