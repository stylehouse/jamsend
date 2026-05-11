# Reactivity, H.ave, and the Stuff/Housing system — working notes

---

## The pipeline

Two time regimes, separated by the beliefs mutex:

```
Atime (beliefs cycle)
  H.todo → answer_calls → _really_answer_calls → beliefs(e)
    → organise (Se.process)
    → attend  (_Aw_think → worker methods)
      → C.i / C.r / C.replace → C.bump_version → C.X.serial_i++ ($state)

  start_watched_C_effect: $effect reads { C.version } for all watched Cs
    when any bump → pending=true, setTimeout(flush, ~25ms)

flush: clear(async () => {
    // inside beliefs mutex (Atime locked out)
    for each watched C that bumped version:
      handler() → dest.empty(); dest.i(n)...; dest.bump_version()
        → H.ave.X.serial_i++ ($state)
})

UItime
  Svelte sees H.ave.version change
    → $effects re-run in components doing H.ave.ob({...})
    → DOM updates
```

The mutex separation is the whole point: worker code sees a stable snapshot, UI sees a fully settled one. There is no mid-cycle partial state in the UI.

---

## TheX, TheC, and where $state actually lives

Three $state declarations drive all of this:

```ts
// TheX — the index
serial_i = $state(1)           // reactive signal; bumped on every write

// StuffIO
X: TheX = $state()             // the index reference itself is reactive
                               //  so swapping X (during replace()) is also reactive

// House fields
ave: TheC = $state(new TheC()) // reference reactive; but ave is never reassigned —
UIs: TheC = $state(new TheC()) //  the inner serial_i is what actually drives redraws
...
```

The outer `$state()` on `H.ave` etc. is defensive armour, not the reactive signal that fires effects. The signal is `H.ave.X.serial_i`. You reach it through `H.ave.version` (getter: `X?.serial_i || 0`), and `ob()` touches it for you.

The double-wrapping (`TheX = $state()` + `serial_i = $state(1)`) is intentional:
- `serial_i` in-place tracks incremental mutations
- `X = $state()` means `empty()` / the `replace()` swap registers as a change too

---

## ob() and the o() family

All live on `StuffIO`. Morphology from a few combinatorial axes:

```
b  = before  — uses X_before instead of X (reads the pre-replace snapshot)
a  = absent  — returns null/undefined when the result would be []
1  = column  — extracts sc values instead of returning TheC rows
```

| method | version reactive | uses X_before | null-if-empty | extracts column |
|--------|:---:|:---:|:---:|:---:|
| `o(sc)` | ✗ | ✗ | ✗ | ✗ |
| `ob(sc)` | ✓ | ✗ | ✗ | ✗ |
| `oa(sc)` | ✗ | ✗ | ✓ | ✗ |
| `bo(sc)` | ✗ | ✓ | ✗ | ✗ |
| `boa(sc)` | ✗ | ✓ | ✓ | ✗ |
| `o1(sc,key)` | ✗ | ✗ | ✗ | ✓ |
| `bo1(sc)` | ✗ | ✓ | ✗ | ✓ |
| `oa1(sc)` | ✗ | ✗ | ✓ | ✓ |

`ob()` reads `void this.version` first — that is the entire reactive subscription. It subscribes to every version bump on this C, not to the specific keys queried. A `$effect` doing `C.ob({ tiny_key: 1 })` reruns on any mutation to C, even unrelated ones.

`oa()` / `boa()` are idioms for presence checks: `if (w.oa({ wants_directory: 1 })) return`.

`o1(sc, 0)` returns the first value of the first column — the deepest shorthand. `o1(sc, 1)` returns all values of the first column. `o1(sc, 'key')` returns all values of that named column.

`oai(s, c)` — select-or-insert; **synchronous**. Does not `replace()`, does not merge `c` onto found.  
`roai(s, c)` — async; same but calls `replace()` if any non-function key differs.

`bo*` are only meaningful **inside** a `replace()` callback. Outside one, `X_before` is undefined and they return `[]`.

---

## H.ave and the watched family

Five stable TheC objects on House, each a destination for one category of Atime data:

