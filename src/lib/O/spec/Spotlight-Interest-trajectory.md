# Spotlight ↔ Interest — the cursor modernisation

`Waft_spec.md` owns the decoration design.  `Waft-palmtree-trajectory.md` owns
the reqy slice.  This doc owns the **cursor symmetry**: who holds "what is being
looked at" on each side, how a gesture becomes that, where playback lives, how a
doc gets furnished, and how the clone tree finally reaches the screen.

The crux, in two lines:

```
%examining/%Spotlight   src = LE.sc.target        — the original, live in the Waft
%Languinio/%Interest    src = working clone root  — the Understanding of it
```

These are the two **ends of the checkout** — the source and its clone — and they
divide the labour: Spotlight (original) owns navigation and glow; Interest
(clone) owns render and edit.  Everything below follows from that split.

---

## 0. Spec-vs-built drift (reconcile first)

- `LiesEnd_spec.md` "Graft seam" still has Lies owning `%LE` and handing it
  across via `Lang_LE_arm`.  **Gone.**  Lies ships `%src`; Lang arms its own
  `/req:workon/{LE:1}` in `req:checkout`.  **LE is Lang's.**
- `%active_what` and `sc.what_keys` are deleted from `Waft_spec.md` (done).
  Deleted here too — §3d.
- `Seem:working%C` (the clones) is read by the edit paths but **not** by the
  render path — `Lang_graft_points_once` reads the live source.  The U sphere is
  write-only.  §3c fixes this; it is the keystone.

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

Written only through `Lies_i_Spotlight` — the atomic seam, which ends by firing
`Lang_workon_update,{src}` across worlds.  `Waft.svelte` glows the row whose
`%What === Spotlight.sc.src`.  This is the model; §3e changes only *who calls* it
(a resolver, not each click).

### `%Languinio` — Lang's signal particle (a bag of holds → §3b makes it a focus)

```
w:Lang/%Languinio
  c.w
  /%LE                same-object hold → /req:workon/{LE:1}
  /%dock,path         same-object hold → docks/{dock:path}
  /%spinner,stale     present while origin pull drifted
```

### `%active_what` — deleted

Named for a breadcrumb, used as a `c.completion` handle, while the genuine
"active What" was always `%Spotlight.sc.src`.  Gone — §3d.

### The LE engine — push / pull (Lang-side, sound)

```
/req:workon/{LE:1}
  /%State          sc.armed|changey|stale
  // %push_dirty   fault child; §3h moves this onto req:push
  /%Seem:origin    Se:Selection, C:$src     — awareness: re-walk → goners/neus
  /%Seem:working   Se:Selection, C:clones   — the editable clone tree + U sphere
    .../%Demonstrations:working/%Understandable   per-clone meanings (c.U)
```

U sphere (`unshowing`, `unaccepted`, the coming `class`) lives on `clone.c.U`,
never `clone.sc`, so enWaft never sees it.

### Doc-open today (the poll we kill)

```
Lang/maneuvre/req:load_doc         re-fires Lies_roai_Open_req every ttlilt re-entry
  → Lies_roai_Open → req:Open (wread)         loads text from the Lies store
    → i_elvisto('Lang_open_dock')             crosses worlds (fire-and-forget)
      → Lang/req:Languish,path                mints the dock
  ← Lang polls w.o({docks}) until dock appears
```

---

## 2. The faults, named

1. **Stranded U sphere.**  Render reads source, edits write clones.  `unshowing`,
   `class`, `unaccepted` cannot reach CM.  Blocks all `Waft_spec` decoration.
2. **No single focus on Lang.**  `%Languinio` is three loose holds.
3. **Doc-open is a poll.**  Cross-world load by elvis-refire + poll.
4. **The cursor is set by whoever clicks last, in-place.**  No record of the
   gesture, no seam where Lies-intent and Lang-intent could ever negotiate.

---

## 3. The modernisation

### 3a. The crux — Spotlight (original) ↔ Interest (clone); `src_Waft` drops

```
%Spotlight.src  ≡  LE.sc.target        the original %What, structurally in the Waft
%Interest.src   ≡  working.sc.C         the clone root, the Understanding of it
```

- **Spotlight = original → navigation + glow.**  `LE_what_*` on `LE.sc.target`;
  glow tests `=== Spotlight.src`.
- **Interest = clone → render + edit.**  Graft reads `Interest.src.o({Point:1})`
  (clones carry `c.U`, §3c).  `LE_clones` editing already writes here.

