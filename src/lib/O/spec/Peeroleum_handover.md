# Peeroleum handover

The living checklist for retiring `Peerily`/`MachPeerily` and growing `Peeroleum` against
`Peeroleum_spec.md`. Each heading is meant to shrink as it is solved. This file is the memory the
work would otherwise re-type into each session — keep it current, correct anything stale.

Notation: `[x]` done · `[~]` started/scaffolded · `[ ]` not begun · `// <` a deliberate hole.

**Two-frequency pair (read before editing either).** This is the HIGH-frequency half: live status,
proofs, next moves, bombs, and the forward look — it changes every session. `Peeroleum_spec.md` is the
LOW-frequency half: the settled design of the "linoleum floor" (particle layouts, frame envelope,
lifecycle, handshake-as-`%req`, the realised relay topology §5). **Rule of thumb:** "how the floor IS
designed, settled" → spec; "what's DONE / BROKEN / NEXT / proven-at-step-N" → here. When something here
settles into design, promote it to the spec and leave a one-line gravestone — no silent caps. (Several
engine-facts, the heading-10 settled design, and the §7/§8 lifecycle bombs were promoted this pass.)

---

## Status — start here

**This session — PereProof step 31 (`corrupt_redial`) + the `%see` assertion doctrine.** Two things landed,
 one of them a way-of-working the next instance MUST adopt:
- **The braid (step 31, `Lake_corrupt_redial_arm` in `Peregrination.g`): corruption DURING a re-dial** — the
   first of the three "NOT yet braided" items below. It composes `reset ∘ verify ∘ ordering`: fresh lossy link
    Cyn/Dax, deliver s1 (cursor→s1), gap-buffer s3/s4 with s2 MISSING, `Peeroleum_reset_handshake(DaxPier)`
     (clears `c.held` + `c.inseq.buffered`, keeps `%Ud` + cursor `last`), then **re-supply s2 CORRUPT** (bad
      `body_hash` → sha256 verify faults, burns its slot), then s3/s4 good → the tail drains exactly once. Proves
       a corruption arriving mid-reconnect **faults cleanly** instead of getting lost in the reset.