| field | source particles | purpose |
|-------|-----------------|---------|
| `H.ave` | `w/{watched:'ave'}` particles across H/A/w | general per-tick UI data; Steps, examining, swatches, story_analysis |
| `H.UIs` | `/{watched:'UIs'}` | component registry; Storui, Liesui, Cytui. Otro reads this to know what to mount |
| `H.actions` | `/{watched:'actions'}` | button rack; `{action:1, role, icon, cls, fn}` particles |
| `H.graph` | `/{watched:'graph'}` | Cyto graph state |
| `H.subHouses` | `/{watched:'subHouses'}` | Houses below this one; Otro uses this to hoist H** |

The flush handler is default unless the watched particle carries `sc.fn`:

```ts
// default — replicate C.o({}) into dest
dest.empty()
for (const n of C.o({})) dest.i(n)
dest.bump_version()   // belt-and-suspenders when C was empty and i() didn't fire
```

`dest.empty()` clears the TheX but the TheC objects inside it are the same references — they are moved wholesale into `dest.X.z`. So particles survive the replicate intact, including `n.c.*` properties.

The version bump on `dest` (H.ave etc.) is a separate $state from the source C's version. They are deliberately decoupled: source may bump many times during one beliefs cycle; dest bumps once per flush, after all_clear. This is the Atime→UItime gate.

### Enrolling into a watched destination

```ts
// find-or-create the {watched:'ave'} source particle on target (usually H),
//  and call enroll_watched() to wire it into H.watched[] once.
H.oai_enroll(H, { watched: 'ave' })

// write into the source; flush will push it to H.ave
ave.i({ examining: 1 })

// fine-grained: watch something else and bump ave on changes
H.watch_c(some_C, () => { examining.bump_version() })
```

`watch_c` is additive and deduplicated. Calling it twice with the same C is a no-op.

### Reading in UItime

```ts
// $effect — re-runs when H.ave.version bumps
$effect(() => {
    const node = H.ave.ob({ examining: 1 })[0]
    // ...
})

// $derived — subscribes to the particle's own version for fine-grained updates
let is_examining = $derived.by(() => {
    void examining?.version   // subscribe to examining specifically
    return examining?.sc.active_path === doc.sc.path
})
```

Using `H.ave.ob(...)` subscribes to all of H.ave. Using `void particle.version` inside a `$derived` subscribes only to that particle. DocRow and Storui's `live_step()` use the finer form for per-pip updates that shouldn't redraw the whole panel.

---

## replace() and ephemeral c.*

**The single most important thing to know about `replace()`:**

```ts
async replace(pattern_sc, fn, q?) {
    this.X_before = this.X
    this.empty()           // fresh X
    await fn()             // fn inserts new particles via this.i(...)
    // resolve() pairs new ←→ old by matching sc.* string values
    // resume_X(a, b): b.X = a.X   — transfers the sub-tree
    // but b is still a brand-new TheC object with empty .c
}
```

After `replace()`, `C.o({...})` returns **new TheC instances** for conceptually-identical particles. `resolve()` transfers `.X` (sub-trees), but nothing in `.c`. The particle walks the same Stuff tree; the object reference is different.

This has two consequences:

**1. Anything stored in `n.c.*` is lost after replace().**

Lies stores `examining.c.w = w` once in the setup guard `if (!w.c.Lies_setup)`. If `w` (the Lies work particle) goes through a replace(), the new `w` has empty `.c`, so `w.c.Lies_setup` is gone. On the next tick, the setup block re-runs: a new `examining` TheC is created, `examining.c.w` gets re-pointed, and the new examining is enrolled in ave. Liesui then sees `lies_w !== Lies` → true, and reassigns `Lies`. This unmounts the `{#if Lies}` block including all WaftComp instances.

**2. UI components keyed by particle identity must key by `sc.*` values, not object reference.**

`{#each all_wafts as waft (waft.sc.Waft)}` is correct. `{#each all_wafts as waft}` is not — object references change across replaces even when the logical waft is the same.

---

## The +Doc form closing issue

The +Waft form (in Liesui, above `{#if Lies}`) lives in unconditional Liesui scope — it cannot close from reactivity unless Liesui itself remounts.

The +Doc form lives inside WaftComp, inside `{#if Lies}{:else}...{/if}`. When `Lies` (the `lies_w` TheC) changes, the entire `{:else}` block tears down, WaftComp instances unmount, form state is gone.

**Why `Lies` can change:**

