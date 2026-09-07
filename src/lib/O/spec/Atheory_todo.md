# Atheory_todo.md — the next rebuild of Housing (that's just A**)

A capture doc, not yet a plan — the owner has reached for this three times in one session
 (2026-08-28), which is the tell it wants its own plot:

- *"we have random lists of .go to include somewhere too... we really need to rethink how code
   loads onto the base Housing, shall surely be Atheory (the next rebuild of Housing thats just
    A**)"*
- *"perhaps we should redo the toplevel? must be a ton of crap built up now huh? could be so much
   simpler and easier to moonwalk through these such transpirings?"* — said while reading a boot
    log of the world-1-destroy → world-2-mount churn at storyFinished.

## 0. What this is about

*2026-09-08 — read `Wordland_todo.md` first: it is where this doc's A\*\* shape, Atlas (what the code says)
 and Electrode (what it does — built that night) are read together.  Electrode's `join` gives the
  static border measurement below its MEASURED twin (one Book run: 379 declared call pairs, 202 ran), and
   the ROLE dimension of the manifest question a measurement instead of a static floor.*

Two irritations, probably one rebuild:

1. **Code loading is random lists.**  Which `.go` ghosts mount is scattered hardcoded lists
    (LocalGen's GFILES default list is the compile-side twin of the same disease — a list you
     forget to be on is a silent absence).  Atheory would make loading DECLARED — the base
      Housing (`A**`) knowing what belongs on it, legibly, the way everything else in the world
       is legible matter.