The clone is structurally detached (nav rides the original, so no internal
up-links).  Its Waft is carried by a scalar back-ref stamped at clone time:

```typescript
// Seem_clone_C — stamp the clone root's Waft once, at birth.
//   Clone is detached from the live tree by design; carries a direct ref so its
//   waft_key is reachable without borrowing from the original.
Seem_clone_C(origin: TheC): TheC {
    const src_What = origin.sc.C as TheC
    const root = _C({ ...src_What.sc })
    root.c.waft = src_What.c.waft          // same field Waft_link_up stamps
    for (const child of src_What.o({}) as TheC[]) root.i({ ...child.sc })
    return root
}
```

**`src_Waft` drops; one helper replaces both readers.**  `req:acquire` (desire)
and the graft both used `Spotlight.sc.src_Waft` for the waft_key.  Both now call:

```typescript
// waft_key_of — derive a waft_key from any src: %What, %Doc, or clone root.
//   c.waft is stamped by Waft_link_up (originals) and Seem_clone_C (clones);
//   the c.up walk is the fallback for a not-yet-linked node.  Generalises
//   LE_what_waft, which becomes a thin wrapper.
waft_key_of(src: TheC): string | undefined {
    let node: TheC | undefined = src
    while (node) {
        if (node.c.waft) return (node.c.waft as TheC).sc.Waft as string
        if ((node.sc as any).Waft !== undefined) return (node.sc as any).Waft as string
        node = node.c.up as TheC | undefined
    }
    return undefined
}
```

Spotlight reads its own (`waft_key_of(Spotlight.src)` — original, linked by
`Waft_link_up`); the graft reads `waft_key_of(Interest.src)` (clone, stamped at
birth).  Neither stores `src_Waft`.

### 3b. `%Interest` — Lang's one focus object

```
w:Lang/%Languinio
  /%Interest,1      src   = working clone root        — the Understanding-pointer
                    c.LE  → /req:workon/{LE:1}        — handle for nav (LE.sc.target)
  /%dock,path       same-object hold → docks/{dock:path}   — §3d: replaces ave/%active_dock
```

One particle that *is* "what Lang is attending to": the clone (`src`) and the LE
handle (`c.LE`).  NaviCado reads `languinio.ob({Interest:1})[0]` and reaches both
the clone and (via `c.LE`) the original for nav.  The dock hold stays alongside —
foreground doc ≠ cursored What (docs tab independently), so it needs its own hold.

**Lifecycle: drop + recreate per move, driven by LE action.**  `req:checkout`
recreates `%Interest` at the fresh `working.sc.C` once `LE_pull` mints it; the
stale Interest is dropped on re-arm — same discipline LE runs on its Seems.

### 3c. The graft reads clones — wire the U sphere (keystone)

```typescript
// was: render the source, blind to the Understanding
const points = src_C.o({ Point: 1 })

// now: render what Lang understands; U sphere included
const interest = languinio?.ob({ Interest: 1 })[0] as TheC | undefined
const LE       = interest?.c.LE as TheC | undefined
const clones   = LE ? H.LE_accepted_clones(LE) : undefined   // drops U%unaccepted
const points   = clones ?? src_C.o({ Point: 1 })             // src_C: pre-pull fallback only
const waft_key = H.waft_key_of(interest?.src ?? src_C)
//  per clone:  clone.c.U?.sc.unshowing  → skip minting a Pmirror
//              clone.c.U?.sc.class       → stamp on the Pmirror for the CM decoration field
```

Closes four standing `// <`s at once: `unaccepted` clones drop from CM (same
predicate `LE_push`/`Seem_toString` use — screen, push, encode agree on what
exists); `unshowing` folds a clone out; `class` (`focus|caution|dim|ghost`) rides
to the Pmirror, presentation meaning on the clone, source `%Point` clean.

**A U-edit does not bump `working.version`.**  `clone.c.U.sc.unshowing = 1` is a
direct sc mutation under a D node, not a `working.sc.C` child change — so the
graft cache key (which gains `working.version`) will *not* invalidate on a
fold-toggle.  That is by design: re-grafting on a fold-toggle would rebuild
Pmirror identity needlessly.  The fold/glow update path is `req:Showing` (§3g),
which is cache-key-independent.  Graft re-runs only when the *clone set* or
*specs* change.

### 3d. Dissolve `%active_what` and `ave/%active_dock`

- **`%active_what`** removed.  Transport-handle role → `%examining/req:timemachine`
  (§3f).