- **The assertion doctrine — `%see:'sentence'`, NOT `%witnessed:step_N` (going forward).** The human dislikes the
   witness (`Lake_witness`/`%witnessed:step_N`): flat latches accreting *inside* the gated snap, opaque (`step_29`
    means nothing without its `.g` comment), redundant with the real gate. **The existing `%witnessed:*` stay
     (they're the recorded gate for steps 2–30 — do NOT churn them).** New assertions are authored as a legible
      lens ON TOP of the snap:
    - `%see:'sentence'` = **once-noticed** — a readable assertion emitted ONCE, the first pass a truth holds
       (idempotent, never re-fires). The meaning is in the sentence, so a run reads back as a transcript of what
        it proved. Bare `i %see:'…'` in a `Lake_*(w)` method compiles to `w.i({see:'…'})` → it rides the step
         snap. NO commas/semicolons in the sentence (the peel parser splits on them) — use an em-dash, as in
          `Tyrant.g`'s `w i %see:'y Tyrant — yyyyar!'`.
    - the rest of the live state = **just an ordinary particle carrying whatever fields that test needs**,
       reconciled each pass. There is NO fixed `%some`/`%kind`/`%state` vocabulary — those were the human rattling
        off examples; do not reify them as real keys.
    - **Why:** a targeted, self-describing assertion on top of the ocean beats confetti inside it; the snap-fixture
       diff (the **ocean**) stays the gate AND the place to notice un-asserted detail.
   Step 31's assertion is a new `Lake_proof_see(w)`, polled BESIDE `Lake_proof_witness` (the 2–30 gate untouched).
    It emits `see:corrupt mid-re-dial frame faulted not lost — good tail recovered` onto `w` once all five
     conditions hold. `%see` lands on the test world (no transient-status `%see` there → no blur).
- **Verified headless: CredRunner `match: 31/31, surprises: []`** (`BOOK=PereProof node_modules/.bin/vitest run
   -c scripts/Story_cli.vitest.config.mjs scripts/CredRunner.spec.ts`); LocalGen compile clean. The exact-vs-
    forgiven split (e.g. `forgiven: [21,31]`) is just `self,round` munge noise and varies run-to-run — only
     `match: N/N, surprises: []` is the gate.
- **COMMITTED** (host committed it between sessions, `ef3bfaee` + the `.g`/gen/`toc` changes): `Peregrination.g`,
   `src/lib/gen/Story/Peregrination.go`, `wormhole/Story/PereProof/{toc,031}.snap` are all in HEAD and consistent
    (the committed gen carries the `%see` sentence). No loose step-31 state to re-record.
- **`ghost-compile` may still be owed for a LIVE :9091 runner.** The gen `.go` is committed (a fresh boot picks it
   up), but a long-lived runner that was up before the commit needs `npm run ghost-compile -- Ghost/Story/
    Peregrination.g` (editor open on :9091) to HMR the new gen in.
- **RECORDING-A-NEW-STEP GOTCHA (cost a churn-revert this session — read before adding any step):** CredRunner
   `ACCEPT=1` re-records ALL steps — it rewrites every fixture's volatile `self,round` field AND writes the RAW
    per-Step dige into `toc.snap`, which DIFFERS from the committed CANONICAL diges → it silently CORRUPTS the
     2–30 gate with a 30-file diff. The gate forgives by **munge-matching the FIXTURE FILE** (the `{"mung":["age"]}`
      tag on `self,round`), NOT by the toc dige. So to add ONE step, never ACCEPT — instead: (1) append the
       `step=N,dige:…` line to `toc.snap`; (2) run a plain CHECK run; (3) copy `/tmp/Story_cli/<Book>/0NN.got.snap`
        → `wormhole/Story/<Book>/0NN.snap`; (4) read that Step's dige out of `/tmp/Story_cli/<Book>/wstory.json`
         (`node -e` — `python3` is not in the container) and set it in the toc line. Then a CHECK run shows N/N.

**This session — the swarm refactor: ONE `w:PereStaple`, Peering+Pier as typed serial-reqs.** The test's
 per-peer `A:<Name>/w:Peeroleum` worlds are GONE; every node now lives under the ONE test world `w:PereStaple` as a
  `%Peering,name,req` (a typed serial-req, new do_fn **`req_Peering`**) holding its one `%Pier,pub,req` and
   its OWN mock carrier on the Peering's `%active_transport`. This is the production shape — a node owns many
    per-remote channels — forced into the test. **The carrier-merge fear that kept Alice/Bob separate was
     moot:** inbox/outbox/seq/inseq already lived on the Pier; only the carrier + the one-Pier-per-`w` lookup
      were `w`-bound, and both move cleanly. (Supersedes `[[aw-req-level-uniformity]]`'s "keep Alice/Bob
       separate" for PereStaple, and the per-side structure described in headings 2/3 + "How the loop works".)
- **Spine (`Peeroleum.g`): two routing primitives.** `Peeroleum_route(w, h, mine)` resolves `{peering, pier}`
   by identity (`from`→Peering on send, `to`→Peering on deliver; the OTHER end = the Pier's `pub`);
    `Peeroleum_carrier(peering, w)` reads the Peering's own carrier, falling back to the `w`-level one. **ONE
     Peering ⇒ short-circuit** (`peerings.length===1` → use it), so a single-identity `w` — production's live
      channel, Tyrant, the Relay Brink that reads `active_transport` off `w` — is BEHAVIOUR-IDENTICAL.
       `send`/`deliver`/`retx_sweep` route through these; `retx_policy` moved per-Peering (the stall test
        tightens just Kim's link); `retx_tick` + the consumer `on` registry stay per-`w` (shared, fine).
- **The level-uniform cascade (the real payoff).** With Peering a req, `w:PereStaple.do()` pumps each Peering
   (`req_Peering`) → each Pier (`req_Pier`) → the handshake — the ambient reqdo_sweep reaches the WHOLE flock
    from ONE entry at `w`, so heading 3's "re-pump MUST live in the wrangler, below reqdo's w-reach" is
     SUPERSEDED. `Lake_pump_handshakes` is KEPT (belt-and-braces, pumps each Peering) but is no longer the only
      driver. **`oai` wires `Peering.c.up=w` and `Pier.c.up=Peering`** — the hand-stamped `.c.up` is gone.
- **The Book (`Peregrination.g`) reads clean.** A peer is `Lake_peer(w,name,pub)`; a link is `Lake_link(w,a,b)`
   (the whole of "two peers talking"). The ~30-line per-side `A:/w:/Peering/c.up/transport/arm/pair` boilerplate
    the human flagged collapses to ONE line per step. The whittle arms ONCE on `w:PereStaple` (its sweep iterates
     every Peering, so heal/stall peers added at later steps are swept with no re-arm — and no per-pair arm-lag).
   **GOTCHA (bit me — empty `w`, no handler, no error):** the per-beat Book handler is dispatched BY THE W-NAME
    (`Story`↔`w:Story`, `PereStaple`↔`w:PereStaple`), so the test world MUST stay named `PereStaple` — renaming it
     to `w:Peers` made the machinery look for a nonexistent `Peers(A,w)` and the whole Book silently never ran. The
      peer flocks just mount INSIDE `w:PereStaple` (the human: indifferent now that peers are reqs). A *different*
       `w:*` earns its keep only for stuff that thinks at a DIFFERENT cadence (its own heartbeat entry — see [[aw-req-level-uniformity]]).
- **Blast radius held to 3 `.g` files.** `Reliable.g` untouched (the lossy partner delegates to the wrapped
   port's `recv`). `Tribunal.g`: the six TEST trial fns (PeerJS/Socket/pair/hand/fall/reputation) take a Peering;
    production `Socket_real`/`Tribunal_activate_websocket` stay on `w`. **No Lies / svelte / Relay-Brink edits.**
- **Status: PROVEN GREEN on :9091 (Peregrination.go @ 349080831f4af54d).** One run witnessed the WHOLE arc —
   `req:handshake,finished` + `Ud` both Piers, hello+trust said/acked/heard both ways, `got_binary` (no `faulty`),
    and all eight `witnessed:step_2,step_3,step_4,step_5,step_6,send_binary,heal,stall` (heal = ivy noop dropped→retx→jon;
     stall = kim noop blackholed→`%stalled,reason:no-ack` latched). Clean: one `w:PereStaple`, six Peering/Pier flocks,
      no per-side actors, no `seemingly`/`p2paddy` cruft. **Two debug rounds got here:** (1) renaming the test world
       `w:PereStaple`→`w:Peers` broke the per-beat handler dispatch (it keys on the **w-NAME** — see the GOTCHA above);
        (2) the REAL pairing bug — `Lake_peer` was AUTO-ASYNC'd by the mock-port closure's `await`, so it returned a
         Promise and `Lake_link` used it un-awaited → `Lake_port(Promise)` threw → the link never paired → mock never
          carried (c.up was a red herring; fix = `await` the cascade, see [[g-authoring-gotchas]] #5). **NEXT: Accept/
           Resnapture steps 2–15** to lock the new snaps as the regression gate.

**Proven in-app, rungs 0–4 (clean quiescent snap, no timeout):** the Creduler acquires the live spine
(`Ghost/N/Peeroleum.g` + `Ghost/N/Tribunal.g`) before the Story begins; the mock transport carries frames
A↔B (heading 2); and at **step 3 the full hello+trust handshake completes** — both Piers
`%req:handshake,finished` (all four leaves), `protocol/{hello,trust}/{said,heard}`, `%Ud,pubkey`,
inbox/outbox pairs, `%witnessed:step_3`. **Heading 4 (full outbox/inbox lifecycle + acks + whittle) is
PROVEN in-app at step 3** — monotone seq (noop=1/hello=2/trust=3 on Alice, hello=1/trust=2 on Bob), every
`%outbox/emit,sent,acked` + `protocol/%said,acked`, inbox `%unemit,verified,done,to:<type>`, the step-2
noop culled to `%recent`, no `%faulty`. (Mechanism is in spec §7/§8 now.) **Standing ask: record the diges
(Accept/Resnapture)** to make these a regression gate.

**Gate status (current):** `toc.snap` runs `step,step=2..15`, and a green :9091 run witnesses the WHOLE arc —
`witnessed:step_2..6` (mock carrier → handshake → trial → `reputation:good`), `send_binary` (step 7),
`heal` (step 8, transient loss), `stall` (step 11, permanent loss); steps 9-10/12-15 are the heal/stall settle.
**Standing ask: Accept/Resnapture steps 2–15** (the recorded `0NN.snap` diges are the regression gate; 011–015
land this session). **Reload the runner before recording** — a long-lived runner can keep a stale cached gen
after a ghost-compile (it bit the stall run once; the committed gen reproduces the same snaps).

**This session — the delivery path went async all the way.** `Peeroleum_pump_inbox` is now an async serial
drain, `Peeroleum_deliver` + carrier `recv` await it, and the body digest is `crypto.subtle` **sha256**
(was a sync FNV hack that only existed to keep the inbox synchronous). The sha256 makes `body_hash` signable
(trust layer). All three `.g` compile clean, gen `.go` regenerated, and the Story driver boots+runs to
completion headless — but **PereStartuppity's headless fixtures are blank right now**, so the dige gate can't
confirm it; verify on **:9091**. Spec §4.2 + §7.3 updated. The endorsed next move — folding the inbox into the
`%req` engine (`%req:unemit` drained by `inbox.do()`, `Peeroleum_pump_inbox` deleted) — is now **BUILT in `.g`
source, compile-verified, with regen/refreeze HELD** so it doesn't disturb the live reconnect check; see heading 4.

**This session — the Pier flock + key naming.** A `%Pier` is now a *typed serial-req*: `%Pier,pub:…,req:N`,
 minted `oai Pier,$pub,req`, pumped by **`req_Pier`** when its `Peering.do()`s (the Lake/Tyrant wranglers
  route through `peering.do()` now, not each Pier directly). Two enabling core lines: `do_fn_for` dispatches
   a typed serial-req by its **mainkey** (the serial req value can't name a method → `req_Pier`), and `oai`
    fires the req machine on a non-first `req:1` serialise-sentinel too (mainkey stays the type → still
     queryable; identity locally-minted ⇒ no remote gut-swap). `publicKey`→**`pubkey`** in the hello/`%Ud`
      (the full key; `pub` is a prefix of it); the spec-only `prepub`/`prepri` (never built) are dropped for
       `pub`/`pubkey`/`prikey`. **All `.g` compile-clean** (headless gate: `scripts/FlockCompile.spec.ts`);
        the handshake/trust BEHAVIOUR *through* the flock is **now :9091-PROVEN** — every PereStaple run shows
         `Pier,pub:…,req=2,ok` + `req:handshake,finished` (all four leaves) on both peers. Design:
          `Hovercraft.design.md` (dispatch ladder) + `Peeroleum_spec.md` §6/§11.3 (the Pier flock).

**This session — network-healing + the reliability arc** (full state: [[peeroleum-reliability-arc]]). Reliability is
 **absence-handling**, an ambient-sweep job — and `%outbox/emit` is a retransmit queue with no retransmitter yet.
  Build order: adversarial carrier + logical clock → inbound seq discipline → retransmit → spine liveness → Tribunal
   fallback. **LANDED, non-pinned (both roles, no re-pin):** `LiesLies` liveness split into `Lies_keepalive` —
    frame-agnostic (`Lies_heard` stamps `last_heard` on EVERY consumer frame, not just ping) + three-state
     LIVE/SLUGGISH/DEAD (reconnect ONLY on DEAD; supersedes the old binary >20s in heading 8) on an INDEPENDENT
      `setInterval` (liveness must not ride think); `relay.ts` keepalive now pings the outbound `peerLink` bridge
       (was `wss.clients`-only). **LANDED, pure+headless:** `src/lib/O/peeroleum_lossy.ts` (adversarial carrier;
        drop/dup/delay-reorder, logical-tick clock; `scripts/LossyCarrier.spec.ts` 5/5) + `peeroleum_inseq.ts`
         (per-Pier dedup + gap-buffer; `scripts/InSeq.spec.ts` 6/6).
- **FOLDED .ts → .g (this session, per the human's doctrine — see below).** The three pure `.ts` primitives +
   their specs are DELETED; their logic now lives as House methods in ONE focused ghost, three regions:
  - **`Ghost/N/Reliable.g`** — the network-healing floor: `inseq_admit` (inbound seq discipline), then
     `retx_delay` + `retx_due` (the re-send decision), then the adversary `lossy_decide` + `make_lossy_partner`
      (a deterministic lossy carrier). The adversary started as its own `Lossy.g` but a separate ghost earned no
       keep for dormant test scaffolding — it's now just the bottom region here (the human: "Lossy could just be
        a region"). In `CREDULER_GHOSTS` + Net/Easy; **gen ghost-compiled live** (`gen/N/Reliable.go`). The
         adversary stays dormant (no caller) until an adversarial Story (heading 6) hands a port through it.
- **inseq is WIRED + live, and now TRANSPORT-GATED (engages only on a lossy carrier).** `Peeroleum_deliver` first
   reads the receiving carrier's `connection.reliable` (default true via `conn?.reliable !== false`): a reliable+ordered
    carrier (the ws relay, the clean mock) **books STRAIGHT and skips inseq entirely** — it already delivers in order,
     exactly once, so the gate would be pure redundancy (and the redundancy was the bug — see the gating note below).
      On a `reliable:false` carrier (the adversary mock today, the webrtc datachannel tomorrow) it folds the frame through
       `this.inseq_admit` BEFORE booking: contiguous → `Peeroleum_book_unemit`+drain; delivered-dup (`seq ≤ last`) → re-ack
        only (never re-dispatch); gap/buffered-dup → hold off-snap on `pier.c.held`, NO ack, and now a `console.warn` (a
         hold is LOUD, never silent). `Peeroleum.g` + `Reliable.go` ghost-compiled & live.
- **retransmit WIRED (ghost-compiled live, DORMANT-safe; active path :9091-PROVEN by the heal verifier).** `Peeroleum_send`
   stashes `emit.c.frame`/`sent_tick`/`attempts`; `Peeroleum_retx_sweep(w)` rides the `Peeroleum_arm_whittle`
    Runstepped boundary BEFORE the cull — advances a per-w logical tick `w.c.retx_tick`, asks `retx_due` which
     un-acked emits' windows elapsed, re-hands each `emit.c.frame` to the CURRENT active transport (no new emit;
      same seq, peer's inseq dedups), bumps attempts + stamps `%resent`; exhausted emits now **roll up `%stalled`
       and are culled** (was `%dead`-and-leak — see the stall rung below). **Dormant on a clean stream** (emits ack
        within the step → `retx_due` skips them → PereStaple snap unchanged). Its ACTIVE path is EXERCISED by the
         heal + stall verifiers (below). The retransmit **policy is now per-w** (`w.c.retx_policy`, default the
          production `{base:2,factor:2,max_attempts:5,cap:16}`) so an adversarial Story can tighten it to land a
           death in a couple ticks instead of ~46.
- **STALL RUNG — `%dead`→`%stalled` rollup + cull (2026-06-25, PROVEN green on :9091, ghost-compiled `Peeroleum.go @ cec4c84`).**
   The two open holes the retransmit left (the `%dead`-only-marks line above) are closed: when an emit's retransmits
    exhaust, `Peeroleum_retx_sweep` (dead branch) latches a per-Pier **`%stalled`** container holding the dead emit
     (`stalled/emit,type,seq,reason:no-ack` — parallel to `%faulty` over `%unemit`, the durable outbound carrier-down
      signal; the inbound-silence half stays the LiesLies keepalive), then **drops the spent emit** (else it re-enters
       `verdict.dead` every sweep and re-dies forever — that WAS the leak). `%stalled` is **latched**, NOT rebuilt each
        boundary like `%faulty` (the emit is gone, nothing to rebuild from); only `reset_handshake` (heading 8) clears it.
         **PROVEN:** step-13 snap shows `Kim/Pier/stalled/emit,…,reason:no-ack`, emit culled, `witnessed:stall` stamped
          (alongside `witnessed:heal`). **< the re-dial itself** (mark the active `%transport` faulty → the Tribunal
           re-trials a carrier) stays the **heading 9/10 seam** — real transports own carrier reselection.
  - **The FREEZE scare + the real cause.** An intermediate run froze: Kim stuck at `resent=2` across steps 13/14/15,
     no `%stalled`. The retransmit/cull heartbeat is a self-re-pushing `Runstepped` rearm (`arm_whittle`:
      `() => Runstepped(() => { retx_sweep; runstepped; rearm() })`), so ANY throw in `retx_sweep` skips `rearm()` and
       that w **stops sweeping forever** — every later frame silently stranded. I first blamed the nested create in the
        `Peeroleum_mark_stalled` helper — **WRONG**: the very next run ran that same helper green. The real culprit was
         an **HMR desync** (`retx_sweep` hot-updated while the new `mark_stalled` method wasn't yet deposited →
          "not a function" → froze). Fix kept both robustnesses: **inline the stamp** (no separate method → nothing to
           desync) and **try/catch the dead branch**, surfacing any residual throw IN THE SNAP (`%stall_err,msg`) — a
            frozen heartbeat must never be silent again. (Latent twin: `rollup_faulty`'s nested `faulty.i(…)` — same
             pattern, fine, but untested; heading 6.) **Lesson: after a ghost-compile, a long-lived runner may keep a
              STALE gen — reload it before trusting a run (the nested-vs-flat snap shape is how this was caught).**
- **The heal verifier — `Peregrination.g` step 8 `Lake_heal_arm` (2026-06-25, PROVEN GREEN on :9091).**
   A FRESH isolated pair (Ivy/Jon) on a clean mock carrier, with the adversary (`make_lossy_partner, {drop:[s]}`)
    slipped onto the Ivy→Jon path; one `noop` seq s sent. A noop is admitted+acked pre-handshake, so no handshake is
     needed (isolated + fresh-seq=1). The drop leaves Ivy's emit un-acked → `Peeroleum_retx_sweep` re-sends at the step
      boundaries (`retx_delay(1)=2` ticks → heal plays out over steps 9-10) → the resend passes the now-spent drop →
       Jon delivers+acks → `%acked`. `Lake_witness` stamps **`%witnessed:heal`** on three cull-surviving readings:
        the adversary's drop-log (`IvyPier.c.lossy.dropped`), Jon HANDLED it (`%done` unemit / `%recent`), Ivy's emit
         `%acked` (live / `%recent`). toc.snap carries `step=8..11` (lie diges). The carrier's `drop` is now drop-ONCE
          (transient → retransmit heals); a new `blackhole` knob is the drop-every-transit permanent-fault case. This is
           the FIRST end-to-end exercise of Lossy + retransmit + inseq.
- **The stall verifier — `Peregrination.g` step 11 `Lake_stall_arm` (2026-06-25, PROVEN GREEN on :9091).**
   The heal's twin: a FRESH isolated pair (Kim/Lee), the adversary on a **`blackhole`** (every transit lost) Kim→Lee,
    a **tight `Kimw.c.retx_policy = {base:1,factor:1,max_attempts:2,cap:1}`** so the death lands in two logical ticks,
     one `noop` Kim→Lee. Lee never hears it and no resend lands → `Peeroleum_retx_sweep` marks the emit `%dead`, rolls
      `%stalled` onto KimPier, culls the emit. `Lake_witness` stamps **`%witnessed:stall`** on two cull-surviving readings:
       the adversary swallowed **≥2 transits** (`KimPier.c.lossy.dropped` — original send + ≥1 retransmit, a clean delivery
        shows none) and the Pier carries the latched `%stalled`. Placed at step 11 (after the heal settles at 10) so the
         heal gate (steps 8–10) stays byte-identical; the stall plays out 11→14 (the arm-lag — `arm_whittle` registered
          mid-step misses the first boundary drain, as the heal pair does — spreads the two retx ticks: send@11, first
           resend@13, exhaust@14, though the arm-lag can be shorter — the green run died by step 13). **PROVEN on :9091:**
            step-13 snap = `Kim/Pier/stalled/emit,type:noop,seq,reason:no-ack`, emit culled, `witnessed:stall` + `witnessed:heal`.
             toc.snap runs `step=15` (12-15 lie diges). **Re-record steps 11–15** (reload the runner first so it re-acquires
              the committed gen — the green run executed a stale cached gen; the committed inline produces the same nested
               shape). Next: the re-dial (heading 9/10 carrier reselection) + spine inbound-silence liveness + Tribunal fallback.
The PINNED carrier `last_heard` stamp (`Peeroleum_deliver`, every frame incl. **acks** — closes the watchdog's
 ack-blindness) rides the next re-pin.
- **TRANSPORT-GATING LANDED — the editor↔runner FIX (2026-06-25, ghost-compiled live `Peeroleum.go @ d1930fee`).**
   ROOT DEFECT (other agent, confirmed in code): `Peeroleum_send_consumer` (`Peeroleum.g:203`) allocates a `Pier_next_seq`
    for EVERY consumer frame — including the ephemerals (ping/pong/run_phase) that `Peeroleum_deliver` routes to handlers
     BEFORE the inseq gate. So each ephemeral burns a seq the receiver never books → inseq reads a PHANTOM gap → the next
      booked frame gap-buffers forever; the 5s keepalive guarantees a hole between any two = **"only the first `rungo`
       lands"** (broken direction editor→runner: the pinned editor seqs its ephemerals, the live runner holds). FIX = the
        gate (above): a reliable+ordered carrier bypasses inseq, so the redundant ordering layer can no longer invent a
         gap. RECEIVER-SIDE → fixes the pinned-editor direction without un-fossilizing. Correct LAYERING, not a hack —
          inseq/retransmit are the healing layer for an UNRELIABLE transport; the live ws path just never reaches them.
   (Promoting live → `pinned_stable` would NOT fix it: both ends would gain inseq → symmetric wedge.)
- **Reverted the cold-start baseline** (was the `last===0 && seq>1` re-baseline at the deliver seed): dead weight under
   gating — that reload wedge lived on the reliable relay, which no longer sequences, so the deliver site is clean algebra
    again. The real lossy-reconnect resync (and reconnect-replay dedup on a reliable carrier) is the **epoch handshake
     (heading 8)** — sender announces its `Pier_next_seq`, receiver adopts it — done properly then, not a band-aid now.
- **A held frame is now LOUD** (`console.warn` on every gap-hold) — DONE, not a follow-up. The wedge hid because liveness
   rides the ephemerals that bypass inseq, so the watchdog saw a LIVE carrier while the consumer starved; now a hold (only
    legitimate on a lossy carrier) screams. **< DEFERRED:** the epoch handshake (above), and mark the webrtc datachannel
     `reliable:false` when it goes live. The larger deterministic reconnect/carrier-swap game belongs AFTER the epoch
      exists to make it determinate — not before.
- **SIDE EFFECT to re-snap:** the clean Alice/Bob mock now bypasses inseq too, so the step 5–7 trial-probe coupling
   (the websocket probe gap-buffering behind the lost webrtc one) DISSOLVES — those steps revert to clean. **Re-record
    steps 5–11** on the next `:9091` run.

> **Doctrine (human, this session): `.g` is the home; the `.ts`+spec+`FlockCompile` route is a STAGED layer.**
>  A pure `.ts` primitive + headless spec (and `FlockCompile`, which compiles in-memory and does NOT write the
>   `.go`) is the "expecting trouble" workbench — fast, isolated, non-committal. The real artifact is the `.g`,
>    and **ghost-compile is the commit** that writes the `.go` + HMRs it live so you can play immediately. Protocol:
>     work it out in the soft layer only if needed, then FOLD into `.g` and ghost-compile. Don't leave scattered
>      `.ts`. New ghosts get registered in `CREDULER_GHOSTS` (LiesLies — the live acquire) AND the Net/Easy overlay,
>       and a ghost MUST have a gen `.go` before it's enrolled (the acquire `import`s the `.go`; no file → boot hangs).

### → START HERE: real websocket transport (heading 10) — editor↔runner is its first customer

**Active direction (settled with the human).** The editor↔runner channel is NOT new construction — it is
the first real customer of heading 10's websocket transport, so the music-app peers and Lies (editor/runner)
become two consumers of ONE envelope/transport/ack/faulty machinery. **The settled design now lives in
spec §5** ("Realised transport topology — the 'heading 10' design"); this is the live build log against it.

**Build progress (this session):**
- **[x] (1) Real `/relay` WS server — PROVEN.** `src/lib/server/relay.ts` (`attachRelay`) + a `configureServer`
   vite plugin in `vite.config.ts`. Two-AP routing, structural loop-safety, set-once browser-commanded role,
    single r2r bridge. Proven node-side by `scripts/relay-test.ts` (10/10) AND live on `vite dev :9091`
     (`/relay` routed a frame, HTTP 200, HMR intact). `ws` 8.18.2 = vite's existing dep, no new package.
- **[x] (2) Real WS carrier port — COMPILES.** `Socket_real(w)` + `Tribunal_activate_websocket(w)` in
   `Ghost/N/Tribunal.g`: a native `WebSocket` to own-origin `/relay?addr=<Peering name>`, send-buffered-until-open,
    inbound delivery wrapped in `post_do` → `Peeroleum_deliver`. The mock `Socket`/pairing is UNTOUCHED so the
     PereStaple test keeps its determinism. `lang-compile` clean; not yet run in-app.
- **[x] (3) Consumer dispatch seam — COMPILES.** `Peeroleum_on(w,type,fn)` (per-w `w.c.on` registry),
   `Peeroleum_send_consumer(w,type,body)`, `Peeroleum_peer_ready(pier)` in `Ghost/N/Peeroleum.g`;
    `Peeroleum_pump_inbox` now dispatches non-hello/trust types to the registered handler inside the same
     inbox/ack/faulty lifecycle. `lang-compile` clean; not yet run in-app.
- **[ ] (4) Lies as first consumer — NEXT, needs in-app.** Editor emits `dock_push` (the `.go` bytes) on
   `write_finished`+`w%editor`; runner registers `Peeroleum_on(w,'dock_push',…)` landing via
    `LiesStore_land_good→drain_good`; `run_result` flows back. Depends on the Editron compile-without-mounting
     split (gate `Ghost_update_notify` on `!w%editor`). Deliberately NOT written blind — no UIless runner yet
      (heading 1b), so build it against a live browser. **The committed `gen/**.go` are stale vs the new `.g`;
       the dige gate regenerates them on the next in-app run (do not hand-edit gen).**
- **[~] (5) The bridged channel RUNS live (runner ⇄ editor) — mind the run_phase wedge (FIXED).** First real
   bridged run: the runner Creduler-acquires the spine, the WS relay bridges runner↔editor, the Story drives
    over it. **Bomb (fixed):** `run_phase` (the transient progress blip the runner sends the editor) was a
     NON-ephemeral frame, so the editor acked each one; the ack hit the runner's `Peeroleum_deliver` →
      `feebly_ponder()` → re-woke the Story drive so the step never quiesced → `step_stall` fired → another
       `run_phase` → another ack → an endless wedge (a 5-step run took 48s). Fix: `run_phase` is now ephemeral
        like ping/pong (`Peeroleum.g` — no booked emit, no ack-back). **That alone did NOT fix it** — the
         runner's gen recompiled fine, but the **editor still ACKs each run_phase** (the editor rides a
          *separate frozen bootstrap* Peeroleum, not the live `CREDULER_GHOSTS` gen the runner re-acquires, so
           it never got the fix), and the runner's ack branch `feebly_ponder`ed on that spurious ack →
            re-wedge (`poll_step` spinning at the 50ms `TICK_MS`, ~18fps; run_phase seq climbed past 390). **The
             robust fix (runner-side, peer-agnostic):** `Peeroleum_take_ack` now returns whether it actually
              stamped an outbox emit / protocol `%said`, and the ack branch only `feebly_ponder`s on a *hit* —
               so an ack for an untracked (ephemeral run_phase) frame is ignored, no matter what the peer does.
                The heartbeat ping rate was halved to 6s (`LiesLies.svelte` `Lies_heartbeat`) but was never the
                 dominant cause (6s ≪ 18fps). The editor still acks run_phase = harmless channel chatter until
                  its bootstrap regenerates.
- **[~] (6) The wedge underneath — a beliefs-drain LOST WAKEUP, now NETTED (verify on :9091).** Confirmed
   *what* it is: NOT churn — a **lost wakeup**. The House goes **idle out of Atime** (`finished_run` set, no
    cycle running) with `Run.todo` **still non-empty** (a `fn:?` = the mock `partner.recv` delivery + a
     `think`), and `poll_step` — which only ever *waited* on quiescence — waits **forever**; its `setTimeout`
      "comes back infinitely" but the machine is FROZEN, not spinning. **Tell:** a STATIC trace while the step
       clock climbs is this lost wakeup; a GROWING one would be the other failure (infinite re-enqueue / churn).
        The drain path is lossy in three spots: `answer_calls` fires `_really_answer_calls()` **async-unawaited**
         behind a 50ms throttle decoupled from work completion; `i_elvisto` defers its `_push_todo` into a
          `clear()` (mutex re-acquire); `feebly_ponder→main` routes through a `throttle()` that can coalesce away
           the kick. (The `Story_cli` harness already works around all this — it manually loops
            `while(todo.length) _really_answer_calls()` + trickles think — which is *why* it never reproduces the
             wedge.) **Net (landed, browser-unverified):** a watchdog in `poll_step` — when
              `not_in_Atime && Run.todo.length` it drives the drain itself (`Run.answer_calls()`), self-healing a
               dropped wakeup on the next 50ms tick; a throttled **`rekick` trace** marks each intervention
                (rekick-then-lands = lost wakeup; rekick-forever = churn, now loud instead of a silent
                 forever-wait). Design write-up: `Story_next_level_spec.md` **§15.5**. **Verify on :9091:** the
                  wedged step should now COMPLETE. Deeper follow-up (optional): root-harden (await `_really`,
                   de-throttle the event-driven think) or the §15 **req\*\*** recast (wake becomes ttlilt-owned,
                    so the whole class dissolves rather than being netted).

**Instruments + open latency thread (this session).** The old brutal *console* trace-tail is GONE — replaced by
 an in-UI **overrun monitor** in Storui: a `⏱` button arms at >5s on a wedged step and opens a live trace ticker
  (batches the latest ≤30 unshown events every 3s) plus an **idle Xs** counter — *idle climbing while the step
   clock runs is the static-trace tell* that reads lost-wakeup-not-churn at a glance. Its signal rides an
    ave-held `live_poll` particle bumped directly (the reactivity_docs "lever"), so it updates even while a wedge
     keeps beliefs from flushing ave. **Open thread — editor↔runner channel RTT is ~400–900ms** (two tabs ↔ two
      node relays), far too slow: applied `socket.setNoDelay(true)` (Nagle off) to the relay sockets (`relay.ts`
       onUpgrade + the r2r bridge) — the multi-hop r2r path can stack ~100ms of Nagle per hop — but the dominant
        cost is likely the app round-trip threading the same throttled belief/think machinery on both ends (cf.
         the boomerang-latency memory). **Instrument the actual ping path next.** Runner-panel stall readout
          matured to a coarse `>2s/>5s/…` band (no per-second count).

**Prerequisite unblocked (compiler robustness — why the editor wrote uncompiled `.go`):** task (4) needs the
editor to compile cleanly, gated by a real bug — a compile firing before the language parser landed emitted
raw `.g` passthrough and WROTE it as the `.go`, with nothing validating. Fixed: `req_compile` waits for the
parser (`waiting:'parser'` ttlilt) + a `Lang_has_lang_parser` guard in `Lang_compile_dock`; `lang-compile`
syntax-gates its output (esbuild). Write-up in `LangCompiler_TODO.md`. Both fixes still want a browser re-run.

**Test status (transport trial, steps 2–6):** steps 2–5 proven in-app; **step 6 was BROKEN, now FIXED.**
`Lake_trial_confirm` re-checked `probe.sc.acked` on the relay-probe emit, but the step-5→6 boundary cull had
moved it to `%outbox/recent`, which STRIPS `%acked` — so it bailed and never stamped
`%reputation:good`/`%witnessed:step_6`. Fix (`Ghost/Story/Peregrination.g`): presence in `%recent` IS the ack
proof (the cull moves ONLY acked emits there); a still-live emit must still carry `%acked`. `lang-compile`
clean. **Re-run to confirm step 6 goes green, then Accept/Resnapture steps 2–6.** Then heading 6 (corruption).
`req_transport_select` is GONE for the test — the trial is wrangler-driven (`Tribunal.g`); the req version is
for real peers (spec §11.2). No wall-clock `ttlilt` in the trial anymore — it's step-paced.

**The in-app run reshapes every step snap** (outbox/inbox carry the full lifecycle; the boundary culls
acked/done into `%recent` after each step), so the `toc.snap` step diges — already lies — are doubly stale.
Run the `PereStaple` Story on :9091, eyeball the lifecycle, then Accept/Resnapture. (`Story_cli` produces a
PereStaple pile too — read `witnessed:*`/`A:PereStaple`; the `A:Lang` AST blob is per-step noise; see the
`peregrination-pile-reading` memory + `Story_cli_docs.md`.)

### Runner access — the verification-loop unlock (heading 1b, in tiers)  `[~]`

Every behaviour claim in this file ends "browser-unverified, verify on :9091" because a human at a
 browser sits in the critical path of every proof. `Story_cli` (vitest+jsdom pile + `ACCEPT` re-record
  + sweep) already runs FIXTURE Books headless — but `Story_cli.svelte` mounts `<Ghost>` only, it NEVER
   fires `Creduler_ensure`, so the wrangler Books that acquire the live spine (PereStaple / PereTyrant /
    Editron / Musu — exactly the ones built here) can't run headless. The gen `.go` for every CREDULER_GHOST
     is on disk + current. The unlock = fire the acquire under node. Tiers, priority order:
- **Tier 0 `[x]` PROVEN this session — Creduler acquire fires headless.** Both open Qs resolved YES: (a)
   `svelte.config.js` maps `.go`→svelte (`extensions:['.svelte','.go']`), so `import('…/gen/**/*.go')` resolves
    under the `svelte()` vitest config — no `.go` work needed; (b) the missing piece was the RENDER tree —
     `scripts/Story_cli_runner.svelte` = the Story_cli shell + Otro's dynamic-UIs `{#each house.UIs.ob({UI:1})}
      <svelte:component this={uiC.sc.component} H={house}/>`, so an enrolled gen MOUNTS headless + its onMount
       eatfunc deposits (the "onMount never fires UIless" warning is about a true no-DOM run; jsdom mounts fine).
        `scripts/CredulerProbe.spec.ts` proves the acquire — all 6 spine ghosts deposit (`Peeroleum_deliver` /
         `inseq_admit` / `Tribunal_pair_websocket` / `Tyrant_grant` / `Run_A_PereStaple` live). `scripts/CredRunner
          .spec.ts` drives the WHOLE Book: acquire prelude (creduler Lies + `Creduler_ensure` crank till spine live)
           → stand up `w:Story,Book:PereStaple` → the proven Story_cli drive loop + pile/diff/ACCEPT. **PereStaple
            runs end-to-end with ZERO browser.** (Musuation.go doesn't enrol → `%Creduler_pending` lingers; orthogonal
             music-cluster gap, PereStaple's spine is full.)
- **Tier 1 `[~]` WORKING — self-record the gate; the equivalence contract now has TEETH.** CredRunner emits the
   pile, diffs each step vs the locked fixture (spay-forgiving the `round=N` age-mung), and has the ACCEPT re-record
    path. Headless PereStaple = **13/15 match** the browser-locked gate. The 2 surprises ARE the contract working,
     not noise: **(1)** step 1's `001.snap` is a stale Jun-24 fixture the `acceptings` commit never rewrote (it did
      002–015) — re-record it; **(3)** a REAL determinism gap — headless snaps step 3 with `req:handshake` /
       `req:heard_trust` NOT yet `,finished` + no `witnessed:step_3` (the post_do/feebly_ponder handshake round-trip
        lags the step's quiescence snapshot; reconciles by step 4, so steps 4–15 match). A harness "trickle-while-
         any-req-open" fix HANGS (the handshake req legitimately spans steps 1–3, so it never lets step 1 quiesce) —
          the right fix is heading-3's ttlilt-on-unfinished-handshake (a `.g` edit → blocked on Tier 2 headless-
           recompile or a browser), NOT a harness hack. So Tier 1 caught the ONE place headless≠browser.
- **Tier 2 `[ ]` — compile→run round-trip.** edit `.g` → compile → runner picks up FRESH gen (no stale cache)
   → run, no human HMR. Kills the "reload the runner to re-acquire the committed gen" gotcha (bit the stall run twice).
- **Tier 3 `[ ]` — two-origin transport.** two runners on separate origins + the real `/relay` ws + fault
   injection I drive (kill relay / drop socket / partition). The mock + `make_lossy_partner` prove the LOGIC of
    inbound-silence-liveness + re-dial + Tribunal fallback; only a real silent socket proves the TRANSPORT. The
     capability that lets the reliability thread FINISH verified, not land dormant like the retransmit/stall rungs.
- **Tier 4 `[ ]` — observability.** on-demand snap at any tick (not just step boundaries) + the `live_poll`
   overrun signal (lost-wakeup-vs-churn tell) in the pile. (`wstory.json` + the ms-trace already cover most.)
Non-goals: no render / CodeMirror / Cyto / Storui — behaviour + snap + trace only (heading 1b: eatfunc without
 a DOM / minimal Otro). Acceptance: PereStaple green→edit→re-run→diff→ACCEPT zero-browser, and a later :9091
  run agrees on the diges (that equivalence IS the contract).

### Standing asks (apply to every heading)

- **Write the spine in the DSL, not raw JS.** Heading L covers a lot — `%` optional on peels, `H` receiver
   for actor-laying, multi-assign two-leg row-capture, drilled-`o` captures, `&name,a,b` calls. Reach for a
    LangTiles extension before raw JS; only object/`.c` seams (mock-port pairing, frame objects off the wire,
     dynamic-value writes) stay raw. Compile every `.g` edit with `npm run ghost-compile -- <file>`.
- **The c.up rule (bit me in heading 3, now spec §8).** A `%req` hosted below `w` (under Pier/Peering)
   silently never pumps unless you stamp the host chain's `c.up` — the belief walk wires `A`/`w` only. So any
    new Pier-hosted req (e.g. `%req:send`, spec §11.3) needs `Pier.c.up=Peering` etc.
- **Working tree left uncommitted for the human.**

## How the loop works (heading 0)

A `.g` ghost's methods exist on `H` only once the dock is compiled + included (compile → `gen/**.go` →
Pantheate `import()` → Otro mount → `eatfunc`). The hand-written `src/lib/O/test/Peregrination.svelte` loader
is **GONE** — the runner now **ACQUIRES the live spine via the Creduler**: `Creduler_ensure(w)` (gated by a
`%Creduler_pending` flag on H, set in `Auto.svelte`) loads every ghost in the `CREDULER_GHOSTS` manifest
(`LiesLies.svelte`) live, compiling+including each before the Story is allowed to start. The `.g` IS the Book.

- `Run_A_PereStaple` (in `Ghost/Story/Peregrination.g`) is the Run recipe — lays `A:PereStaple/
   w:PereStaple` and guards the `runner` role. (Mirrored by `Run_A_Editron`.)
- per beat, `PereStaple(A,w)` installs `%req:wrangle,eternal` whose do_fn `await`s `Lake_drive(w, req)`.
- `Lake_drive` is the inner-step dispatch (step 2 `Lake_sides_up`, 3 `Lake_handshake`, 4/5/6 `Lake_trial_*`),
   off a req-local `req.c.did_step` — explicitly NOT `H.on_step` (see "Why NOT on_step" under heading 2).
- `Lake_witness` polls each pass and stamps `%witnessed:step_N` by structural query. **(Legacy pattern — kept
   for the recorded 2–30 gate, but NEW assertions use `%see:'sentence'` once-noticed; see the Status block and
    `Lake_proof_see`.)**

Driven by the **PereStaple Story** (`wormhole/Story/PereStaple/toc.snap`), whose Prep opens the
**Ghost/Net/Easy** Waft overlay (`wormhole/Ghost/Net/Easy/toc.snap`) — its `.g` Docs are the manifest.

> (`LakeNetherland` is NOT this wrangler — it is an unrelated 3-line fixture in
>  `Ghost/test/Story/Lake/LakeAmeliorations.g`, surfaced in the LakeNets editor-machine Book. The
>   PereStaple wrangler is `PereStaple(A,w)`/`Lake_drive`. Earlier notes confusing the two were wrong.)

---

## Engine facts (the rest promoted to the spec)

The two engine-facts that corrected the spec's aspirational prose are now **in the spec** (reqy→C-native →
spec §3; the never-built `%req:waiting`/`%exports`/`waits_savepoint` were dropped from the spec — waiting is spec §3.2). What stays here, live:

- **LangTiles gaps** (→ raw-JS passthrough, flag `// <`): no auto-`async` (hand-write it), no
  `oa`/`drop`/`empty` verbs, no drilled paths on `oai/r/rm`, no object/`.c` payloads in `sc`, no list
  fan-out. See heading L.
- One-liner reminder of what moved: `reqy()` is deleted (live API `oai/doai/do/finish/all_finished`,
  `Stuff.svelte.ts`); waiting today = `H.i_req_ttlilt(req,secs,{waiting})` (`Hovercraft.svelte:380`) +
  eternal-foreman `req.sc.ok=1`. Both detailed in spec §3/§3.2.

---

## Headings

### 0 — Bootstrap / Creduler acquire  `[x]`  DONE
The loader is gone; the Creduler acquires the spine (see "How the loop works"). Proven in-app with a clean
quiescent snap. Things learned / kept:
- **Include needs no special UIless step** — Pantheate `import()`s the gen module and Otro mounts it (its
   `eatfunc` runs, Ghostmeta confirms). **Fixed bug**: Pantheate keyed every include under one
    `UI:Pantheate-include` slot, so two simultaneous includes collided — now keyed by `gen_path`.
- **Currency gate**: a `.g` already compiled+included by a prior reset is reused (skip recompile when
   `Ghostmeta_<name>() === dig(text)`); a drifted dige recompiles, never masked by a stale prior compile.
- **"UIless" here = editor-less / cursor-less compile, still in-browser** (Otro must mount the gen so
   `eatfunc` runs). A genuinely no-browser run is heading 1b.

### 0b — Net/Easy Waft overlay  `[x]`
`wormhole/Ghost/Net/Easy/toc.snap` — the annotation-overlay on-ramp; `What→Doc→Point` situating the test /
peer / transport / spec. Its `.g` Docs double as the compile manifest. Next: when heading W lands, the
acquire reads this list instead of a hardcoded manifest.

### 1a — compile path  `[x]`  (lets the agent compile `.g` files)
The pure translator was extracted verbatim from `LangCompiling.svelte` into `src/lib/O/lang/compile.ts`
(`export const LANG_COMPILE`); the ghost spreads `...LANG_COMPILE` into its eatfunc, so the in-app path is
behaviour-identical. **The standalone `scripts/lang-compile.ts` CLI has since been REMOVED** (the
"consolidate scripts" commit) — the translator extraction is what endured. The agent now compiles a `.g`
with `npm run ghost-compile -- <file.g>`, which signs a relay ticket to the live in-app editor (the editor
owns the only compiler). **Use it to compile every `.g` edit** ([[ghost-compile]]).

### 1b — UIless Story-runner  `[~]`  acquired Books run headless (CredRunner) — see "Runner access"
The "Otro render that mounts gen components" half is DONE: `scripts/Story_cli_runner.svelte` renders the dynamic
`watched:UIs` includes + `scripts/CredRunner.spec.ts` cranks `Creduler_ensure` before the Story, so a Creduler-
ACQUIRED Book (PereStaple et al.) runs to completion headless and emits the per-step pile (full account: the
"Runner access" section above + `Story_cli_docs.md`). **Story verification of the COMMITTED spine is no longer
:9091-only.** What's left for a *fully* UIless loop: (a) the determinism residual — a `post_do`/`feebly_ponder`
step can snap a beat early headless (PereStaple step 3); (b) **Tier 2** — a headless `.g`→`.go` writer so EDITS,
not just the committed gen, run headless (today a `.g` edit still needs `ghost-compile` on :9091). Surface:
`story_drive`/`do_step`/`snap_step`/`advance`, `Run.main()`/`beliefs`/`all_clear`, `Story_subHouse`. (Cited as
**heading 1b** by Editron.md + Everything_todo.md — keep the token.)

### 2 — Mock transport spine  `[x]` PROVEN in-app  (spec rung 1)
`transport()` (`Ghost/N/Peeroleum.g`) declares `%transport,type:mock` + `%active_transport,type:mock,open` and
wires a mock-port on `at.c.connection` (raw JS): `send` → `post_do(() => partner?.recv(frame))`, `recv` →
`Peeroleum_deliver`. The wrangler pairs the two ports. `Peeroleum_send`/`Peeroleum_deliver` carry the one
envelope (mechanism: spec §4/§7). Step-driven (inner steps start at 2): `Lake_sides_up(w)` (step 2 — stand up
`A:Alice`/`A:Bob`, each `w:Peeroleum` with a `%Peering`/`%Pier` + mock transport, pair ports, send one A→B
`noop`), `Lake_handshake(w)` (step 3), `Lake_trial_*` (4–6). `Lake_witness` stamps `%witnessed:step_N` (step
in the *value*). The `toc.snap` carries one `step,…` line per inner step; the diges are **lie diges** until a
run records them.

- **Why NOT `H.on_step` (a real bug, fixed):** `on_step` keys off one H-global `did_on_step_n`. When
   cold-compile/include spills into step 2, the step-1 path still runs and claims step 2 → the wrangle's
    step-2 setup is **starved** (tell: a step-3 snap with `%reached:step_3` but no `A:Alice`/`A:Bob`). Fix:
     `Lake_drive` keeps a req-local `req.c.did_step`, immune to any other caller.
- **Snap-fold knobs:** `%dontSnap` (a node emits its line but the walk descends no further — orthogonal to
   pump, so an edited `.g` still recompiles) folds the compile apparatus (`A:Lies` GhostList, `A:Lang` gen
    text); `w%runner` makes `Lies.svelte` skip provisioning GhostList entirely (the dirlist Funkcion never
     walks). `Lake_order` floats `A:Alice`/`A:Bob` above the apparatus actors (peers-first snap).

### 3 — hello+trust under mock → `%req:handshake,finished`  `[x]`  PROVEN in-app at step 3  (rung 2)
The four leaf do_fns + say/hear exchange + frame dispatch (`Peeroleum.g`), plus the wrangler's per-pass
re-pump + step-3 witness (`Peregrination.g`). Mechanism (leaf existence-checks, say/hear, dual-init,
cross-side short-circuit) is **spec §8**; the c.up bomb is **spec §8**. Status-only bombs that stay here:
- **Re-pump lives in the wrangler, NOT reqdo_sweep.** The handshake is nested (`Pier/Peering/w`), below
   reqdo_sweep's w-level reach, so `Lake_pump_handshakes` (each pass) drives it; delete it and the leaves
    freeze after step-3 seeding. (Production will pump via the per-Pier worker once `req_p2paddy` seeds the
     handshake — spec §11.2/§11.3 — but the test wrangler lays sides directly and drives them.)
- **The step holds open via `post_do`/`feebly_ponder` — no ttlilt needed.** Each `Peeroleum_send` `post_do`s
   a delivery; each `Peeroleum_deliver` `feebly_ponder`s → think → `Lake_drive` → `Lake_pump_handshakes` →
    `pier.do()`, so the round-trip self-drives to completion in one step. If an in-app run ever snaps
     mid-handshake, the fix is a waiting ttlilt on the handshake req + `H.i_scheme_req(w,[{Peering:1},
      {Pier:1}])` so `i_Story_o_req_ttlilt` can reach the nested req — but bet on the chain first.
- **Duplicate A→B hello — RESOLVED.** Step 2's scaffold frame is a `type:noop` (carrier+ack ping; spec §7.3
   sanctions `noop` pre-Ud), so the hello is sent exactly once, at step 3.

### 4 — outbox/inbox lifecycle + acks + whittle  `[x]`  PROVEN in-app at step 3  (rung 3)
Written into `Peeroleum.g` + `Peregrination.g`; both `lang-compile` clean, the in-app step-3 diff matched the
expected shape exactly. **Mechanism is now spec §7** (outbox `created→sent→acked`, light acks, serial inbox
`queued→handling→verified→done`, whittle to `%recent`; the query-safe-delete invariant; cull-after-snap). The
realised helpers: `Pier_next_seq` (monotone per-Pier on `.c`), `Peeroleum_send`/`_pump_inbox`/`_take_ack`/
`_rollup_faulty`/`_runstepped`/`_arm_whittle`. Status: confirmed in-app at step 2 (noop) and step 3 (hello+
trust lifecycle, both `%req:handshake,finished`). Still open (deferred, not blocking): production wiring of
acks/sends through `%req:send` (spec §11.3) — under the mock the `post_do` chain drives the round-trip, so the
deferred `want_savepoint`/exports (voided, dropped from the spec) aren't needed yet.
- **The inbox is the `%req` engine now — BUILT in `.g` source, compile-verified, regen/refreeze HELD.**
   `Peeroleum_pump_inbox` is GONE. Each inbound frame is booked as `%req:unemit,seq:N,type` under the inbox
    (`Peeroleum_deliver`) and drained by **`inbox.do()`**, which runs the new **`req_unemit(req)`** do_fn one at a
     time, in arrival order, awaiting each — that IS the serial async drain. The realisations:
  - **The `%handling`/`%queued` lock is GONE.** `do()`'s `for (…) await _req_do_one` serialises within a pass,
     and the beliefs mutex (the carrier's `post_do` is awaited across the whole delivery) means no two `do()`
      drains ever overlap — so there's no re-entrancy to guard. This is exactly the thesis: ordering is a property
       of the reconciler (the engine), not a sync-execution constraint.
  - **`req_unemit`** does the per-frame logic only: pre-`%Ud` gate → awaited sha256 body-hash → `hear_*`/handler
     → on success `req.sc.done`+`%to`, `inbox.finish(req)`, ack; on failure `req.sc.error`, finish, roll up
      `%faulty`. `w`/`pier`/`frame` ride the req's `.c` (stashed at booking — avoids a deep `c.up` walk).
  - **c.up:** `oai` auto-wires `ureq.c.up = inbox`; `Peeroleum_deliver` stamps `inbox.c.up = pier` (one line) so
     `do()`'s climb reaches the House to resolve `req_unemit`. The Pier→Peering→w→Mundo chain the handshake reqs
      already rely on does the rest. (Pier itself is now a typed serial-req — `%Pier,pub:…,req:N`, minted
       `oai Pier,$pub,req`, pumped by `req_Pier` when its `Peering.do()`s — BUILT this session; the mainkey
        stays `Pier` so it's still a queryable type, and `oai` wires its `c.up`. The enabling change is one
         line in `do_fn_for` (typed serial-req → mainkey handler) + `oai` firing on a non-first `req:1`.)
  - `rollup_faulty`/`runstepped` now read `inbox.o({req:'unemit'})` (was `{unemit:1}`); recent records keep the
     readable `%unemit:seq` shape.
  - **NOT regen'd / refrozen** (so live reconnect verification isn't disturbed) and **browser-unverified** —
     `lang-compile` PASS only proves valid JS. Re-shapes the inbox snaps (`%unemit:N` → `%req:unemit,seq:N`), so
      re-record after verifying on :9091. Promote spec §7.3 from the `%unemit` description once proven.

### 5 — per-req demand for time  `[x]`  CLOSED — `ttlilt` is the realised waiting-req
`%ttlilt` (`Hovercraft.svelte:380`) IS spec §3.2's per-req owned demand (dropped on `finish()`,
polled-not-mutated, no write-write race), and the live system runs on it (LiesStore/Lang/LiesCortex). The never-built
`%req:waiting` + computed-max global exist in **no** code (spec §13 now redirects to §3.2). Don't rebuild it — it'd
churn every step snap for no p2p gain. The only thing that bites is a ttlilt expiring before its work
finishes; the fix is the seconds knob (bump `i_req_ttlilt(req, 2.5, …)`). Don't re-open this rabbit hole.

### 6 — corruption tests  `[~]`  receive-side PROVEN headless; send-side meddle-wrap still TODO
`meddle_fn` on an eternal `%req:emit_corruption`, wrap installed on `%active_transport` (not `Pier.emit`), so
it's transport-agnostic. `publicKey`→not-them; `sign`→invalid-signature; `%faulty,claim:step_N`. The receive
side is **already realised** (`hear_*` return false → `%error` → `Peeroleum_rollup_faulty`); the only new
machinery is the meddle wrap. Re-applies `MachPeerily.svelte:725-794`. Spec §14 / §14.1.
- **Receive-side fault path PROVEN headless** (CredRunner): a tweaked `body_hash` fails the awaited sha256 and
   latches `%faulty,error:bad-body-hash`. Step 25 `Lake_corruption_arm` (one bad noop → `%witnessed:corruption`),
    and the combinatory step 44 `Lake_corrupt_stream_arm` (a bad frame BETWEEN two good ones: the cursor advances
     past the burned slot, the good frames behind it still deliver → `%witnessed:corrupt_stream`). The send-side
      meddle wrap is the only thing left to author here — the assertion target (the fault) already proves itself.

### 7 — binary frames  `[~]`
`body` + `body_hash` folded into the one envelope; `test_binary` as just-another-frame; corruption identical to
a tweaked hello-sign. Spec §4.2, §15.
- **Wire form = text header line then raw buffer (spec §4.2), NOT base64.** A buffer-carrying frame is
   `[header JSON]\n[raw buffer]` — one atomic message, "text first" (header human-readable at the front;
    JSON.stringify never emits a raw \n so the first 0x0A is the delimiter), raw bytes (binary is the bulk; no
    33% base64 tax). One message ⇒ no per-frame assembly queue (the receiver splits on the first \n: header = a
     JSON view, buffer = a near-zero-copy byte-tail). Beats Peerily's three-message crypto→data→buffer reassembly;
      the reassembly that IS needed (a transfer split into ~50kB frames) moves UP to the chunk layer (Phase 3). The
       buffer rides to PeerJS as one ArrayBuffer (whole-buffer efficiency). **Hybrid**: no-buffer frames (hello/
        trust/ack/noop/control) stay text JSON; only buffer frames go binary. The **mock** serialises nothing —
         it carries `{header, buffer:Uint8Array}` by reference. Buffer off-snap; only `body_hash`+`body_len` snap.
- **Digest is sha256, async all the way (was sync FNV).** The whole delivery path is now awaited end to end:
   the carrier `recv` awaits `Peeroleum_deliver` awaits `Peeroleum_pump_inbox` (an async serial drain) awaits
    `Peeroleum_body_digest` (await `crypto.subtle.digest('SHA-256', …)`). Because the carrier's `post_do`
     callback (`async () => { await partner.recv(frame) }`) is awaited inside the beliefs mutex
      (`_really_answer_calls` holds it across `await e.sc.fn(e)`), the digest resolves **within** Atime — the
       reason the FNV sync hack existed is gone. Mismatch → `%error:bad-body-hash` → `%faulty`, same path as a
        bad sign (no bifurcated error paths). sha256 makes `body_hash` **signable** — one-sig signing (header
         commits to the buffer via body_hash) now drops in with the trust layer, no second hash. Matches
          `cluster_trust.ts` `sha256hex` in strength (string-body vs raw-buffer is the only difference).
- **`test_binary` dispatches via the `Peeroleum_on` consumer registry** (§5 ask 1), not a hardcoded branch in
   pump_inbox; the harness registers it. Sent only AFTER handshake (the pre-Ud gate rejects non-hello/noop).
- **Carriers grow a binary branch.** `Socket_real` (Tribunal.g) encodes/decodes the `[header]\n[buffer]`
   message (`binaryType='arraybuffer'`); the relay (relay.ts) routes a binary message by reading the header
    line's `to` and forwards it whole (buffer opaque) — covered by `scripts/relay-test.ts` (local + cross-relay,
     buffer-intact). The mock/in-process carrier is by-reference, unchanged.
- **Exercise:** `Lake_exercise_binary` (Peregrination.g) runs as wrangler step 7, witnessed
   `%witnessed:send_binary`. The first of the transport-agnostic exercise set (same body runs over mock or the
    real-ws carrier). Built; lang-compile clean; **browser-unverified** — run on :9091, eyeball the lifecycle,
     Accept/Resnapture steps 2–7.

### 8 — disconnect + reset_handshake  `[~]`  protocol reset BUILT + PROVEN headless; transport reconnect BUILT
`%active_transport e:close` → `o_elvis:reset_handshake` on the Pier: drop protocol/outbox/inbox/faulty, keep
`%Ud`; p2paddy re-dials. Spec §9.
- **Protocol-level reset BUILT** (`Peeroleum_reset_handshake`, Peeroleum.g): drops protocol/outbox/inbox/faulty/
   stalled/silent + the handshake `%req` and clears the dead-stream `.c` (connection/held/last_heard_tick), but
    KEEPS `%Ud` AND the seq cursors (`c.seq`/`c.inseq`) — continuity dodges the epoch handshake a seq-reset would
     force on both sides. **PROVEN headless**: step 32 `Lake_reset_arm` builds a full dead-connection state and
      asserts one reset keeps `%Ud`+cursors and drops everything else (`%witnessed:reset`); the combinatory step
       46/48 `Lake_rededup_arm`/`_replay` proves the CONSEQUENCE — a re-dial does NOT re-open the replay window:
        an old frame replayed after the reset is caught by the surviving `c.inseq` cursor (`%witnessed:rededup`).
- **BUG FOUND + FIXED by the storm_redial braid (step 50):** reset kept `c.inseq` WHOLE while dropping `c.held`,
   so `c.inseq.buffered` (the seq numbers of the deleted held frames) lingered → a reset mid-gap silently lost the
    re-supplied tail (ghost-slot drain). Fixed: `reset_handshake` clears `c.inseq.buffered` with `c.held`, keeps
     only the cursor `last`. See the Combinatory section. **Spine change — re-pin `pinned_stable` + browser-verify.**
- **Transport-level auto-reconnect IS built** (the "no ping on both ends" bug — a dev-server/relay restart
   dropped both browsers at once and v1 had no reconnect). Three parts:
  - **`Socket_real` (Tribunal.g)** re-dials on `onclose` with capped backoff+jitter; `ws` is reassigned per
     reconnect (wire/send read it live, `port.ws` tracks it). New `port.on_open(cb)` re-fires consumer open-work
      on *every* (re)connect; `port.reconnect()` force-drops a half-open socket; ephemeral frames are dropped
       (not buffered) while down so `pending` can't bloat.
  - **`LiesLies`** registers the relay `become` via `port.on_open` (so a returning socket re-binds its role/addr).
     Liveness is now **`Lies_keepalive`** (split out of `Lies_heartbeat`), driven by an INDEPENDENT `setInterval`
      (NOT the belief loop — a think-quiesced peer must still ping) and **frame-agnostic** (`Lies_heard` stamps
       `last_heard` on every inbound consumer frame). Three states: only **DEAD** (nothing heard >20s) re-dials;
        **SLUGGISH** (heard, but no pong home) surfaces on the Relay Brink but does NOT reconnect — the old binary
         force-reconnect tore live channels mid-ghost_compile (the self-flap).
  - **Relay (`relay.ts`)** — fixed the bridge "state stuckness": a stale half-open `peerLink` is non-null but
     dead, and the `!peerLink` re-dial guards skipped it forever (only a server restart cleared it). Now a
      non-OPEN `peerLink` counts as down — closed and re-dialed on the next runner browser (re)connect. The
       heartbeat round also **keepalive-pings the outbound `peerLink`** itself now (was `wss.clients`-only), so a
        half-open outbound bridge is terminated+nulled proactively, not only on the next browser reconnect.
  - **Editor needs the re-freeze**: it runs the FROZEN `p2p/pinned_stable/*.go`, so reconnect only reaches it after
     `cp src/lib/gen/N/*.go src/lib/p2p/pinned_stable/` (done this session). A runner-only fix leaves the editor's
      socket dead — the channel needs BOTH ends reconnecting. Browser-unverified; confirm two-origin on :9091/:9092.

### 9/10 — transport trial: webrtc → websocket fallback (mocked)  `[~]`  PROVEN in-app thru step 5
The mocked selection lives in `Ghost/N/Tribunal.g` ("a peer connection's reputation, constantly on trial") —
the carriers moved out of `Peeroleum.g` (now just the mock carrier + envelope). It runs as **steps 4–6** of
the wrangler, paced by Story STEPS, not a wall-clock window (a step boundary is already a quiescence point):
- **webrtc mock = black hole** (`.c.port.send` drops the frame → no ack); **websocket mock = working** (rides
   the shared in-process queue, ports paired by `Tribunal_pair_websocket`).
- **step 4 `Lake_trial_arm`**: install both carriers, hand `%active_transport` to webrtc, probe A→B; black hole
   → un-acked emit lingers (the visible no-ack). Witness: both `active_transport,type:webrtc`.
- **step 5 `Lake_trial_fallback`**: probe still un-acked → fall BOTH sides to websocket FIRST
   (`%transport,type:webrtc,faulty,reason:no-ack` + repoint active), THEN probe the relay (so the ack rides
    back; demoting both before probing kills the cross-side race). Witness: both webrtc `faulty` +
     `active_transport,type:websocket`.
- **step 6 `Lake_trial_confirm`**: relay probe acked → `Tribunal_reputation_good` blesses both carriers
   `%reputation:good`. (Fixed this session — see Test status.)
- **Proven on :9091 thru step 5** (the hard part): webrtc faulty, active→websocket, relay carried
   (`emit=5,acked` / `unemit=5,verified,done`), `witnessed:step_4/5`. Step 6 follows from the acked emit.

**Remaining = the real transports** (still `[ ]`):
- **9 — real webrtc**: replace the black-hole port with the real PeerJS DataChannel (relocated from old
   Peerily); note the app-level no-ack timeout built here STAYS needed (PeerJS reports connection-level errors
    for free, not a channel that opens then goes silent). Spec §4.1.
- **10 — real websocket** `[~]` ACTIVE: a `/relay` WS endpoint forwarding a signed frame by `header.to`
   without parsing `body`; client `.c.port` → real WS. **Settled design = spec §5.** Live build log under
    "START HERE" above.

### 11 — Thangs persistence  `[ ]`
`w:Thangs,thangs:peerings` / `thangs:identities` (Dexie) drive `req:p2pman` (online identities) and
`req:p2paddy` (known peers + `transport.last_good`). Spec §10.

### 12 — migrate Otro, delete Peerily, rename  `[ ]`
Move Otro onto Peeroleum; delete `Peerily.svelte.ts` + `MachPeerily.svelte`; rename Peeroleum → Peerily. This
completes the void of the legacy Mach layer. Spec §16.

### L — LangTiles gaps to close  `[~]`  (so more of this lives in `.g`, not raw JS)
Done so far (all verified with `npm run lang-compile`, corpus output unchanged): loose peel values
(`reason:no-direct-route`); `n%such → n.sc.such` (tight `%` only); `H`-receiver actor-laying (`H i A:Alice`);
`$` row-capture on a valued leg + multi-assigning two-leg (`%` now optional on peels). NB: editing
`stho.grammar` makes `stho.grammar.ts` stale (registry falls back to live `buildParser` — correct, just
flagged); regen via the in-app gen action. Still open — each a place the spine drops to raw JS:
- auto-`async` on a method with a bare `await`-verb; `drop`/`empty`/`oa` verbs + deep/wildcard `drop
  Pier/protocol/**`; drilled paths on `oai/r/rm`; object/`.c` payloads (`c.connection`, `stashed:{…}`); list
  fan-out (one `%req:dial` per peer over a thang list).
Corpus + compiler: `Ghost/test/Story/Lake/LakeTiles.g`, `src/lib/O/LangCompiling.svelte`, `LangCompiler_TODO.md`.
Prose orientation (verbs/peels/captures/`%req`+`doai`, how a `.g` goes live, how to change the language):
`src/lib/O/spec/stho_primer.md`. (PathVal value-token mechanics live in `io_tokens.ts`, covered there.)

### W — Hide compilation behind Waft architecture  `[ ]`
Make opening a Waft auto-compile its `.g` Docs, so the explicit `Dock_open` loop (and a hardcoded manifest)
disappears — the Net/Easy overlay's Docs become the manifest directly. (Verify it's still meaningful under the
Creduler acquire, which already loads a `CREDULER_GHOSTS` manifest.)

### M — Multicast / topics over a claimed `@channel`  `[x]`  built + :9091-VERIFIED; lives in PereProof (step 29 after the split)
**Settled design is now spec §18.** The product motivation (the human, this session): a high-bandwidth
 publisher relaying to ~100 listeners must upload **once** to a topic, not 100 addressed copies, and may not
  even hold all the addresses. So `to` gets a special case — a `to` starting with **`@`** is a topic, not a
   peer `pub` — and the relay fans the one upload out to every subscriber. The handover seam: a 1:1 Pier hands
    over a **stream pointer** (`Peeroleum_offer_stream` → a `stream_offer` frame), the peer subscribes, and the
     bulk goes multicast. **"Someone has to come and claim that `@name`"** — a claim reserves the name (first-
      come now, a community/crypto gate later); enforcement is soft (trust-everything v1).
- **BUILT (4 files, all FlockCompile-clean + LocalGen-regenerated gen):**
  - `Peeroleum.g` — `Peeroleum_claim` / `_subscribe` / `_publish` (fire-and-forget: NO outbox emit, NO ack,
     per-**channel** seq) / `_offer_stream`; the `@`-branch atop `Peeroleum_deliver` (scans subscribed Peerings,
      no inbox/ack); the mock carrier `send` fans a `@`-frame into the in-process relay.
  - `Tribunal.g` — `Socket_real` gains `claim`/`subscribe`/`unsubscribe` port methods (relay control frames).
  - `relay.ts` — `claims` map + `handleControl` claim/subscribe/unsubscribe; **subscribe reuses `bind`+
     `deliverLocal`** (already a fan-out over the addr's Set), so routing is UNCHANGED; `drop()` releases a
      socket's subs + claims on close.
  - `Peregrination.g` — `Lake_multicast_arm` (step 53): Pab claims `@radio`, Sib subscribes via the
     `stream_offer` HANDOVER, Sob/Sub subscribe directly, Pab publishes ONE frame → all three land `%mcast`
      exactly once. `Lake_witness` stamps `%witnessed:multicast`.
- **:9091-VERIFIED (the human ran it live):** the browser pile showed `pab/owns:@radio`, `sib2|sob|sub` each
   with `%mcast` + `%subscribed:@radio`, sib2's `stream_offer` ran the full inbox lifecycle (`req:unemit…done…
    finished` → culled to `%recent`), and `witnessed:multicast` under the world. So the LOGIC + spine fan-out +
     the inbox round-trip are confirmed in a real browser (the in-process mock hub; a real `/relay` socket
      fan-out is still Tier 3 — see below).
- **NOW LIVES IN PereProof (the split — see "Two parallel Books" below):** multicast was step 53 of the old
   54-step PereStaple; it moved to **PereProof step 29** (`Lake_multicast_arm`, witnessed by `Lake_proof_witness`),
    recorded in `wormhole/Story/PereProof/`. Behaviour identical — only the Book + step number changed.
- **STANDING ASK:** a real-`/relay` two-socket fan-out test (Tier 3) — the headless mock + the :9091 in-process
   hub both prove the LOGIC + spine, but only real sockets prove the relay's `bind`/`deliverLocal` channel
    fan-out end-to-end. **Open seams (spec §18):** the
     crypto-signed claim gate (the community thing), cross-relay topic fan-out (one instance for now — a topic
      is LOCAL-only, the bridge isn't forwarded), a per-channel inseq + NACK for a lossy multicast carrier, and
       re-subscribe-on-reconnect. **First real customer = the music app** (`Music_todo.md` slice-3 radiostock
        fan-out is exactly one-source→many-listeners — wire `Radiola` publish/subscribe onto these calls).

### Two parallel Books — PereStaple (liveness) | PereProof (correctness)  `[x]`  split this session
PereStaple had grown to 54 linear steps; the human asked to split it so the two halves run in PARALLEL and
 reach "all green" in roughly half the wall-clock (target ~30 steps each). The cut follows the natural seam the
  handover already named:
- **PereStaple — the LIVENESS arc (steps 2–22).** Spine + transport trial + binary + heal/stall/silence/redial
   — "does the floor carry, heal, and detect death." Dispatch `Lake_drive`, witness `Lake_witness`. Fixtures
    `001–022.snap` are UNCHANGED by the split (the proof peers only ever appeared at step 25+, so 2–22 snaps are
     byte-identical) — kept, no re-record. CredRunner: **21/22** (the lone miss is the known step-3 quiescence
      residual). The old `023–054.snap` are DELETED (those proofs moved to PereProof, renumbered).
- **PereProof — the CORRECTNESS arc (steps 2–30).** Corruption, dedup, reorder, reset, pre-Ud, dedup-cull, the
   combinatory braids (storm / corrupt-stream / rededup / storm-redial), and multicast — "does the floor stay
    correct under adversarial input." Dispatch `Lake_proof_drive`, witness `Lake_proof_witness`. Fixtures
     `wormhole/Story/PereProof/001–030.snap` recorded headless (it has NO handshake, so no step-3 residual —
      fully deterministic). CredRunner: **30/30**, all 12 `witnessed:*` fire.
- **Mechanics + gotchas.** Both Books live in the SAME `Peregrination.g` (already a CREDULER_GHOST — no manifest
   change); the `Lake_*` ARM methods are SHARED, only the dispatch + witness split. The world MUST be named
    `w:PereProof` (the per-beat handler `PereProof(A,w)` is dispatched BY THE W-NAME — the same footgun the
     `w:PereStaple` rename hit). `Lake_order` was generalised to float `w.sc.w`'s actor (not a hardcoded
      `PereStaple`). **The one trap the split sprang:** `Peeroleum_arm_whittle(w)` (the retx/cull/liveness
       sweep) is armed by PereStaple's `Lake_sides_up` (step 2); PereProof has no sides-up, so dedup-cull (needs
        the cull) and storm (needs retransmit) silently never witnessed until `Lake_proof_drive` arms it at its
         own step 2. Registered on the Credence board via `wormhole/Ghost/Net/Easy/toc.snap` (`Storying,of_Book:
          PereProof` + `Point,method:Run_A_PereProof`). Run headless: `BOOK=PereProof … CredRunner.spec.ts`.
- **Next split, when wanted:** multicast is the natural third Book once `pub[]` + `@handle` addressing grow it
   (the human floated `to:pub[]` as the sender-side small-fan-out twin of `@channel`); for now it rides PereProof.

---

## Forward look — the cabinetry+party over the floor: Garden.g + Tyrant.g

**Peeroleum is the linoleum on the floor; the cabinetry and partying go over the top.** Over the transport
floor sits the social platform, reborn clean-room in stho as **two** new ghosts (legacy `ghost/Gardening.svelte`
+ `ghost/Tyranny.svelte` are the conceptual ancestors):
- **Tyrant.g** — the *cabinetry*: identity & trust (ex-Tyranny). **BUILT (`Ghost/N/Tyrant.g`, M1+M2,
   `lang-compile` clean).** M1 = trust over GIVEN identities (`%Ud` pre-stamped, a bidirectional `vouch`
    exchange over the Pier settling on acks → `%trust,grants:full`); M2 = policy-gated admission (`%req:join`
     whose `finished` is the AND of maz-ordered policy leaves `proven`∧`trusted`, above an `admit` leaf →
      `w/%member,signed` — "you're not on the network until the req is signed finished", the LiesStore
       phased-`%req` shape). Wired into `CREDULER_GHOSTS` (LiesLies) + the Net/Easy overlay. **NOW RUNNABLE —
        Book `PereTyrant`** (`wormhole/Story/PereTyrant/toc.snap`, step 2 trust / step 3 admit), click-runnable on
         the Credence board under `What:Pere`; the Book/recipe/actor renamed `Tyrant`→`PereTyrant` (the `Tyrant_*`
          helpers keep the subsystem name). **:9091 run:** M1 trust COMPLETES (`req:trust,finished`, vouch
           exchanged both ways) — BUT **`%trust,grants:full` isn't landing on the Pier** despite `Tyrant_grant`
            lowering fine (`pier.oai({trust:1},{grants:full})`), so the `trusted` policy + `admit` stall (no
             `%member,signed`). **That grant gap is the open item before admission goes green** (suspect: confirm
              `Tyrant_grant` actually runs / the snap wasn't truncated). Meet+prove (earning `%Ud`) is the deferred
               deeper M2.
- **Garden.g** — the *partying*: social cultivation (ex-Gardening). Introductions, engagements, tending many
   Piers, pruning dead ones. **Net-new, unbuilt.**

Both ride the Peeroleum floor via the **reused transport seam** — they emit through `&Peeroleum_send` →
`Peeroleum_deliver` → `Peeroleum_take_ack` (the outbox/inbox lifecycle, `rollup_faulty`, whittle) and plug new
`hear_<verb>` receive handlers into the inbox dispatch exactly like `hear_hello`/`hear_trust`. No carrier code.
The attach point is heading 10's v1 **trust-everything** seam (spec §5: the runner has an Id, enforcement
deferred) — exactly where Tyrant.g's identity/trust bolts on. Design sketch (M0 reused / M1 trust over given
Alice+Bob / M2 meeting + policy admission) in `Covenant_design.md` (being realigned from the rejected "Joinery"
name to the Garden.g/Tyrant.g split). The earlier `Joinery`/`Covenant` single-ghost name is **rejected** — two
ghosts, Garden.g + Tyrant.g.

---

## Files in play
- `Ghost/N/Peeroleum.g` — the spine (compiled; the mock carrier + envelope + lifecycle).
- `Ghost/N/Tribunal.g` — the transport-trial carriers (webrtc/websocket mocks + `Socket_real`/relay client).
- `Ghost/Story/Peregrination.g` — the Book + wrangler: `Run_A_PereStaple`, `PereStaple(A,w)` installs
   `%req:wrangle`, `Lake_drive`/`Lake_witness`/`Lake_sides_up`/`Lake_trial_*`. (Acquired by the Creduler —
    `Creduler_ensure` / `CREDULER_GHOSTS` in `Lies.svelte`/`LiesLies.svelte`; no hand-written loader.)
- `src/lib/server/relay.ts` — the real `/relay` WS server (`attachRelay`) + its `configureServer` vite plugin.
- `Ghost/N/Reliable.g` — network-healing floor, three regions: `inseq_admit` (wired), `retx_delay` + `retx_due`
   (wired via `Peeroleum_retx_sweep`), and the adversary `lossy_decide` + `make_lossy_partner` (dormant scaffolding,
    folded down from the retired `Lossy.g`).
- `scripts/FlockCompile.spec.ts` — headless compile gate for the flock (incl. `Reliable.g`); the break-glass
   "expecting trouble" check, NOT the default (ghost-compile is). Boots + passes again (LiesEnd WIP settled).
- `scripts/Story_cli_runner.svelte` + `scripts/CredulerProbe.spec.ts` + `scripts/CredRunner.spec.ts` — the
   headless runner-access build (Tier 0/1, see the "Runner access" section): the runner shell = Story_cli's shell
    + Otro's dynamic `watched:UIs` mount (the piece Story_cli lacks); the probe proves the Creduler acquire deposits
     the spine; CredRunner drives the whole acquired Book + diffs the pile (`BOOK=PereStaple node_modules/.bin/vitest
      run -c scripts/Story_cli.vitest.config.mjs scripts/CredRunner.spec.ts`, `ACCEPT=1` to re-record). 13/15 vs the
       locked gate; surprises [1] (stale fixture) + [3] (handshake-quiescence timing).
- `wormhole/Ghost/Net/Easy/toc.snap` — annotation overlay / compile manifest, curated to landmarks (one front-door
   Point per theme, not every method).
- `wormhole/Story/PereStaple/toc.snap` — drives the **LIVENESS** Book (steps 2–22 after the split): 2–7
   spine/trial/binary, 8 heal, 11 stall, 16 silence, 19 redial. Fixtures `001–022.snap`; CredRunner 21/22 (step-3
    quiescence residual the lone miss). See "Two parallel Books" under heading M.
- `wormhole/Story/PereProof/toc.snap` — drives the **CORRECTNESS** Book (steps 2–33, split off PereStaple): 2
   corruption, 4 dedup, 6/7 reorder, 9 reset, 11 pre-Ud, 13/15 dedup-after-cull; the **combinatory braids** 17
    storm (drop+dup+gap), 21 corrupt-stream, 23/25 rededup, 27 storm_redial (the re-dial-mid-gap braid that found
     the reset/buffered bug), 29 multicast (claim + offer-handover + 3 subscribers + 1 publish → fan-out), **31
      corrupt_redial** (corruption mid-re-dial; the first proof in the new `%see` style — `Lake_proof_see`, not a
       `%witnessed` latch), **32 silence_retx** (inbound `%silent` + outbound `%stalled` coexist on one peer), and
        **33 crossfire** (three interleaved identities — clean | gap-healed | corrupt-faulted — isolated by routing).
         Fixtures `001–033.snap` recorded headless; CredRunner **33/33, surprises []** (no handshake → fully
          deterministic, no step-3 residual). To add a step, see the RECORDING gotcha in the Status block — never
          `ACCEPT=1` (it churns the whole 2–31 gate).
- `src/lib/O/spec/Peeroleum_spec.md` — the pinned design (the floor). This file — the living progress.
- `src/lib/O/spec/Covenant_design.md` — the cabinetry+party design sketch (Garden.g/Tyrant.g).

## Combinatory phase + behaviour-space map (the simple proofs are in; what braids next)

The proofs grew in two layers, deliberately in this order:
- **Isolated floor proofs (steps 25–38)** — each bends ONE knob on its own clean stage: corruption, dedup,
   reorder/gap, reset, pre-Ud admission, dedup-after-cull. The simple single-concept assertions.
- **Combinatory braids (steps 40–48)** — several knobs on ONE stream, so they must hold TOGETHER. Done so far:
  - **storm (40)** — drop + dup + gap-buffer on one stream; every seq still delivered exactly once in order
     (the dropped seq MAKES the reorder, retx heals it, the dups collapse in the buffer). `heal ∘ dedup ∘ reorder`.
  - **corrupt-stream (44)** — a corrupt frame between two good ones: it faults without wedging the stream behind
     it. `verify ∘ ordering`.
  - **rededup (46/48)** — a re-dial (reset_handshake) keeps `c.inseq`, so a replayed old frame is still caught:
     the reconnect does not re-open the replay window. `reset ∘ dedup` — the security consequence the lone reset
      proof only implied.
  - **storm_redial (50)** — a re-dial WHILE a gap is open. `reset ∘ dedup ∘ ordering`. **This braid FOUND A REAL
     BUG** (it was on the "not yet braided" list below as "worth a witness" — it was): `reset_handshake` dropped
      `c.held` (the gap-buffered frames) but kept `c.inseq` whole — including `c.inseq.buffered`, the seq NUMBERS
       of those deleted frames. So after a reset mid-gap, inseq believed those seqs were ready: the re-supplied
        tail drained the ghost slots (no frame → silently skipped) then deduped the real re-sends — **data lost on
         a reconnect that lands mid-gap.** The lone reset proof (step 32) built `buffered:[]` empty, so it never
          saw it. **Fix:** `reset_handshake` now clears `c.inseq.buffered` together with `c.held` (two halves of
           one fact), keeping only the cursor `last`. The braid now witnesses full recovery (`%witnessed:storm_redial`):
            held cleared, cursor kept, the re-supplied tail admitted in order, every seq dispatched exactly once.
            **Spine change — browser-verify the editor↔runner channel + re-pin `pinned_stable/N/Peeroleum.go`.**
  - **corrupt_redial (PereProof step 31)** `[x]` — a corruption that arrives DURING a re-dial. `reset ∘ verify ∘
     ordering`. Cyn/Dax lossy link: deliver s1, gap-buffer s3/s4 (s2 missing), `reset_handshake` (held + buffered
      cleared, `%Ud` + cursor kept), then re-supply s2 CORRUPT (`body_hash` mismatch → sha256 verify faults, burns
       the slot), then s3/s4 good → tail drains exactly once. Proves the bad frame **faults, not lost-in-the-reset**.
        First test authored in the new **`%see`** style (asserted by `Lake_proof_see`, not a `%witnessed` latch):
         `see:corrupt mid-re-dial frame faulted not lost — good tail recovered`. CredRunner 31/31, surprises [].
  - **silence_retx (PereProof step 32)** `[x]` — SILENCE racing RETRANSMIT on ONE peer (the handover's "which latch
     wins?"). Answer: **neither pre-empts the other** — `%silent` (inbound, the silence sweep) and `%stalled`
      (outbound, the retx sweep) are independent one-shots that COEXIST. Ben/Amy fresh link: Ben hears once
       (stamps `last_heard_tick` — the silence gate), the link blackholes, then `silence_dead:1` (a tick TIGHTER
        than `max_attempts:3`) latches `%silent` on the FIRST sweep **while Ben's emit is still retransmitting**;
         two sweeps later the emit exhausts and `%stalled` joins it. `silence ∘ retransmit`. Synchronous via explicit
          `Peeroleum_retx_sweep`/`Peeroleum_liveness_sweep` calls (the deterministic twin of the per-beat sweep).
           `%see` style: `see:silence latched mid-retransmit — then the stall joined it — both carrier-down signals
            coexist`. CredRunner 32/32, surprises [] (snap deterministic but for the round-mung).
  - **crossfire (PereProof step 33)** `[x]` — MULTI-PEER CROSSFIRE: three identities under one w, their streams
     INTERLEAVED, one clean + one lossy + one corrupt, proving the swarm routes by identity so the three never
      cross-contaminate (the swarm refactor's whole point — `Peeroleum_route` resolves `{peering,pier}` by from/to).
       Gar→Het (clean), Ime→Jad (a gap that HEALS — i2 arrives late, i3 buffers, i2 fills → all dispatch in order),
        Kye→Lom (k2 bad-body-hash FAULTS + burns its slot, k1+k3 dispatch around it). Deliveries shuffled
         (g1·i1·k1·g2·i3·k2✗·i2·k3) so they race; end state each in ISOLATION, and **the fault stayed Lom's alone**
          (Het+Jad carry no faulty). `%see`: `see:three interleaved streams routed by identity stayed isolated —
           clean delivered — lossy healed — corrupt faulted alone`. Synchronous awaited delivers (no sweeps).
            CredRunner 33/33, surprises [].
  > The bracketed numbers in the bullets ABOVE (40/44/46/50/32) are the **pre-split PereStaple** numbering and are
  >  stale; the live PereProof step→arm map is in "Files in play" (`PereProof/toc.snap`: storm 17, corrupt-stream 21,
  >   rededup 23/25, storm_redial 27, multicast 29, corrupt_redial 31, silence_retx 32, crossfire 33).

**The behaviour-space combinatory braids are now COMPLETE — all three "not yet braided" items proven:**
- ~~corruption DURING a stall/redial~~ **DONE — PereProof step 31 `corrupt_redial`** (the braid above);
- ~~silence + retransmit racing~~ **DONE — PereProof step 32 `silence_retx`** (both latches coexist);
- ~~multi-peer crossfire~~ **DONE — PereProof step 33 `crossfire`** (three identities isolated under interleaved load).

The next frontier is NOT another one-off braid — it is the **PENCILED WORRY** below (the missing *logical* scenarios:
 restart / seqinx rollover / asymmetric-link / mid-stream carrier death / graded loss — the mock CAN model these)
  and the **Tier-3 two-origin real-transport harness** (timing/persistence, which the mock structurally cannot) —
   the latter doubles as the runner-fleet grid (see "The runner fleet" above).

> **PENCILED WORRY (the human, this session — look at next): the p2p layer is tested happy-path +
>  binary-failure only, and the headless harness gives FALSE CONFIDENCE on exactly where p2p fails.**
>  PereStaple is 50+ steps but **linear**: no peer restart, no seqinx rollover, no cursor-persistence-across-
>   reload (the exact [[inseq-reload-baseline]] bug), no mid-stream carrier death, no realistic loss/jitter
>    (the mocks are all-or-nothing blackhole/faulty), no asymmetric (one-way-down) link. ttlilt boundary
>     races are documented (the MundaneStation lesson) but **not regression-tested** — and node's `setTimeout`
>      is more reliable than the browser's, so the headless harness **structurally can't reproduce the timing**
>       that bites on :9091. The headless runners are excellent for LOGIC; they give false confidence on
>        **timing and persistence**, which is exactly where p2p fails. Two distinct gaps to close: (a) widen the
>         deterministic Story with the missing *logical* scenarios (restart, rollover, asymmetric, mid-stream
>          death, graded loss — these the mock CAN model); (b) the *timing/persistence* class needs the
>           **two-origin real-transport harness (Tier 3)** + a reload/persistence Story — the mock can't, by
>            construction. Don't let a green PereStaple read as "p2p is proven."

**The real-application connect (the "realer things to test it with" — bigger, its own arc):**
- **runner ↔ editor v2 channel** as a Story: the editor emits `dock_push` (the gen `.go` bytes) and `run` over the
   consumer seam (`Peeroleum_on`/`Peeroleum_send_consumer`), the runner emits `run_result`/verdict back — the same
    edit→compile→run→witness loop CredRunner+LocalGen already close locally, but now ACROSS the transport, with the
     reliability floor underneath. This is the first real customer of the spine (heading 10 ask 4). A `Lies%editorv2`
      Book would drive it. **Bigger than a combinatory braid — its own heading; map its step arc before building.**
- **Trust + Features port** — the legacy `PeeringFeature`/`PierFeature` model (`src/lib/p2p/Peerily.svelte.ts`,
   `Trust.svelte.ts`) onto the C-particle spine. Recommendation for v1: **NOT** a first-class `A:` actor — float a
    `req**` under the existing `w:PereStaple` (or a thin `w:Featurings` only if a snap/heartbeat boundary earns it;
     an `A:` is for peer-isolation, which Features doesn't need yet — see the Aw/req level-uniformity note). The
      receive-side trust check already half-exists (`hear_trust` + the pre-Ud gate). First test: a frame from an
       untrusted/unfeatured peer is refused, the same `%error→%faulty` path corruption/pre-Ud already prove. Swap
        the carrier (req** → w → A) later if it grows weight; the test stays.

**The runner fleet — the spine primitives to invent NOW (the long-term goal: a self-driving grid of runners).**
 The vision (the human): a Selenium/KVM grid of Chrome app-servers running the app, a `Cluster/**` of forkable Ids,
  a runner that a given editor *owns* (so `%Rungo` is handed to a runner that focuses on us, not a random shared one),
   a coordinator that asks for a docker/libvirt restart when a crash-quorum of tabs dies, and an Id hop-over. The
    OPERATIONS half (the `?I=` fork param, the `Lies%runner` UI, the restart/resume service the inner sockets to —
     lifted from `ty/`: `virtreset.py` + the puppeteer `watchdog.js` + KVM snapshot-revert so File System Access
      handles survive — now succeeded by *dockerised Chrome* for real-isolation sims) lives in
       **`spec/Cluster_spec.md`** (the cluster spec: trust substrate + runner flock + the testbed + the build order
        to remote `%Rungo`). The SPINE half — what Peeroleum must invent — is small and mostly ONE primitive:
- **`?I=` identity selection** wired into the spine beside the role param. Today role is `?E=`/`?B=` (`Lies_role`)
   and the cluster Idento rides `House.stashed`. Add `?I=<tag>` to select WHICH forked Idento *this tab* uses, minted/
    loaded from `stashed` keyed by the tag — so one browser profile can host many separable runner tabs (open a flock
     by clicking N links, each a different `?I=`), where `ty/` needed a whole OS browser-profile per identity.
- **Point-to-point Idento addressing.** The relay already has the pieces: `bind(addr, ws)` + `deliverLocal(to,…)` +
   `@channel` claims. Bind each node's `Idento.pub` as its addr on the signed hello, route `to:<pub>`. The signing
    layer (ClusterTrust) makes the addr trustworthy — an addr IS a verified identity.
- **The signed claim/lease — the ONE primitive that unlocks most of the vision.** Generalise the relay's existing
   `claims` map (`@channel → the socket that claimed the name`, already in prod for multicast) to arbitrary named
    tokens leased by an Idento: a `%Claim,name,by,until` particle + `claim`/`release` frames in the ClusterTrust
     privileged-frame table, verified in the recv window like `dock_push`. Then **runner-affinity** ("the focused
      runner" = the editor's Idento holds the claim on runner R), the **distributed mutex** ("whoever does mutexes" =
       whoever holds the named token), and the **restart-token** are all the SAME primitive wearing three hats.
- **`%Rungo` → leased runner.** `Rungo` (run-authority token) + `Storyrun` + the verdict wire + `runner_ask`/
   `story_repl` RPC already exist; handoff = route Rungo to the claim-holder instead of a shared `?B=` runner.
- **Health-quorum → `restart_request`.** App-side liveness is LIVE/SLUGGISH/DEAD; the relay sees every socket. The
   relay counts DEAD across the fleet and, past a quorum (the human's "most of 7 tabs crashed"), emits a control frame
    bridged to the host's reset socket (`ty/`'s `/tmp/jamsend-supervisor/chrome_launcher.sock`, `RESTART:<profile>`).
- **Lineage to mine for the lifecycle:** the legacy garden (`src/lib/ghost/Gardening.svelte`) already invented the
   Id+Pier *process reality* — **`Idzeugnation`** (Id birth: asked/finished/dead/waits), **`Ringing`** (a contact
    attempt + `Because` reasons), `OverPiering`/`%Hath` (the who-exists directory), `Ping` onlinity, trust grants,
     active-terminal migration, whittling. Id hop-over = `Idzeugnation` reborn on the spine. Port these, don't reinvent.
> Sequencing (the human): **get on with the spine now** (the claim/lease primitive + `?I=` + addressing are buildable
>  on what we have — `relay-test.ts` already proves headless ws round-trips), and only stand up the bunches-of-runners
>   grid at the natural time. The grid doubles as the Tier-3 two-origin harness the PENCILED WORRY says we still owe.

**Real relay (the transport under all this).** The deterministic Story rides the clean mock + the adversary on
 PURPOSE — logical-tick replay, no wall-clock (so a Story replays identically). The real relay is the integration
  layer, and it splits: **websocket IS reachable headless** (a node `ws` client → the `/relay` server in `relay.ts`,
   covered by `scripts/relay-test.ts`), so a headless ws-round-trip smoke test is buildable as a SEPARATE harness
    (not a witnessed Story — real timing is non-deterministic, an integration probe not a replay proof). **webrtc is
     browser-only** (no `RTCPeerConnection` in node without a heavy polyfill) — that stays Tier 3 / on :9091. Note the
      transport-selection LOGIC (webrtc black-hole → ws fallback → reputation) is already witnessed at steps 4–6 with
       mock carriers; only the actual socket bytes are unproven headless.
