# Repli_design.md — how replication actually works, and the three places it isn't itself yet

Working doc, not a spec — the human hasn't preened it. Written 2026-08-05 out of a session that
 proofed Repli on live runners (RepliUpsert / RepliSplit / RepliShadow, all green, all sabotage-gated).
  The overview is reportage: it describes the code as it stands. The last three sections are design,
   and they are the parts wanting refinement.

---

## 0. What to get on with next

Three gaps, in the order they matter. All three are the SAME gap seen from different sides — Repli
 half-uses the machine's awareness primitive and hand-rolls the other half.

1. **Repli does not use `i_Seem`/`o_Seem`.** It calls `new Selection()` + `se.process({...})` raw
    (`Repli.g:880`). The porcelain the rest of the machine standardised on is `LangHold.svelte:930/980`.
     This is the one to close first — it's a like-for-like conversion with a live gate already sitting
      under it, and everything below gets easier once Repli speaks the same words as Voro / Stemdex /
       Graft.
2. **The Seem it does have is blind below the particle.** It resolves which *records* come and go; it
    has never looked at which *keys* moved. That blindness is the whole reason an identity TABLE
     (`Repli_identity_keys`) exists in a protocol whose claim is that it knows nothing about particles.
3. **The key-level memory is a `.c.*` smear.** `.c.repli_sent_sc` — re-derived every beat, never snaps,
    dies on reload. Exactly the smell `Seemables_todo.md` names as the thing Seems abolish. The human's
     read (2026-08-05): *"any mention of `.c.*` is likely meant to be another attached sphere, hanging
      off the first D that an n finds."* §5 is that idea, unresolved and awaiting the human's naming.

**Open rulings owed** are collected in §6.

**But do §8 first if you only have one sitting.** A snap-reading audit (2026-08-05) found five VERIFIED
 bugs that don't need any ruling to fix — an unbounded, uncullable Pier inbox that scans itself per
  arriving frame (§8.1), MusuReplica's cull silently never running (§8.2), `%Fill`'s two dead keys and a
   source-side counter frozen at zero (§8.3), a Book assertion whose marker no writer stamps any more
    (§8.4), and ~96 fixtures gating behaviour the code can no longer produce (§8.5). The design work
     above is the interesting half; §8 is the half that's actually broken.

---

## 1. The arc

Repli replicates a C** of scalars + buffers from one Pier to another, paginatedly. You COMMUNICATE
 ABOUT a thing (ship its head as an enWaft-shaped line fragment), then DEAL OUT the rest on demand
  (bytes pulled page by page). The full protocol prose lives at the top of `Ghost/N/Repli.g`; this doc
   is about its *shape*, specifically where awareness lives and where it's faked.

The destination: **one-way replication that knows nothing about the particles it carries.** No schema,
 no per-mainkey table, no stamps at mint sites. Identity is *observed*, not *declared*. Today it's
  about 80% observed and 20% declared, and the 20% is load-bearing for exactly five shapes.

---

## 2. What Repli does today — three layers

### 2a. The drive: a real Seem, at Record granularity

`Repli_sent_se` (`Repli.g:880`) is a genuine `Selection`, one per library, held at `library.c.sent_se`:

```
w:Musu
  Library                                   ← the BASIS (n:)
    Record,id:t1,title:Bloom
      Fill,name:audio,have:41,total:120
    Record,id:t2,title:Cinder
  Sent_Tree,pier:B,dontSnap                 ← the D** MIRROR (process_D:)
    Sent,id:t1,name:Bloom,have:41,total:120,got:41
    Sent,id:t2,name:Cinder,have:0,total:96,got:0
```

Each pass re-traces from the library. `resolve()` pairs a `%Sent` with last pass's self **by id** — so
 counts moving is *continuity*, not a new thing (deliberately no `resolve_strict`). The unpaired ends
  are the protocol's entire event vocabulary:

```
neus   → library.c.repli_on_neu     → Repli_offer    (ship its head)
goners → library.c.repli_on_goner   → Repli_retire   (an op:delete line)
```

