---
name: ttlilt-rides-finishing-req
description: a /%ttlilt must hang off a req that FINISHES — never an eternal req; the ttlilt is the timing slice, not the work
metadata:
  node_type: memory
  type: feedback
  originSessionId: 5856ad5e-04a8-49ab-af3f-c1f5d9b62cc5
---

A `/%ttlilt` (the snap-timing advisory: "this slice of wall-clock isn't quiescent yet") must ride a
`%req` **that finishes**. Finishing is the single completion signal — it's how Story knows the slice
is done (ttlilt hygiene drops ttlilts only from finished reqs, Hovercraft.svelte:442). Hanging one on
an **eternal** req (never finishes) means it can only ever time out, and you'd have to invent
sub-states to know when it's "done" — the human: *"how will we know when that's finished without
splitting finished into a bunch of tiny pieces and going insane."*

**Why:** the ttlilt is **the timing itself, narrowly — not the thing having the timing.** Reach for a
ttlilt to time a bounded slice, and put it on the req whose finish ends that slice.

**How to apply:** if the work belongs to a req that *can't* finish (an eternal foreman like
req:Rundown), use `req/req/ttlilt` — a finishing CHILD req holds the ttlilt (BlatDo under Rundown is
exactly this: see [[blatdo-drive-rundown]]). And when a finish happens elsewhere but the host must
react in-step, **drive the host** (reqyoncile / `_req_do_one`) rather than holding a ttlilt to bridge
the gap. Authoritative: spec/Hovercraft.design.md (§4 finished reqs are captured as leaves; §6
e_reqyonciliation host-drives) and the i_req_ttlilt doc-comment in Hovercraft.svelte. Read those
before touching the req/ttlilt/finish machine — CLAUDE.md's prose is stale ([[reqy-deleted-c-native]]).
Related: [[ttlilt-not-a-keepalive]] (re-arm is a no-op; it advises snap timing, doesn't re-fire think).

----
## merged from ttlilt-not-a-keepalive.md

---
name: ttlilt-not-a-keepalive
description: "a req's %ttlilt is a one-shot snap-timing advisor, NOT a re-arming keep-alive; the work that clears the gate must itself re-pump (i_elvisto think / feebly_ponder)"
metadata: 
  node_type: memory
  type: project
  originSessionId: e706066f-325c-4eae-adad-ee0bd28695ab
---

`i_req_ttlilt(req, secs, {waiting})` (Hovercraft.svelte) is ONLY a snapshot-timing hint to Story.poll_step ("this wall-clock slice isn't quiescent yet"). Hard rules (comment at the def): it does NOT re-fire think/reqyoncile at until_ts; calling it again with the same identity is a **no-op** (won't reset until_ts, won't clear `timed_out`); once expired the ttlilt walker marks `timed_out:1` and stops gathering it, so Story can go quiescent. So a gate-poll loop "re-arm ttlilt each pass while pending" only survives as long as the FIRST ttlilt's window — after it times out, nothing re-pumps.

Consequence: whatever clears the gate a held req waits on MUST schedule a fresh think itself. The compile-spinner-stuck / "needs more tickling, eventually finishes" bug was exactly this: `req_compile` (Lang.svelte, in req:Languish) holds with `waiting:'gen_write'` while `job.sc.pending`; `req_compiled_is_settled` (LangCompiling.svelte) cleared pending but didn't re-pump, so if req_compile already ran earlier in that do()-pass it stayed `firing` forever (dump: `req:compile,firing` + `ttlilt,waiting:gen_write,timed_out`). Fix = `H.i_elvisto(w, 'think')` right after `delete job.sc.pending`. The canonical wake-after-advance is `feebly_ponder()` (see e_reqyonciliation). Async req completion already re-pumps via `o_elvis_req`'s finish → `i_elvistwo(...,'think')` (Housing.svelte.ts). Related: [[nested-req-needs-cup-stamped]], [[mundanestation-ttlilt-determinism]], [[creduler-runner-architecture]].

Also spotted, not removed: a stray `debugger` gated to `name.includes("Idzeuzia")` in the rw_op write handler (Housing.svelte.ts ~1852) — freezes Idzeuzia writes if devtools open.

----
## merged from ttlilt-in-snap-means-timeout.md

---
name: ttlilt-in-snap-means-timeout
description: a live ttlilt in a got_snap ⟺ expecting() timed out — TRUE only since publish-at-arm closed the publish-race third path (2026-07-07); owner wants it as a global Story assertion
metadata: 
  node_type: memory
  type: project
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

**Invariant (owner flagged 2026-07-05).** `expecting(w, name, secs, async_fn)` (Hovercraft.svelte) is meant to
 have exactly two outcomes: **RESOLVE** (async settles → reqyoncile finishes the req → next poll sees NO live
  ttlilt → snap the resolved state) or **TIMEOUT** (async overran `secs` → ttlilt times out → Story snaps an
   in-progress picture WITH the ttlilt visible + on_step_ending('timeout')). So a live ttlilt in a got_snap
    should ONLY come from timeout — "the bounded escape, NOT the normal path."

**The third path that used to break it — closed 2026-07-07 (publish-at-arm), verified live on RaStock.**
 A ttlilt lives in THREE places: **arm** (`i_req_ttlilt` writes {ttlilt} on the world req), **publish**
  (agency_officing → `i_Story_o_req_ttlilt` gathers live world reqs → flat `Run.i({ttlilt,of_w,…})` copies at
   the H-root), **read** (`poll_step` → `o_Story_req_ttlilt` scans ONLY the H-root copies, unmutexed, no tree
    dive). `beliefs()` publishes in attend BEFORE `reqdo_sweep` pumps the beat that arms — so a sweep-armed
     ttlilt's own tick publishes NOTHING (armed after officing ran). The live editor's interval re-cycles
      officing within a tick and hides this; a **parked Story Run** (drive sitting in poll_step, an expecting's
       async_fn minting no thinks) never re-runs officing → the copy is never written → the pass snaps
        MID-FLIGHT with a live, un-timed-out world ttlilt frozen in — the "random snap timing" (self,round also
         inflated when a heartbeat was tried as the fix; DON'T — it spins the belief loop at ~20Hz and leans on
          entropy spay:graft to hide it). **Fix:** `i_req_ttlilt` now seeds the H-root copy at the arm
           (fresh-arm only; same House officing writes to = `this`), so the hold is visible the same tick with
            ZERO extra thinks. Blast radius touched every expecting/re-arming caller; re-record owed on
             MusuGenerateTestsMusic + MusuBounce (RaStock done).

**Therefore the invariant now genuinely holds** → the owner's **GLOBAL Story assertion** ("does this got_snap
 contain a live ttlilt? → fail") is finally SAFE to add (before, it would false-positive on the publish-race).
  One built-in check across every Book, no per-Book authoring; lives in the snap/verdict/matching layer, so it
   needs owner sign-off (story_matching = owner-approval gate). NOT YET BUILT. Relates to [[see-is-not-a-latch]],
    [[ttlilt-not-a-keepalive]]; the motivating opaque-stuck-ttlilt case was a [[remotewormhole-no-binwrite]] gap.
