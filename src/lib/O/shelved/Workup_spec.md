# Workup — spec / doc block

## What this is

The Understanding gets a memory.  `%LE` stays one-target-at-a-time (that
boundedness is its whole joke), but retargeting no longer sheds unpushed work —
it parks it.  `%LE/%workup` is the LE-retargeting-transcendent pile of clearly
documented `Seem:working` states at their various points in Waft**: the What
we changed or added hanging out there, addressed by Dip so the surrounding
What** structure stays implied by the address rather than cloned along.

Why now rather than TODO: with `auto_push` off, `LE_arm` discards the working
clone tree on every cursor move.  Staged-push without a park is half a
decision — every retarget is a silent reset.  The workup is the missing half;
the leg | commit ceremony is then a thin layer of presentation over a
mechanism that has to exist anyway.

---

## The lifecycle

```
touring inward, editing
        │ retarget away while changey
        ▼
%workup/%Seemed,$at          — parked; resumes wholesale on return to $at
        │ ascend the What** slope above the floor of pooled change
        ▼
%workup/%leg                 — presented: "rides your next move"
        │  (↩ per-row discard · ✕ discard all · `·` dismiss-keep-pooling · ↑ now)
        │ the next structural move
        ▼
%Waftlet,$ts on w:Lies req:git   — landed in the real Waft; receipt filed
        │ soft while among the newest two   (↩ revert · ⋈ merge)
        ▼
hardened                     — heavy refs dropped; sc + encode snaps remain
                               as the raw material of the lazy-loaded git log
```

The clearing image: you run forward in time accumulating change; coming back
up the slope past the threshold, it stands presented in the open.  Any move
onward lands it.  The last two landings linger where you can still grab them;
everything older stacks beneath.

---

## Dip — Waft** as an address space

`Waft_dip(waft)` runs a `Selection` (one per waft, `waft.c.dip_Se`, its D
sphere persisted across `process()` via resume_X) over the whole Waft** and
stamps `c.Dip` on every What|Doc|Point.  Cyto's exact `Dip_assign` protocol
under a third scheme, `waftid` — the topD is seeded with `%Dip,value:w` so
depth-1 children claim distinct slots.

Properties that matter:

- **Opaque after minting.**  The value encodes the path at mint time only;
  thereafter it is identity.  Reorders and renames don't rewrite it — a
  renamed particle that resolve() can pair keeps its Dip; a genuinely new one
  claims the next slot.