The chain is:
1. Story trickle drives H:Story's beliefs cycle more aggressively
2. H:Story (or Story worker on the main House) calls i_elvisto to Lies, triggering a Lies() tick
3. Lies() calls `replace()` on some subset of its particles (open_req processing, waft loading)
4. The `w:Lies` particle itself is an argument to `Lies()` — it's the work particle, not what's being replaced. But if organise()'s Se.process() calls `replace()` on Se or on the D-tree, and resolve() fails to match `w:Lies` → the old TheC pairs with null, a new TheC pairs with null from the other side, and the new w object has no `.c.Lies_setup`
5. Next Lies() tick: setup re-runs, new examining, new `examining.c.w`, ave gets new examining
6. Liesui's $effect: `ex.c?.w !== Lies` → `Lies = new_w`

Actually step 4 is the uncertain part without seeing Selection.svelte. But the observed symptom is consistent with `.c.Lies_setup` getting lost. The immediate fix would be to not depend on `examining.c.w` as the stable back-ref to `w`, and instead find `w` from H directly:

```ts
// instead of ex.c?.w, find w by query on every tick:
const lies_w = H.Awo('Lang', 'Lies')  // throws if missing, so wrap in try
```

Or more robustly: make Liesui not depend on identity stability at all, and derive what it needs from `examining.sc.*` instead of `examining.c.*`.

**Why Story trickle in particular triggers it:**

Story `trickle` toggle stores the Book name rather than `true` so it's per-book. When on, Story drives H:Story more frequently and probably sends elvisto calls to the main House more often. Each main House beliefs cycle touches H.ave (Story's `if (!ave.oa({ Styles: 1 })) ave.i(...)` runs every Story() tick). This makes Liesui's $effect fire more frequently, increasing the chance of catching a window where `Lies` has churned. If Lies is mid-replace during one of these flush windows, the particles are the new objects.

There's also the `examine` watching chain:

```ts
// Lies() worker:
H.watch_c(w, () => {
    examining.bump_version()
})
```

If `w` churns (new TheC after a resolve), this `watch_c` is still registered on the OLD `w`. The new `w` is not watched. So examining no longer bumps when the new w changes — until the setup block re-runs and re-wires `H.watch_c(new_w, ...)`. This could cause stale examining state as a secondary effect.

---

## Confusing integration points

### $effect in non-component context

`Stuffing` registers a `$effect` in its constructor. Svelte 5 allows this only "while a parent effect is running." Housing provides that parent via `$effect.root(() => { this.start() })` in its constructor. The `$effect.root` creates an effect owner; any `$effect` called while `start()` runs is a child of that root.

**Gotcha:** If Stuffing is ever constructed outside a Housing.start() call (e.g., in a module-level or lazy-init context), the `$effect` silently registers to nothing and never re-runs. No error, no warning.

### Ghost methods and reactivity

`eatfunc` adds methods to the House instance via `Object.assign`. These are plain functions — not Svelte's reactive getters/setters. Mutations inside ghost methods (`n.sc.foo = val`) are **not automatically reactive** to Svelte's compile-time signal tracking. Reactivity comes from explicit `bump_version()` / `C.i()` / `C.r()` / `C.replace()` calls.

### todo = [...H.todo, e] vs todo.push(e)

Both are reactive in Svelte 5 (the field is `$state([])`, array methods are tracked through the proxy). The spread-assign pattern in `_push_todo` might predate rune-based proxying and is harmless either way.

### believing = $state(false)

This field exists to let UI components optionally avoid rendering during a beliefs cycle (`{#if !H.believing}`). But nothing in the shown components uses it as a gate — it's more of a debugging/tracing aid. The real UItime/Atime separation is via the flush timing (setTimeout after mutex release).

### oai_enroll vs watch_c timing

