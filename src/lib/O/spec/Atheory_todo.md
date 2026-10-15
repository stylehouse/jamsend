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

## Case study: the serving box (2026-10-14) — two more irritations, measured, fed here rather than patched

The owner, after a week tuning the jamserve daemon: *"we do indeed need to compartmentalise and notice change better, but I
 think we might be scraping together a case study to feed to Atheory more than further optimising this now… this is a
  coherent point!"* The numbers and file:lines are in `Perf_todo.md` §7 (§7.6 is four surveys' evidence). What it says about
   Housing's next shape:

3. **Code arrives by polling.** `Creduler_reswap` (`LiesLies.svelte:1483`) asks the dev server "which `.go` changed?" every
    2 s from every runner tab (`/__gen/dige`, or ~35 HEADs without it). It even did so on the daemon, at prod, for nothing (now
     skipped there). Owner: *"we should not require polling like that, code changes should push out to the required runners."*
      The server already knows the instant a `.go` is written (the Docindex push, `control:docindex` ≈450 ms, is the precedent).
       And A** knows which runner holds which ghost (the declared manifest of §0 irritation 1). So delivery is a PUSH addressed
        by the manifest: "Swarm.go changed → the runners whose A** holds Swarm get it". The swap seam ("never mid-run") stays
         the receiver's rule. Visibility comes free: a code version becomes a particle on the A that holds it, so "which runner is
          on which Swarm.go" reads off the tree instead of an ETag map in `.c`.
4. **Change is noticed by re-running everything.** A belief pass re-derives the world (organise, attend, reqdo_sweep, officing)
    whether or not anything changed. The surveys found why that can't be cheaply gated today:
    - `version` is per particle and nothing carries it to the world or the House;
    - plain `sc` and `.c` writes record nothing;
    - every pass bumps every A itself (the `self_timekeeping` round, `A.replace({w:1})`);
    - eternal reqs look like work every pass;
    - wakes are anonymous (`think` from anyone, for anything).

    On a box that never sleeps, that re-running WAS the workload (60–80% of a core, idle). The Atheory answer is
     **compartments that know they changed**: each A/w carries a dirty mark raised by any mutation beneath it (an up-walk on
      bump, which REACTAP's per-host tap already half-does), cleared at the end of its own pass. A pass visits only dirty
       compartments plus those holding a HOLD (an unfinished req, a due ttlilt). Clock-driven work declares itself
        (`wants_clock`) instead of riding every pass. A wake names its compartment (`think(w)`, not `think`).

    **The owner's direction (2026-10-14), rejecting even a module-level counter many readers consume:** *"this need is going
     into the Atheory design, possibly some kind of space-flow map that refers to itself for responditivity and time|space
      isolation scheme… the need to make the entire weave of computation mergable."* Read as requirements:
    - **Space-flow map.** Which compartment feeds which is itself legible matter, the map the passes follow, not a global
       signal everyone polls.
    - **Refers to itself for responditivity.** A change finds who must respond by consulting that map, so responsiveness is
       a lookup, not a broadcast.
    - **Time|space isolation.** A compartment's pass sees a consistent slice: one place, one moment.
    - **Mergeable.** Two weaves of computation (two tabs, two bodies, a runner and an editor) can be joined like the
       particles they're made of, which only works if every change is a recorded, attributable event.

    That's a Housing redesign, not a patch. Its correctness rests on EVERY change being noticed, which is exactly what the
     code doesn't guarantee today. Hence: case study first, rebuild later.

5. **The heap a body carries should be chosen, not inherited (2026-10-15).** The jamserve daemon idles at ~725 MB RSS (~1.35 GB
    while encoding). The particle tree is ~5 MB of that; the rest is the whole app booted headless: vite-node, jsdom, every UI
     face, the Story/Vyto houses. A serving body needs perhaps a fifth of it. That's irritation 1's declared manifest with a
      ROLE: an A** that says "serve" loads the serving ghosts, prebuilt, and nothing that only exists to be looked at. Owner:
       *"it could lose some weight as part of Atheory which is going to be selective about the javascript heap we have
        running."* Measurements + the cheap interim levers: `Daemon_todo.md` §0.000.

*Interim on the daemon (deliberately small):*
- the tour rests with no audience;
- an idle floor with wake-on-queued-work;
- no stack capture per `replace()`;
- a dir-listing cache;
- the reswap skip.

None of these touches Housing's pass. The proposed "R1b" (a global bump counter to skip empty daemon thinks) is parked: it's
 a cheap imitation of irritation 4's dirty marks, and its blind spot (writes that don't bump) is the same blind spot.

## The merge organ — LE and Repli each hold half of it (expanding the retired Tend §7, 2026-10-15)

