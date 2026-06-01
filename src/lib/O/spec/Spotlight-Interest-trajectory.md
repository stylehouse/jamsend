# Spotlight ↔ Interest — the cursor modernisation

`Waft_spec.md` owns the decoration design.  `Waft-palmtree-trajectory.md` owns
the reqy slice.  This doc owns the **cursor symmetry**: who holds "what is being
looked at" on each side, where playback lives, how a doc gets furnished, and how
the clone tree finally reaches the screen.

The crux, in two lines:

```
%examining/%Spotlight   src = LE.sc.target        — the original, live in the Waft
%Languinio/%Interest    src = working clone root  — the Understanding of it
```

These are not two views of one thing.  They are the **two ends of the checkout** —
the source and its clone — and they divide the labour: Spotlight (original) owns
navigation and glow; Interest (clone) owns render and edit.  Everything below
follows from that split.

---

## 0. Spec-vs-built drift (reconcile first)

- `LiesEnd_spec.md` "Graft seam" still has Lies owning `%LE` and handing the live
  particle across via `Lang_LE_arm`.  **Gone.**  `Lies_i_Spotlight` fires
  `Lang_workon_update,{src}`; Lang arms its own `/req:workon/{LE:1}` in
  `req:checkout`.  **LE is Lang's**; Lies only ships `%src`.
- `%active_what` and `sc.what_keys` are deleted from `Waft_spec.md` (done).  They
  are deleted here too — see §3d.
- `Seem:working%C` (the clones) is read by the edit paths
  (`e_Lang_LE_edit|add|drop` → `LE_clones`) but **not** by the render path —
  `Lang_graft_points_once` reads `%Spotlight.sc.src` → the live source.  The U
  sphere is write-only.  §3c fixes this; it is the keystone.

---

## 1. Catalogue — the cursor systems as they stand

### `%Spotlight` — the Lies cursor (healthy)

```
w:Lies/%examining/%Spotlight,1
  sc.src              $C → %What | %Doc      ← the live Waft particle
  sc.src_Waft         waft_key               ← redundant; dropped in §3a
  sc.accepted_push_id Date.now() | 1(cold)
  sc.accepted_entries { spec, showing }[]
```

Written only through `Lies_i_Spotlight` — the atomic seam.  Every move funnels
here and ends by firing `Lang_workon_update,{src}` across worlds.  `Waft.svelte`
glows the row whose `%What` is `===` `Spotlight.sc.src`.  This is the model.

### `%Languinio` — Lang's signal particle (a bag of holds → §3b makes it a focus)

```
w:Lang/%Languinio
  c.w                 back-ref
  /%LE                same-object hold → /req:workon/{LE:1}
  /%dock,path         same-object hold → docks/{dock:path}
  /%spinner,stale     present while origin pull drifted
```

Enrolled in ave, parallel to `%examining`, but with no single notion of focus —
consumers reach `o({LE:1})`, `c.dock`, `o({spinner})` separately.

### `%active_what` — deleted (was the identity-crisis particle)

Named for a breadcrumb, used as a `c.completion` handle, while the genuine
"active What" was always `%Spotlight.sc.src`.  Three referents, wrong name.
Gone — its jobs reassigned in §3a/§3d.

### The LE engine — push / pull (Lang-side, sound)

```
/req:workon/{LE:1}                     stable for the Lang instance
  /%State          sc.armed|changey|stale
  // %push_dirty   fault child; §3e moves this onto req:push
  /%Seem:origin    Se:Selection, C:$src    — awareness: re-walk → goners/neus
  /%Seem:working   Se:Selection, C:clones  — the editable clone tree + U sphere
    .../%Demonstrations:working/%Understandable   per-clone meanings (c.U)
```

`LE_arm` → `LE_pull` (origin awareness, first-pull `Seem_clone_C`, working walk,
`%State`) → edits on `LE_clones`/`clone.c.U` → `LE_encode_compare` → `LE_push`.
The U sphere (`unshowing`, `unaccepted`, the coming `class`) lives on `clone.c.U`,
never in `clone.sc`, so enWaft never sees it.

### The graft — LangGraft (the stranded render path)

