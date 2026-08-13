# Datalayer_todo — Stuff.svelte.ts and Hovercraft, reviewed

Commissioned by the owner 2026-08-13: *"yeah review our data layer... somehow. Stuff.svelte.ts and
 Hovercraft"* — and, in the same breath, the question this doc opens with: *"is it a req pile, like became
  a standard recently when I was more involved in code aesthetics before it started talking about pump?"*

A working `_todo`. Companions: `Hovercraft.design.md` (the req machine's own design), `Coding_guide.md`
 (the non-obvious mechanics), `Cstructures_todo.md` (the glass NOTATION for C**, a different subject).

## 0. Next move (read first)

Nothing here is urgent and nothing here is broken. **One** finding worth a decision:
 1. **§3.1 `resolve()` is O(N²) with a proxy multiplier** — real by construction, UNMEASURED as to whether
     any live container is big enough to feel it. The fix is four lines. Decide by measuring, not by taste.

§3.2 is the audit that *dissolved*: the off-pump queues look like an unbounded leak from the producer side
 and are not, because the servicing actor sweeps them. It is kept because the next person will reach the
  same wrong conclusion and may "fix" it at the wrong end. Everything else is description, recorded because
   answering the owner's question needed it.

## 1. The answer: yes, it is a req pile — and "pump" is not a rival standard

**Yes.** The req pile is the standard, and it is deliberately split across **two walls**:

| wall | file | owns |
|---|---|---|
| **mechanism** | `Stuff.svelte.ts` (`StuffAware`) | `%req` is *"the ONE property the Stuff layer treats as meaningful"*. `oai`/`doai` seed or re-key a req; `do()` drives a host's reqs highest-`maz` first; `finish()` settles one; `all_finished()` rolls up; `maybe_mutate_sc()` merges and stamps `%mutated`. **This wall does not know House.** |
| **meaning** | `Hovercraft.svelte` | which handler a req gets (`do_fn_for`: `%mutated`→`mutated_fn`, then a doai-set `req.c.do_fn`, then the `H.req_$name` convention), re-entry out of time (`reqyoncile` / `e_reqyonciliation`), `reqonce`, and the `ttlilt` advice Story reads. |

The seam is one line of Stuff's own: when `do()` needs a handler it **climbs `req.c.up` until it meets a
 node with `do_fn_for`** — so it reaches the House without ever naming it. That is the whole trick, and it
  is why the mechanism can live below the thing that gives it meaning.

**"Pump" is the VERB, not a competing architecture.** `do()` *pumps* a host's reqs; `reqdo_sweep`
 supervises the pool. What sounds like a second standard is actually the named escape hatch:

> **off-pump** — an owner-driven IO queue (`wh`, `rw_queue`, `fs_op`, the Radios' load queues) is just
> `w.oai({name:1})`: a container with a **non-req mainkey** holding `%req` items, so they sit outside `w`'s
> supervised pool and `reqdo_sweep` never touches them. The owner drives with `q.do(fn)` or iterates
> `q.o({req:1})` and retires by hand.

So the vocabulary is coherent: *pile* is the shape, *pump* is the driving, *off-pump* is opting out of
 supervision on purpose. Nothing has drifted; the two words came from the same design.

**A req is a proto-`w`** — *"lighter and curlier, that does its work and finishes rather than persisting"* —
 and hosts nest freely (`w/req**`). That is the one sentence to keep: it explains why `maz` levels exist,
  why `needs_work = !finished && !ok` gates entry, and why `sc.ok` is pass-local rather than durable.

## 2. Where the substrate actually is

`Stuff.svelte.ts` (1600 lines) is **not** a req pile and must not become one — it is the wall the pile
 stands on, and a req is made of C particles, so the store cannot be built out of reqs without circularity.
  It is a plain class plus an index (`TheX`): `X.z` the ordered list, `X/$k` a key bucket, `X/$k/$v` a value
   bucket. `i()` attaches and keys; `o_query`/`o_results` read; `drop()` **marks** `c.drop` and leaves the
    row; `compact()` rebuilds through the same `i()` path that built it, carrying `serial_i` over so
     observers see one clean bump rather than a version reset.

Two guards worth knowing about, both earned:
- **auto-GC before the fatal** (`i_z`, :157). `drop()` only marks, so a hot parent — a Pier `%outbox`, a req
   shelf — accretes dead rows until the ceiling. At **5000** rows the dropped ones are purged in place; only
    genuinely **live** rows past **6000** still throw, and the message now names the offending index. The
     fault this fixed killed the share beat and silently stopped the Sounditrons talking.
- **`replace()` is a whole-container transaction** and empties the container across two awaits. Swapping one
   timer particle with it left the House visibly childless ~17×/minute, which destroyed and rebuilt Vytui's
    entire subtree each time. Merge in place (`oai`) unless you mean the transaction.

## 3. Findings

### 3.1 `resolve()` pairs old children to new in O(N²), with a per-element proxy cost

`StuffAware.resolve(X, oldX, partial, q)` (`Stuff.svelte.ts`:1091) is `replace()`'s matcher — what turns a
 container swap into clean `Dif:change` pairs instead of goner+new. Its bookkeeping is three linear
  structures scanned linearly:

```
unfound = [...X.z]                              // :1181
claim = (oldn,n) => { …; unfound = unfound.filter(m => m != n); claimed.push(oldn) }   // :1184
for (let n of oldX.z) { if (!unfound.includes(n)) continue; claim(n,n) }               // :1191
…  if (!unfound.includes(n)) continue           // :1192, :1208
…  if (claimed.includes(oldn)) continue         // :1216
…  .filter(oldn => !claimed.includes(oldn))     // :1246
```

Every `includes` is O(N) and every `claim` rebuilds `unfound` with a full `filter`, so matching K of N
 children is O(K·N) — quadratic on the common path where most children pair up. **And this file is
  `.svelte.ts`**, so each element comparison pays a reactive-proxy dispatch: the multiplier recorded in
   [[svelte-ts-rewrites-array-search]], where `includes`/`indexOf` were the measured problem and `Set`/`Map`
    the fix. The same file already took that medicine once — `i_refer` :209 notes *"O(1) via the value map
     (2026-08-06) — was `x.vs.indexOf(v)`, an O(N) scan per lookup"*.

**UNMEASURED, and say so:** I have not shown that any live container is large enough for this to matter.
 Small containers dominate, and quadratic on 8 children is nothing. The honest next step is to instrument
  `resolve` with the size it was handed and read the distribution off a live tab — [[a-meter-can-clip-what-it-measures]]
   applies, so count the N it receives, not the time it takes. **Do not "optimise" this on the strength of
    the shape alone.** If the distribution says it never exceeds a few dozen, close this finding.
 If it does: `unfound` becomes a `Set` (delete instead of filter), `claimed` becomes a `Set` (`has` instead
  of `includes`), and the ordered `X.z` walk is untouched — so ordering and semantics are bit-identical and
   only membership gets cheaper.

### 3.2 Off-pump queues — AUDITED, AND THE PATTERN IS SOUND. Recorded because it looked like a bug.

The shape is alarming on the producer side and I expected a leak. Every off-pump write seeds an **anonymous**
 req — `rw.oai({ req: 1, rw_name: path, rw_op: 'write', rw_data: snap })` (`Auto.svelte`:1138, :1436;
  `LiesLies.svelte`:1253, :1292; `Story.svelte`:3004) — and because `rw_data` differs every time, `oai` can
   never match an existing one: it mints a fresh serialised `%req:$i` per save, each holding a **whole
    snapshot string in `sc`**. None of those call sites drops anything, `reqdo_sweep` does not supervise an
     off-pump queue, and the `rw_op` actor only marks `rw_req.sc.finished = 1` — which is CLAUDE.md's own
      warning that `finish()` *"does NOT detach the req"*. That reads like unbounded growth straight into
       §2's 6000-row fatal, with a library snap pinned per row.

**It is not, because the retirement lives in the CONSUMER, not the producer:**
```
;(rw.o({ req: 1, finished: 1 }) as TheC[]).forEach(rr => rw.drop(rr))    // Housing.svelte.ts:2606
;(fs.o({ req: 1, finished: 1 }) as TheC[]).forEach(fr => fs.drop(fr))    // :2511 — "drop settled
;(wh.o({ req: 1, finished: 1 }) as TheC[]).forEach(n  => wh.drop(n))     //  wrappers so the queue
                                                                        //  doesn't accrete (do() never drops)"
```
Every actor that services an off-pump queue sweeps its own settled wrappers at the end of each pass. All
 four named queues do it, and `Auto`'s one *named* req (`req:'lib_read'`) additionally drops by hand on its
  error paths, where a re-ask must re-issue rather than re-find a stale reply.

**So the house rule already exists — it is just not where you would look for it.** Write it down as: *the
 queue's SERVICER retires it, at the end of the pass, by sweeping `{req:1, finished:1}`.* Anyone adding a
  new off-pump queue must add that line to its actor; a producer that "forgets to drop" is correct by
   design. **No action.** Kept in this doc because the producer side is genuinely misleading to read, and
    the next person to audit it will reach the same wrong conclusion I did and may "fix" it at the wrong end.

### 3.3 Not a finding, but the seam most likely to bite a newcomer

`sc` is not reactive — only `version` is ([[sc-is-not-reactive-only-version-is]]). Combined with §1's split,
 that means a req can change state in a way nothing observes unless someone bumps. The req machine handles
  this internally (`maybe_mutate_sc` bumps), but code that pokes `req.sc` directly — and there is some —
   silently freezes every face watching. `reqyoncile` exists partly to make this impossible: it queues the
    sc to apply *at* `e_reqyonciliation`, so **state change and work arrive together**. Reach for it rather
     than writing `req.sc.x = y` from an async callback.

## 4. What this review did not cover

`IDB.svelte.ts`, the `Thing*`/`Stuff*` satellites, and the relic `%aim`/`%satisfied` machinery quarantined
 at the bottom of Hovercraft (idle on this House). Also: nothing here was executed. The findings are read
  off the source, and §3.1 says plainly which of its claims is unmeasured.
