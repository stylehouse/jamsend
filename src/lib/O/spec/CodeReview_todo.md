# CodeReview_todo

A shape audit — "where are we mechanically under pressure, not shapely enough?" — run 2026-07-27.
Method: four parallel readers (core data layer, transport `.g` family, Lies/belief pipeline, a
 repo-wide harvest of the code's own confessions) + a repo-wide sweep for the un-awaited-async
  transaction hazard. A representative citation from each reader was re-verified against live code;
   `file:line` below are real as of this date but drift, so re-grep before acting.

This is a **working doc**, not a spec. It is a map of debt, most of it debt the code already confesses
 to. Nothing here touches the display side (Story / Cyto / Vyto — mid-refactor, the human's) or
  `src/lib/gen/**` (generated).

The root finding — the transaction primitive — is written up in full in the session that produced this
 doc; the condensed version is §3 below.

## 0. What to get on with next

The through-line: **almost every finding is a symptom of two root strains** — state kept as untyped
 `.c` scratch instead of a named object (§1 theme 1), and async transactions treated as synchronous
  mutators (§1 theme 2). Fix the roots and a dozen symptoms retire with them. Candidate next moves,
   roughly in leverage order:

- **Make `replace()` serialise overlapping same-C transactions instead of throwing** (§3). This is the
   single highest-leverage move: it retires the whole un-awaited-`await` hazard class (the Peeroleum
    bug, the ~100 legacy `src/lib/ghost/*` calls, the live `Peeroleum.g:476` sibling) at the source, and
     lets the idle-gallop no-op patch retire too. It is a **core change** — prove it in isolation
      (a Book that fires two overlapping `replace()`s on one C and asserts both land in order) before
       it goes near the live tree. See [[nested-replace-in-do-fn]], [[fight-back-on-core-changes]].
- **Close the one live production sibling: `Ghost/N/Peeroleum.g:476`** — `await on(w, pier, frame)`.
   One word, but it shifts a handler into deliver's mutex window on the transport spine, so it wants a
    live-runner verify (the only runner up during this audit was wedged + stale). See §2 row 3.
- **Hoist the editor↔runner channel into one typed `%Channel`** (§2 row 2) — the ~26 `w.c.*` keys become
   its fields, greppable and initialised in one place. Biggest legibility win; no behaviour change if
    done as a pure move.
- **Fund one of the promised convergences** (§2 rows 7–8) — the "two begin-paths — converge ~mid-Jul
   2026" deadline is already past. See Human decisions.

## Human decisions (recommendation first)

- **Which convergence to fund first?** Recommend the **run-begin** paths (`req_rungo` vs
   `Lies_become_book_drive`) — it is self-flagged, overdue, and the version-gate is currently written
    twice. The transport carrier-switch convergence (Tribunal `fall` vs `redial`) is second: same
     conceptual event, opposite side effects on handshake reset, and a real wrong-behaviour consequence.
- **Is the transaction-primitive redesign (§3) worth a core change?** Recommend **yes, but gated on an
   isolation proof** — it is the root, but it is `Stuff.svelte.ts`, so it earns the highest bar.
- **Delete or gate the inert throttle machinery?** (§2 row 4) Recommend **move to `spec/history`** unless
   an A/B arm is imminent — ~60 lines + 5 tuned constants ride the hottest path behind `V.gallop = 0`.

## 1. The shape of the pressure — five recurring strains

1. **State as untyped `.c` scratch, never a named thing.** The editor↔runner channel is a ~26-key ad-hoc
    state machine on `w.c.*` (`channel_up, transport_up, no_socket_since, inbound_batch, inbound_draining,
     pending_rungo, pending_runs, …`). Same disease in the store's read machine (`good.c.content|asked_at|
      complained_at|notfound_rounds`) and in cross-*world* refs (`blatdo.c.run_done` set in `w:Pantheate`,
       read in `w:Lies`). The machine that runs "state as legible living matter" keeps its own most
        important state illegible.
2. **Async transactions treated as synchronous mutators.** `TheC`'s mutation verbs are all async and
    defend a per-instance invariant by *throwing*, so a forgotten `await` is a latent crash. A legacy-layer
     disease (~100+ un-awaited calls in `src/lib/ghost/*`, imported only by the out-of-bounds
      `src/lib/mostly/Modus.svelte`); production `.g` is clean but for one live sibling. See §3.
3. **Wall-clock timeouts standing in for signals that don't exist.** The 20s rungo give-up, the 5s inseq
    keepalive, the 1s AudioContext-resume race, the 15s no-socket note, the 200ms ledger poll. Time
     substituting for a missing event — starkest in `req_rungo`, which abandons `ttlilt` for a 150ms
      self-spin and ships `console.log('🔥 … burning CPU on unmet demand')` as its guard-rail.
4. **"Wedge" = stale liveness state.** Latches/caches that assert "up"/"valid" over dead state
    (`channel_up` over a dead channel, the FSA handle cache after a dir delete, the inseq phantom-gap),
     each healed by a reconcile-or-force-refresh hack. Catalogued in `Robustness_plan`'s numbered "Organs"
      — inventoried but unpaid.
5. **Two-paths-that-should-converge + god-functions.** Self-flagged ("Two begin-paths is a dev ugliness —
    converge ~mid-Jul 2026", a deadline now past). God-functions: `replace()` (~110 lines),
     `Peeroleum_deliver` (~10 branches + a triplicated ephemeral-type list), `req_Store` (~134 lines).

## 2. Ranked findings

Legend: **discovery** = surfaced by the audit; **known debt** = the code already flags it; **footgun** =
 a live trap. Rows 1–6, 9–10 are discoveries; 7–8 are known debt (ranking them = which to fund).

| # | Site | The pressure | Kind |
|---|------|--------------|------|
| 1 | `Stuff.svelte.ts:854` `replace()` + guard `:863/:877` | Async primitive defends its X-swap invariant by throwing; a missing `await` is a latent crash (prod too — the `:877` `X_before` throw is unconditional). God-method tangles transaction envelope with the resolve algorithm. | discovery (root) |
| 2 | `LiesLies.svelte` channel `.c.*` (~26 keys); `LiesStore` `good.c.*` | Undeclared state machines smeared across untyped scratch keys. | discovery |
| 3 | `Peeroleum.g:476` `swarm_hi` dispatch | Un-awaited async handler (crypto check + reject discarded) — the live sibling of the fixed nested-replace bug; twins at `:450`/`:590` await it. | discovery · **quick fix (verify)** |
| 4 | `Housing.svelte.ts:24` `V.gallop=0`, `:13` `V.req_legs=0` | ~60 lines + 5 A/B-tuned constants + parked req-legs machinery ride the hottest path **inert**. | discovery |
| 5 | `Stuff.svelte.ts:1083` `UNAMBIGUITY_THRESHOLD=0.23` | Every `replace()`'s identity continuity leans on a fuzzy scorer "reduced from 0.33 or it breaks LangTiles." | discovery |
| 6 | `Peeroleum.g:410` `deliver` god-fn + triplicated ephemeral list (`:382`,`:476`) | Outbox correctness rests on two hand-edited literal lists staying in lockstep — the comments name the leak if they drift. | discovery |
| 7 | begin-paths `LiesLies.svelte:1014` / `LiesFunk.svelte:1877`; Tribunal `fall`(`:251`) vs `redial`(`:295`) reset divergence | Same conceptual transition, different side effects (redial resets handshake, fall doesn't). | known debt (overdue) |
| 8 | `LiesStore.svelte:956/476/606`; `Lies_deliver_soon:984` | Four "a transient signal got treated as authoritative" band-aids (the wipe / the tailspin / the ~20% load hang / the death-spiral). | known debt |
| 9 | `Y.svelte.ts` `exactly()` | Core matcher stringifies `{k:1}` → `{k:"1"}`, silently defeating `o()`'s numeric-1 wildcard — already caused a real re-find bug (moai). | footgun |
| 10 | `Stuff.svelte.ts:773` `r()` — `r(pat,{})` means *delete* | Delete spelled as empty-merge, run through the full async resolve pipeline (O(N) reinsert) just to remove rows. | discovery |

### Supporting detail on the transport rows (reader 2)
- **Row 6 — triplicated ephemeral list.** Send side `Peeroleum.g:382-383`, deliver side `:476`, plus the
   send/book gate. The set of "ephemeral" frame types (`ack/ping/pong/run_phase/advertise/swarm_hi`) is
    hand-maintained in three places; if they drift, a type booked on send but never acked on deliver
     "piles %emit rows nothing reliably culls." Shapelier: one `Peeroleum_frame_kind(type)` classifier read
      by both `send` (to decide booking) and `deliver` (to decide dispatch), collapsing the branch cascade
       to a `switch`.
- **Row 7 — carrier switch.** Four near-identical "repoint `active_transport`" verbs
   (`activate_websocket`/`hand_to_webrtc`/`fall_to_websocket`/`redial`); the two that mean "carrier failed,
    switch" diverge — `redial` calls `Peeroleum_reset_handshake` per Pier, `fall_to_websocket` does not, so
     stale `protocol`/`outbox`/`inbox`/`%stalled` rides onto the fresh carrier after a step-paced fall.
      Shapelier: one `Tribunal_point_at(peering, type, {demote, reset})` with the four verbs as thin flag-callers.
- **Reliable-vs-lossy double dedup** `Peeroleum.g:500-545` — dedup is either "seq served, unemit present"
   (reliable, weaker — only ~20 recent items) or "seq ≤ inseq.last" (lossy, durable). Both paths share an
    identical `await inbox.do(); await rollup; feebly_ponder` tail written twice. Shapelier: model the
     reliable carrier as a degenerate inseq (never holds, always admits, still advances `last`) so there is
      ONE book→drain→rollup pipeline.
- **Per-connection state reset by hand-enumeration** `Peeroleum.g:676` — `reset_handshake` enumerates 6
   sc-children + 4 `.c` refs; a real drift bug already bit here (`buffered`/`held` "two halves of one fact").
    And it never touches Repli's per-Pier state (`pier.c.awaiting`, `pier.c.bufs`, the `%req:awaitbuf` reqs),
     which survive a mid-pull redial pointing at invalidated mirror particles. Shapelier: group live
      per-connection state under one `pier.c.conn = {...}` so reset is `pier.c.conn = fresh()`, plus a reset
       hook Repli can register into.

### Supporting detail on the pipeline rows (reader 3)
- **Row 8 band-aids** are all one shape: "a transient signal must not be treated as authoritative."
   `notfound_rounds` (two-round confirm so a transient `not_found` can't overwrite the durable snap — the
    Cluster/Keep/Library wipe), the two-pass `sc.seen` drop (the re-dispatch tailspin), the lost-dispatch
     self-heal that re-opens `req_sent` (the ~20%-on-load hang), and `Lies_deliver_soon`'s coalescer (the
      100+-todo death-spiral). Shapelier: build the `req:handle_inbound` the deliver_soon comment already
       asks for, and give reads/writes an explicit tri-state (`loading|absent|present`) instead of
        `undefined|null|string` on `good.c.content` — the two-round and two-pass hacks collapse once
         absence is a value, not a race.
- **Foreman/settle duplication.** `req_Store` (LiesStore ~134 lines, 5 phases inline), `e_Lies_compiled`
   (LiesCortex ~92 lines), and the settle signal `Lies_compile_settled` emitted from **three** sites
    (LiesCortex:142/197/295); the handoff flag `write_finished` set in two files, cleared in a third, read
     in a fourth — one flag, four drivers. Shapelier: one `Cortex_settle(path, dige)` all emitters route
      through; extract each `req_*` phase into a named sub-step.

## 3. The root: the transaction primitive (condensed)

Every child-mutation on a `C` goes through `replace(pattern_sc, fn, q)`:
`r`/`rm`/`place`/`roai`/`i_kv`/`i_wasLast`/`i_chaFrom` all funnel into it. `replace()`:
1. **Guards** (`:863`, `:877`): if a replace is already in flight on this C → throw `"nested replace()
    transactions"`. The rich dual-stack diagnostic is behind `OPTIMISE_FOR_DX` (currently a hardcoded
     `true`); the `if (this.X_before) throw` backstop at `:877` is **unconditional**, so contention is
      fatal in production too — not a dev-only assertion.
2. **Swaps** the reactive child index aside: `X_before = X`; `empty()` (`X = null; Xify()` → a fresh empty
    `X` that inherits `X_before.serial_i` so observers don't miss a beat). `X` is `$state()`, so this is
     also a reactive invalidation.
3. `partial = bo(pattern_sc)` — the matching subset, read from `X_before`.
4. `await fn()` — the caller materialises new atoms into the fresh `X`.
5. **Reconciles**: `resolve()` pairs old↔new by a fuzzy identity score (§2 row 5), `resume_X` carries each
    survivor's `C/**` across, `gone_fn` fires for the vanished; then the non-`partial` out-group is
     re-inserted in order (an O(N) index rebuild).
6. `finally`: clears `X_before`/`replace_having` and **unconditionally** `X.bump_version()` — even on the
    rollback path and even for a no-op.

Three structural problems, in order of how much they hurt:

- **It defends its invariant by aborting contenders, not by serialising them.** `X_before` is really a
   mutex, but "already locked" is spelled `throw`, not `await the lock`. Two independent async tasks that
    both `replace()` the same C — the ordinary outcome of one forgotten `await` in a loop or a sync-looking
     caller — crash instead of queueing. Because the verbs *read* synchronous (`w.r({aim:1},{})`), the
      forgotten `await` is the default mistake, not the exceptional one. **Shapelier:** a per-C promise
       tail — `this._txn_tail = (this._txn_tail ?? resolved).then(() => run())` — turns overlapping same-C
        transactions into sequential ones; a missing `await` degrades to *slower-but-correct* instead of a
         crash, and `bo()` becomes well-defined (the second txn reads the first's committed state). Keep a
          *synchronous* re-entrancy guard (a flag set before the first `await`, cleared after) that still
           throws, so genuine nested-replace-in-one-fn — already unsupported today — stays an error rather
            than a deadlock. This single change retires the whole hazard class.
- **`replace()` is a ~110-line god-method** interleaving the transaction envelope (guard / X-swap /
   rollback / bump) with the reconcile algorithm (resolve / resume_X / reinsert). You cannot reason about
    the transaction boundary without also reading the identity-matching. **Shapelier:** extract
     `withTransaction(fn)` (owns guard/X-swap/rollback/bump) and `reconcile(partial, q)` (pairs/resume/
      reinsert); the invariant becomes local to the envelope, reconcile becomes independently testable.
- **The `finally` bump is unconditional**, so a rolled-back or no-op transaction still tells watchers "I
   changed," and the House re-runs beliefs on that bump. This over-invalidation is *upstream* of a whole
    downstream throttle: the `r()` idle-gallop skip (`:805`) is a patch for it one layer out, and the
     `V.gallop` adaptive throttle (§2 row 4, now inert) was built to absorb the resulting think-loop churn.
      Pressure propagated outward from an over-eager bump. **Shapelier:** track whether `reconcile` actually
       changed the row set and bump only then; never bump on rollback. Then `r()`'s no-op skip and (much of)
        the gallop machinery can retire.

The **delete-via-empty-merge** trap (§2 row 10) sits on top of all this: `r(pat, {})` means *delete*, and
 runs the entire resolve/reinsert pipeline (async, O(N)) just to remove rows, on the hot
  `w_forgets_problems`/`_req_do_one` path. A real `rm(pattern)` that drops matches and re-indexes once,
   synchronously (there is nothing to reconcile when inserting nothing), retires both the perf cost and the
    `{}`-means-delete footgun.

## 4. Done in this pass

- Fixed the nested-replace crash the audit started from: `Peeroleum_rollup_faulty`/`Peeroleum_runstepped`
   made `async` + awaited at all sites (Ghost/N/Peeroleum.g, recompiled). See [[nested-replace-in-do-fn]].
- Fixed a stale comment: `LiesFunk.svelte:474` claimed `bytes ride base64 for now (TODO: binary frame)`;
   the binary path (`Lies_send_binary_to`, `:578-618`) is built — comment corrected.

## 5. Not audited (out of scope this pass)

- Display side: Story runner, Cyto/Cytui, Matstyle, Vyto — mid-refactor, the human's.
- `src/lib/gen/**` — generated.
- The legacy `src/lib/mostly/*` + `src/lib/ghost/*` beyond counting the un-awaited-async instances — it is
   the superseded generation; the question there is retirement, not repair.