> 👤 **For people.** The owner wants Atheory to make *"the entire weave of computation mergeable"*: two tabs, two devices,
> a friend's copy, an LLM's suggestion, all able to meet and become one, the way particles already can.  The machine has
> TWO halves of the thing that would do that, built separately, and neither is whole.  One (LE, the editor's "understanding")
> can hold a rival version of something and decide whether to take it, but only for documents.  The other (Repli, the
> wire's replication) moves any kind of thing between bodies, but has no notion of a rival version at all: whatever arrives
> simply IS the new truth.  Meanwhile, every place two bodies actually share state has grown its own little merge by hand.
> This section says what one merge organ would be, and why it's an Atheory job rather than a patch.

Source: `history/Tend_todo.md` §7, "Why not LE, why not Repli" (scouted in full 2026-09-04; its references re-checked
 2026-10-15: `Repli_design.md` still asks for the Seem port, the sole-writer axiom is still `Repli.g:313`, LE's encode
  path is unchanged).  The rest of that retired doc's vocabulary (qua/grain/accord) is left where it is on purpose (owner:
   *"I don't really believe much of this language… maybe we'd better leave most of it"*).

### What the two share — the part that is already right

Both stand a `Selection` and bottom out in the SAME `resolve()` pairing (`Stuff.svelte.ts:1114`): given a new tree and an
 old one, pair each new particle with the old one it IS, by unambiguity scoring, and say what was born, what went, and what
  stayed.  Both independently dodged the same `est_D_T` footgun and both left `resolve_strict` off.  Twice-validated, by two
   teams of one, a month apart.  **Any merge organ is `Selection`/`resolve()` at its core.  Don't build another.**

### What each half lacks

| | LE (`LangHold`, `i_Seem`/`o_Seem`) | Repli (`Repli.g`) |
|---|---|---|
| **a candidate** — a rival version held BESIDE the canonical, decided on | ✅ `Seem_clone_C`: origin vs working | ❌ arriving lines go straight into the live `%Theirs` shelf (`Repli_merge:356`) |
| **who wins** | the human, by accepting | unaskable: the **sole-writer axiom** (`Repli.g:313`): only the sender ever writes, so its copy IS truth |
| **any mainkey** | ❌ `LE_encode_compare → Seem_toString → enWaft` faults outside `%What/%Doc/%Point` (silently corrupts the gate, not a crash) | ✅ protocol-blind lines |
| **depth** | ❌ clone extent hard-coded depth-1, in two places | ✅ whole subtrees, paged |
| **key-level memory** (which KEY moved, not just which particle) | partial (the D-sphere) | ❌ a `.c.repli_sent_sc` smear: never snaps, dies on reload, so a mutation across a restart splits into a twin (`Repli_design.md` §5) |
| **refusals** | ❌ `U%unaccepted` lives on `.c`, and the D-sphere is `r()`-wiped each walk | ❌ `ra_missed`/`breach` on `.c` |
| **proven** | ❌ no Book (only Svelte rigs) | ✅ eleven Books |

Read across a row: each column is strong exactly where the other is weak.

### Why it's urgent now: the sole-writer world is over

Repli's axiom was true when a body only ever mirrored a FRIEND's shelf.  It stopped being true when one soul got many
 bodies (crew, 2026-09) and when the same ledger began living on several devices.  Since then, every shared-state seam
  has hand-rolled its own merge:
- **`Heard_mirror_merge`** (`Heard.g:379`): per stamp, newest timestamp wins, plus a special case so an un-ticked LOFI can
   travel (the "listing copy only ever adds" bug, 2026-10-04).
- **`Swarm_crew_heard`** (`Swarm.g:241`): the crew ledger, signature-gated.
- **`Swarm_charter_heard`** (`Swarm.g:8280`) and **`Swarm_roster_heard`** (`Swarm.g:8037`): the charter and the roster.
- **`Repli_merge`** itself, with its identity table and `.c` shadow.
- **Pier marks** (☆/notes) — deliberately kept browser-local (2026-10-14) precisely because there was no merge to trust.

Each one re-decides "same thing?", "who wins?", "what about a delete?" and "what about a refusal?" on its own, and each
 has had its own bug where the answer was subtly wrong.  That's the anonymous-wake disease (Case study irritation 4) in
  data form: no shared organ, so everyone re-derives.

### The organ, in four rules (design, unbuilt)

1. **Pair with `resolve()`, on DECLARED identity.**  Identity is minted by whoever mints the thing (an id, a tok, a
    prepub), never inferred from content: inferred identity makes every rename a goner+newborn and every re-parse churn.
     `c.vyto_tok` is the precedent.
2. **Arriving data is a CANDIDATE, not the truth.**  It lands beside the canonical, and a per-kind POLICY accords it:
   - *derivations* (computed from the canonical; can only be stale) auto-accord;
   - *proposals* (want to become the canonical) need a rule or a person.
   "Newest stamp wins" (heard), "signed by the soul wins" (crew/charter) and "the sender owns it" (a friend's shelf: today's
    sole-writer case, now just one policy among several) are all policies, not separate mechanisms.
3. **Key-level memory is a sphere, not a smear.**  Per the owner's 2026-08-05 framing in `Repli_design.md` §5, the
    "what did I last send/accept for this key" memory is a second sphere in `D/*`, stitched at each particle.  It's a real
     C** that can persist, so restarts stop splitting twins.
4. **Refusals snap, with their reason.**  A refusal that lives on `.c` is re-offered forever.  The machine must remember
    what it declined and why, the same as what it took.

### Lineage and naming (owner, 2026-10-15)

- **LE came first, and Repli was written knowing it**, which is why Repli reused `Selection`/`resolve()` and why
   `Repli_design.md` asks to move onto `i_Seem`/`o_Seem`.
- **Se becomes known as Merge, eventually.**  `Selection` (the "Se") is the pairing engine both halves stand on.  It's on
   the same development path as `Cstructures_todo.md` §3, "what the Se wants": every saying carries its provenance
    (`by:` which engine, `rule:` which law, `hid:` what it subsumed, `pass:` when).  That's rule 4 above generalised: not
     only refusals but every merge decision states why.  The thing that holds state and reacts in certain ways.
- **"Bi-directional Repli" was never built.**  Today each side runs its own one-way Repli of its own shelf; friends mirror
   each other through two channels.  The real two-way case is the crew: two bodies of ONE soul writing the same ledger.
    That's what the hand-rolled merges above are doing.

### The next iteration — not a port, a successor

Owner: *"the next iteration will be another LE|Repli thing.  LE is going away, and Repli should be easily replaced by a
 more mature and feature-achieving version of itself… having it stream over the wire, be distributable, like fractures of
  conversations on the fediverse drifting by that can load their earlier bits."*

So the old "port Repli onto i_Seem/o_Seem first" is dropped.  The successor (call it Merge until it's named) is built new,
 keeping only what's twice-validated (`resolve()` pairing), and is shaped by these properties:

- **Fractures, not dumps.**  The unit on the wire is a fracture: a piece of a weave (a few particles, or one change)
   carrying its declared identity and a reference to what it came from.  A receiver can hold a PARTIAL weave.
- **Earlier bits load on demand.**  Like a fediverse reply drifting into your timeline, you can see it without the thread,
   and ask for its ancestors when you want them.  A fracture names its parents, and any holder can serve them.  Today's
    `repli_want` (pull the offsets you lack) is the seed of this, but it only knows "pages of one record".
- **Distributable.**  A fracture is valid from whoever holds it, not only its author.  It is authenticated by its own
   signature, not by the road it came on.  That's the same move as the signed call (`Signed_call_todo.md` §3) and the WT session
    keys (`Trust_audit_handover.md` §0.3).  SoundPooling already distributes audio this way; Merge does it for state.
- **Streams.**  It applies as it arrives, in any order the parents allow.  No "whole catalog every 60 s" (Perf §7: R4c).
- **Candidate + policy + provenance** (rules 2–4): arriving fractures are candidates; a per-kind policy accords them; every
   decision, and every refusal, leaves its `by/rule/why`.

### Point (c), expanded: prove the organ on ONE known-answer merge

Before anything new rides it, the organ must reproduce a merge we already trust, exactly.  The heard mirror is the case:
- **Today:** `Heard_mirror_merge` (`Heard.g:379`) walks a sibling's Cards.  For each one, per stamp key, the newer
   timestamp wins.  Listing keys copy over when a stamp advanced, and `lofi` follows the press exactly.  That's about 25
    lines of hand logic.
- **On the organ:** the sibling's Mag arrives as a candidate; `resolve()` pairs Cards by their declared identity
   `(id, pub)`; the policy is "per key, max stamp; listing keys ride an advance; lofi rides the press".  The organ produces
    the accorded Mag and the provenance rows.
- **The proof:** MusuHeard, MusuMagnet and MusuHandoff stay byte-identical, with the old function deleted.  If the policy
   can't be said in a few lines, or the fixtures move, the organ's abstraction is wrong.  We'd learn that cheaply, on a
    merge we already understand, before trusting it with crew ledgers or the wire.
- **Why that one:** it's small, well fixtured, single-policy, already multi-writer (Captain + Cave), and it has had the
   exact class of bug the organ exists to end (the un-ticked LOFI that couldn't travel, 2026-10-04).

### What it unlocks

- **Pier marks** (☆/notes) that follow you across your Caves, which are browser-local today because nothing could merge
   them safely.
- **The crew's ledgers** (crew, charter, roster) without per-kind merge code.
- **Eventually the editor and runner sharing one weave.**  Today the editor compiles a `.go` and ships its bytes to each
   runner (`LiesStore_good → land_good`), and Atheory's case-study irritation 3 is that delivery being polled.  With Merge,
   code changes would be fractures like any other, pushed to the bodies that hold that ghost.

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