- **`ave/%active_dock`** removed.  `%Languinio/%dock` (already built) is the single
  foreground-doc truth; Langui watches `%Languinio` (already in ave) instead.
  `Lang_set_active_dock` re-points `%Languinio/%dock`, keeps the
  `Lies_active_doc_changed` elvis (the notify stays; only the ave storage goes).
  `w.c.active_dock_path` stays as a cheap routing string.

### 3e. `req:wants` — gestures become intents, the cursor becomes a resolution

Today every click sets the cursor in-place.  Instead, a gesture becomes a `%want`
particle; the newest resolves to the Spotlight.  Gestures accumulate, so the
cursor stops being "whoever clicked last" and becomes the output of a process
that can later weigh more than one source of intent.

```
w:Lies/req:wants                  the cursor-intent accumulator (open-ended)
  /%want,$ts                      one per gesture; c.src → wanted C; sc.kind: click|drag|step|next|cold
  do_fn: newest %want → Lies_i_Spotlight(src) → (the seam fires Lang_workon_update)
```

Every cursor handler (`e_Lies_set_cursor`, `e_Lies_cursor_next|what`, cold-start,
`e_Lies_active_doc_changed`, the desire step) stops calling `Lies_set_examining`
directly and instead emits `i_elvisto(w, 'Lies_want', { src, kind })`.
`e_Lies_want` appends `%want,$ts`.  `req:wants` is the **single caller** of
`Lies_i_Spotlight` — the seam funnels once, from one place.

```
// < older %want pile up as history — drag-drop reordering, multi-select, undo,
//   and "where was I" can read them later.  Today they are kept, not pruned.
// < the resolver is the one place to weigh a Lies want against what Lang is
//   obsessively working on (a Lang-side want crossing in).  Today: newest wins.
// < a %want carrying sc.kind:'drag' with a drop target is the natural shape for
//   the eventual drag-drop gesture — already expressible, not yet honoured.
```

### 3f. `req:desire` thins to the lock; transport on the cursor

`req:completion` → **`req:timemachine`** (it steps the What tree through time),
and it moves onto the cursor.  `req:desire` empties out to just the Waft lock:

```
w:Lies/%examining
  /%Spotlight,1            the resolved want (§3e)
  /req:timemachine         sc.playing:0|1 — the playback engine + state, ave-visible.
                           do_fn: reads desire/%Waft + Spotlight; drains
                           Lies_desire_play|pause|step; auto-advances Waft_cursor_next
                           (by emitting a %want, kind:'step' — §3e).

w:Lies/req:desire
  /req:acquire, maz:9      the gate.  Holds (re-entry on think — NOT ttlilt) until a
                           Waft is present; the Waft-loaded elvis pokes the think
                           that lets acquire find it.  On acquire: lock /%Waft,key,
                           seed %examining/req:timemachine, finish.
  /%Waft,key               c.src → the locked Waft
```

`maz:9` keeps acquire above everything; the playback engine cannot run before a
Waft is locked, so acquire seeds `req:timemachine` only once acquired.  NaviCado
shows the transport when `%examining/req:timemachine` exists — i.e. once acquired,
matching today's "transport when desire is active".

```
// < desire is now just the Waft lock + the seed.  It could collapse further:
//   acquire moves to w:Lies and the desire wrapper drops.  Left as a wrapper
//   for now so the Waft lock has a visible home in the snap.
```

### 3g. `req:Showing` — re-decorate without re-grafting

A fold-toggle (`unshowing`) or a `class` change does not alter the Pmirror set —
it changes which folds CM shows.  Re-grafting (the `replace()` over Pmirrors)
would be wasted work.  `req:Showing` walks the existing Pmirrors and dispatches CM
fold/decoration effects per each clone's current `c.U`:

```
Lang/maneuvre/req:Showing, maz:0?    NO — maz bottoms at 1.  An OPEN-ENDED tail req:
Lang/dock/req:Showing                open-ended; never finishes.  Re-fires on each think
                                     after graft has minted the Pmirrors.
  each re-entry: for pmirror in dock/%Pmirrors:
      clone = pmirror.c.src_clone (or resolve via spec)
      apply clone.c.U?.sc.unshowing → fold/unfold;  .class → decoration field
```

Downstream of graft (Pmirrors must exist) and downstream of any C-U adjustment:
`LE_drop_clone` and `e_Lang_LE_edit` already call `feebly_ponder()`, which pokes
`w:Lang`; that poke re-enters `req:Showing` directly.  No dirty-flag, no cache
key — `req:Showing` is the cache-key-independent path §3c relies on.

