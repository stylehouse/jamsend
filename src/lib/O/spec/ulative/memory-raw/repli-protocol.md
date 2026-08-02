---
name: repli-protocol
description: the paginated streaming C** replication protocol (Repli_* in Musuation.g) + its demo Book MusuReplica
metadata: 
  node_type: memory
  type: project
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

A general **paginated streaming C** replication** protocol, built 2026-07-03 (owner co-designed it live across
 several messages). Replicates a C** of scalars + buffers from one Pier to another: you start by COMMUNICATING
  ABOUT a thing (ship a particle's head — identity + scalars — as an enWaft-shaped line fragment) then DEAL OUT
   the rest on demand; the bulk (a track's audio) is a **%Stream** child PULLED page by page.

**PRINCIPLE (owner, 2026-07-04) — this is NOT a %Good, keep it orthogonal to RPC.** The owner sees the Repli
 C** stream as a *singularity for elegant data delivery*: a replicated **landscape of a single type** (C) with
  clearly-defined frontiers | paginations and defined methods of navigating them — you WALK it, you don't `GET`
   it. `%Good`/`req:Store` is the legacy request-response RPC floor (GET /something); the stream is the elegant
    alternative and must NEVER fold into a Good. Delivery, availability (the %Sent_Tree), pagination, retirement,
     even idle-reap (a goner in the Se, §9.6) all live in the stream's OWN vocabulary — not a Good's fetch-and-
      cache. The old Radio_spec "host as a %Good" todo was DELETED on these grounds. (Principle also stated in the
       repli region header in Musuation.g + Radio_spec §5.2.)

**Where:** `Repli_*` H-methods live in `Ghost/Story/Musuation.g` `//#region repli` (deliberately NOT a new
 ghost — HMR-safe, no gen-crosswire risk while :9091-unverifiable; graduate to reality/own ghost once a 2nd
  user earns it). Demo Book **MusuReplica** in the following `//#region replica` (a `//#region crush` sits
   between them — the data-crusher folding confetti behind %stuff chunks; its %Crush_Tree STAYS hand-rolled:
    a Se D** mirrors its walk while the crush report is deliberately FLAT, so lifting it = redesigning the
     report shape). **LIVE-VERIFIED on the :9091 runner 2026-07-03; fixtures ACCEPTED 2026-07-04** (green
      caveat:0, round-drift forgiven by the w_self-round Trope Entcase).

**Wire format** (reuses `enL`/`deL` — the line primitives — NOT core enWaft/decode_wh_lines, so no Text.svelte
 edit): each fragment is enWaft-shaped lines (`ind(2d) + peels \t {objecties-json}`) but STREAMY — a partial
  UPDATE the mirror merges, not a snapshot. Decisions the owner set:
- **PULL** pagination: B's mirror sends `want id/stream/from_idx`; A answers a page.
- **Buffers ride the existing preview|stream|buffer path**, NOT base64-in-text: a buffer-bearing particle's line
   carries **`objecties.buffer = <id>`**; the bytes ride a SEPARATE `repli_page` frame tagged
    **`header.bufferid = <id>`** (per-Pier monotonic `tx.c.bufseq`). `req_unemit` sha256-verifies bytes before
     the handler. Extra unemit processing = a **`%req:awaitbuf`** under the Pier that reconciles bufferid→bytes
      and WARNS if the promised page never lands (owner: "should have all been sent together, ~150k for the
       first two 2s chunks").
- **Merge = upsert** ("each arriving C** change is a replace of itself"): o()-locate then mutate, else create —
   "like oai" — but the line carries MORE than identity, so the sender declares **`objecties.loc = [locatory key
    names]`** (the rest are merge props — "the latter half of an oai()'s args"), and **`objecties.op`** carries
     non-default intent (`dupe` = force-new, `delete` = locate+remove). The owner's "weird unicode mutation
      marker" idea → lives in objecties, not a magic key in the data.
- **The Se** ("waving C** change"): **LIFTED onto a real Selection.process 2026-07-03** (`Repli_sent_se`, the
   hand-rolled `Repli_sent_scan` deleted). One Se per library (`library.c.sent_se`, `new Selection()` via the
    IMPORT block), one STABLE `%Sent_Tree,pier:<side>,dontSnap` topD under w per side, `%Sent` D basis re-traced
     every pass. The footguns, disarmed: est_D_T's D~T throw is dodged **in place** by `tree.c.T = null` before
      each process() (organise's fresh-topD-per-pass via `Se.r()` would churn the tree's identity, which the
       witnesses/Cyto want stable); resolve() pairs old/new %Sent by `id` (unambiguity 1.0 ≥ the 0.23 threshold)
        so have/got churn is CONTINUITY — do NOT pass resolve_strict (any changed value would goner+neu every
         pass and re-offer everything); resume_X is harmless on leaf %Sents. **The resolved neus|goners ARE the
          protocol's drive**: hooks ride the LIBRARY (`library.c.repli_on_neu|repli_on_goner` — NOT w, so the
           mirror's Se runs hook-free) — a neu Record offers itself, a goner retires via `Repli_retire` (one
            op:delete line; `Repli_merge`/`Repli_recv_lines` made async so the rm is awaited). Sender's tree
             reads `rec.c.sent` (served); mirror's reads %Stream have (arrived).

**The RECO layer (built 2026-07-04, Book MusuReco LIVE-GREEN + ACCEPTED):** `Repli_recommend` — a `%Reco`
 note (by/note) is knowledge attached to the %Record (the C** IS the knowledge graph), so ONE offer
  fragment carries record + %Stream + %preview set + %Reco together (Repli_lines_of recurses children —
   free). GATE: only recommend a Record you've STARTED (≥1 transcoded chunk) — returns null refused.
    Keep notes comma-free (comma tips encode_stringies to JSON — roundtrips but ugly).
**EAGER preview→stream (same session):** `Crate_transcode_begin/release` (Crate.g) — decode a real file
 ONCE via the nav (real:1 only stamped there), full PCM on c.raw_chunks, then RELEASE the frontier into
  c.chunks slice by slice, one `%preview,seq,from,to` per span, `sc.transcoded` at the end. Serve side:
   pages are FIXED-STRIDE while transcoding (`Repli_page_ready` — full page or PARK; short page only at a
    COMPLETE record's true end, else pipelined offsets overlap and byte counts inflate); a want the
     frontier hasn't reached parks as a plain `%parked_want` particle (NOT a %req — nothing to pump);
      `Repli_serve_parked` after each release answers what the frontier passed. PAGE knob `w.c.repli_page`
       (default 2). BUG FIXED: serve's Stream line must send total=sc.nchunks (the PROMISE), not
        chunks.length (the frontier) — a mid-transcode page shrank the mirror's total and its window.
         Puller shape: windowed fire-and-forget wants (see [[transport-frames-post-do]] — round trips
          CANNOT be observed intra-beat). MusuReco: 11 beats, witnesses recommended / refused_unstarted /
           started_early / outran_then_served / complete / real_music; tracks = the first two sorted
            testsounds/ files (Cosmic C 100 chunks, Dorian D 120).
**IN-FLIGHT (2026-07-04, source ahead of fixtures — NOT green yet):** found that PAGE=10 divides 100/120
 evenly, so `complete` only ever proved the ALIGNED case — the short-final-page branch of Repli_page_ready
  (a <PAGE page at a COMPLETE record's true end) was written but never run, and that unaligned case is the
   real-world common one. FIX (compiled, unverified): PAGE=8 (trk0's last page = [96,100), 4 chunks) + the
    puller rewritten to express interest in the WHOLE remaining stream once (want per stride offset have→total,
     want-once) so the PARKING is the flow control, not a have-chasing window — converges deterministically
      (all park at beat 4, serve_parked drains along the frontier, beat 9 releases all). BLOCKED on verify:
       the runner tab begun-wedged (every Book incl MusuSkip stuck at "begun") after the HMR — needs a human
        tab reload, then run MusuReco (expect complete to fire proving the partial page) and re-record/accept.
         Until then MusuReco source (PAGE=8) is AHEAD of its accepted fixtures (PAGE=10) → will read RED.

**MusuReplica** (now 14 beats, Opt/useCyto+dontSnapCyto on): setup (Lake_link two Piers, synth 3 real-PCM
 Records + %Stream handles, Repli_arm) → OFFER = A's first Se pass finds 3 neus → each offers itself → DROP
  (rec2's page promised but bytes withheld → awaitbuf warn) → pull 5-10 (want-once cursor pages rec0/rec1;
   `rx.do()` pumps B's awaitbuf each beat) → settle → witness(12) → RETIRE(13) = A rm's rec2 → Se pass goner →
    op:delete crosses → B's mirror drops it → witness_retire(14). Witnesses: the 8 originals + `retired`
     (surgical: rec2 gone AND exactly 2 survive — this also DEFENDS the pairing: mis-pairing would retire
      everything) + 2 Se-drive %sees off hook counters (w.c.repli_neus|repli_goners). Handlers disambiguate the
       two-piers-one-w setup by `pier===w.c.tx` (A serves wants) vs `w.c.rx` (B receives lines/pages) — same
        trick as [[music-real-audio-pivot]]'s MusuBounce. **Live-verified 2026-07-03 on the :9091 runner via
         runner_ask (run @7561cca4): all 14 steps ran, every witness + %see fired, no %Sent lines in the snap
          (dontSnap folds both trees), mirror = rec0+rec1 post-retire. Fixtures ACCEPTED 2026-07-04 (inspect →
           accept → re-run green caveat:0) and REGRESSION-GREEN 14/14 caveat:0 after the reco-layer serve
            changes (@e816d81a). Also: the crush
            stamps the trees %stuff (≥3 homogeneous %Sents) and %Crush_Tree goes stale-by-design post-retire
             (crushable returns null at 2 records → the n:3 D just stops refreshing).**

**The magic-trick surface (owner flagged it 2026-07-03 — CLOSED same day by the Se lift):** 7 of the 8
 witnesses assert OBSERVABLE replication (catalog crossed, title byte-faithful, pages reassembled to the EXACT
  source sample count, drop detected) — backend-blind, green only when true. `tracked` asserts a CONTRACT (a
   `%Sent_Tree` mirror exists, have>0). The fixture-churn risk (the D-basis serialized into every NNN.snap
    churning on a behaviorally-equivalent backend) was defused by the queued `dontSnap` landing WITH the lift:
     both trees fold from got_snap (header line stays — `Sent_Tree,pier:X,dontSnap,stuff` — %Sent subtree
      folds, nodes keep pumping so `tracked` + Cyto are unhurt) → the fixture gates on the replicated Records
       (the subject).

**dontSnapCyto (BUILT 2026-07-03):** new `Opt/dontSnapCyto` toggle — a conditional action button beside
 `waitCyto` in Story `story_ui` (only posited when useCyto on; `wa.rm` sweeps it otherwise), read in
  `story_snap` to fold the whole `Snap:cytowave` channel out of got_snap while KEEPING live Cyto (scans,
   animates, gates waitCyto). Turned ON in MusuReplica's `The/Opt` (toc.snap). Not `.g` — pure Story ghost +
    fixture, HMR-safe. Next live record of MusuReplica drops the cytowave block (fixtures re-record live anyway).

**Load-bearing gotchas hit:** a bare `else` (no braces) mangles in .g → use two guarded ifs or `} else {`
 ([[g-authoring-gotchas]]); Lake_link IS symmetric so B→A wants route (MusuBounce only ever went A→B, so
  bidirectional was untested-by-precedent); the awaitbuf warn clock must count PUMPS (req.c.waited), not a
   lines-driven tick that freezes. Audio-proof (B plays its replicated copy on its own context) deliberately
    DEFERRED — the protocol, not the sound, is MusuReplica's subject. See also [[testing-is-story-books]],
     [[verify-via-live-runner]].