**Nobody calls "offer this record".** A record appearing in a library IS the offer — the Seem notices,
 and the notice is the send. This is the good part, and it's genuinely Seem-shaped.

One tree per SIDE, each reading its own adjusted reality: the sender's `%Sent` reads `rec.c.sent`
 (what it served); the mirror's counts arrived chunk-particles, falling back to the `%Fill` counter.
  The hooks ride the LIBRARY, not `w` — so the far Pier's mirror runs the same Se hook-free, because
   its records appearing is replication *arriving*, not something to re-offer.

The trees are `%dontSnap`: the D basis re-mints every pass by construction, which is exactly the churn
 a fixture shouldn't gate on. **Note this for §5** — it's the constraint that makes "just snap the
  shadow" not free.

### 2b. The wire: positional recursion, no Seem involved

Encode is a plain depth-first walk stamping a depth number (`Repli_lines_of`, `Repli.g:211`):

```
d0  Record,id:t1,title:Bloom        {"loc":["Record","id"]}
d1    Stream,seq:0,cid:a9           {"loc":["Stream","seq"],"buffer":7}
d1    Stream,seq:1,cid:b3           {"loc":["Stream","seq"],"buffer":8}
d1    Reco,of:t1,note:banger        {"loc":["Reco","of"]}
```

Decode (`Repli_merge`, `Repli.g:273`) rebuilds the parent chain from a **small stack keyed on that
 depth** — pop while `top.d >= line.d`, and the survivor is your parent:

```
stack: [mirrorTop]                  ← d0 arrives: parent = mirrorTop, upsert Record, push
stack: [mirrorTop, Rec]             ← d1 arrives: parent = Rec,       upsert Stream, push
stack: [mirrorTop, Rec, Stream]
                                    ← next d1 pops Stream, parent = Rec again
```

So structure is carried by **indentation**, identity by **`loc`**, and each line resolves independently:

```
pattern = the loc keys        →  parent.o(pattern)[0]
props   = every other key     →  hit:  write ONLY these onto what it found
                                 miss: parent.i({...pattern, ...props})
```

Which is `oai` spelled out over a wire. **A line is a serialized find-or-create.** That framing is the
 most useful thing to hold about this protocol.

Two consequences worth keeping in the front of your head:

- **A resent identical line lands on ITSELF.** With no `loc`, the pattern is every key, so the line
   matches its own prior transmission. Idempotent — strictly better than a true insert under
    at-least-once delivery.
- **ABSENCE IS NOT DELETION.** A hit writes only the keys the line CARRIES. Its other sc keys, its
   children and its siblings are untouched. So a key cleared at the source stays set on the mirror
    forever — the `1`-or-absent boolean idiom cannot be un-set over this wire. `op:delete` removes a
     whole particle; nothing removes one key. (Ruling owed — §6.4.)

### 2c. Identity: a table, plus an experiment

`Repli_identity_keys` (`Repli.g:97`) maps mainkey → which sc keys are the identity. Hand-authored, per
 shape, by whoever wrote the shape. The fallback for an unlisted mainkey is ALL keys, which SPLITS
  rather than merges — fail-closed, matching the receiver's own default. Wide is the safe way to be
   wrong: a too-wide loc mints a churn row you can SEE in a snap; a too-narrow one silently makes two
    different things one.

**The table is only load-bearing for shapes that mutate after mint and re-cross** — about five:
 `%Record` head, `%ask` have/held, `%Reco` note, `%Mag` head, `%Card`. Everything else is covered by
  self-matching resend. That's the measurement that says the table is nearly all dead weight.

`Repli_loc_shadow` (`Repli.g:164`) is the experiment that removes it, built to the human's brief —
 *"I want the Seem that tracks the Repli to notice there's no big deal most of the time, and set op
  and/or loc when things are complicated"*:

```
unchanged since last send  ⇒  pattern on ALL keys        (lands on its own last transmission)
changed                    ⇒  pattern on the keys that HELD STILL
```

