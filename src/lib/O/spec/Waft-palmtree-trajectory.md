# Palmtree trajectory — Point navigation in Lies & beyond

Carry-forward handoff for the post-🌴 work.  `Waft_spec.md` owns the *design*
(the What tree, transport, carry-over) for this and beyond; **this** doc owns
*this* slice of work — getting Points to land, resolve, and navigate cleanly,
on the path toward the spec's What-level transport.

Each chunk below is sized for one fresh convo (resettable to a cheaper model).
File:line anchors are from the upload set at fork time — treat them as "look
near here", not gospel; HMR and edits drift the numbers.

---

## Correcting the stale picture first

The Pmirror/Waft handoffs that came before this are behind the code.  A good
chunk of what they frame as "next" is already built — don't redo it:

- `e_Lies_cursor_next` and `e_Lies_accept_What_Point` are **implemented**, not
  stubs (`%LiesCurse` ~L173, ~L211).  What's missing is marked with `// <`:
  persisting `accepted_entries`, validating specs against the live compile.
- The minimap is mostly there: capsule strip with auto-promote, orb=showing
  toggle, the ×-only-when-dormant friction gate, push / revert /
  `receive_what_point_from_lies`, the `accepted_push_id` watch, and the `→`
  button (`%DocMinimap` ~L613–638).  Region def-lists (the old "Arc 2 method
  list") render at ~L685–700.  `go_to` already does selection + `scrollIntoView`
  (~L502).
- **Class-method defs resolve.**  Old "Arc 1" is effectively closed — the log
  shows `minimap rebuild …Peerily…: regions=11 defs=69` and Pier + emit resolve
  *after* compile.  The compiler emits `%def,$method` for class methods now.

So the load-bearing problems left are **timing, autostart, and noise** — plus
the What-level arc that lives mostly in `Waft_spec`.

---

## Chunk 1 — Quiet the noise (two "not-yet" gates)

Independent, mechanical, low-risk; they make every later chunk legible.

### 1a — Peerily write-on-init

Symptom: `Lies_source_write: …Peerily… (756c)` then `(43507c)` on init, with no
keystroke, triggering an HMR that tears down even `H:Story`.  The handoff claims
this was fixed by gating on `_autosave_last_input_ts > 0`; the gate isn't
holding.

Fix in `e_Lies_source_write` (`%Lies` ~L317).  Add a dige-equality "not-yet":
only proceed past the gate when `dig(text) !== %loaded_doc.sc.base_dige`
(`base_dige` read ~L330, set ~L367).  A freshly-loaded doc has
`base_dige === dig(text)` so it short-circuits **before** touching `rw_queue`.
This also removes the spurious `source_write_check,path:…Peerily…,rw_op:read`
that "shouldn't have needed to happen yet" — same root.

### 1b — Lazy doc loading

Today `Lies_sync_waft_docs` (~L809) reflects *every* `/%Doc` into an
`%open_req`, so Lies eagerly loads all Waft docs serially (~4.3s, step 1; load
loop `%Lies` ~L522).  Plan:

- `Lies_sync_waft_docs` builds the `/%Waft` tree **without** queuing `%open_req`s
  for non-cursor docs (gate the existing `w.oai({open_req:1,…})` ~L809 behind a
  not-yet so the path sits unchanged but dormant).
- `%LiesCurse` queues exactly one `%open_req` for the cursor's target path when
  it isn't already a `/%loaded_doc`.

Net: open is cheap, fewer in-flight reqs racing the HMR teardown.

---

## Chunk 2 — Cursor reality (autostart + the glow regression)

One root: `%LiesCurse`'s active-doc watch / cold-start isn't landing the cursor,
so `/%examining/%What_Points,1` never auto-populates (you click a DocRow to force
it) **and** `%examining.sc.active_path` never gets stamped — which is why
DocRow's `is_examining` glow went dark.

- DocRow derives the glow from `examining.sc.active_path === path`, tracking
  `examining.version` (`%DocRow` ~L66; `class:ls-doc-examining` ~L115; style
  ~L187).  `%examining` *is* threaded down (Liesui → Waft ~L154/L260/L302).  So
  the prop chain is fine; the field just isn't being written.
- In `%LiesCurse` (~L42): the `active_doc` watch wire (~L65–83) and cold-start
  placement (~L99–104) both need `active_doc` present when they run.  Suspect
  the `examining_sig_watch` latch (~L65): if it sets `true` on a tick where
  `active_doc` was still `undefined`, the watch is permanently skipped.  Only
  latch once the watch is actually installed.

End state: open a doc that lives in a loaded Waft → cursor lands,
`active_path` stamps, glow shows, no manual DocRow click.  Prerequisite for
Chunk 3 to be observable.

---

## Chunk 3 — Resolution timing  *(load-bearing — if pressured, do only this after 1–2)*

The real "Arc 1" now: `Lang_graft_points` runs and resolves before
`docC/%Compile/%methods` exists, so `%Pmirror`s land unresolved and only fix up
on the next recompile (the "change the document and they land" behaviour you
saw in the LakeSurfer step:2 diff).

Use the `%ttlilt` machinery already built — this is exactly the savepoint-timing
tech the new reqy suite exercises (`MachReqy`).  Anchors:

- graft entry `Lang_graft_points` (`%LangGraft` ~L95); compile read ~L139–143;
  unresolved diagnostic ~L212.
- compile lifecycle: `docC/%Compile/%Pending,1` set in `Lang_compile_step`
  (`%LangCompiling` ~L166–168), cleared on `e:Lies_compile_settled` (~L242–250);
  Lang polls while Pending (`%Lang` ~L371, ~L437); graft called each tick
  (`%Lang` ~L387).
- hold API `i_req_ttlilt` (`%Hovercraft` ~L495); Story consumes via
  `o_Story_req_ttlilt`.

Plan: in `Lang_graft_points`, when there are cursored Points (`points.length`)
but the compile isn't ready — `/%Compile/%Pending,1` set, or `%methods`
absent — arm `i_req_ttlilt` on the active Story Run req for a short beat instead
of letting the tick settle into a snap.  The *first* snap after opening a Waft
doc then already shows resolved grafts: "Points are real on open."

Open design choice (raise at convo start): lean on the existing `%ttlilt` API as
above, **or** go straight to a fuller `%reqy` interlock where the graft is a
`/%req` that depends on the compile req finishing.  The ttlilt route is cheaper
and lands the win; the reqy route is more of Chunk 4's migration brought
forward.  Default to ttlilt unless you're already mid-migration.

---

## Chunk 4 — First `requesty_serial → reqy` migration: the push|pull

You called it: "tidier req around the push|pull is probably required."  The
autosave read-then-conditional-write in `e_Lies_source_write` is the cleanest
first candidate — a two-step interlock (`source_write_check` read → compare dige
→ maybe `source_write`) that `%reqy` models natively as `/%req` with a
dependency.

- `reqy()` host + spec (`%Hovercraft` ~L191, ~L136); `requesty_serial` it forks
  from ~L19.
- Migrating this (a) sets the retire-`requesty_serial` pattern, and (b) lets the
  dependency graph **skip the pull** when `base_dige` is absent (new/empty
  docs) — the other half of the spurious-read complaint, so if Chunk 1a is
  thorough this becomes pure tidiness + pattern rather than a bugfix.

Keep `requesty_serial` everywhere else for now.  Toe in the water.

---

## Chunk 5 — Carry-forward persistence (unblocks the big arc)

Land the two `// <` markers in `e_Lies_accept_What_Point` (`%LiesCurse` ~L209):
store `accepted_entries` on the `/%Doc` particle inside the Waft so a
`/%What_Points` survives Waft saves and is available to seed `+time`.  Small, but
it's the data dependency for Chunk 6 (the carry-over heuristic reads it).

Optional if time:
- minimap nail (`⬆ → Lies_export_point`) — the handler exists (`%Lies` ~L702),
  the capsule just has no nail button yet (`%DocMinimap` ~L621–633).
- surface `/%loaded_doc/%surprise_read` in Liesui with a diff + "push anyway"
  (logged but not surfaced; `%Lies` ~L344–349).
- tighten fuzzy resolution (`Lang_resolve_spec` `%LangGraft` ~L261) now that
  class methods are real defs — word-boundary / camelCase-token rather than raw
  substring, or drop fuzzy and require exact.

---

## Chunk 6 — What-level transport (the destination; its own sub-project)

Lives mostly in `Waft_spec.md` ~L161–228.  The `◀◀ rwnd  ‖ pause  ＋time` bar,
ghosting at 18% with the 10s rescue timer, the carry-over heuristic (engaged
Points copy forward; sub-30s `created_at` Points move forward; the rest ghost),
and promoting `cursor_next` from stepping `/%Doc`s to stepping sibling
time-slice `/%What`s.  This is the "A,B / A,C / A,D by promoting A back to the
in-group" story.  Multi-reset on its own; only start once 1–5 leave the base
calm.

---

## Sequencing

- 1 and 2 are independent and cheap — either order.
- 3 wants 2 (you need an auto-landed cursor for the timing fix to be visible).
- 4 overlaps 1a's spurious-read fix; do 1a thoroughly and 4 shrinks to a
  migration-pattern job.
- 5 gates 6.
- If a single convo has to carry the most value: **2 then 3** is "open a Waft
  doc, Points resolve and show, no clicks" — the moment Points become real.

---

## Style notes (carry forward)

- Keep comments that stay true on rewrite; drop dev-mumbling (no "always returns
  an array — no sentinel needed" once the sentinel's gone).
- `// < …` marks a *lack* of development — known shortcomings / deferred work.
- C objects: `%like,this` when naming one alone, `/%like,this/written:is` for
  structures.  `$values` for sc scalars, `$C` for TheC refs in sc.
- `oai` is sync; `roai` is async.  `roai` from a sync context returns a Promise
  and silently breaks the assignment — verify call-site async-ness when touching
  particle-creation code.