```
// < req:Showing needs each Pmirror to reach its clone's U node.  Stamp
//   pmirror.c.src_clone alongside the existing pmirror.c.src_Point during the
//   graft replace(), so Showing reads c.U without re-resolving by spec.
```

### 3h. `req:push` — a coherent push machine (desire-independent)

`LE_push` becomes a cluster; it lives at `w:Lies/req:git` (the Waftlet home), NOT
under `req:desire` — a push can happen with no playback running.  **maz bottoms
at 1**, three phases:

```
w:Lies/req:git/req:push                 one per attempt; durable, inspectable
  maz:3 encode     LE_encode_compare — clean? finish (nothing to push)
                     // encode error children hang here on a malformed clone tree
  maz:2 replace     replace-back, skipping U%unaccepted
  maz:1 verify      LE_pull + re-encode; clean → finish;
                     dirty → stamp /%dirty,1 (the fault), leave open
```

Wires the old `%push_dirty` to a real fault child (`req:push/%dirty`); makes push
**resumable** ("push anyway" re-enters from `maz:1 verify`; the cached encode
snaps on `working.c.encode` dump onto `req:push` so a reload resumes the
push-state without re-deriving from the live ropeways).

```
// < the existing maneuvre runs req:encode at maz:0, which maz-bottoms-at-1
//   forbids — fold that encode into the graft phase tail so the maneuvre stays
//   checkout(3) → furnish(2) → graft+encode(1).  Confirm the floor before relying.
```

### 3i. `req:Furnishing` — doc-open as an RPC (desire-independent)

Doc-open gets an owner at `w:Lies` top level (not under desire — a cursor can
land on a doc with no playback).  The mechanism is `i_elvis_req`/`o_elvis_req`:
the req particle IS the courier, `req_sent:1` gates double-fire, `finish(reply)`
lands the reply and pings the source house with `reqturn:1` to re-think.

```
w:Lies/req:Furnishing,path              the intent to open one path; seeded by the
                                        wants resolver when the new Spotlight has a doc path
```

Lies do_fn (fires each think):

```typescript
async (furnishing: TheC) => {
    if (!furnishing.sc.text) { /* wread (req:Open child); i_req_ttlilt as a backstop; return */ }
    // req:Furnishing IS the req.  i_elvis_req stamps req_sent:1 on first fire and
    // returns true once finish() landed req.sc.finished.  Re-entry is driven by the
    // reqturn:1 think-ping, not by ttlilt.
    if (H.i_elvis_req(w, 'Lang/Lang', 'Lang_open_dock', { req: furnishing })) {
        rqg.finish(furnishing)   // reply = { path, ready:1 }
    }
},
```

Lang receiver:

```typescript
for (const { req, finish } of H.o_elvis_req(w, 'Lang_open_dock')) {
    const path = req.sc.path as string, text = req.sc.text as string
    // drive req:Languish,path as today — mints the dock from text
    // once Languish finishes:
    finish({ path, ready: 1 })   // → req.finished + req.reply; reqturn:1 pings Lies back
}
```

Lang's maneuvre drops `req:load_doc`.  Its graft phase guards on dock-exists as
today; the dock re-check rides Lang's **own** think when Languish completes (the
`reqturn:1` ping goes to Lies, not Lang).  A `i_req_ttlilt` on the furnish phase
is only a backstop holding the snap open while waiting — it does not itself
re-think; if it expires, the snap proceeds and the phase retries on the next poke.

---

### 3j. Breadcrumb — removed

DocMinimap header breadcrumb gone.  No `LE_what_keys`, no `what_keys`, no crumb
row.  NaviCado computes `depth|has_prev|has_next` locally off `Interest.c.LE`.

---

## 4. Change-set, file by file

