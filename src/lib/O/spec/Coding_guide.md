# Coding guide — the non-obvious mechanics

Things that bite because they look like something they're not. Read this before touching the belief
loop, `req`/`ttlilt`, the compile pipeline, or anything a Story snaps. The deep reference is
`Hovercraft.design.md`; this is the "what surprised us" layer on top, grown one lesson at a time.

## Wake ≠ Hold  (the one that bites most)

Two primitives look interchangeable and do **opposite** things:

- **Wake** — `feebly_ponder()`, `i_elvisto(w, 'think')`, a bare `bump_version()`. Means "run the
  loop again soon." It SCHEDULES a tick. It does **not** stop the loop going quiescent.
- **Hold** — an **unfinished `req`** (`needs_work`), or `i_req_ttlilt(req, secs, {...})`. Means "the
  loop is NOT settled yet." It **prevents** Story from snapping until it clears.

A pending async operation that must show up in the snap needs a **HOLD**, not just a WAKE. A wake
only ensures the work eventually runs — Story can still snap *before* it does.

**Why it hides:** interactively (no Story running) a wake is enough — the work runs, you see it. The
bug only appears under a Story run (which snaps at quiescence) and only when the work is slow enough
to lose the race. So it reads as a "flaky test," not a "missing hold." A slow compile or a cold read
widens the window and tips a ~50/50 race to mostly-fail.

**The fix shape:** arm the hold **synchronously, at the cause** — never in a later gate you reach via
a wake.
> 2026-07-01 (LakeTiles "didn't take the text manipulation"): `req_text_mutated`'s machine/test path
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
  you can — a deterministic hold beats "hope N seconds is enough."

## The compile → rerun chain  (worked example of an all-holds path)

edit → `Lang_texting` → `req:text_mutated` re-arms `req:compile` → `Lang_compile_dock` (gen write,
ttlilt held til written) → `e_Lies_compiled` un-finishes the sibling `req:Codebit` → Codebit finishes
with the new dige → `req:Rundown` computes a new *moment* → `req:BlatDo` fires the run and holds a
ttlilt → run lands → `req_run_method` drives Rundown → records `%ran` → BlatDo reaped. **Every link
holds the snap** (an unfinished req or a ttlilt), so the snap can never catch a half-done state. A
missing hold anywhere in the chain = a race.

## Verify a timing fix by RE-RUNNING, not once

A race is invisible in a single green run. Run the Book several times — a race shows as different
diges / a flip-flopping `ok_pct`. **Robustly green across N runs is the gate**, not one pass. Always
via the live runner (`scripts/runner_ask.mjs`), never headless `Story_cli` (false greens).