`Lang_graft_points_once` reads the cursor cross-world, takes
`points = src_C.o({Point:1})` off the **live source**, and `.replace()`s
`dock/%Pmirrors/%Pmirror,$waft,$spec` to mint CM marks.  It never touches the
clones, so `unaccepted` still paints, `unshowing` can't fold, `class` can't reach
CM.

### Doc-open today (the poll we will kill)

```
Lang/maneuvre/req:load_doc            re-fires Lies_roai_Open_req every ttlilt re-entry
  → Lies_roai_Open → req:Open (wread)        loads text from the Lies store
    → elvis Lang_open_dock,{path,text}       crosses to Lang
      → Lang/req:Languish,path               mints the dock (text_loaded/compile phases)
  ← Lang polls w.o({docks}) until the dock appears
```

Fire-and-forget elvises bridged by a ttlilt poll.  §3f replaces the poll with an
RPC.

---

## 2. The faults, named

1. **Stranded U sphere.**  Render reads source, edits write clones.  `unshowing`,
   `class`, and `unaccepted` cannot reach CM.  Blocks all of `Waft_spec`'s
   decoration.
2. **No single focus on Lang.**  `%Languinio` is three loose holds; nothing
   answers "what is Lang attending to."
3. **Doc-open is a poll.**  `req:load_doc` drives a cross-world load by re-firing
   an elvis and polling for the result.

---

## 3. The modernisation

### 3a. The crux — Spotlight (original) ↔ Interest (clone), and `src_Waft` drops

The invariant the seam already maintains, now named and leaned on:

```
%Spotlight.src  ≡  LE.sc.target        the original %What, structurally in the Waft
%Interest.src   ≡  working.sc.C         the clone root, the Understanding of it
```

- **Spotlight = original → navigation + glow.**  `LE_what_depth|parent|prev|next`
  run on `LE.sc.target`; the glow tests `=== Spotlight.src`.  "Where am I in the
  Waft" is an original-tree question.
- **Interest = clone → render + edit.**  Graft reads `Interest.src.o({Point:1})`
  — clones carrying `c.U` (§3c); `LE_clones` editing already writes here.  "What
  does my Understanding say" is a clone question.

The clone never needs internal up-links (nav rides the original), so it stays
detached.  Its waft is reached by a **scalar back-ref stamped at clone time**:

```
// Seem_clone_C — stamp the clone root's Waft once, at birth.
//   The clone is detached from the live tree (no c.up into the real Waft, by
//   design), so it carries a direct scalar ref to its origin's Waft instead.
//   Cross-domain ref = scalar $C in c.*, never another domain's sc.
Seem_clone_C(origin) {
    const src_What = origin.sc.C
    const root = _C({ ...src_What.sc })
    root.c.waft = src_What.c.waft          // ← every clone root knows its Waft
    for (const child of src_What.o({})) root.i({ ...child.sc })
    return root
}
```

So `src_Waft` is gone on both sides: Spotlight reads its own `c.up`/`c.waft`
(stamped by `Waft_link_up`); Interest reads `Interest.src.c.waft` (stamped above).
And the safety net the prompt named — "walk across to the Spotlight side and go
up" — holds as the fallback: LE always knows its target, so
`LE.sc.target.c.waft` recovers the Waft if a clone ever lands unstamped.

### 3b. `%Interest` — Lang's one focus object

`%Languinio` keeps its dock hold and gains a focus object:

```
w:Lang/%Languinio
  /%Interest,1      src   = working clone root        — the Understanding-pointer
                    c.LE  → /req:workon/{LE:1}        — handle for nav (LE.sc.target)
  /%dock,path       same-object hold → docks/{dock:path}   — §3d: replaces ave/%active_dock
```

`%Interest` is the answer to fault 2 — one particle that *is* "what Lang is
attending to": the clone (its `src`) and the LE handle (its `c.LE`).  NaviCado
reads `languinio.ob({Interest:1})[0]` and reaches both the clone and (via `c.LE`)
the original for nav.  The dock hold sits beside it (foreground doc ≠ cursored
What — you can tab docs independently, which is why active-dock can't be derived
from Interest and needs its own hold).