`oai_enroll` calls `enroll_watched()` immediately when a new watched particle is created. `enroll_watched()` walks all current `H/A*/w*` to find `{watched:X}` particles. **Particles that haven't been inserted yet won't be found.** Workers that create their watched source after `enroll_watched` has already run need to call `H.enroll_watched()` themselves, or ensure their source particle is created before the first beliefs cycle that might also create other watched particles. Calling it multiple times is idempotent (dedup'd by identity check).

### The $state wrapping on class hierarchies

```
Housing extends TheC extends Stuff extends TimeOffice extends StuffIO
  StuffIO:  X: TheX = $state()
  TheX:     serial_i = $state(1)
  Housing:  todo, started, believing, ghosts, subHouses, UIs, ave, ... = $state(...)
```

Each `$state` field at each level is independently tracked. A Housing is simultaneously: a reactive Stuff store (via X.serial_i), a Svelte-reactive object with its own fields (todo, believing, etc.), and a participant in the watched flush. Reading `H.ave.ob({})` subscribes to `H.ave.X.serial_i`. Reading `H.believing` subscribes to the Housing-level field. These are orthogonal signals.

---

## Stuffing — C observer in Atime

`Stuffing` lives in Atime but drives a `$effect`. It's the bridge for non-Housing Stuff watchers (like the Stuffing/Stuffusion/Stuffziad/Stuffziado tree for the data browser UI).

```ts
$effect(() => {
    if (this.Stuff.version) {       // subscribe
        if (this.Stuff.X_before) return   // mid-replace, wait
        setTimeout(() => this.slowly_brackology(), 1)
    }
})
```

The `X_before` guard is important: during a `replace()`, version bumps multiple times (pre- and post-). Without the guard, `brackology()` would run on partial state. The guard makes it wait for the finalise bump in `replace()`'s `finally` block.

`slowly_brackology` is throttled to 200ms — coarser than the watched flush (25ms), intentionally so, since re-grouping is expensive.

---

## Wildcard 1 and exactly()

`o({ step: 1 })` — wildcard: matches any particle having a `step` key, regardless of value.  
`o(exactly({ step: 1 }))` — literal: matches only `step === 1`.

`exactly()` stringifies values: `"1"` is not `1` in the index. `o_kv` knows to coerce strings back to numbers (see the `v * 1` block), so `exactly({step:1})` → `{step:"1"}` → coerced back → finds numeric `{step:1}`. The coercion path is there specifically because `exactly()` forces this situation.

The naming convention: uppercase key (Step:N) = live/session; lowercase (step:n) = canonical/disk. `exactly()` is needed whenever the value is literally `1` and you want the specific one, not the wildcard behaviour.

---

## requesty_serial

```ts
async requesty_serial(w, t) → requlator
```

Returns a requlator object that wraps a serial queue of `{requesty_T:1}` particles in `w`. The first call does an `await w.r(...)` internally (inside `ison()`), so it must be awaited.

The requlator is not a TheC — it's a plain object with `i()`, `oai()`, `o()`, `do()`. Its `i()` is async (also awaits `ison()`). Its `do(fn)` is the worker loop: drops finished reqs, forgets problems, calls `fn(req)` for each live req.

The pattern for IO-gating:

```ts
// inside LiesPersist:
const rw  = await H.requesty_serial(w, 'rw_queue')
const req = await rw.oai({ rw_name: path, rw_op: 'read' })
if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })) {
    w.i({ see: '⏳ loading…' })
    return false   // caller returns; Wormhole will i_elvisto think when done
}
// req.sc.reply is now populated
```

First Lies() tick: `i_elvis_req` returns false (request sent, not yet answered). Second tick: `oai` finds the existing req particle (same `rw_name`+`rw_op` key), `i_elvis_req` sees `req.sc.finished` → returns true. Proceed.

This two-tick dance is the standard IO pattern throughout. Any function that contains it must be re-entrant — each tick sees an earlier-than-expected return.

---

## Summary of likely remounting culprit

The form closes because `Lies` (a `$state` variable in Liesui) gets assigned a new TheC, which causes the `{#if Lies}` block to fully remount.

The `Lies` variable is derived from `examining.c.w`, a `.c.*` property. `.c.*` properties do not survive `replace()`. Something in the beliefs pipeline causes the `w:Lies` work particle to lose its `.c.*` and get setup re-run, producing a new examining TheC with a new `.c.w` back-ref.

The fix is to not store `w` in `.c.w` as the stable reference back to the worker. Instead derive it freshly:

```ts
// in Liesui $effect:
const lies_w = H.Awo('Lang', 'Lies')   // find by scheme walk, not by back-ref
```

or store the path (`examining.sc.Aname = 'Lies'`) and look it up on each tick. The `sc.*` of examining survives replace() via `resume_X`.