Identity is what didn't move. Sound because the sender is the sole writer, so the mirror's copy equals
 the shadow. No table, no stamps, no schema. Proven by the RepliShadow Book, and sabotage-gated: forcing
  `loc` to all-keys reddens `identity-observed` and `shadow-self-matching` by name.

It is gated behind `opts.shadow_loc` and currently only the Book pumps it.

---

## 3. Gap one — Repli doesn't use the standard porcelain

The machine standardised on `i_Seem` / `o_Seem` (`LangHold.svelte:930` / `:980`). Voro, Stemdex and
 LangGraft all speak it. Repli does not — it builds a `Selection` by hand and drives `se.process()`
  directly with an inline options bag.

What the porcelain gives that the raw call doesn't:

```
i_Seem(LE, {Seem:'name', C: subject, ...})   →  LE/Seem:name          ← the Seem is a PARTICLE
                                                  .sc.Se   = Selection   (live object, snap-hostile)
                                                  .sc.opt  = the walk hooks
                                                  .sc.C    = the basis
o_Seem(Seem)                                 →  { goners, neus, topD }
                                                and stamps  Seem/News:name,goners:N,neus:N
                                                and r()'s a fresh topD each pull
```

Three concrete things Repli currently hand-rolls that the porcelain already does:

- **the fresh-topD dance.** `Repli_sent_se` sets `tree.c.T = null` with a four-line comment explaining
   it's dodging `est_D_T`'s D~T throw by forgetting the Travel in place. `o_Seem` handles this by
    `r()`-ing the topD (`Seem.r({Demonstrations: seemName})`).
- **goners/neus collection.** Repli's `resolved_fn` calls hooks inline at depth 0. `o_Seem` returns
   `{goners, neus}` natively, which is what `LangGraft.svelte:493` deliberately reads.
- **the `%News` counts.** Repli has no equivalent — how much moved this pass is currently invisible.

**The conversion is not free** and the reason is worth writing down: Repli's `each_fn` is doing real
 shape-specific work (`T.sc.more = this.Ra_recs(n)` at depth 0 — the shape-agnostic census, so a paged
  `%Mag`/`%Cloud` self-stock serves as a flat shelf does) and its `resolved_fn` fires protocol side
   effects. Both are passable through `i_Seem`'s `opt`, but the `%dontSnap` on the Sent_Tree and the
    `Seem` particle's own snap-hostility (a live `Selection` rides its `.sc`) need thinking about
     together — see §5.

**A cost this recommendation has to price, found in the 2026-08-05 audit (§8).** `i_Seem` writes a
 LIVE `Selection`, a bag of functions, and a C ref straight into `Seem.sc`
  (`LangHold.svelte:933-956`: `Seem.sc.Se ??= new Selection({})`, `Seem.sc.opt = {...fns}`,
   `Seem.sc.C = ...`). That is precisely the CLAUDE.md hazard — *an object|function value in `.sc` is
    fatal at encode* — dodged only because the SNAP encoder mutes it to `{"ref":{...}}`. The toc|storage
     encoder does not (`Repli.g:176-178` spells out the asymmetry). So converting Repli to the porcelain
      **puts a toc-hostile particle into a world Story persists**. Not a blocker, but it means the
       conversion is "move Repli onto the porcelain AND decide where the Seem particle lives so it never
        reaches the storage encoder", which is a bigger job than it first reads. Ruling §6.1 should be
         answered with this in hand.

**Also unresolved:** `i_Seem`'s first arg is named `LE` and its default `trace_sc` is
 `{Demonstrations: opt.Seem}`. Repli's D nodes are `%Sent` under a `%Sent_Tree,pier:` — keyed by PIER,
  because there's one tree per side. Whether the porcelain wants a general "many Seems of the same name,
   discriminated by a key" affordance, or whether Repli should just name them `Seem:'sent@B'`, is a
    design question, not a mechanical one.

---

## 4. Gap two — the Seem is blind below the particle

Stated plainly: **`Repli_sent_se` resolves RECORDS. `loc` is about KEYS.** There is no awareness organ
 at key granularity anywhere in the protocol, which is precisely why the gap got filled by a
  hand-authored table.

