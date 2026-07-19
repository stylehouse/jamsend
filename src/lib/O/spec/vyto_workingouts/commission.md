# Workingout — §10 The commission and the grapple

Elaborates `Vyto_spec.md` §10.  A working doc, not a spec: everything here is proposed,
 and the code citations are real (checked 2026-07-19 against the live tree).  The one
  correction this workingout forces on §10's mental model is flagged loudly in "The drive"
   below: `watch_c` is shallower and stricter than the sentence "watch_c's the whole
    complicated bunch" implies, and the transitive grapple derivation turns out to be
     **load-bearing, not a convenience** — without it the drive misses most of what moves.

## 1. The commission sc, v1

Five keys.  Nothing else.

> commission (a detached `TheC`, scaffolding — never attached to the snapped tree, exactly
>  like today's; refs ride `.c`, scalars ride `sc`):
>
> | key | which form | what |
> |---|---|---|
> | `Scannable` | plain | a ready C to scan (ref, `.c`) |
> | `recipe` | recipe | IOexprs as children of the commission (§3); mutually exclusive with `Scannable` |
> | `Styles` | both | the styles C, poured into the ave channel as today (ref, `.c`) |
> | `client_w` | both | the commissioning world (ref, `.c`) |
> | `grapples` | plain, optional | explicit source list (refs, `.c`); default = `[Scannable]` |

What is deliberately **absent**, against today's `e_Cyto_commission`
 (`/app/src/lib/O/Cyto.svelte` 111-142, which caches `supports_seek`,
  `supports_takeTurns`, `supports_constraints`, `wants_wave_done`,
   `wants_animation_done`, `useVoroCyto`, `useFaces` onto `w.c`):

- **takeTurns** — dies with the regime it names.  The comment at Cyto.svelte 89-91 is the
   epitaph: *"When commissioned by a takeTurns client, all work happens in
    e_Cyto_animation_request and e_Cyto_seek. Cyto() is idle."*  The drive belonged to
     the client; in Vyto the drive is the glass's own (§4 below).
- **wants_wave_done / wants_animation_done** — there is no wave to be done.  Ceremony,
   when Story needs it (settle-before-snap), rides the *request*: a seek or settle request
    carries its own await and reads the `%Settle` tick (spec §3).  The Sounditron regime
     already proved the snap side: toc carries the pure-H stance and nobody waits on a
      handshake (`/app/Ghost/Story/Sounditron.g` 118-125).
- **useVoroCyto / useFaces** — the fold and the faces are Vyto's nature, not opts.
   Voro.g's knowledge is the Fold organ; showing/hiding is the tuner's crew dial, not a
    commission capability.
- **supports_seek / supports_constraints** — seek is always supported and is a request,
   not a negotiated capability.

### How the refusal behaves — proposal: loud rebuff, then proceed

A refused key on the commission must not be silently ignored — silent failure is exactly
 the culture §10's %Tuner lesson names (*"the failure is silent and reads as 'toggles do
  nothing'"*).  But refusing the whole commission is too brutal for the moult: a
   half-ported Book would get *no glass at all* and the porter would be debugging absence.

Proposed: **refuse the key, accept the commission, mint a loud %rebuff row** in the glass
 world, one per offending key — the invite-ledger idiom ("read the %rebuff why"):

```
w.i({ rebuff: 'takeTurns', why: 'v1 — ceremony rides the request' })
w.i({ rebuff: 'wants_wave_done', why: 'no wave exists — await %Settle on the request' })
```

The row is an ordinary sc row, so where the glass world reaches a snap it lands in the
 fixture diff — a ported Book that still passes a dead flag goes **red at the gate** with
  the reason written in the diff, instead of wedging on a handshake that never comes and
   teaching the porter nothing.  Plus a `console.warn` for the live tab.  (A client that
    passed `wants_wave_done` and then awaits it will still wedge — nothing can un-wedge a
     waiter — but the why is now standing in its own world.)

## 2. The plain form

The commission hands a ready `Scannable` (+ `Styles`, `client_w`) and, optionally,
 `grapples` — the explicit list of source Cs to watch.  No list given: **the degenerate
  default is a single grapple on the Scannable itself.**  That watches only the
   Scannable's *direct* children (see §4 on version semantics — this is a real limit, not
    a nicety), which still beats today's nothing: the comment at Cyto.svelte 108-110
     promises *"watch_c the Scannable so future mutations fire cyto_update_wave
      automatically"* and the body of `e_Cyto_commission` never places any watch.  The
       spec's "the drive was never built" is confirmed at that exact seam.