- **Session-lived.**  `c.*` never snaps.  The workup and soft Waftlets are
  session-lived by design ("it should only exist for a little while until
  commit"), so re-minting on reload costs nothing they depend on.
- **Threaded OC→C.**  `Seem_clone_C` carries `child.c.Dip` onto each clone
  (patch below); `Workup_replace_back` carries it back onto pushed particles.
  A `PeelItem`-added clone has no Dip until its first landing dips it.

The svelte `#each` contract this buys:

```
{#each H.LE_clones(LE) as clone (clone.c.Dip ?? spec_of(clone))}
{#each seemeds as s (s.sc.Seemed)}        — Seemed mainkey IS the Dip
{#each softs as W (W.sc.Waftlet)}
```

Capsule rows and `%Pmirror,$spec` keyed on Dip become rename-proof — the
`c.Dip` TODO in the NaviCado join resolves through here once Point renaming
is wired.

---

## %workup — the particle layout

```
w:Lang/%LE                              — stable; survives LE_arm untouched
  /%workup                              — retarget-transcendent, session-lived
    /%leg                               — present only while a batch rides the
                                          next move; sc.t, sc.n
    /%Seemed,$at                        — at = target's c.Dip
      sc.at | what | waft | depth | t
      sc.live                           — this address is the armed target now
      c.target → OC %What               — live ref for the eventual replace-back
      c.C      → parked working clone root
                 (U meanings ride each clone.c.U — see meaning-carry patch)
      /%encode  snap_origin | snap_working | dirty
```

**Park** (`LE_park`, called by `LE_retarget` before every re-arm): runs its
own `LE_encode_compare` — the driver encodes after edits, but an edit and a
cursor move can land between thinks and `req_understanding` does checkout
before encode, so the parked receipt must not trust the last `%State`.
Changey → write|refresh `%Seemed,$at`.  Clean → drop any prior `%Seemed,$at`
(a resumed change the user worked back to clean leaves nothing behind).

**Resume** (inside `LE_retarget`): a `%Seemed` waiting at the destination's
Dip has its `c.C` adopted as `Seem:working%C` *before* `LE_pull`, so
`was_fresh` stays false and the walk wires fresh D|U spheres onto our clones.
An immediate `LE_encode_compare` resurfaces changey.  The Seemed stays in the
workup as the leg roster, marked `%live` — the next park refreshes it.

**Floor**: min `sc.depth` over the pool.  A retarget to a destination with
`depth <= floor - LEG_ASCENT` (constant, 1) presents the leg.  A Waft-level
destination reads depth -1, so surfacing all the way out always presents.

**Commit** (`Workup_commit`): for each Seemed, keep a revert base
(`Workup_keep_origin` — sc-copies of the OC children, Dips carried), then
`Workup_replace_back` (skip `U%unaccepted`, carry Dips).  The Waft watcher
(`watch_c` in Lies) sees each mutation and does `Lies_waft_save` + the
`e:Lies_waft_mutated` notify itself — commit owes no IO.  The rows then cross
to w:Lies as plain data (`e:workup_filed`), which is the Lies|Lang bridge the
trajectory's item 17 wanted: Lang hands over a finished receipt, never its
reqs.  The live target re-baselines (`LE_arm` + `LE_pull`) so its
Understanding reads clean against the just-pushed origin.

---

## The spool — req:git/%Waftlet

```
w:Lies …/req:git
  /%Waftlet,$id                — id = commit ts (seconds)
    sc.t | n | label | waft
    sc.soft                    — the newest two: revertable | mergeable
    sc.reverted                — spent by an intervene; hardened
    sc.t_from                  — a merged Waftlet's span begins at the older leg
    /%Seemed,$at               — the mute receipt per landed address
      sc.at | what | waft | depth
      c.target | c.C | c.origin_C       — soft only; Waftlet_harden drops them
      /%encode  snap_origin | snap_working
```

The spool is conceptually another Waft** imaged off the top of this one —
deeper cuts, revisions, floating fabrics.  Its representation stays
deliberately **mute**: label · age · ↩ · ⋈ — enough that someone realises
they are changing the real memory and can intervene, no more.

- **revert** — `origin_C` back as the target's children; watcher saves and
  notifies; an LE armed inside the reverted extent re-pulls via
  `origin_dirty`.  Spent → hardened.
- **merge** — the newer soft absorbs the older.  Shared addresses keep the
  newer working state over the **older** revert base, so one revert undoes
  both; you keep going on the same topics inside one commit.
- **harden** — past the newest two: drop the heavy `c.*`, keep sc + encode
  snaps.  They stack beneath as the raw material of the lazy log.

```
// < enWaft of req:git/* into wormhole/$path/spool.snap — the imaging that
//   makes the spool a real Waft, and the lazy-loaded log UI riding it.
// < a visual language for the grapple a teed-up operation makes on the real
//   memory, hung on the starting intention.
// < req:git do_fn proper (flush to remote) — the Waftlet is now the thing it
//   would flush; the do_fn remains pending.
```

---

## The empty Waft

`Workup_default_target(waft)` — first `%What`, else the `%Waft` itself.  An
armed-at-Waft LE works unchanged: clones are the Waft's direct children,
replace-back lands there, `Workup_at` falls back through `sc.Waft`, depth
reads -1.  PeelItem's first add just throws in a `%Point:1` and lets them
change it.

```
// < that bends the grammar (Waft → (What | Doc)*); promote the bare Point
//   into a %What once it has company or a name.
// < Lies_i_Spotlight should deliver Workup_default_target(waft) as the
//   cursor src when a Waft has no Whats — Lies-side wiring.
```

---

## Capsule framing — where search results will land

`LE_capsule_body(clone) → { spec, kind, raw }`.  Today every clone yields
`kind:'name', raw:spec` and the strip renders exactly what it renders now.
The frame is the contract for what flonks in later: a text-search hit over a
50k-line codebase arrives as a clone (`%Point,method,…`) carrying
`c.body = { kind:'patch', raw }`, and the capsule's body slot springs up to
show it.  `Workup_rawdiff` is the same slot's leg-row form — set-difference
of snap lines, ± prefixed, no ordering smarts, no folding.

```
// < the coherently folded patch renderer replaces both raw forms: hunks
//   region-squished per the Waft spec's `...` convention, target lines
//   enlarged.  The slot exists; the renderer doesn't.
```

---

## Patches to files not re-uploaded fresh

These three live in LiesEnd.svelte, which I only have in its pre-refactor
form — apply by hand against your live file.

### 1. `_Seem_CDUsive` — meaning carry (required for resume)

A resume drops the old D|U sphere with the Seems, but the parked clones still
hold their `c.U` object refs.  The fresh walk's `oai({Understandable:1})`
creates a NEW U and clobbers `C.c.U` — losing `unaccepted|unshowing|class`.
Carry them forward:

```ts
_Seem_CDUsive(C: TheC, D: TheC, Seem: TheC) {
    C.c.D = D
    D.c.C = C
    if (Seem.sc.opt.use_Understandable) {
        let U = D.oai({ Understandable: 1 })
        // a resumed clone arrives with meanings on its old (sphere-dropped) U —
        // carry them onto the fresh sphere's U before re-pointing the ref.
        const old = C.c.U as TheC | undefined
        if (old && old !== U) {
            if (old.sc.unaccepted != null) U.sc.unaccepted = old.sc.unaccepted
            if (old.sc.unshowing  != null) U.sc.unshowing  = old.sc.unshowing
            if (old.sc.class      != null) U.sc.class      = old.sc.class
        }
        D.c.U = C.c.U = U
        U.c.D = D
        U.c.C = C
    }
},
```

### 2. `LE_pull` — arm-freshness keys on the origin sphere, not working%C

A resume sets `working.sc.C` before the first pull, so `was_fresh` is false —
but the origin D sphere is fresh from the arm, every Point arrives as a neu,
and `stale` is stamped spuriously on every resume.  Key first-pull-ness on
the origin Seem instead:

```ts
// first pull since LE_arm — the origin D sphere is empty, every Point
// arrives as a neu; that is an arm artefact, not a remote drift.
const arm_fresh = origin.sc.topD === undefined

const od = await H.o_Seem(origin, strict)
…
const was_fresh = working.sc.C === undefined        // still gates Seem_clone_C
if (was_fresh) working.sc.C = H.Seem_clone_C(origin)
…
const stale = !arm_fresh && (od.goners.length > 0 || od.neus.length > 0)
```

### 3. `Seem_clone_C` — thread the Dips OC→C

```ts
Seem_clone_C(origin: TheC): TheC {
    const src_What = origin.sc.C as TheC
    const root = _C({ ...src_What.sc })
    root.c.waft = src_What.c.waft
    root.c.Dip  = src_What.c.Dip          // the clone answers to the OC's address
    for (const child of src_What.o({}) as TheC[]) {
        const k = root.i({ ...child.sc })
        k.c.Dip = child.c.Dip
    }
    return root
},
```

---

## NaviCado integration

- Mount `<NaviLeg {H}/>` directly below the tools row.  It is a pure renderer
  of `%workup` + the `%git_hold` ave hold; it adds no model.
- The `~` bar's reset already means `LE_arm + LE_pull`; unchanged.  The ~
  bar covers the live target; NaviLeg covers everything parked — they
  coexist without overlap because park drops a worked-back-to-clean Seemed.
- Capsule join: consume `H.LE_capsule_body(clone)` per clone; render `raw`
  in a body `<pre>` only when `kind !== 'name'`.  Key rows on
  `clone.c.Dip ?? spec`.
- The `What !== undefined` gates (PeelItem, ×→mark, target derivation) loosen
  to `What !== undefined || Waft !== undefined` so an empty-Waft session can
  inject its first Point.

Mounting LiesWorkup: like LiesEnd, by BOTH Lies.svelte and Lang.svelte — the
w:Lang handlers (`e_workup`) and w:Lies handlers (`e_workup_filed`,
`e_waftlet`) are two ends of one protocol and belong in one file.

---

## States, restated with the workup

`%State` on `%LE` is unchanged (armed | clean | changey | stale; `%push_dirty`
the push-cluster fault).  The workup adds positions, not states:

- a `%Seemed` is a changey state **parked at an address** — out of `%State`'s
  sight until resumed, when changey resurfaces through the normal encode.
- `%leg` is a presentation over the pool, not a state of any Understanding.
- a soft `%Waftlet` is a **clean** outcome that remembers how to become the
  origin again.

stale ∧ changey on resume-over-moved-origin is now the honest reading: the
encode shows exactly what a push would clobber.
`// < merge of resumed edits against a moved origin — resume-wins for now.`

---

## Open / deferred

```
// < time-trigger leg presentation — a quiet-minutes ttlilt alongside the
//   ascent rule; "as time|landscape goes by", landscape built, time not.
// < the coherently folded patch renderer for capsule bodies and leg rows;
//   text search over 50k-line codebases flonks hits into the same slot.
// < spool imaging: enWaft req:git/* → wormhole/$path/spool.snap; lazy log UI.
// < gesture layer: heaplet-clusters of collected labels (Cyto-layout-derived
//   svg-texted balls) laid up above|below a visor panel that lifts; the
//   Waft-overlay-or-merge dragged like a U-bend to the far side of it.
//   Needs a gesture-interpreting library; the world wanted eventually.
// < cross-waft legs: %Seemed carries sc.waft per row and commit saves the
//   touched set via the watcher, so the mechanism already tolerates a pool
//   spanning wafts — the leg presentation just doesn't say so yet.
// < bare-Point promotion into a %What on the empty Waft.
// < vanish (unaccepted goner on verify) — unchanged from LiesEnd_spec; a
//   commit that only unaccepts may read dirty on the live target's verify.
```