```
Sent,id:t1,have:41,total:120     ← the Seem sees THIS  (does the record exist, how far along)
Record,id:t1,title:Bloom,plays:3 ← loc is about THIS   (which of these keys is the identity)
                  ↑
        nothing resolves at this level
```

Everything in §2c — the table, the shadow, the five mutating shapes, the `warn`-on-unknown-mainkey —
 exists to paper over that one missing resolve.

---

## 5. Gap three — the `.c.*` smear, and the sphere idea

The shadow works, but look at where it lives:

```
Record,id:t1,title:Bloom
  .c.repli_sent_sc = { Record:'1', id:'t1', title:'Bloom' }   ← invisible, never snaps, dies on reload
```

`Seemables_todo.md` names the smell exactly: *the smell is **re-derived-each-beat** `.c.*`*. This is
 that, textbook. And it's the source of the one honest weakness already logged in `Mag_todo §0.2e`:
  **`.c` doesn't survive a reload, so a mutation across a restart splits into a visible twin.** (Churn,
   not loss — the fail-closed floor holds — but visible churn.)

### The human's framing (2026-08-05), which is the better one

> *any mention of `.c.*` is likely meant to be another attached sphere, hanging off the first D that an
>  `n` finds... perhaps it's called `K**` or something... or `O**`? we can put anything we want (as well
>   as the basis `%Tree` or whatever it is) in the `D/*` space, including stitching an `O**` onto a `K**`
>    at every point.*

So the move isn't "make the shadow snap." It's that **`D/*` is a space, not a single tree**, and
 per-particle memory belongs to a sphere hanging in it rather than smeared on `.c`. The shadow is then
  not a memo at all — it's a second sphere, stitched to the first D that each `n` finds:

```
Sent_Tree,pier:B
  Sent,id:t1,have:41,total:120          ← sphere 1: the basis D — does it exist / how far along
    <K?>,k:title,was:Bloom              ← sphere 2: per-KEY memory, stitched at this point
    <K?>,k:plays,was:3
  Sent,id:t2,have:0,total:96
    <K?>,k:title,was:Cinder
```

and `loc` stops being computed by a helper reading `.c` — it's **read off a resolved diff**. The
 survivors ARE the pattern. `Repli_identity_keys` shrinks to nothing, and the reload weakness dies with
  the smear, because a sphere in `D/*` is a real C** that can be made to persist.

### What's genuinely open here

- **The name, and whether it's one concept or two.** `K**` and `O**` were both floated. The stitching
   language (*"stitching an `O**` onto a `K**` at every point"*) suggests two distinct kinds — plausibly
    K = the per-point keyed memory, O = something laid over it — but that's the human's to say, and
     this doc should not invent it. **Not guessed at here on purpose.**
- **Snapping vs `%dontSnap`.** The Sent_Tree is `%dontSnap` *because* its basis re-mints every pass.
   A shadow sphere has the opposite requirement — it must survive to be a shadow at all. So either the
    spheres in `D/*` need independent snap policy (likely the real answer, and generally useful), or
     the shadow lives in a different tree that snaps. Either way **it moves fixtures**, which is why
      this is a ruling and not a task.
- **Cost.** Per-key D nodes for every replicated particle is a lot of nodes. Whether the sphere holds
   one node per key or one node per particle carrying a stringified was-map is an efficiency question
    that should be settled before building, not after.
- **Whether this generalises past Repli.** A "what did this look like last beat, per key" sphere is not
   a replication concept. If `D/*` grows it, several other organs likely want it, which argues for
    building it in the Seem porcelain rather than in `Repli.g`.

---

## 6. Rulings owed

1. **Convert Repli to `i_Seem`/`o_Seem`?** (§3.) Recommended yes, and first — it's like-for-like with a
    live gate under it. Needs an answer on the per-pier Seem naming.
2. **The sphere: name and shape.** (§5.) `K**`? `O**`? One kind or two? Nothing gets built until this
    lands.