The plain form is the migration door: any current commissioner can move over by deleting
 its dead flags, and tighten into a recipe later.

## 3. The recipe form — IOexprs and the Sunpit

The recipe says *how to make* the Scannable.  No `Scannable` key rides the commission;
 the **Sunpit** — the staging container where the poured-in sources assemble — *becomes*
  the Scannable.  The Sunpit stands c-side on the glass world (`w.c.sunpit`), `c.up`
   stamped for upward walks, unreachable from H\*\* — so it never snaps and Books stay
    glass-blind (the snap-inclusion law: snapped iff reachable).

### The IOexpr row grammar

Each IOexpr is one child of the commission particle, mainkey `IO`, its value the row's
 name.  Refs in `.c`, scalars in `sc`:

> ```
> %IO,<name>
>   from:   (.c) a resolved source C — a shelf, a face particle, a world
>         | find: an o()-query (sc, scalars only) walked from `in:`
>   in:     (.c) the root for `find:` — defaults to client_w
>   each:   1 — `find:` fans out: EVERY match is a source, and the derivation
>              re-runs as matches come and go (a new friend home joins live)
>   shape:  mirror | slope | presence | pick:<keys> — the shaping verb
>   as:     the name the assembled matter wears in the Sunpit (defaults <name>)
>   weight: <sc key> — slope only: which quantity is the height
>   deep:   1 — grapple the containers DISCOVERED under the source too
>              (the Mag-page reality — see §4 on why this must exist)
> ```

The `find:`/`in:` split lets a recipe be authored before the gear stands — the query
 re-resolves each derivation pass, so gear minted later is picked up without
  recommission.

### Assembly semantics

Assembly is the first half of every scan (§4 gives the timing).  For each IOexpr:
 resolve the source(s), apply the shaping, land the result under `Sunpit/%<as>` by
  find-or-create with in-place drift-bump — the `i_actions_to_c` lesson (Housing
   1570-1575): same ref every pass, version bumped only on real drift, so nothing churns.

The shapings, v1:

- **mirror** — many-place the *same refs* into the Sunpit, the `enroll_watched` default
   handler's own idiom (Housing 1531-1540: `dest.empty(); for n of C.o({}) dest.i(n)`).
    The Sunpit rows ARE the source particles, so faces get their `source_n` backlink for
     free and identity is never impersonated.
- **slope** — mint a `%Slope` scope (spec §6) whose members are referring rows wearing
   `of:<id>` (the many:1 law), height read from `weight:`.  Meaning-owned when the model
    reads the position back.
- **presence** — reduce to compact rows, the trickle-fingerprint idiom
   (`Sounditron_trickle_look` builds exactly this: `Friend → here/records/music`).
- **pick:** — project the named sc keys onto referring rows; guard every maybe-undefined
   (the `undef`-brand law — a sloppy pick is a mint bug).

### The transitive grapple derivation

Because the recipe names its sources, Vyto derives the grapple set — *a grapple on what
 it has a grapple on*:

1. Every resolved `from:` / `find:` match.
2. For `each:` rows, also the `in:` root — so a NEW match arriving (a friend home minted
    by `Swarm_share_up`) bumps the root, fires a scan, and the re-derivation grapples the
     new source before the next burst.
3. For `deep:` rows, every container *discovered during shaping* — the shelf's
    `%Mag:shuffle`, each `%Cloud,page:N` under it.  Re-derived after every scan (it is
     the same walk, already paid for); a page minted mid-play enrolls itself.

Step 3 is not politeness.  §4 shows why: a bump never propagates up the C tree, so
 without the transitive closure the drive is blind to almost everything that actually
  moves.

Each derived grapple stands as a c-side `%Grapple` row under the glass world's board
 furniture (`{Grapple:<io name>, era:N}`, `.c.source` the ref) — the panel paints them
  (spec §9: organs declare their links), and the era guards teardown (§5).

## 4. The drive — what the machinery really does

Read against `/app/src/lib/O/Housing.svelte.ts` 1458-1544 (`watch_c`,
 `start_watched_C_effect`, `enroll_watched`) and `/app/src/lib/data/Stuff.svelte.ts`
  61-64, 98-101, 203-215, 239-260 (version semantics).  Four facts differ from the
   casual reading of §10; each shapes the design.