2. **The toplevel has built-up crap.**  The boot walks worlds it then destroys (the
    world-1→world-2 remount at storyFinished; BigSoundland's un-buffered `cyto` derive + keyser
     remount is furniture balanced on that churn).  A stranger's cold boot runs a 1-step toc and
      leaves `step_n` stranded at 1 forever — the whole cold-boot disease (Solo_todo bombs) is
       toplevel sediment.  A simpler toplevel would make those seams walkable ("easier to
        moonwalk through these such transpirings").

## The load-list inventory — DONE 2026-09-05 (the "when it starts" step below, paid)

Measured, so §0's irritation 1 now has a number instead of a suspicion.

**The three lists, and they do not agree.**
- `CREDULER_GHOSTS` — `LiesLies.svelte:56-101`, 36 paths, the RUNTIME manifest a runner loads live.
- `GFILES` default — `scripts/LocalGen.spec.ts:23`, **4** paths (`Reliable Peeroleum Tribunal
   Peregrination`), the COMPILE-side twin.  A stale subset of the above — whatever was in hand the
    day it was written.
- `scripts/Siphon_include.svelte` — 6 hand-written `gen/**.go` imports, existing ONLY because Siphon
   was deliberately left out of `CREDULER_GHOSTS`.  A workaround is the third list.

**What the manifest costs a page that does not want it.**  `gen/` is 4.4MB.  A humdinger music page
 loads all 36 (4.19MB) via `Creduler_ensure`.  Radio.g's full static call-closure — `this.`, `H.`,
  `&`, and elvisto edges followed — reaches **14 of them (2.38MB)**.  The other **22 (1.81MB) are
   loaded and never touched**, and the bulk of that is other pages' Story test Books:

```
 454K Story/Heistation   159K V/Vytonation    91K Story/Peregrination   19K M/Radiola
 325K Story/Swarmation   149K Story/Voronation 33K N/Tribunal           17K Story/InvFerry
 192K Story/Musuation    118K V/Voro          33K Story/InvWalk         14K M/Mixer
                         107K Story/Radiation                           13K Story/Berthation
```

`Sounditron.g` — the music page's OWN diagnostic Book — is correctly reached, so this is not "Books
 are unreachable": a humdinger loads *every other page's* tests.  ~1.5MB of Story test code parsed at
  boot on someone's phone.

Measured with `scripts/drawer.mjs needs M/Radio.g` (a static def/call index over 228 files / 157k
 lines: 3,670 defs, 12,790 call sites, 93.5% of callees resolving).  It is a FLOOR — dynamic dispatch
  (`do_fn_for` by `w.sc.w`) is not followed — so real need is somewhat higher, but the test-Book bulk
   is not in doubt.

**The cure §0 already names is the right one, and the numbers say so.**  Not "delete entries" but
 *"make loading DECLARED — the base Housing knowing what belongs on it, legibly, the way everything
  else in the world is legible matter"*: **the manifest wants to be particles, not a JS array.**  A
   role dimension then falls out (a humdinger stands the music spine, a runner stands everything
    because it genuinely runs those Books) without hardcoding a second array beside the first.

**Two enabling notes for whoever picks this up.**
- `Lies_ghost_set(path)` (`LiesLies.svelte:999`) takes an ARBITRARY path and dynamic-imports it.  It
   never consults `CREDULER_GHOSTS` — the manifest is only the default list `Creduler_ensure` walks.
    So loading is already path-driven; only the *roster* is hardcoded.
- The array lives inside `LiesLies.svelte`.  Extracting it to its own module first (the
   `runner_liveness.mjs` precedent — *"the channel-liveness thresholds live in ONE place now… was
    three inline literals that could drift"*) makes `LiesLies` a one-line import change and puts the
     role logic somewhere touchable.  `RUNNER_FACETS` (`LiesLies.svelte:100`) is the same pattern
      already applied to a different list, with the rationale written out.

Still owed from the "when it starts" list: the inventory of what the toplevel actually does between
 page-load and commission.

## THE A** SHAPE — proposed 2026-09-07 (the owner's `TheA_$dige`), measured and bench-verified

*Status honesty: the "Not yet" below asked for the toplevel inventory first, and that inventory is
 STILL OWED.  What follows is proposed on a different measurement — the CALL GRAPH — because the owner
  reached for the shape directly ("we're creating a class called `TheA_$dige` which pulls in a bundle of
   code to specifise, and superclass of Housing has the rest").  Nothing here needs the toplevel
    inventory to be judged; the inventory is still what tells us what the rebuilt toplevel DOES.*

### The shape

```
        House  (the spine — Housing's walk + the 72 generic names)
          ▲
   TheA_<Name>_<Variant>_<dige>   (the mutually-recursive core + the shared API)
          ▲
   TheA_<Name>_<Variant>_<dige>   (one Book, one leaf ghost)
```

Each layer is a real prototype; instances of an A hang off the topmost.  Chain lookup is live, so a
 method anywhere below is reachable, and a method on the bundle layer is invisible to a plain House —
  which is the specialisation the owner asked for.

**The name has three parts, ruled by the owner 2026-09-08: `TheA_SomeName_SomeVariant_<dige>`.**
- `Name` — WHICH bundle (the platform core, a Book, a leaf ghost).
- `Variant` — which BUILD of that bundle.  This is the slot that makes the whole scheme pay, and it has
   a first concrete tenant: an **electroded build**.  `Electrode_todo §1` splits tracing in two — a
    runtime wrapper sees entry and exit of a method and needs nothing from here, but LINE-level and
     BRANCH tracing (*"trace all the way through every line… excellent for teaching the program's
      flow"*) can only come from the compiler emitting marks inside the body, i.e. a genuinely different
       compiled form of the same ghost living beside the plain one.  That is a variant.  So the shape
        below is not only about isolating an A's overrides; it is the thing that lets an instrumented
         build and a clean build coexist, per A, with the cluster still pinned to one stable version.
- `dige` — the content hash, so a bundle's identity is what it IS, not what it was called.

### The seam it needs ALREADY EXISTS, unused

`do_fn_for` (`Housing.svelte.ts:1487`) already resolves `w_inst[method]` **before** `H[method]`, and
 `organise_scheme` marks only the `H` level `is_inst`.  Its own comment says the rest fall back on
  purpose: *"For is_inst levels (House at depth 0) sets T.sc.inst = n.  Otherwise inst stays undefined
   and _Aw_think falls back to H.\* (ghost-injected) methods."*  Give the `A` level `is_inst` and an
    instance to hang there and dispatch lands on it with `this` bound to that A.  The spine does not
     change.  This is an activation, not a rewrite.

### What the border actually measures (2026-09-07, every `.g` scanned)

The raw cross-ghost count looks fatal to partitioning and is not.  Of 3,088 cross-file `this.` calls,
 **2,445 are a Story Book calling its own subject ghost** — the test relationship, not a border.  The
  real domain-to-domain border is **643 calls**, and it concentrates hard:

| | |
|---|---|
| domain cross-called methods | 196 |
| carried by 16 methods with ≥3 callers | 292 calls (45%) |
| carried by 150 single-caller methods | 224 calls |

The 16 are a platform layer nobody designed: `Radio_trace` · `Ra_recs` · `Ra_rec_find` · `Crate_nav` ·
 `Radio_pub` · `Ra_home_self`/`_them`/`_shop` · `Radio_clean` · `Repli_chunk_at`/`_bytes` ·
  `Repli_xfer_get` · `Pier_next_seq` · `Swarm_now` · `Heist_keep_born` · `Radio_friendly`.  A trace
   facility, the record store, home/shop resolution, chunk IO, sequence allocation and a clock.  **That
    is the "backending in a superclass" the owner proposed, and it can be named today.**  The 150
     single-caller reaches are the audit: each is either an API that should join the 16, or a reach that
      should not exist.

**The hard constraint: 21 ghost pairs are mutually recursive** (`Ra ↔ Radio`, `Heist ↔ Ra`,
 `Heard ↔ Swarm`, `Ra ↔ Repli`, `Heist ↔ Repli` …).  A prototype chain is linear, so no ordering exists
  for a cycle — that cluster must be **flattened into ONE layer**.  Median fan-out among the other files
   is 1, so the leaves layer cleanly.  This kills the finer-grained variant (one class per ghost,
    chained) before anyone tries it.

### The mechanics, verified on the real `House` (not reasoned about)

- **Mutating a prototype in place WORKS.**  `Object.assign(TheA_X.prototype, fresh)` is seen immediately
   by already-constructed instances — replaced methods, brand-new methods, and deletions.
- **Svelte 5 `$state` is not a problem.**  Rune fields compile to accessors on the *declaring* class's
   prototype with a `#private` slot on the instance.  A generated subclass keeps `Housing.prototype` in
    its chain, so reactivity survives both mutation and re-pointing — including a `$state` write from a
     method that did not exist at construction time.  Chain verified:
      `House → StorableHousing → Housing → TheC → Stuff → TimeOffice → StuffAware → StuffIO`.
- **`setPrototypeOf` works but is the dangerous one.**  It is safe only while the new class extends the
   *same* `House` class object.  Against a different EVALUATION of `Housing.svelte.ts` it succeeds
    silently, resolves methods fine, and then throws `Cannot read private member #believing` —
     asynchronously, inside the persistence effect at `Housing.svelte.ts:452`.  A sync try/catch around
      the re-point catches nothing.  **Pin the base**: capture the one live `House` and always extend
       that object.  (Mitigating fact: nothing in `src/lib` calls `import.meta.hot.accept`, so a change
        to a non-component module bubbles to a FULL PAGE RELOAD by Vite's default — the observed
         behaviour all session, where every gen write reloaded every tab.  So this landmine is unlikely
          to fire from a Housing edit; pinning is cheap insurance, not a live hazard.)
- **So: construct a class once per dige, and MUTATE that prototype thereafter.**  Re-pointing becomes a
   deliberate act — an A adopting a different code version — not an automatic consequence of a reload.
    This is also the only shape that pays: two `TheA_` prototypes over one pinned `House` let two A's
     run different code versions in one tab, which one flat `H.ghosts` can never do.

### Two migration constraints, both sharp

1. **An own property permanently masks its prototype twin.**  `ghostsHaunt` today does
    `Object.assign(h, this.ghosts)` — own props on every House instance — and an own prop beats the whole
     chain.  A half-migrated method name reads the stale own copy forever.  **The cutover must be
      all-or-nothing per method NAME**, or `ghostsHaunt` must delete as it goes.
2. **`Object.assign` only ever adds.**  A method a bundle drops lingers on the prototype forever unless
    explicitly deleted — which matters directly for §0's "make loading DECLARED", since a bundle that no
     longer declares a method must not still answer to it.

### What this does NOT fix

**The 1.81MB.**  Class construction changes how methods ATTACH and DISPATCH, not which `.go` modules get
 imported and parsed.  The measured waste — a humdinger parsing every other page's Story Books — is
  decided upstream by `CREDULER_GHOSTS`, and stays exactly where it is until the manifest becomes
   particles (§0's own cure).  Do not let the A** shape be mistaken for that fix.

### Open decisions

- **What the dige covers.**  A bundle's dige is over a SET (its transitive closure — Radio's is 14 of
   36), so any member changing invalidates every class containing it, and the mutually-recursive core is
    both the biggest set and the most-edited.  Per-ghost dige or per-closure dige is unruled.
- **Generated classes cannot declare reactive state.**  No rune compilation at runtime, so `$state`
   fields can only be inherited from `Housing`.  Behaviour only; a hard constraint, not a preference.
- **Where the 150 single-caller reaches land** — the audit above is unstarted.

## Not yet

The toplevel inventory (what happens between page-load and commission) is still owed, and §0's second
 irritation — the built-up toplevel crap, the world-1→world-2 remount — has no design.  The A** shape
  above addresses the LOADING half's dispatch and identity; it does not on its own make the toplevel
   walkable.

## Its twin: the focus authority (`Focus_todo.md`)

The toplevel has TWO jobs and this doc names only one.  Atheory is the **loading** half (what code
 mounts onto the base Housing).  `Focus_todo.md` is the **attention** half (which fullscreen surface
  commands the user's screen at each moment — the "who's stealing the user's focus" the owner asked
   to have *"formulated carefully"*, 2026-08-28).  They meet here: the rebuilt toplevel should OWN
    the §3 focus authority from `Focus_todo` and stand it up early, rather than re-scattering the
     seven fullscreen surfaces that today each decide for themselves.  Design either without blocking
      on the other; land the focus coordinator on today's toplevel first to de-risk the rebuild.