3. **May a sphere in `D/*` snap while its sibling basis tree is `%dontSnap`?** This is the crux — it's
    what decides whether the shadow can survive reload, and it moves fixtures.
4. **The never-un-sets-a-key invariant** (§2b) — rule it as permanent and document it, or design an
    explicit op (`op:clear`, a key list) to lift it? Nothing needs it today; it will bite eventually.
5. **Retire the shadow's `.c` implementation once the sphere exists**, or keep it as the fast path with
    the sphere as the reload bridge?
6. **Is the identity table deleted or kept as a fallback?** If the shadow is primary, the table's only
    remaining job is the first send after a reload for the five mutating shapes. That's a small enough
     job to argue either way.

---

## 7. What is actually proven, as of 2026-08-05

Not assumed — recorded on live runners, each Book sabotage-gated (neutralise the mechanism, confirm the
 right assertions redden by name), then reverted and re-confirmed green twice.

```
RepliUpsert   7 steps   mint / self-matching resend / hit-writes-only-carried-keys
                        / mirror-local-key-survives / absence-is-not-deletion
                        / op:delete / op:dupe
RepliSplit    5 steps   spine crosses whole / spine locates itself
                        / two %Spins stay two while a re-spun one updates in place
                        / an undeclared mainkey splits VISIBLY
RepliShadow   5 steps   first send needs no identity / identity observed from what held still
                        / unchanged resend lands on itself
                        / shadowless negative control splits into a twin
```

Sabotage result (forcing `loc` to all-keys in both `Repli_loc_for` and `Repli_loc_shadow`):

```
RepliUpsert  ok_pct 0.43   gaps: hit-writes-carried-keys, absence-not-deletion, op-delete
RepliSplit   ok_pct 0.60   gaps: many-to-one-stays-many
RepliShadow  ok_pct 0.40   gaps: identity-observed, shadow-self-matching
```

Registered on Waft:Credence under `What:Repli`.

**Read the RepliShadow step-5 snap with its intent in hand** — it shows a `%widget` standing as TWO
 rows in the mirror (`hue:red` beside `hue:blue`) while the `%gizmo` beside it stands as one. That is
  the deliberate negative control: the gizmo was pumped WITH the shadow, the widget WITHOUT, and the
   split IS the proof that the shadow is what carried the identity. It reads alarming in a snap. If
    that keeps costing a double-take, the control particle should be renamed to say so out loud
     (`%control_widget`, or moved under a `%control` container).

---

## 8. Lateral audit, 2026-08-05 — what a snap-reading sweep turned up

The human read one MusuReplica snap and caught two real bugs by eye ("*that inbox isn't draining!*";
 "*even total=6 is already on Record as nchunks=6*"). That prompted a full sweep. **Everything in §8.1–8.5
  below was verified directly against the code or the fixtures** — quoted evidence, not inference. §8.6
   is the sweep's remaining material at lower confidence.

The meta-lesson worth keeping: **the recorded fixtures are the best bug detector in the repo.** They are
 literal text of program state across time, so accumulation, redundancy and staleness are all directly
  greppable. Diffing an early snap against a late one in the same Book is a five-second check that found
   things a month of green runs did not.

### 8.1 The inbox books a `%req:unemit` per repli_lines/repli_page frame, and nothing bounds it

`Peeroleum_deliver` bypasses the inbox for `repli_want` ONLY (`Peeroleum.g:618`). `repli_lines`,
 `repli_page` and `ive_got` were made ephemeral on SEND but still fall through to
  `Peeroleum_book_unemit` on RECEIVE, each then running `await inbox.do()` AND
   `Peeroleum_rollup_faulty(pier)` — which scans the WHOLE inbox. That is the same O(N²) melt the
    2026-07-29 pass diagnosed and fixed for wants, still live on the response leg.

The asymmetry that shows it's an oversight: the OUTBOX got two bounds in that pass (`ACKED_KEEP = 200`,
 and a `live.length >= 2000` structural backstop). **The inbox got neither.** Its only cull is
  `Peeroleum_runstepped`, reachable only via `Peeroleum_arm_whittle`, which the code says three times is
   **Book-only** (`Peeroleum.g:432`: *"the LIVE station arms NO retx sweep"*). So in production nothing
    culls the inbox at all.

