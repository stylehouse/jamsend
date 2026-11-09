# Coding guide — the non-obvious mechanics

Things that bite because they look like something they're not. Read this before touching the belief
loop, `req`/`ttlilt`, the compile pipeline, or anything a Story snaps. The deep reference is
`Hovercraft.design.md`; this is the "what surprised us" layer on top, grown one lesson at a time.

## Wake ≠ Hold  (the one that bites most)

Two primitives look interchangeable and do **opposite** things:

- **Wake** — `feebly_ponder()`, `i_elvisto(w, 'think')`, a bare `bump_version()`. Means "run the
  loop again soon." It SCHEDULES a tick. It does **not** stop the loop going quiescent.
- **Hold** — a **ttlilt** (`i_req_ttlilt(req, secs, {...})`) on a live req. Means "the loop is NOT settled
  yet." It **prevents** Story from snapping until it clears.

**What Story actually reads.**  Its `poll_step` (StoryFu.g) snaps when the House has been quiet for
`quiesce_snap_time` (no think since), its todo is empty, nothing set `leave_running`, and **no ttlilt is
live** — that is the whole list.  An **unfinished `req`** is not on it: `needs_work` halts descent within a
pass, and it holds the snap only for as long as something keeps WAKING the loop (each wake resets the quiet
clock).  On its own it bows out, the loop goes quiet, and Story snaps with the req un-`ok` sitting IN the
snap — the tell to look for.
> 2026-11-09 (MusuRaStream, red at every step since September, identically every run): `req:crossing`
> held "until the boundary chunk arrives" by leaving itself un-ok.  Nothing woke the loop, so the step
> settled two rounds in and the snap showed `req:crossing,eternal` without `ok`; the transcoded chunk
> landed a step late and the head crossed on a drop.  This guide said an unfinished req holds — it
> doesn't.  Fix: `MusuRaStream_hold_boundary` — a one-shot gate req carrying a ttlilt, armed in the beat
> that sent the ask (the cause), waking the next pass itself while it waits (the wire and the transcode
> are pass-driven), finishing+dropping the moment the chunk lands (no fixture footprint).  Same shape as
> `MusuHeist_hold_for_a_pass`.  0 of 4 runs crossed → 3 of 3.

A pending async operation that must show up in the snap needs a **HOLD**, not just a WAKE. A wake
only ensures the work eventually runs — Story can still snap *before* it does.

**Why it hides:** interactively (no Story running) a wake is enough — the work runs, you see it. The
bug only appears under a Story run (which snaps at quiescence) and only when the work is slow enough
to lose the race. So it reads as a "flaky test," not a "missing hold." A slow compile or a cold read
widens the window and tips a ~50/50 race to mostly-fail.

**The fix shape:** arm the hold **synchronously, at the cause** — never in a later gate you reach via
a wake.
> 2026-07-01 (HohoTiles "didn't take the text manipulation"): `req_text_mutated`'s machine/test path
> set `dock.c.compile_ready = true` (a plain `.c` flag) + `feebly_ponder()`, and left the real re-arm
> of `req:compile` to a next-tick gate. Both are wakes — so Story could quiesce and snap in the gap,
> capturing the *stale* compile output (and its stale downstream Rundown rerun). The edit itself had
> applied fine; only the re-run raced. Fix: re-arm `req:compile` (`delete sc.finished`/`sc.firing` +
> `reqyoncile`) right there in `req_text_mutated`, so its `needs_work` holds the snap from the same
> pass. Flaky (ok_pct flip-flopping 0.33/0.89) → robustly green (4/4).

## ttlilt rules  (the hold with a timeout)

- A ttlilt is a **one-shot snap-timing advisor** — "don't snap for ~N seconds." Re-arming is a no-op;
  it does not re-fire a think. It is NOT a keep-alive. (memory: ttlilt-not-a-keepalive)
- A ttlilt must ride a `req` that **FINISHES** — finishing is the done-signal (hygiene drops ttlilts
  of finished reqs). Can't-finish host → `req/req/ttlilt` (a finishing child holds it). Finish-
  elsewhere → **DRIVE the host**, don't bridge with a bare ttlilt. (memory: ttlilt-rides-finishing-req)
- Prefer DRIVING a req to unfinished (`delete sc.finished` + `reqyoncile`) over a timeout bridge when
  the req's own work keeps the loop busy (a compile that writes, a run that lands) — that is a hold by
  wakes.  When it would only WAIT for something to arrive, give it a ttlilt: waiting makes no wakes.
- A ttlilt holds; it does not wake.  If the thing you are waiting for is pass-driven (a pump that only
  moves when the House thinks), the holder must wake the next pass itself while it waits.
- Bound it generously and let running out be the failure: a step that ended on its ttlilt reports
  `timeout:1` (runner_sweep prints `⏱ timeout step N`) — read that as a starve, not a green.

## The compile → rerun chain  (worked example of an all-holds path)

edit → `Lang_texting` → `req:text_mutated` re-arms `req:compile` → `Lang_compile_dock` (gen write,
ttlilt held til written) → `e_Lies_compiled` un-finishes the sibling `req:Codebit` → Codebit finishes
with the new dige → `req:Rundown` computes a new *moment* → `req:BlatDo` fires the run and holds a
ttlilt → run lands → `req_run_method` drives Rundown → records `%ran` → BlatDo reaped. **Every link
holds the snap** (a ttlilt, or an unfinished req whose own work keeps waking the loop), so the snap
can never catch a half-done state. A missing hold anywhere in the chain = a race.

## Verify a timing fix by RE-RUNNING, not once

A race is invisible in a single green run. Run the Book several times — a race shows as different
diges / a flip-flopping `ok_pct`. **Robustly green across N runs is the gate**, not one pass. Always
via the live runner (`scripts/runner_ask.mjs`), never headless `Story_cli` (false greens).
