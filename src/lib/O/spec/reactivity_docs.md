# Reactivity, H.ave, and the Stuff/Housing system — working notes

---

## Reactivity basics

`C.bump_version()` — which `C.i|r|replace|drop` all do — makes anyone reading `C.v` react. In Atime that means `C.ob()`; in UItime it means `$derived` and `$effect` via the watched flush. Worker methods manipulate C trees directly with no Svelte involvement; Svelte only ever sees the version signals.

**oai vs roai:**

`oai(s, c)` — select-or-insert synchronously. If the particle is found, returns it unchanged (`c` is ignored). Good for idempotent one-time setup: `w.oai({ examining: 1 })`.

`roai(s, c)` — async; same select-or-insert, but if found and any non-function value in the full `{...s,...c}` set has changed, calls `replace()` to update it in place. Good for keeping a derived-state particle current across ticks: `wa.roai({ action:1, role:'pause' }, { label, cls, fn })`.

The practical difference: `oai` never changes a found particle; `roai` replaces it when stale. Use `oai` for structure, `roai` for display state.

---

## The pipeline

Two time regimes, separated by the beliefs mutex:

```
Atime (beliefs cycle)
  H.todo → answer_calls → _really_answer_calls → beliefs(e)
    → organise (Se.process)
    → attend  (_Aw_think → worker methods)
      → C.i|r|replace|drop → C.bump_version → C.X.serial_i++ ($state)

  start_watched_C_effect: $effect reads all { C.version } for enrolled Cs
    any bump → pending=true, setTimeout(flush, ~25ms)

flush: H.clear(async () => {        ← inside beliefs mutex (Atime locked out)
    for each watched C that changed version:
      handler()  →  dest.empty(); for n of C.o({}): dest.i(n); dest.bump_version()
                    ↑ H.ave.X.serial_i++ ($state)
})

UItime
  Svelte sees H.ave.version change
    → $effects re-run in components doing H.ave.ob({...})
    → DOM updates
```

The mutex separation is the point: workers see a stable snapshot, UI sees a fully settled one.

---

## Where $state actually lives

Three `$state` declarations drive all of this:

```ts
// TheX — the index
serial_i = $state(1)           // the reactive signal; bumped on every write

// StuffIO
X: TheX = $state()             // the index reference is reactive —
                               //  replace()'s X swap is also visible to Svelte

// House watched destinations
ave:       TheC = $state(new TheC())   // never reassigned — inner serial_i fires effects
UIs:       TheC = $state(new TheC())
```

The outer `$state()` on `H.ave` etc. is defensive; those fields are never reassigned. The reactive signal is `H.ave.X.serial_i`, reached via `H.ave.version` (getter: `X?.serial_i || 0`). `ob()` touches it for you.

---

## ob() and the o() family

`ob(sc)` reads `void this.version` before querying — subscribing to every bump on this C. A `$effect` doing `C.ob({tiny_key:1})` reruns on any mutation to C, not just that key.

The suffix notation: `b` = read from `X_before` (only meaningful inside a `replace()` callback); `a` = return null if empty; `1` = extract sc column values rather than TheC rows. They compose: `boa1` = before, null-if-empty, column.

`void particle.version` / `.v` (getter: `version + 1`, always truthy) inside a `$derived` subscribes to only that particle — useful for fine-grained per-row reactivity without subscribing to a whole container.

---

## H.ave and the watched family

Five stable TheC objects on House, each a destination for one category of Atime data:

| field | purpose |
|-------|---------|
| `H.ave` | general per-tick UI data: Steps, examining, swatches, story_analysis |
| `H.UIs` | component registry; Otro reads to know what to mount |
| `H.actions` | button rack: `{action:1, role, icon, cls, fn}` particles |
| `H.graph` | Cyto graph state |
| `H.subHouses` | Houses below this one |

The flush handler for each enrolled C: `dest.empty()`, then `dest.i(n)` for each row, then `dest.bump_version()`. `dest.i(n)` inserts `n` itself — same reference, not a copy. No identity discontinuity across flushes; the TheC objects in `H.ave.X.z` are the same objects as in the source C.

Source and dest versions are deliberately decoupled: source may bump many times during one beliefs cycle; dest bumps once per flush, after all_clear. This is the Atime→UItime gate.

### Enrolling into watched