`MusuReco/009.snap` holds 46 `req:unemit` rows from a single step, each carrying a 64-hex `body_hash`. A
 real 100MB library pull is thousands, permanent, per Pier.

**Genuine counter-argument, not dismissed:** the reused-seq collision guard (`Peeroleum.g:642`) *depends*
 on finished unemits staying put, and `Peregrination.g:1096` documents a Book that deliberately doesn't
  whittle for exactly that reason. So "never cull" is defensible. "Never cull AND never cap AND full-scan
   per frame" is not.

### 8.2 MusuReplica alone never drains — and the sweep's `try/catch` is why nobody saw it

`MusuReplica_setup` arms the whittle (`Musuation.g:2647`), yet its inbox grows monotonically
 (`003=3, 006=12, 007=16, 013=17, 014=17`) and `%inbox/recent` **never appears in any step**. Across
  seven Books checked, it is the ONLY one that arms and still fails:

```
MusuPier   unemit=1  recent=4      MusuBay    unemit=0  recent=4
MusuBounce unemit=0  recent=2      MusuBuddy  unemit=0  recent=4
MusuReco   unemit=0  recent=1      MusuDoor   unemit=0  recent=1
MusuReplica unemit=17 recent=0   ← alone
```

MusuReco is the control that matters: same file, same protocol, armed the same way, drains fine.

**Mechanism not yet found** — it needs a live probe, not more reading. But the reason it stayed invisible
 is worth fixing on its own: `Peeroleum_arm_whittle` wraps all three sweeps in
  `try { ... } catch (e) { console.error(...) }` and rearms (`Peeroleum.g:991-995`), so a sweep that
   throws every boundary leaves **no trace in any snap** — only a console line nobody reads during a
    recorded run. A `%sweep_err` stamp on w would have named this in one step. (`Peeroleum_retx_sweep`
     already does exactly that for its own inner throw, `:945` — the pattern exists, it just isn't
      applied to the outer chain.)

### 8.3 `%Fill` — two dead keys, and a source-side counter frozen at zero

`Repli.g:639`:

```js
let sline = { Fill: 1, name: h.stream, total: +(rec.sc.nchunks || chunks.length),
              have: end, page_from: from, page_to: end }
```

`have` and `page_to` are **the same local `end`**, written under two names. A repo-wide grep for
 `page_from|page_to` returns **exactly one hit — this write.** Nothing reads them, ever. They land
  permanently on every mirror `%Fill` and, per §2b, can never be cleared over the wire.

Worse: `Crate_transcode_begin` sets `fill.sc.have = 0` (`Crate.g:340`) and `Crate_transcode_release`
 advances `rec.c.chunks` **without ever touching it**. The only writers of `Fill.have` in the whole repo
  are that `= 0` and the wire line above — which lands only on the MIRROR. So the source's fill counter
   is permanently stale-zero:

```
Record,id:trk0,…,nchunks=240,real,transcoded          ← fully transcoded
  Fill,name:audio,total=240,have=0,sr=48000            ← says nothing has filled
```

And the same number has **three spellings**: `Record.nchunks`, `Fill.total`, and `Record.total` (which
 `Repli_sent_se:925` and `Repli_page_ready:456/462` both branch on by substrate).

This is the evidence for the human's read that `%Fill` says nothing interesting. It doesn't today.
 `Fill.got` vs `Fill.have` IS a real distinction (mirror page count vs chunk frontier, both read) — but
  `total`, `page_from` and `page_to` are dead weight, and source-side `have` is a lie.

### 8.4 `landed:1` is asserted but has no writer — a Book gate that stopped meaning anything

`Musuation.g:2744`:

```js
let stuck = rx ? rx.o({ req: 'awaitbuf' }).some(r => !r.oa({ landed: 1 })) : false
```