```
Lies.svelte
  - one-time setup: drop %active_what.
  - add req:wants (accumulator) + e_Lies_want (append %want); make req:wants the
    sole caller of Lies_i_Spotlight (§3e).
  - desire: req:acquire,maz:9 gate seeds %examining/req:timemachine; desire holds
    only the Waft lock now.
  - timemachine engine (renamed from completion) lives on %examining; auto-advance
    emits a %want kind:'step'.
  - move push to w:Lies/req:git/req:push (§3h); Furnishing to w:Lies (§3i).
  - add waft_key_of helper (§3a); LE_what_waft becomes a wrapper.
  - cursor handlers (set_cursor, cursor_next/what, cold-start, active_doc_changed)
    emit Lies_want instead of calling Lies_set_examining.

LiesCurse.svelte
  - Lies_i_Spotlight: stop writing sc.src_Waft (§3a).
  - the e_Lies_* cursor handlers become want-emitters (§3e).

LiesEnd.svelte
  - Seem_clone_C: stamp root.c.waft (§3a).
  - LE_push becomes the maz:2 body of req:push (§3h).

Lang.svelte
  - %Languinio: add %Interest,1 (src=clone, c.LE→LE); keep %dock hold.
  - req:checkout: recreate %Interest at working.sc.C (§3b).
  - maneuvre: drop req:load_doc; phases checkout(3) → furnish(2) → graft+encode(1);
    furnish(2) guards on dock-exists with a ttlilt backstop.
  - Lang_set_active_dock: re-point %Languinio/%dock; drop ave/%active_dock.
  - e_Lang_open_dock: drain via o_elvis_req; finish({ready}) on Languish finish (§3i).

LangGraft.svelte
  - Lang_graft_points_once: source from LE_accepted_clones via Interest.c.LE;
    waft_key via waft_key_of; honour clone.c.U.unshowing/.class; src_C fallback
    pre-pull; add working.version to graft_cache_key; stamp pmirror.c.src_clone.
  - add req:Showing tail (§3g) walking Pmirrors → fold/decoration effects.

NaviCado.svelte
  - read LE via Languinio/%Interest.c.LE; transport via %examining/req:timemachine.
  - collapse $derived.by(void …) to vers && chains.

Langui / DocMinimap / Waft.svelte
  - Langui: watch %Languinio for active dock.
  - DocMinimap: remove breadcrumb; read dock via %Languinio/%dock.
```

---

## 5. Sequencing against Chunk 4c

Before 4c.  4c's carry-over reads `clone.c.U?.sc.unaccepted` and stamps
`class:'ghost'` — U-sphere reads that only *mean* something once the graft (§3c)
and `req:Showing` (§3g) honour the U sphere.

```
4b.5  Spotlight↔Interest
        3a crux + src_Waft drop + waft_key_of
        3b %Interest                  3c graft reads clones      ← the unlock
        3d dissolve active_what/active_dock
        3e req:wants intake           3f desire thins, timemachine on cursor
        3g req:Showing                3h req:push                3i req:Furnishing RPC
        3j remove breadcrumb
4c    ↘ / ↓ branch + dive            class:'ghost' now renders (via §3c + §3g)
```

§3c + §3g are the keystone pair: clone-sourced graft + a Showing pass turn
`unshowing`/`unaccepted`/`class` from write-only flags into visible behaviour.

---

## 6. Open faults (carried + updated)

```
// < clone.c.waft is one scalar on the clone root; LE.sc.target.c.waft is the
//   fallback for any clone landing unstamped.
// < LE_what_* stay identity-based and frail; Travel-based when the tree grows.
// < graft fallback to src_C in the pre-pull window: one stale tick where
//   unaccepted/unshowing Points still paint.
// < req:wants never prunes; history grows unbounded until a sweep exists.
// < the wants resolver is newest-wins; a Lang-obsession want crossing in has no
//   weighing rule yet.
// < req:timemachine is a reqy particle under %examining (an ave signal);
//   tolerated — precedent: %Spotlight child + c.w back-ref.
// < req:Showing assumes pmirror.c.src_clone is stamped at graft time; wire it.
// < maz:0 in the existing maneuvre (req:encode) is out-of-spec; fold into graft
//   tail and confirm maz bottoms at 1.
// < req:push/%dirty needs surfacing in the reqy fault UI.
// < vanish: unaccepted clone goner fires push_dirty on the verify re-pull; §3c
//   makes unaccepted-invisible true on screen — the visible companion to the
//   pending suppress-the-goner fix (bD/was_disincluded).
// < clicking a Waft Doc ~7x loses the What glow; killing ave/%active_dock removes
//   one of the two ping-ponging signals — re-test after §3d.
```

---

## Style notes (inherited, standing)

- `// < …` marks a lack of development.
- `%like,this` for a lone C object; `/%like,this/written:is` for structures.
- `oai` sync, `roai` async; `i()` always inserts.
- Cross-domain refs are scalar `$C` pointers in `c.*`; no domain writes another
  domain's `sc`.  `%Interest.src`, `%Interest.c.LE`, `clone.c.waft`,
  `pmirror.c.src_clone` are same-object holds.
- `i_elvis_req` carries the req particle itself; `finish(reply)` pings `reqturn:1`.
- `i_req_ttlilt` holds the snap open (defers finalize); it does not poke a think.
- Read children-dependent derives with `.ob()`; chain on `vers`, not
  `$derived.by(void …)`.