**Fact 1 — watch_c is a House registry, not a per-C facility.**  `watch_c(C, handler)`
 is a method on Housing; each House keeps `watched: Array<{C, handler}>` with a parallel
  `watched_v: number[]` of last-seen versions.  Any C can be watched, but only by
   explicit enrolment on some House.  And the dedup is by C ref with **silent drop**:

```ts
watch_c(C: TheC, handler: () => void | Promise<void>) {
    if (this.watched.some(w => w.C === C)) return   // second claimant silently loses
    this.watched.push({ C, handler })
    this.watched_v.push(C.version)
}
```

One handler per (House, C).  If another ghost on the same House already claimed the C,
 Vyto's grapple is dropped without a sound — the elvis-mismatch gotcha's cousin.  Real
  instance: Story watch_c's `The_Styles` and `The_Opt` on the Story House
   (Story.svelte 1509-1512); a Vyto grapple on the same Styles C *on that House* would
    silently no-op.  Mitigation: enroll grapples on the **Run House** (§5), where Vyto
     is in practice the only watch_c client — and see Open questions for whether Housing
      earns a multi-handler or at least a loud warn.

**Fact 2 — version bumps do not propagate up.**  `C.version` is the serial of the
 particle's own root X.  A direct child attach bumps the parent (`i()` calls
  `this.X.i_z(n)` → root `bump_version`, Stuff.svelte.ts 245); `oai` bumps on real
   drift; `drop()` bumps; but a **grandchild mint bumps only its own parent**, and the
    REACTAP comment states the law plainly (Stuff.svelte.ts 62-64): *"the root serial is
     the only one a `void C.version` subscriber sees, so child-x index bumps are
      non-events."*  Also: **raw `n.sc.k = v` bumps nothing** — only `i()`/`r()`/
       `oai`-drift/`bump()` do (hence `gn.bump_version()` sprinkled through Cyto).
        Consequences: the degenerate plain form sees only the Scannable's direct
         children; the transitive `deep:` grapples are what make the drive real; and a
          source that mutates sc raw without bumping is invisible — the discipline the
           drive rewards is already written in Radio country (*"Bumps w ONLY on a real
            change"*, Sounditron.g 184).

**Fact 3 — the flush runs after beliefs settles, but UNDER a fresh mutex hold.**
 `start_watched_C_effect` (Housing 1497-1518) runs per House at `start()`.  One $effect
  reads `void C.version` for every watched C — Svelte subscribes to them all.  First
   bump: `pending = true`, `setTimeout(flush, ANSWER_CALLS_TICK_MS/2)` (= 25ms).  Then:

```ts
const flush = () => this.clear(async () => {
    pending = false
    for (let i = 0; i < this.watched.length; i++) {
        const C = this.watched[i].C
        const v = C.version
        if (v !== this.watched_v[i]) {
            this.watched_v[i] = v
            await this.watched[i].handler()
        }
    }
})
```

`clear(fn)` (Housing 978-984) awaits `all_clear()` — the top House's `_mutex_beliefs` —
 **and then re-acquires the beliefs mutex** to run `fn`.  So handlers fire (a) after the
  beat fully settles, (b) inside their own exclusive hold: the world is frozen under
   them, and **an unbounded await inside a handler starves every subsequent beat exactly
    like one inside a do_fn** — the Sounditron deadlock lesson applies to the flush,
     not only to steps.  Handlers also run *sequentially* in one loop shared by every
      watch on that House: a slow Vyto handler delays its neighbours.

**Fact 4 — the flush fires once per changed C, not once per burst.**  Trailing-edge
 coalescing at the flush layer is real: bumps within the 25ms window and the mutex wait
  share one flush (`pending` stays true through the wait); a C bumped six times fires its
   handler once (single version compare); bumps arriving *during* handler execution
    re-arm `pending` and schedule a follow-up flush.  But six *different* grapples
     changed in one window fire six handler calls.  "One scan per burst" is therefore
      Vyto's own second stage:

> **The Vyto scan hook.**  Every grapple enrolls the *same* handler, and the handler is
>  latch-and-schedule only — sync, O(1), nothing awaited:
>
> ```
> grapple handler(w, era):
>     if era stale → return                    // teardown, §5
>     if w.c.scan_pending → return             // the second-stage latch
>     w.c.scan_pending = 1
>     setTimeout(() => H.clear(() => {         // its own frozen transaction,
>         w.c.scan_pending = 0                 //  off the beat, off the flush loop
>         Vyto_assemble(w)                     // IOexprs refresh the Sunpit (§3)
>         Vyto_scan(w)                         // Scan writes the mirror; solvers follow
>     }), 0)
> ```
>
> Six grapples changed in one flush → six latch calls, one scan.  The scan rides its own
>  `H.clear()` — same frozen-world guarantee as the flush, but out of the shared handler
>   loop, so neighbours never wait on a tessellation.  (queueMicrotask is NOT safe here:
>    the flush awaits between handlers, so a microtask from handler 1 can run before
>     handler 2 — the timeout is the correct trailing edge.)

**Teardown.**  There is **no unwatch anywhere** — grepped: the watched array only ever
 grows, no splice, no removal API.  What exists is House death: `stop()` disposes the
  `$effect.root` (Housing constructor 145-147, stop 130-136), which kills the flush
   effect — a stopped House stops watching, though its array pins refs until GC.  Two
    consequences: grapples must enroll on a House whose death matches the commission's
     life (the Run House, §5); and a *re*-commission on a living House cannot remove the
      old handlers — so every handler is **era-guarded** (the stoker/trickle idiom:
       `Stoker_wake`, `Sounditron_trickle`): the commission stamps `w.c.grapple_era`,
        handlers carry their era and no-op stale.  Dedup makes re-enrolment of a
         still-grappled C a no-op, so the era stamp is the entire recommission story.

## 5. Ownership — the run owns the commission

**Vyto: the commission is owned by the RUN.**  The world commissions its own glass from
 its glass stand (the `Sounditron_glass` position — the world-side cut the human made
  2026-07-17), the grapples enroll on the **Run House** (`H/%H,Run` — a real Housing
   instance with its own watched registry and its own flush effect), and the commission
    lives as long as the world.  Teardown is House death — no unwatch needed for the
     common case.  **Story is a seek client, not the owner**: it asks (seek requests,
      settle-awaits) and every ask rides the request.

Contrast with today, which has *two would-be owners and a latch*:

- **The rail commission** (Story.svelte 1523-1564, `Story_settingoff`): Story mints the
   commission gated on `The/Opt/useCyto`, Scannable = the Run House, client_w = w:Story,
    `supports_seek + supports_takeTurns`, `wants_wave_done + wants_animation_done`
     always, useVoroCyto/useFaces per Opt.  The owner is the rail; the world is a
      bystander to its own glass.
- **The world commission** (Sounditron.g 126-177, `Sounditron_glass`): the world
   commissions itself (no wave flags, no takeTurns) but must **stand down** if the rail
    got there first — lines 168-172: *"a second commission here would overwrite its wave
     flags and wedge the snap wait — stand down when it already rides."*  That stand-down
      dance is the tell that ownership is contested; in Vyto it dies because the second
       owner dies.

What carries over: the `Scannable`/`Styles`/`client_w` trio, the elvisto door
 (`e_Vyto_commission`, since world and glass are different ghosts), Styles pouring into
  the ave channel, idempotence per world.  What dies: takeTurns and the client-driven
   idle regime; `wants_wave_done`/`wants_animation_done` (no wave); the
    `supports_*` capability negotiation; `useVoroCyto`/`useFaces` (nature, not opts);
     the Opt-gated rail commission itself and the stand-down latch.

## 6. Furniture lookups — the three-shape walk

The Scannable may be a world, or a Run House whose worlds sit one A-hop deeper — and a
 lookup that only checks one shape fails *silently*: the %Tuner lesson, live in
  Cyto.svelte 374-388, where a client_w-only lookup *"threw the census away every scan
   ('no crews yet', forever)"* and read as "toggles do nothing".

One helper, in Vyto.g, used for **every** furniture find (tuner/crews, `%Seek`, board
 state, `%Grapple` rows):

> `Vyto_furniture(w, q)` — first hit wins, in order:
> 1. `w.c.client_w?.o(q)[0]` — the commissioning world
> 2. `Scannable.o(q)[0]` — the scanned thing itself
> 3. `Scannable.o({w:1})` → each `.o(q)[0]` — a House's worlds
> 4. `Scannable.o({A:1})` → each `.o({w:1})` → each `.o(q)[0]` — H > A > w, the
>     Run-House shape the rail hands over
>
> Never inline the walk at a call site; the day a fifth shape appears it gets added
>  here once.

## 7. Worked example — a Radio world commissions with a recipe

The gear that really stands in a Radio run world (Radio.g / Ra.g / Sounditron.g):
 `%Radio` and `%Stoker` face particles (`Radio_ensure`, `Stoker_ensure`), `%Tuner`,
  `%Mag:'Lineup'` with `%Card` children (`Radio_lineup_fill`), `%Friend` rows kept
   current by the trickle, my home `%MusuSelf,pub:<me>` whose `stock` shelf pages as
    `%Mag:shuffle → %Cloud,page:N → cards` (the Mag model, Ra.g 533-546), and each
     friend's mirror `%MusuThem,pub:<them>` whose stock still lays flat (*"mirrors still
      lay flat until the wire cut"*, Ra.g 536).

The commission, authored where `Sounditron_glass` builds today's (Sounditron.g 176-177),
 replacing it:

```
commission %Vyto_commission          — detached scaffolding, refs in .c
  client_w: w
  Styles:   SH.The_Styles(stw)
  recipe:
    %IO,stock                        — "my stoker's stock"
      find: {MusuSelf:1, pub:<me>} → stock shelf     in: w
      shape: mirror    deep: 1
    %IO,mags                         — "these piers' Mags shaped as a slope"
      find: {MusuThem:1} → stock shelf               in: w    each: 1
      shape: slope     weight: fresh
    %IO,presence                     — "the trickle's presence"
      from: w    pick: {Friend:1}
      shape: presence
```

The derived grapple set — *a grapple on what it has a grapple on*:

> - `%MusuSelf,pub:me/stock` — the shelf; **deep** adds `%Mag:shuffle` and every
>    `%Cloud,page:N` under it.  A page minted by `Stoker_mag_draw` enrolls at the next
>     derivation; without deep, cards landing on page 3 would be invisible (Fact 2).
> - each `%MusuThem,pub:<them>/stock` — one flat shelf per friend; plus `w` as the
>    **each-root**, so a new friend home minted by `Swarm_share_up` bumps w, fires a
>     scan, and the re-derivation grapples the new shelf — a friend arriving mid-play
>      joins the slope with no recommission.
> - `w` itself for the presence row — and the trickle already keeps the bargain the
>    drive needs: it bumps w **only on a real change** (Sounditron.g 184), so presence
>     costs a scan exactly when a friend arrives, leaves, or their counts move.

One burst, walked: the stoker's look lands six records and draws a Mag page — shelf and
 page bump repeatedly inside one beat → the Run House's flush effect wakes once, 25ms
  after beliefs settles → each changed grapple's handler latches `scan_pending` → **one**
   assembly + scan → the Sunpit's `%stock` mirror refreshes in place, the `%mags` slope
    re-heights, presence untouched → Scan writes the mirror, Fold and friends move the
     glass once.  Today that burst moves nothing until Story pokes or a hand gesture
      lands.

The slope's second payoff is §6 of the spec made concrete: if `%IO,mags` is
 meaning-owned, dragging a friend's Mag up the slope *writes* the weight that
  `Radio_lineup_fill`'s round-robin could read as a draw bias — arranging the queue is
   playing it.  v1 can land the slope display-only and cut the write-back when the fill
    learns weights (open question below).

## Open questions

1. **The rebuff stance.**  Proposed: refuse the *key*, accept the commission, loud
    `%rebuff` row that reaches the fixture diff, plus console.warn.  The alternatives —
     silent ignore, or refusing the whole commission — are both defensible.  Rule.
2. **watch_c's silent dedup.**  One handler per (House, C), second claimant silently
    dropped.  Does Housing earn a multi-handler `watch_c` (or at minimum a loud warn on
     the dropped claim), or does Vyto live with Run-House-only enrolment and the
      collision risk?  Touching Housing is a core seam — if yes, it gets proven in
       isolation first.
3. **Grapple hygiene over a long life.**  No unwatch exists; on a long-lived resident
    world (BigSoundland, tab open for days) pages and friend shelves accumulate
     grapples that never leave.  Is era-guarding + dedup enough for v1, or does Housing
      earn an unwatch?
4. **Where w:Vyto stands.**  With the Run House (ownership and teardown clean; the
    spool's moments die with the run) or under the top/Story House like A:Cyto today
     (spool survives runs; needs the era-guarded recommission to be the whole story)?
5. **The Sunpit's visibility.**  Proposed c-side (`w.c.sunpit`, never snapped, Books
    glass-blind).  The board's own small glass (spec §9) might one day want it
     attached-and-pruned instead.
6. **The slope write-back.**  Does v1's `%IO,mags` slope stay display-only, or does
    `Radio_lineup_fill` learn to read the written weight in the same cut?