**Nothing anywhere writes `landed:1`.** `Repli_attach_page` drops the req instead (`Repli.g:838`), and
 `Repli.g:833`'s comment — *"Only a LANDED awaitbuf drops"* — describes a marker that no longer exists.
  So the assertion has silently degraded to "does any awaitbuf exist", which is correct **by accident**.
   Fix the assertion or restore the marker; don't leave a gate that passes for the wrong reason.

### 8.5 ~96 fixtures gate behaviour the code can no longer produce

`MusuMag`, `MusuRaChase` and `MusuRaStream` — 96 snaps, all mtime 2026-07-27 — record inbox bookings for
 a frame type that `Peeroleum.g:618` now returns before booking:

```
req:unemit,seq=5,type:repli_want,body_hash:8656aa55…,body_len=4,done,to:repli_want,finished
emit=5,type:repli_want,seq=5,sent,…,acked                  ← the outbox half is stale too
```

These three Books **cannot be green against current code.** Note they overlap the Books already known to
 need an FSA-live runner, so the likely story is "couldn't be re-recorded, so they weren't" rather than
  "nobody noticed" — but the effect is the same and it should be stated in the open rather than
   rediscovered.

Separately, the corpus's **only** three `{"undef":[...]}` markers are `PereComplain/002-004.snap:22`:

```
type:no_protocol,sent	{"undef":["emit","seq"]}
```

`Peeroleum.g:407-414` describes this exact malformed row and says it fixed it by making `no_protocol`
 ephemeral. Fixtures are 2026-07-22; the fix is 2026-08-04. **The fixture now gates the bug, not the fix.**
  Per CLAUDE.md an `undef` marker is a mint bug, never furniture — these three are the corpus's only ones
   and they should go.

### 8.6 Lower confidence — worth a look, not yet proven

- **Orphaned `%req:awaitbuf`.** `Repli_recv_page`'s `BUFCAP` drop (`Repli.g:751-757`) discards a stale
   stashed page, but its awaitbuf req and `pier.c.awaiting` entry are only removed on a real landing
    (`:838`) — and the re-ask returns under a FRESH bufferid, so the old one can never resolve.
     `MusuReplica/014.snap` shows one `req:awaitbuf,bufferid / warned:buffer_late` surviving ten steps.
      `Swarm_share_why` (`Swarm.g:1604-1639`) already censuses exactly these three collections as things
       that "silently accrue dead entries without GC" — someone suspected this and built the diagnostic
        without adding the sweep.
- **`bufferid` rides as a NUMBER** (`Repli.g:766, 837`), so `bufferid: 1` trips the `{k:1}` presence
   wildcard. Repli applies the string-it idiom correctly twice with a comment each time (`:195`, `:475`)
    and misses it here. Mostly self-cancelling while `bufseq` is monotone from 1 — but `bufseq` lives on
     `.c` and doesn't survive a reload, while unlanded awaitbufs do.
- **Unpruned `.c` maps keyed by track id:** `w.c.serve_miss_ts` (`:528`) and the HUD's `x.serves`/`pulls`/
   `freed` (`:688`). The neighbouring `x.spark` IS bounded to 32 (`:574`); these aren't.
- **Vestigial:** `req.c.armed` written never read (`:769`); `Repli_register_rx(w, pier)` never uses `w`
   (`:401`); a node carrying BOTH a binary `.sc` value and `.c.page_bytes` would orphan a page
    (`:235-247`) — no shape does today, latent only.

### 8.7 Explicitly ruled INTENTIONAL — do not "fix" these

- `%Sent_Tree`/`%Sent` never snapping — `%dontSnap` with a load-bearing rationale (§2a).
- `tree.c.T = null` instead of an `r()`'d topD — documented `est_D_T` dodge (§3).
- RepliShadow step-5's `%widget` standing as two rows — the deliberate negative control (§7).
- `Fill.got` beside `Fill.have` — different granularities, both genuinely read.
- `{"mung":["age"]}` on `self,round=N` — uniform across every snap of the Books that have it; reads as a
   stable encoder note. **This is the one marker class the sweep could not chase to a writer** — treat as
    unresolved rather than cleared.
