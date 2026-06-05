# Reactivity, H.ave, and the Stuff/Housing system — working notes

## the frontier

Atime and UItime are basically the same thing, both share an H** global mutex lock.

Atime is got to by calling H.i_elvis*(target,method,sc), UItime via H.UItime(async () => ...).

Not awaiting a replace() in Atime causes it to fall outside microtick space chasm,
always keep your limbs within Atime, or a UItime might read transacting state,
which for replace() starts empty! So your UI reading state has things that vanish
for a tiny moment, all the time.

It was called clear() but just calling it UItime() might be clearer.

I think we'll figure out how to ideally:
    //  use it in an $effect() block
    //   after reading the reactive state,
    //   put the reactive state read AGAIN in one of these
    //    to make sure all state is read without any other Atime changing things

Langui does this at the mo, but probably wants the clear() end of it throttling...
But it really shouldn't need throttling?

### conflict

Having to wait UItime (with the global mutex lock) is in conflict with wanting to
stay in $effect's sync time so the state reads can become reactive.

Ie, we don't get reactivity via ob() in UItime(), only outside it,
directly in the $effect(), so we might repeat ourselves (read then read+assign).

To redesign the language to do this elegantly...

I'm thinking something like:

```
$effect
    dock.vers
    time:
        something = dock?.o({ something: 1 })[0]
```

Requiring all effects to be pure IOing might work... Then we can split off the read part.
Probably going to hide $effect() with something else along those lines,
it looks under the hood from where we're going....

Anyway.

---

## Reactivity basics

`C.bump_version()` — which `C.i|r|replace|drop` all do — makes anyone reading `C.vers` react. In Atime that means `C.ob()` (observe); in UItime it means `$derived` and `$effect` via the watched flush. Worker methods manipulate C trees directly with no Svelte involvement; Svelte only ever sees the version signals.

`vers` is just an accessor for `C.version` plus one, so it can be is the UItime-safe reactive signal ($state); `version` is the raw Atime counter. Use `vers` in UI code, `version` in worker code.

**oai vs roai:**

`oai(s, c)` — select-or-insert synchronously. If the particle is found, it is returned unchanged — the second argument `c` is ignored. Good for idempotent one-time setup: `let exa = w.oai({ examining: 1 })`.

`roai(s, c)` — async; same select-or-insert, but if found and any non-function value has changed, calls `replace()` to update it in place. Because it goes through replace() this is fast but async. Good for keeping a derived-state particle current across ticks: `wa.roai({ action:1, role:'pause' }, { label, cls, fn })`.

The practical difference: `oai` never changes a found particle; `roai` replaces it when stale. Use `oai` for structure, `roai` for live state.

Note: passing a second arg to `oai` is a bug waiting to happen — it is silently ignored on a found particle. Use `roai` if the values need to update.

---

## The pipeline

Two time regimes, separated by the beliefs mutex:

```
Atime (beliefs cycle)
  H.todo → answer_calls → _really_answer_calls → beliefs(e)
    → organise (Se.process)
    → attend  (_Aw_think → worker methods)
        let exa = w.oai({ examining: 1 })
        H.watch('ave').i(exa)        // enrol exa into the ave channel
      → exa.i|r|replace|drop → exa.vers++ ($state)

  start_watched_C_effect: $effect reads all { C.vers } for enrolled Cs
    any bump → pending=true, setTimeout(flush, ~25ms)

flush: H.clear(async () => {         ← inside beliefs mutex (Atime locked out)
    for each watched channel with a changed source C:
      handler() → channel.roll(source_C)
                    // roll: channel.empty(); channel.i(n) for each n in source_C
                    // exa re-emerges here as one of those n
                    → channel.bump_version()
})

UItime
  Svelte sees H.ave.vers change
    → $effects re-run in components doing H.ave.ob({...})
    → DOM updates
```

**`H.watch(channel_name)`** returns (or creates) the source C for a named channel — 'ave', 'UIs', 'actions', 'graph', 'subHouses'. Inserting into it queues that content for the next flush into `H.ave` / `H.UIs` etc. Setting up a handler on the watched particle tells flush to do something other than `roll()`. Any UI can read from any channel at any time — H.ave, H.UIs etc. are plain reactive TheC objects.

---

## Where $state lives

```ts
// in TheX — the reactive signal; bumped on every write
serial_i = $state(1)

// in StuffIO — replace()'s X swap is also visible to Svelte
X: TheX = $state()

// in House — never reassigned; inner serial_i fires effects
ave:   TheC = $state(new TheC())
UIs:   TheC = $state(new TheC())
```

The outer `$state()` on `H.ave` etc. is defensive; those fields are never reassigned. The signal that fires UI effects is `H.ave.X.serial_i`, reached via `H.ave.vers`.

---

## ob() — observe

`C.ob(sc)` reads `void C.vers` before querying — subscribing to every bump on C. A `$effect` doing `C.ob({tiny_key:1})` reruns on any mutation to C, not just that key.

`void particle.vers` inside a `$derived` subscribes to only that particle — useful for fine-grained per-row reactivity without subscribing to a whole container.

**`void` inside single-expression `$derived` is a trap.** `void X` returns `undefined`, so in `$derived(A && (void X) && B)` the `void` expression is falsy and `&&` short-circuits — B is never reached and the expression always evaluates to `undefined`. The same problem appears in `$derived(A && (void X) || B)` — the `||` always fires.

The safe pattern — `vers` is always ≥ 1 (truthy), use it as a chain link:

```ts
let target = $derived(LE && LE.vers && LE.sc.target)
```

