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

## Not yet

No design here yet beyond the inventory above — this doc exists so the itch has an address.  Before
 proposing the A** shape, finish the toplevel inventory.

## Its twin: the focus authority (`Focus_todo.md`)

The toplevel has TWO jobs and this doc names only one.  Atheory is the **loading** half (what code
 mounts onto the base Housing).  `Focus_todo.md` is the **attention** half (which fullscreen surface
  commands the user's screen at each moment — the "who's stealing the user's focus" the owner asked
   to have *"formulated carefully"*, 2026-08-28).  They meet here: the rebuilt toplevel should OWN
    the §3 focus authority from `Focus_todo` and stand it up early, rather than re-scattering the
     seven fullscreen surfaces that today each decide for themselves.  Design either without blocking
      on the other; land the focus coordinator on today's toplevel first to de-risk the rebuild.
