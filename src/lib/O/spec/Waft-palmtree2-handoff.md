# Waft palmtree2 handoff — Languish + Languinio

Carry-forward from the 🌴+1 conversation.  Covers the reqy mechanics needed
to understand and implement the `req:Languish` renovation, the `%Languinio`
ave particle, and what they replace.

---

## What has already landed since 🌴

- `LiesCurse`: `Lies_first_doc` fallback added alongside `Lies_first_point_doc`.
  Cold-start case 2 now falls back to the first %Doc even if the Waft has no
  Points yet (new Wafts).  Both picker calls in `LiesCurse` updated.

- `Hovercraft`: `rq.finish(req)` now drops `req/%ttlilt` particles alongside
  the oncelers cleanup:
  ```js
  req.o({ ttlilt: 1 }).map(ttl => req.drop(ttl))
  ```
  This closes the `// <` marker in the ttlilt region ("reqy().finish(req)
  should drop req/%ttlilt particles …"). Delete that `// <` now.

---

## Hovercraft change still to land — multi-maz `do()`

Current `do()` runs the highest unfinished maz then stops.  Languish needs it
to *descend* to the next maz level in the same pass when a whole level finishes,
so `req:text_loaded` finishing and `req:compile`'s reqonce firing happen in one
tick rather than two.

```js
// do them all — run the highest unfinished maz level. If that level fully
//  finishes this pass, descend to the next maz down in the same go, so a
//  reqonce that was blocked by a higher maz fires now, not next tick.
async do(fn?: Function) {
    while (true) {
        const N = q.o().filter((req: TheC) => !req.sc.finished)
        if (!N.length) return

        const maz_high = Math.max(...N.map((req: TheC) => req.sc.maz || 1))
        const level = N.filter((req: TheC) => (req.sc.maz || 1) == maz_high)

        for (const req of level) await q.do_one(req, fn)

        // someone armed a ttlilt and bowed out — Story waits, stop here.
        if (level.some((req: TheC) => !req.sc.finished)) return
        // whole level finished — loop to the next maz down.
    }
},
```

---

## reqy mechanics — what you need to know

These live in Hovercraft `//#region reqy`.  Don't look them up in snaps or
talk about `reqcons:1` — it's backoffice infrastructure, invisible in docs.

### Creating a reqy context

```js
const rq = H.reqy(w)          // mainkey = 'req'
const rq = H.reqy(w, { do_fn: myFn })   // attach protocol fn at creation
```

`reqy(w)` creates/finds `w/reqcons/reqcon:req` (invisible) and returns an
`rq` object with methods below.  All req particles live on `w`.

### `rq.roai(c, sc?)` — find-or-create a req

```js
await rq.roai({ req: 'Languish', path })          // named req
await rq.roai({ req: 'text_loaded', maz: 3 })     // with maz
```

First arg is identity (used for lookup); second arg is sc to set on creation
only.  If found, `sc` is ignored unless values changed — then `%mutated` fires.
`maz:1` is the default and is deleted from sc (snap is clean).

### `rq.do()` — run the highest-maz unfinished req(s)

With the multi-maz patch above, descends through maz levels as long as each
level fully finishes.  Stops when a req arms a ttlilt and returns unfinished.

### `rq.finish(req)` — mark done, yoink oncelers + ttlilts

```js
q.finish(req)
```

Stamps `req.sc.finished = 1`.  Deletes all `req.c.oncelers` keys from `req.sc`
so the snap only shows `%finished`.  Drops `req/%ttlilt` particles.
Calls `feebly_ponder()`.

### `rq.unify_finished(over_rq?)` — cascade finish upward

When all sub-reqs under `w` are finished, finishes `w` itself (treating it as
a req owned by `over_rq`).  Used in nested req patterns:

```js
sub.do()
sub.unify_finished(q)   // finish Languish when all three phases finish
```

### `H.reqonce(req, name)` — one-shot gate

```js
if (H.reqonce(req, 'opening')) {
    // this block runs exactly once per req lifetime
    H.Lang_open_doc(languish)
}
```

Stamps `req.sc[name] = 1` and `req.c.oncelers[name] = 1` on first call;
returns `true`.  Returns `false` on every subsequent call.  `rq.finish()`
yoinks both so `%opening` doesn't appear in the resting snap.

*Returns true = "your one chance to kick this off."  Not "the work is done."*

### `H.i_req_ttlilt(req, secs, sc?)` — hold Story open

```js
H.i_req_ttlilt(req, 0.5)
```

Creates `req/%ttlilt,until_ts:T` (identity = `{ttlilt:1,...sc}`).  Climbs
`req.c.up` chain to `w` and sets `w.c.has_req_ttlilt`.  Story's poll holds
the snap open until `until_ts`.

**One-only**: same identity means the ttlilt is created once; subsequent calls
with the same sc do nothing to `until_ts`.  The deadline is fixed, not pushed
out each tick.  Calling it every tick while waiting is fine and intended.

`rq.finish(req)` drops all `req/%ttlilt` children so stale ttlilts never sit
beside `%finished`.

### Named req dispatch

`do_one` dispatches to `H[q.k + '_' + name]` for a named req.  For mainkey
`req` and `{req:'Languish'}`, it calls `H.req_Languish(req, q)`.  For a sub-req
`{req:'text_loaded'}` on Languish (whose sub `rq` also has `k='req'`), it
calls `H.req_text_loaded(req, q)`.

### `handler_of_last_resort`

If a req has its own `reqcons` children, `do_one` delegates to them
recursively and `unify_finished` finishes the parent when all children are done.
This is how Languish works: its own `do_fn` (`req_Languish`) stages three
sub-reqs and calls `sub.do(); sub.unify_finished(q)`.

### `c.up` chain

`req.c.up = w` (the host).  `i_req_ttlilt` climbs this.  For sub-reqs inside
Languish: `phase_req.c.up = languish`, `languish.c.up = w:Lang`.  So a ttlilt
on a phase req climbs up through Languish to `w:Lang` and sets
`w:Lang.c.has_req_ttlilt` — no scheme:req extension needed.

---

## What Languish replaces

| Old particle on w:Lies | New home |
|------------------------|----------|
| `open_req:1, path, done` | `req:Look` on w:Lies |
| `compile_pending:1, path, source` | req:Languish / req:compile phase |
| `loaded_doc:1, path, gen_path, base_dige` | `req:Languish.sc.{docC, look_req}`; `gen_path`/`base_dige` stay on `docC.sc` |

`Lang_graft_points` (currently a free-running every-tick function in
LangGraft) becomes `Lang_graft_points_once` — a plain function called only
from the `req:grafted` phase and from a fresh Languish on cursor-move.

Current flow (to replace):
```
Lies: open_req processed →
  LiesStore_read →
  i_elvisto('Lang/Lang', 'Lang_open_doc', {path, gen_path, text}) →
  w.oai({loaded_doc, path, gen_path}); ld.sc.base_dige = ...

Lang: e_Lang_open_doc → docs.oai({doc:path}); ave text-sync; Lang_set_active_doc
  compile fires from e_Lang_editorBegins once CM state exists

Lies: e_Lies_compiled → compile_pending
  LiesRealised → LiesStore_write; Ghost_update_notify; Lies_compile_settled →
  Lang: clears Compile/Pending
  (Story snaps here; LangGraft runs next tick; race)
```

New flow:
```
Lies: req:Look →
  LiesStore_read →
  Lang_open_doc(languish) writes text + mints docC
  ↓ descends via maz in same tick:
Lang: req:Languish/req:text_loaded fires once, monitors docC.sc.text_in
    → req:compile fires Lang_fire_compile once, monitors Compile/%Pending
      (ttlilt holds Story open during compile)
    → req:grafted calls Lang_graft_points_once
      (Story snaps here — all phases done, Pmirrors resolved)
```

---

## req:Look (w:Lies) — replaces open_req

```
w:Lies
  req:Look, path:Ghost/test/Hello.g, Waft:Ghost/Tour
    text_loaded:1    ← reqonce: LiesStore_read done, text handed to Lang
    finished:1
```

Minted by `Lies_ensure_doc_loaded` (currently mints `open_req`).  The Look
`$C` is stamped onto `req:Languish.sc.look_req` as a cross-reference so that
later when Points move (method rename), Lies can walk `w:Lang`'s Languish reqs
by `look_req` to find the affected docC without a full rescan.

---

## req:Languish (w:Lang) — Lang's mind for one doc

### Shape at rest (oncelers yoinked by finish)

```
w:Lang
  req:Languish, path:Ghost/test/Hello.g
    docC: $C           ← set by req:text_loaded's reqonce, read by compile + grafted
    look_req: $C       ← cross-ref to w:Lies/req:Look
    req:text_loaded, maz:3, finished:1
    req:compile,     maz:2, finished:1
    req:grafted,     maz:1, finished:1
    finished:1
```

### Languish do_fn — newest wins

```js
async req_Languish(req: TheC, q: any) {
    const H = this as House
    const w = req.c.up as TheC

    // newest Languish wins — evict all prior paths' Languish particles.
    //  a cursor move to a new doc is just: w.oai({req:'Languish', path:newPath})
    //  then this line does the takeover on its first do().
    if (H.reqonce(req, 'sole')) {
        w.o({ req: 'Languish' }).filter(r => r !== req).map(r => w.drop(r))
    }

    // stage the three phases once
    if (H.reqonce(req, 'staged')) {
        const sub = H.reqy(req)
        sub.roai({ req: 'text_loaded', maz: 3 })
        sub.roai({ req: 'compile',     maz: 2 })
        sub.roai({ req: 'grafted',     maz: 1 })
    }

    const sub = H.reqy(req)
    await sub.do()
    sub.unify_finished(q)
},
```

Re-grafting an already-open doc is uniform: drop Languish, re-mint, text_loaded
and compile pass their monitors immediately (docC has text + compile output
already), grafted re-runs against the current What_Points.

### req:text_loaded, maz:3 — get docC + text ready

Not instant — monitors the text being genuinely in docC.

```js
async req_text_loaded(req: TheC, q: any) {
    const H = this as House
    const languish = req.c.up as TheC
    const languinio = (languish.c.up as TheC).o({ Languinio: 1 })[0] as TheC

    if (H.reqonce(req, 'opening')) {
        // one chance: mint docC, install CM text from Look req's loaded content.
        //  sets languish.sc.docC.  Lang_open_doc replaces e_Lang_open_doc handoff.
        languinio.oai({ spinner: 'text_load' })
        H.Lang_open_doc(languish)
    }

    const docC = languish.sc.docC as TheC | undefined
    if (!docC || !docC.sc.text_in) {
        // docC not minted yet, or text not installed — fixed 0.3s grace
        H.i_req_ttlilt(req, 0.3)
        return
    }
    languinio.o({ spinner: 'text_load' }).map(s => languinio.drop(s))
    q.finish(req)
},
```

### req:compile, maz:2 — fire compile, wait for %methods

`Lang_fire_compile` lives here — not in text_loaded.  With multi-maz `do()`,
this reqonce fires in the same tick text_loaded finishes.

```js
async req_compile(req: TheC, q: any) {
    const H = this as House
    const languish = req.c.up as TheC
    const docC = languish.sc.docC as TheC
    const languinio = (languish.c.up as TheC).o({ Languinio: 1 })[0] as TheC

    if (H.reqonce(req, 'firing')) {
        // one chance: text is now in — kick the compile.
        languinio.oai({ spinner: 'compile' })
        H.Lang_fire_compile(docC)
    }

    // monitor: %Compile settled — %Pending gone, %methods present
    const job = docC.o({ Compile: 1 })[0] as TheC | undefined
    if (!job || job.o({ Pending: 1 }).length || !job.o({ methods: 1 }).length) {
        H.i_req_ttlilt(req, 0.5)   // holds Story open during compile
        return
    }
    languinio.o({ spinner: 'compile' }).map(s => languinio.drop(s))
    q.finish(req)
},
```

This ttlilt is what kills the snap-before-graft race.  Compile is already
in flight before Story would settle.

### req:grafted, maz:1 — run the graft

```js
async req_grafted(req: TheC, q: any) {
    const H = this as House
    const languish = req.c.up as TheC
    const w = languish.c.up as TheC
    const docC = languish.sc.docC as TheC
    const languinio = w.o({ Languinio: 1 })[0] as TheC

    if (H.reqonce(req, 'ran')) {
        // one chance: compile output is ready — run the graft pass once.
        //  Lang_graft_points_once is a plain function, not a free-running tick.
        languinio.oai({ spinner: 'grafted' })
        H.Lang_graft_points_once(w, docC)
    }
    // unresolved Pmirrors are a valid terminal — minimap surfaces them.
    languinio.o({ spinner: 'grafted' }).map(s => languinio.drop(s))
    q.finish(req)
},
```

---

## %Languinio — Lang's ave particle (reactive spinner signal)

Parallel to `%examining` on w:Lies.  Lives on w:Lang, enrolled in ave at
setup.  Spinner sub-particles are the moving parts — oai'd in when a reqonce
fires, dropped when the phase finishes.

### Lang setup (one-time)

```js
let languinio = w.oai({ Languinio: 1 })
let ave = H.oai_enroll(H, { watched: 'ave' })
if (!w.c.Lang_setup) {
    w.c.Lang_setup = true
    ave.i(languinio)
    languinio.c.w = w   // back-ref so Langui can reach w:Lang from languinio
}
```

### What's in ave at runtime

```
H.ave
  examining:1, active_path:Ghost/test/Hello.g    ← from w:Lies
  Languinio:1
    spinner:text_load    ← present while text_load unfinished
    spinner:compile      ← present while compile unfinished
    spinner:grafted      ← present while grafted unfinished
```

At rest Languinio is empty — all spinners dropped by finish().

### UItime — Langui (editor host), spinners for text + compile

```svelte
let languinio: TheC | undefined = $state()
$effect(() => {
    languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
})

let _load_spin  = $state(false)
let _compile_spin = $state(false)
$effect(() => {
    void languinio?.vers
    const loading   = !!languinio?.ob({ spinner: 'text_load' }).length
    const compiling = !!languinio?.ob({ spinner: 'compile'   }).length
    if (loading || compiling) {
        _load_spin    = true
        _compile_spin = compiling
    } else {
        setTimeout(() => { _load_spin = false; _compile_spin = false }, 333)
    }
})
```

```svelte
{#if _load_spin}    <div class="spinner cm-loading"  />  {/if}
{#if _compile_spin} <div class="spinner cm-compile"  />  {/if}
```

### UItime — DocMinimap, spinner for grafted

DocMinimap already reads `H.ave` for `lang_doc` and `active_doc`.  Languinio
is the same slightly wider context — no new prop needed.

```svelte
let languinio: TheC | undefined = $state()
$effect(() => {
    languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
})

let _graft_spin = $state(false)
$effect(() => {
    void languinio?.vers
    const grafting = !!languinio?.ob({ spinner: 'grafted' }).length
    if (grafting) { _graft_spin = true }
    else          { setTimeout(() => { _graft_spin = false }, 333) }
})
```

### Spinner CSS (from Stuffing — use for all Languish spinners)

```css
.spinner {
    position: absolute;
    top: 0%;
    left: -1em;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0.3em 0.6em;
    color: rgb(38, 110, 217);
    font-size: 1.6em;
    animation: pulse 1s ease-in-out infinite;
    text-shadow: 2px 2px 2px rgb(12, 28, 51);
}
.spinner::before {
    content: "⟳";
    display: inline-block;
    animation: spin 0.3s linear infinite;
}
@keyframes spin  { to { transform: rotate(360deg); } }
@keyframes pulse {
    0%, 100% { opacity: 0.6; }
    50%       { opacity: 1;   }
}

/* tint variants to distinguish stages at a glance */
.cm-compile { color: rgb(180, 130, 40); }   /* amber */
.cm-graft   { color: rgb(180, 160, 40); }   /* gold  */
```

The 333ms minimum is the `setTimeout` in the UItime `$effect` above — the
worker drops the spinner particle honestly when the phase finishes; the
component floor prevents single-frame strobing on fast compiles.

Note on sub-particle vers gating: `oai`/`drop` on Languinio's children bump
`languinio.vers`.  These bumps may reach UItime without waiting for the next
`H.ave` flush (known open question in reactivity_docs.md).  For spinners this
is desirable — fast appearance when compile starts is correct UX.

---

## Implementation order

1. **Hovercraft**: multi-maz `do()` patch above.  Delete the resolved `// <`
   in the ttlilt region.

2. **Lang setup**: mint `%Languinio`, enroll in ave (same pattern as examining
   in Lies).

3. **Lang**: `req_Languish` + three phase handlers.  `Lang_open_doc` becomes
   a plain function (takes `languish` particle, sets `languish.sc.docC`).
   `Lang_fire_compile` called from `req_compile`'s reqonce.

4. **LangGraft**: `Lang_graft_points` refactored to `Lang_graft_points_once`
   (plain function, no longer free-running each tick).  Called from `req_grafted`.

5. **Lies**: `req:Look` replaces `open_req` in `Lies_ensure_doc_loaded`.
   Instead of `i_elvisto('Lang/Lang','Lang_open_doc',…)`, mint/update
   `req:Languish` on w:Lang.  Drop `loaded_doc` minting — callers read from
   `req:Languish.sc.docC.sc.{gen_path, base_dige}` instead.

6. **Langui + DocMinimap**: Languinio-based spinners as above.

Single-session highest value: **1 + 3 + 4** — Languish with compile phase.
"Points resolve on open without a race" is the visible win.

---

## Chunks 3 and 4 (unchanged from palmtree-trajectory.md)

Chunk 3 — `accepted:1` persistence on %Point: stamp in `e_Lies_accept_What_Point`,
re-read at cold-start.  Two `// <` markers in LiesCurse.

Chunk 4 — What-level navigation: `req:desire`, sibling `→`, branch `↘`, dive
`↓`, ghost + rescue window, `◀◀ rwnd`.  Design in palmtree-trajectory.md §Chunk 4.
Depends on Chunk 3.


# transfiguration

Right — the handoff names `Lang_fire_compile` as if it exists; it doesn't. The real compile entry point today is whatever `Lang()` calls at tick time, and I need to read the actual machinery before designing the phase boundaries. Let me trust only the working code.Now let me see where this methods-building function is called from — is it inside `Lang_compile_collect`, called synchronously during `Lang_compile`?Now I understand the full machinery. Let me map the real pathway as it works today, then design the reqy structure.

## The real pathway (trusting only the code)

**Compile is fully synchronous on the Lang side.** `Lang_compile(A, w)` walks the doc, builds `%Compile/%methods` (defs/regions/calls) inline via `Lang_compile_collect`, and:

- **Soft-compile** (no `gen_path`): clears `%Pending` *immediately*, sets `compile_secs`, returns. `%methods` is fully populated synchronously. **No async, no Lies, no race** — the methods index is ready the instant `Lang_compile` returns.
- **Hard-compile** (`gen_path` present): leaves `%Pending` set, fires `e:Lies_compiled` across to Lies, returns. `%methods` is *still* populated synchronously — `%Pending` only tracks the *disk write*, not the index build. Lies writes to disk, fires `e:Lies_compile_settled` back, and `Lang_compile_step` (every tick while `%Pending`) clears it.

So a crucial discovery: **`%methods` is ready synchronously the moment `Lang_compile` returns, in both cases.** The `%Pending` flag is purely about the disk-write airlock for hard-compiles. The grafting resolver only needs `%methods`, not the disk write.

**Where the race actually is**: `Lang()` does, in order each tick:
1. `Lang_compile_step` (if Pending) — clears Pending when Lies replies
2. `Lang_graft_points(w)` — resolves against `%methods`
3. … later, the `!docC.c.ever_compiled` guard fires `Lang_compile` *for the first time*

The race: on **first open**, the `ever_compiled` guard at the *bottom* of `Lang()` (line 439) is what triggers the very first compile — but `Lang_graft_points` ran *above* it at line 390, before `%methods` existed. So the first graft pass sees no methods, resolves nothing, and Story can snap with unresolved Pmirrors. Next tick it's fine, but the snap already captured the empty state.

## The reqy redesign

The handoff's `req_text_loaded`/`req_compile`/`req_grafted` three-phase split maps onto this, but I want to correct two things the handoff got wrong given the real code:

1. **`req:compile` doesn't need to monitor `%Pending` to know `%methods` is ready** — `%methods` is synchronous. The ttlilt-during-`%Pending` is only needed if we want the *disk write* settled before snapping (which we may, for hard-compiles, so the gen file exists). But for *grafting*, `%methods` present is the real gate. I'll make `req:compile` finish when `%methods` is present, and arm the ttlilt only while `%Pending` (so hard-compile disk writes still hold Story open, but a soft-compile finishes instantly and grafts in the same descent).

2. **`Lang_fire_compile` is the refactor**: today `Lang_compile` *is* the entry, but it's bound to `Lang_active_docC(w)` and tick context. I'll split it: the index-building core takes an explicit `docC` (so a Languish phase can drive it for a specific doc, not "whatever's active"), and the existing `Lang_compile(A,w)` action-button entry becomes a thin wrapper that resolves the active docC and calls the core. That's the "nice reqy structural foundation" — the core is callable from a phase handler with a known docC.

Here's the structure I'd build:

```
w:Lang
  req:Languish, path:…
    sc.docC: $C          ← set by text_loaded reqonce
    sc.look_req: $C       ← cross-ref to w:Lies/req:Look (set by Lies when minting)
    req:text_loaded, maz:3   reqonce: Lang_open_doc_into(languish) — mint docC,
                              install ave text, set docC.sc.text_in.
                              monitor: docC + docC.c.state present (CM has mounted)
    req:compile,     maz:2   reqonce: Lang_compile_docC(docC) — sync index build.
                              monitor: %methods present. ttlilt while %Pending (hard-compile
                              disk write) so Story holds for the gen write, but soft-compiles
                              finish instantly in the same do() descent.
    req:grafted,     maz:1   reqonce: Lang_graft_points_once(w, docC). always finishes —
                              unresolved Pmirrors are a valid terminal.
```

**One real wrinkle I need to flag before coding**: today the first compile is triggered *lazily* by the `ever_compiled` guard inside `Lang()`, and it depends on `docC.c.state` existing — which only happens after Langui mounts the EditorView and fires `e_Lang_editorBegins`. So `req:compile` can't fire the moment `req:text_loaded` finishes minting docC — it has to wait for CM to actually mount and populate `docC.c.state`. That's why `req:text_loaded`'s real monitor isn't just "docC exists" — it's "docC exists *and* `docC.c.state` is populated." The text round-trips: Lang writes ave text → Langui renders → CM mounts → `e_Lang_editorBegins` stamps `docC.c.state` → *now* compile can run. So `req:text_loaded` arms a ttlilt until `docC.c.state` shows up (CM mounted), and *that's* the genuinely-async wait the handoff vaguely gestured at with `docC.sc.text_in`.

So the corrected phase monitors are:
- **text_loaded**: mint docC + ave text once; ttlilt until `docC.c.state` exists (CM round-trip).
- **compile**: once state's there, run the sync index build once; ttlilt while `%Pending`; finish when `%methods` present.
- **grafted**: run graft once; finish.