`LE.vers` never breaks the chain, but Svelte still registers the read. Prefer this over `$derived.by` — it puts pressure on keeping UI-facing interfaces simple and inline. `$derived.by` is a last resort for genuinely multi-step logic that can't be factored out.

**`.o()` vs `.ob()` in `$derived`:** `.o()` has no version tracking — a `$derived` that calls `languinio.o({ LE: 1 })` will not re-run when Languinio's children change. Use `.ob()` when the derived value depends on a particle's children:

```ts
// wrong — re-derives only when languinio reference changes
let LE = $derived(languinio?.o({ LE: 1 })[0])

// right — re-derives whenever languinio is bumped (e.g. after languinio.i(LE))
let LE = $derived(languinio?.ob({ LE: 1 })[0])
```

---

## Enrolling and reading — UItime pattern

```ts
// Atime side (worker):
let exa = w.oai({ examining: 1 })     // stable particle on w
H.watch('ave').i(exa)                 // hand it to the ave channel; idempotent

// for live state, roai into exa so UItime gets it without subscribing to all of w:
await exa.roai({ active_path: doc.sc.path, step: current_step })
```

```ts
// UItime side:
let exa: TheC | undefined = $state()

$effect(() => {
    // subscribes to all of H.ave; re-runs on any ave flush
    exa = H.ave.ob({ examining: 1 })[0] as TheC | undefined
})

// subscribes only to exa; .vers is the UItime-safe version signal
let is_exa = $derived(exa?.vers && exa.sc.active_path === doc.sc.path)
```

The flush is the Atime→UItime gate for `H.ave.vers`. Whether sub-particles like `exa` need their own UItime-gated `vers` signal rather than leaking Atime bumps directly is an open question — see unknowns.

---

## H.ave and the watched channels

| channel | purpose |
|---------|---------|
| `H.ave` | general per-tick UI data: Steps, examining, swatches, story_analysis |
| `H.UIs` | component registry; Otro reads to know what to mount |
| `H.actions` | button rack: `{action:1, role, icon, cls, fn}` particles |
| `H.graph` | Cyto graph state |
| `H.subHouses` | Houses below this one |

`channel.roll(source_C)`: `channel.empty()`, then `channel.i(n)` for each row from source_C, then `channel.bump_version()`. `channel.i(n)` inserts `n` itself — same reference, not a copy. No identity discontinuity across flushes.

Source and channel versions are decoupled: source may bump many times during one beliefs cycle; channel bumps once per flush, after all_clear.

---

## replace() — what survives

```ts
// C contains many /*n — particles each named n inside C.X.z
async replace(pattern_sc, fn, q?) {
    C.X_before = C.X
    C.empty()              // fresh X; old /*n gone from index (not from memory yet)
    await fn()             // fn creates or inserts particles
    // resolve() pairs new /*n ←→ old /*n by sc.* string values
    // for each pair (a=old n, b=new n): resume_X(a, b)  →  b.X = a.X
}
```

**If `fn` does `C.i({such:1})` or `C.i(n.sc)`:** b is a fresh TheC. resolve() matches by sc.* values; if matched, `b.X = a.X` transfers the sub-tree. b.c.* starts empty, but b's sub-particles (`b/*`) are the same objects as a's were.

**If `fn` does `C.i(n)` with an existing TheC:** b IS n — same object — so n.c.* will be exactly as they were.

**Concretely:** w (the Lies work particle inside A) never gets replaced. Se.process() only calls `replace()` on D particles — the trace mirror. So `w.c.*` is stable across beliefs cycles.

---

## Otro's UIs mounting

```svelte
{#each house.UIs.ob({ UI: 1 }) as uiC (uiC.sc.UI)}
    <svelte:component this={uiC.sc.component} H={house} />
{/each}
```

Particles returned by `ob()` are the same TheC references as in the source. Keyed by `uiC.sc.UI`, so Liesui, Storui etc. survive every UIs flush.

---

## Failure modes

### Liesui Waft/+Doc form closing

Fixed in a80e5b4747ab860ca311155542db78a7775a67d6

Bug: The form lives in WaftComp (`adding_doc = $state(null)`), keyed by `waft.sc.Waft`. `Lies` ($state in Liesui) does not change; w is never replaced; waft sub-particles of w are stable. WaftComp should survive. Yet the form closes during Story trickle. Mechanism unknown.

Solution: I'm not sure exactly, try H.ave -> H.clear({} setting your state })
```
    $effect(() => {
        const ex = H.ave.ob({ examining: 1 })[0] as TheC | undefined
        ...
        H.clear(async () => {
            loaded_docs = lies_w.o({ loaded_doc: 1 })  as TheC[]
```
Test: is fairly untamed, unexplained: ReactiveWaft

## Open unknowns — to be chased with tests

But are all low priority now Liesui panned out...

**Sub-particle vers gating:** The flush gates `H.ave.vers`, but `H.ave` contains the actual `exa` TheC. If Atime bumps `exa.vers` directly, UItime reads see it immediately — bypassing the flush gate. A properly gated `exa.vers` would need to be a separately managed UItime-only signal. Whether this is causing mid-cycle re-reads is unknown but plausible as a contributor to the form issue. The related architectural direction — channel.roll() copies a clone of exa rather than exa itself, with a Selection-like process emitting targeted bumps on the clone — needs testing to know if it's necessary.

**Stuffing over-creation:** Each `stuff.vers` bump in Stuffing.svelte creates a new Stuffing instance. Many may run brackology in parallel before any finishes. Throttle strategy to be confirmed with a test.