```ts
let ave = H.oai_enroll(H, { watched: 'ave' })  // find-or-create source, wire once
let exa = ave.i({ examining: 1 })              // write to source; flush copies ref to H.ave
exa.c.w = w                                    // fine — exa is the same object post-flush
H.watch_c(w, () => { exa.bump_version() })     // bump exa when w changes
```

`start_watched_C_effect()` sets up the single `$effect` that polls all enrolled C versions and schedules the flush. New entries to `H.watched[]` are picked up on the effect's next run.

### Reading in UItime

```ts
let exa: TheC | undefined = $state()

$effect(() => {
    exa = H.ave.ob({ examining: 1 })[0] as TheC | undefined
    // subscribes to all of H.ave — re-runs on any ave flush
})

// subscribes only to exa, not all of H.ave
let is_exa = $derived(exa?.v && exa.sc.active_path === doc.sc.path)
```

---

## replace() — what survives

```ts
// C has many n inside C.X.z
async replace(pattern_sc, fn, q?) {
    C.X_before = C.X
    C.empty()              // fresh X; old n* gone from index (not from memory)
    await fn()             // fn creates or re-inserts particles
    // resolve() pairs C.X (new n*) ←→ C.X_before (old n*) by sc.* string values
    // for each pair (a=old, b=new): resume_X(a, b)  →  b.X = a.X
}
```

**If `fn` creates a new TheC:** b is fresh, `b.c.*` empty, `b.X` undefined until resume gives it `a.X`. resolve() matches by sc.* — if values are the same, the pair scores well and the sub-tree transfers cleanly.

**If `fn` does `C.i(n)` with an existing TheC:** b IS n — same object, same `c.*`, same `X`. resolve() scores this as an unambiguous match (sc.* values are identical). `resume_X(a,b)` is effectively a no-op on a self-same object. This is the stable pattern: deliberately re-inserting the same TheC preserves everything including `c.*`.

**Concretely:** `w` (the Lies work particle inside A) is never the target of `replace()`. Se.process() only calls `replace()` on D particles — the trace mirror of n**. The n particles themselves (H, A, w) are traversed but not replaced. So `w.c.Lies_setup` and `w.c.*` generally are stable across beliefs cycles.

---

## Otro's UIs mounting

```svelte
{#each house.UIs.ob({ UI: 1 }) as uiC (uiC.sc.UI)}
    <svelte:component this={uiC.sc.component} H={house} />
{/each}
```

The particles returned by `house.UIs.ob(...)` are the same TheC references as in the source (flush inserts originals, not copies). Keyed by `uiC.sc.UI`, so Liesui, Storui etc. survive every UIs flush.

---

## Open unknowns — to be chased with tests

**+Doc form closing (primary):** The form lives in WaftComp (`adding_doc = $state(null)`), keyed by `waft.sc.Waft`. Analysis shows: `Lies` (the lies_w reference in Liesui) does not change; w particles are never replace()d by Se.process(); waft TheC objects are stable sub-particles of a w that shares its X with any resolved counterpart. WaftComp should survive all of this. Yet the form closes during Story trickle. Mechanism unknown. Needs a test case that isolates a form inside a keyed component inside an H.ave-driven `$effect`.

**watch_c granularity:** `H.watch_c(w, () => exa.bump_version())` fires on every w mutation — making the UI re-read examining even for w changes unrelated to examining. The right fix is for w to `roai` into exa when examining-relevant state changes, or for a Selection-like process to watch w/* and emit targeted bumps. Possibly points toward a UI-Se that notices when sub-particles of a presented C** need their own `bump_version()` to propagate reactivity inward, rather than blasting the whole container's version.

**Stuffing over-creation:** `stuff.version` bumps on every `C.i|r|replace|drop`. Each bump in the Stuffing.svelte `$effect` creates a new `Stuffing` instance. If many bumps arrive before the first `Stuffing.started` fires, multiple instances run brackology in parallel, wastefully. The right throttle strategy — skip if one is already in flight, but always start fresh once done if stuff has since changed — to be confirmed with a test.

**Missing inner C.v reactivity:** The suspect pattern: UI watches a container's version and re-reads everything on each bump, rather than watching sub-particle versions directly. This can look like it works but forces heavy reconciliation on every tick. If any form closes or remounts unexpectedly, it may be a symptom of this — the container's version bump cascading too broadly through Svelte's reconciler.
