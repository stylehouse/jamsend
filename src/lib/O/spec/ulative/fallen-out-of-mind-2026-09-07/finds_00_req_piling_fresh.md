# Req piling — should a landed ask be a req?

Fresh reading, no prior context. Concrete case: the `%Rummage` folder-describe ask
(`Ghost/M/Heist.g:2162-2186` mints it, `:2339-2376` answers it by polling the mirror each beat).

## A. What "req piling" would mean for the landed ask

A req is *"a proto-w, lighter and curlier, that does its work and finishes rather than persisting"*
(`Hovercraft.svelte:232`). `do()` (`Stuff.svelte.ts:754-765`) pumps a host's `%req` children highest-maz
first; `needs_work = !finished && !ok` gates entry; a req that bows out unfinished halts descent
(`:763`), and that unfinished-ness IS the hold Story waits on (`Coding_guide.md:13`). A throwing do_fn is
contained and simply retried next pass (`:781-797`).

Today the source side answers with a sweep plus five `.c` stamps: `answered_epi`, `answers`, `answer_ts`
(`Heist.g:2366-2374`), and the asker keeps `desc_ts` + `keep.sc.asks` (`:2615-2618`). Every one of
those answers a question a req answers structurally — *already running? ran recently? ran too often?* —
and none is visible in a snap (`Backpressure_todo.md:712-721` censused **29** such stamps across
Heist/Ra/Repli).

The req-shaped version, in the machine's vocabulary:

- **Not the `%Rummage` itself.** The landed ask is *foreign matter* in a mirror, upserted by Repli
  (`Repli.g:350`); it is the asker's particle. *"Producer and consumer never share a req"*
  (`Backpressure_todo.md:701`), and `%req` is minted only through `oai|doai` (`Hovercraft.svelte:255`).
  The source mints its **own** `req:Answer,of:<seed|want>,pier:<asker>` beside it — the `of:` many:1
  referrer shape CLAUDE.md prescribes.
- **Lifetime: transient.** Not eternal (the ask is one episode), not permanent (not one-per-ghost).
- **maz: low** — below any stream pump; describing a folder must never outrank bytes.
- **`finished`** cannot mean "the answer landed" — there is no ack on this wire, which is the whole
  reason the ≤3 budget exists. Honestly it means one of: budget spent (`sc.answers` reached 3), the
  asker's `%Rummage` left the mirror (goner), or the ask was superseded (`sc.epi` drifted → un-finish
  and re-arm, the `mutate+stamp+run` preset at `Hovercraft.design.md:225`).
- **Who drops it:** the owner, at the same sweep that pumps it — *"an owner drops its finished
  transient reqs"* (CLAUDE.md; `Network_procedures_todo.md:299-302`).
- **The episode counter does not go away.** A re-landed upsert whose sc did not change does not bump
  (`Heist.g:2176-2179`), so `ask.sc.n` on the wire is still what tells the source "new ask". It moves
  from `ask.c.answered_epi` to `req.sc.epi` — legible, not deleted.
- **The 5s patience is not a ttlilt.** A ttlilt is snap-timing advice, *"NOT a keep-alive"*
  (`Coding_guide.md:36-37`); it does not re-fire anything. The re-answer still needs a clock, and the
  clock is the share beat.

So yes, it is more in the spirit — but only if the beat becomes the *clock* and stops being the
*worker* (`Backpressure_todo.md:739-742`).

## B. Has the codebase been avoiding reqs?

Not as doctrine. The census: ~20 distinct req names across `Ghost/` (Peeroleum, Repli, Swarm, the Story
Books) and ~100 across `src/lib/O` (Lies, Lang, Story, Machinery). The compile pipeline is *all* holds
(`Coding_guide.md:44-51`); `Datalayer_todo.md:26-28` answers the owner's own question flatly: *"Yes. The
req pile is the standard"*, and *"pump is the verb, not a competing architecture"*.
`Backpressure_todo.md:1372-1378` is RULED in the owner's voice: *"req can take the business end of a
lot of the model — it is a better place for state than a string on a particle."* CLAUDE.md's
"scaffolding, not ledger" is hygiene about *dropping*, not a warning against *piling*.