**Lifecycle: drop + recreate per move, driven by LE action.**  `LE_arm` drops the
Seems and re-clones on first pull; `req:checkout` recreates `%Interest` pointing
at the fresh `working.sc.C` once `LE_pull` mints it.  The stale Interest (old
clone) is dropped on re-arm — same drop discipline LE already runs on its Seems.

### 3c. The graft reads clones — wire the U sphere (keystone)

`Lang_graft_points_once` sources Points from the Understanding, not the source:

```
// before — renders the source, blind to the Understanding
const points = src_C.o({ Point: 1 })

// after — renders what Lang understands; U sphere included
const interest = languinio?.o({ Interest: 1 })[0]
const LE       = interest?.c.LE
const clones   = LE ? H.LE_accepted_clones(LE) : undefined   // drops U%unaccepted
const points   = clones ?? src_C.o({ Point: 1 })             // src_C: pre-pull fallback only
//  per clone:  clone.c.U?.sc.unshowing  → skip minting a Pmirror
//              clone.c.U?.sc.class       → stamp on the Pmirror for the CM decoration field
```

This closes four standing `// <`s at once:

- `unaccepted` clones drop from CM for free — same predicate `LE_push` and
  `Seem_toString` use, so screen, push, and encode finally agree on what exists.
- `unshowing` folds a clone out of the Lang UI (`Waft_spec` behaviour, reachable).
- `class` (`focus|caution|dim|ghost`) rides to the Pmirror; presentation meaning
  stays on the clone, the source `%Point` stays clean.