What HAS been avoided is precise and local: **the transport ghosts stay off `beliefs()`**, and the req
machine is welded to it (`reqdo_sweep` runs inside `beliefs()`, `Housing.svelte.ts:1291`).
`Heist_todo.md:949-951`: *"The pump — there is no req pile… No ttlilt, no maz level, no todo gate."*
`Radio.g:24`: *"THE MUTEX LAW… nothing here runs under beliefs()."* `Swarm.g:4903-4912`: the sound
supervisor *"MUST NOT BE A REQ"* because a req *"is queued behind the very wedge it exists to detect"*
(`"beliefs mutex held 8s by H:Mundo fn:swarm_share_beat"`). Each is an earned scar, not a stance
against reqs — it is a stance against *awaiting IO under the mutex*, and the field notes are unanimous:
`Ra.g:3864, 3879`; `Repli.g:783` (verify+mint per frame under the mutex), `:950`, `:1380`, `:1416`
(*"never sends inline in this drain"*). `Backpressure_todo.md:1363-1366` names it: byte work on the
C tree's critical section, *"fixed there. Do not restructure the drain."*

So: the pile is the standard, the transport layer opted out of it to escape the mutex, and
`Backpressure_todo.md §4` (the `%Heist` req pile, `:687-770`) is the RULED design for bringing it back —
written 2026-08-06, not built.

## C. Coupling every thought into `beliefs()`

If every pending intention is a req, then `beliefs() → attend → reqdo_sweep` walking the pile *is*
attention, and `i_Story_o_req_ttlilt` (`Hovercraft.svelte:466-544`) already gathers the world's
patience into one flat list at the H-root.

**What it buys.** The 29 `.c` stamps become sc on reqs: snap-visible, diff-able, `%see`-assertable
(*"the source is waiting on 1 answer"*). An unanswered ask becomes a HOLD, so the MusuHeist-family
Books stop racing the wire (`Coding_guide.md:16-22`). Retry-on-throw is free (`Stuff.svelte.ts:781-797`)
instead of `catch (er) { ask.c.answers = n }`. *"Creating a req is scheduling its supervision"*
(`Hovercraft.design.md:202`) — the sweep at `Heist.g:2343-2376` dissolves. And the `%mutated` preset
gives episode-drift detection for free where today it is hand-compared.

**What it costs, concretely.**
1. **The mutex.** `do()` is serial and an `await` inside a do_fn is blocking (`Backpressure_todo.md:748-750`).
   `Heist_rummage_answer` does a census and, on a want-ask, a whole file read (`Heist_materialise_one`,
   `Heist.g:2202`). Under `beliefs()` that is exactly the stall class at `Ra.g:3879`. The shape must be
   issue → return unfinished → `reqyoncile` on completion (`Hovercraft.svelte:271-304`).
2. **Reqs have no clock.** `reqdo_sweep` runs on a `think`; nothing ticks a parked req at +5s. The beat
   remains the metronome — a req makes the retry *legible*, not *self-timing*.
3. **Snap noise.** Every ask/answer pair lands in every fixture; the `awaitbuf` cull (38 dead rows per
   track) is the cautionary tale, and the eternal re-arm already churns 20-40 elvises per settle
   (`Story_future_directions.md:192-196`). The drop law must be built in from the first line.
4. **A req cannot watch the machine it rides.** `Swarm.g:4906` stands: liveness supervision stays a
   plain timer on `.c`.
5. **The wire is still lossy.** No req shape makes `finished` mean "delivered"; it only makes the
   *guess* visible.

## D. Recommendation: the middle path — build `Backpressure_todo §4.2`, narrowly, here first

Do not intensify piling globally; the MUTEX LAW is paid for. Do not keep the sweep+counter shape
either; it is the deaf-budget bug's native habitat (`Heist.g:2358-2365`). Instead:

- On landing (or on the beat's first sight), `home.oai({ req:'Answer', of:<seed|want>, pier:<asker> })`
  beside the mirrored `%Rummage`, carrying `epi`, `answers`, `at` as sc. Transient, low maz.
- The beat thins to `home.do()` — *"the beat stops being the worker and stays the clock"*.
- do_fn: epi drifted → reset `answers`; `answers ≥ 3` or the `%Rummage` gone → `finish` + drop at
  the sweep; within 5s → return (stays `needs_work`, so a Book holds); else **detach** the answer
  (never awaited under the beat, `Ra.g:3862` idiom), stamp `answers`/`at`, and `reqyoncile` on
  settle.
- Drop finished reqs in the same sweep, over a fresh `o()` snapshot.

That turns the scaffolding into matter the town can see, prove and rewrite (`Homethink §1`) without
handing the transport layer back to the mutex. If it holds under `MusuNeGrind`'s *"beat never
overruns 600ms"* invariant (`Backpressure_todo.md §0`), the same seam lets `materialise` and the pull
window join the pile — and only *then* does "attention = walking the reqs" become true for the music,
not just for Lies.