Decoration (applying `unshowing`/`class`) is folded into the graft tail rather
than split into a separate `req:Showing` — minting the Pmirror and stamping its
class are one pass over the same clones, so a second phase buys nothing.  (If a
case later wants to re-decorate without re-grafting, split it then; `// <` until
there's a reason.)

The `src_C` fallback covers only the pre-pull window (`LE_clones` is `[]` between
`LE_arm` and the first `LE_pull`), so a freshly-armed cursor still grafts the raw
source for one tick.  Pmirror identity stays `$waft,$spec`, so resolve()'s
carry-over is unaffected by the source swap.  The graft cache key gains the
working Seem's version so a clone edit re-grafts:

```
const cache_key = `${dock.version}:${job?.version ?? 0}:${what_pts_C?.version ?? 0}:${working?.version ?? 0}|${fingerprint}`
```

### 3d. Dissolve `%active_what` and `ave/%active_dock`

- **`%active_what`** is removed.  Its breadcrumb role is gone (breadcrumb deleted —
  §3g); its transport-handle role moves to `%examining/req:timemachine` (§3a-below).
- **`ave/%active_dock`** is removed.  `%Languinio/%dock` (the same-object hold that
  already exists) becomes the single foreground-doc truth; Langui watches
  `%Languinio` (already enrolled in ave) instead of `ave/%active_dock`.
  `Lang_set_active_dock` re-points `%Languinio/%dock` and keeps the
  `Lies_active_doc_changed` elvis (the cross-world notify stays; only the ave
  storage goes).  `w.c.active_dock_path` stays as a cheap routing string (it's
  free) or reads off `Languinio.o({dock})[0].sc.dock`.

### 3e/3a-below. `req:timemachine` — the transport, on the cursor

`req:completion` is renamed `req:timemachine` (vivid: it steps the What tree
forward/back in time) and hangs off the cursor:

```
w:Lies/%examining
  /%Spotlight,1            the lit target
  /req:timemachine         sc.playing:0|1  — drains play/pause/step elvises; auto-advances

w:Lies/req:desire          the *will* and the Waft lock stay here
  /req:acquire             one-shot Waft lock
  /%Waft,key               c.src → the Waft
  /req:git                 the push home (§3e)
```

Playback now hangs off the thing being played.  NaviCado reads cursor *and*
transport from the one enrolled signal (`%examining`).
`Lies_desire_step_once`'s end-of-play bump retargets from `%active_what` to
`%examining` (the ref is already in scope as `completion`/timemachine).

### 3e. `req:push` — a coherent push machine

`LE_push` stops being a monolith and becomes a cluster under `req:git`, giving
push-state a C** home that encode errors, fault flags, and "push anyway" can hang
off.  **maz bottoms at 1**, so three phases:

```
w:Lies/req:desire/req:git/req:push     one per attempt; a durable, inspectable fact
  maz:3 encode     LE_encode_compare — clean? finish the cluster (nothing to push)
                     // encode_errors children hang here on a malformed clone tree
  maz:2 replace     LE_push's replace-back, skipping U%unaccepted
  maz:1 verify      LE_pull + re-encode; clean → finish;
                     dirty → stamp push/%dirty,1 (the fault), leave unfinished
```

This wires `push_dirty` to a real reqy fault particle (`req:push/%dirty`),
closing the standing `// <`, and makes push **resumable**: "push anyway" after a
reload re-enters the cluster from `maz:1 verify` instead of re-deriving the
push-state from the live ropeways — the resumability the LiesEnd spec keeps
gesturing at.  The two encode snaps already cache on `working.c.encode`; dumping
them onto `req:push` makes a reload resume the exact push-state.

> The existing maneuvre cluster runs `req:encode` at **maz:0**, which the
> maz-bottoms-at-1 rule forbids.  Fold that encode into the graft phase tail
> (graft at maz:1 runs `LE_encode_compare` after minting Pmirrors) so the
> maneuvre needs only `checkout(3) → furnish(2) → graft+encode(1)`.  `// <`
> verify maz:0 is truly disallowed before relying on the fold.

### 3f. `req:Furnishing` — doc-open as an RPC to Languish

Doc-open gets an owner on the showy end and the cross-world poll dies.  The
Furnishing↔Languish link is an **RPC** (`i_elvis_req(...).reply(...)`), not a
fire-and-forget elvis + ttlilt poll:

```
w:Lies/req:desire/req:Furnishing,path       the intent to open one path
  do_fn:
    wread the text (req:Open's job — Lies owns the store)
    i_elvis_req('Lang/Lang', 'Lang_open_dock', { path, text, gen_path })
        .reply(({ ready }) => { if (ready) rq.finish(furnishing) })

w:Lang  e_Lang_open_dock                     drives req:Languish,path (mints the dock)
  on Languish finish:  reply({ path, ready: 1 })   ← the RPC return
```

Lies owns *intent to furnish* and the text; Lang's `req:Languish` owns the
*mechanism* (mint the dock) and **replies** when the dock exists.  Furnishing
finishes on the reply, so "this path is furnished" is a finished, inspectable req
on Lies.  Lang's maneuvre drops `req:load_doc` entirely — its graft phase already
guards on dock-exists, and the RPC makes the dock appear promptly instead of via
poll.

> `i_elvis_req`/`.reply` is the house RPC primitive; it does not appear in the
> SI file set (only `i_elvisto` fire-and-forget, `ttlilt`, `reqonce` are here),
> so this section trusts its described shape.  `// <` confirm the reply channel
> survives the beliefs-mutex round-trip the way `i_elvisto` does.

### 3g. Breadcrumb — removed

The DocMinimap header breadcrumb is gone (tiresome).  No `LE_what_keys`, no
`what_keys` array, no crumb row.  NaviCado keeps only its ↑ ← → derives
(`depth`, `has_prev`, `has_next`) computed locally off `Interest.c.LE` —
single-component, no duplication to dedupe.

---

## 4. Change-set, file by file

```
Lies.svelte
  - one-time setup: drop %active_what.
  - desire: rename req:completion → req:timemachine; hang it under %examining.
  - add req:Furnishing,path under req:desire (RPC to Lang_open_dock).
  - move req:git push handling into the req:push cluster (§3e).
  - Lies_desire_step_once: end-of-play bump on %examining, not %active_what.

LiesCurse.svelte
  - Lies_i_Spotlight: stop writing sc.src_Waft (§3a); seam otherwise unchanged.
    // < optionally stamp examining/req:timemachine.sc.playing=0 on a hand jump
    //   so a manual move pauses the slideshow.

LiesEnd.svelte
  - Seem_clone_C: stamp root.c.waft = src_What.c.waft (§3a).
  - req:push phases call LE_encode_compare / replace-back / LE_pull (§3e);
    LE_push proper becomes the maz:2 body, not a standalone monolith.

Lang.svelte
  - %Languinio: add %Interest,1 (src=clone, c.LE→LE); keep %dock hold.
  - req:checkout: after LE_pull, (re)create %Interest at working.sc.C.
  - maneuvre: drop req:load_doc; phases become checkout(3) → furnish(2) →
    graft+encode(1).  furnish(2) awaits the Furnishing RPC's effect (dock exists).
  - Lang_set_active_dock: re-point %Languinio/%dock; drop ave/%active_dock.
  - e_Lang_open_dock: reply({path,ready}) when Languish finishes (§3f).

LangGraft.svelte
  - Lang_graft_points_once: source points from LE_accepted_clones via Interest.c.LE;
    honour clone.c.U.unshowing (skip) and .class (stamp on Pmirror); fall back to
    src_C only pre-pull; add working.version to graft_cache_key.

NaviCado.svelte
  - read LE via Languinio/%Interest.c.LE; transport via %examining/req:timemachine.
  - collapse $derived.by(void …) to vers && chains.

Langui / DocMinimap / Waft.svelte
  - Langui watches %Languinio for the active dock instead of ave/%active_dock.
  - DocMinimap: remove breadcrumb header; read dock via Languinio/%dock.
```

---

## 5. Sequencing against Chunk 4c

Before 4c, not after.  4c's carry-over heuristic reads
`clone.c.U?.sc.unaccepted` at branch time and stamps `class:'ghost'` on
prior-What Points — both U-sphere reads that only *mean* something once the graft
honours the U sphere (§3c).  Branch/dive writing `class` the screen ignores is
untestable.

```
4b.5  Spotlight↔Interest                 this doc
        3a  crux + src_Waft drop + clone.c.waft
        3b  %Interest focus object
        3c  graft reads clones            ← the unlock
        3d  dissolve %active_what + ave/%active_dock
        3e  req:push cluster
        3f  req:Furnishing RPC
        3g  remove breadcrumb
4c    ↘ / ↓  branch + dive               class:'ghost' now actually renders
```

§3c is the keystone: it turns `unshowing`/`unaccepted`/`class` from write-only
flags into visible behaviour — the precondition for 4c being demonstrable.

---

## 6. Open faults (carried + updated)

```
// < clone.c.waft is one scalar per clone root; nested Whats inside a clone are
//   not separately linked (nav rides the original, so they don't need it).
// < LE_what_* stay identity-based and frail; Travel-based when the tree grows.
// < graft fallback to src_C in the pre-pull window briefly renders
//   unaccepted/unshowing Points until LE_pull wires c.U.  One stale tick.
// < req:timemachine is a reqy particle under %examining (an ave signal).
//   Tolerated (precedent: %Spotlight child + c.w back-ref).
// < i_elvis_req/.reply reply channel surviving the beliefs-mutex round-trip —
//   confirm it behaves like i_elvisto across the Atime gate.
// < verify at maz:0 is disallowed (maz bottoms at 1); confirm before relying on
//   the encode-into-graft-tail fold.
// < req:push/%dirty still needs surfacing in the reqy fault UI.
// < vanish: unaccepted clone goner fires push_dirty on the verify re-pull; §3c
//   makes unaccepted-is-invisible true on screen, the visible companion to the
//   still-pending suppress-the-goner fix (bD/was_disincluded).
// < clicking a Waft Doc ~7x loses the What glow (active_dock ping-pong).  Killing
//   ave/%active_dock removes one of the two ping-ponging signals; re-test.
// < Furnishing is keyed by path; a Waft with two Docs at the same path (unlikely)
//   would collide — fine for now.
```

---

## Style notes (inherited, standing)

- `// < …` marks a lack of development.
- `%like,this` for a lone C object; `/%like,this/written:is` for structures.
- `oai` sync, `roai` async; `i()` always inserts.
- Cross-domain refs are scalar `$C` pointers in `c.*`; no domain writes another
  domain's `sc`.  `%Interest.src`, `%Interest.c.LE`, `clone.c.waft` are
  same-object holds, not copies.
- Read children-dependent derives with `.ob()`; chain on `vers`, not
  `$derived.by(void …)`.
