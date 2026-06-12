# Note — Workup is theory; autopush is the everyday truth

## Decision: autopush on by default

`workon.sc.auto_push` defaults to 1 (Lang `req:plan`).  `Opt nopush` turns it
off, which the LE op-suite test sets so it can watch `%State%changey` and the
explicit `op:push` without the flush hiding the divergence.

The everyday mode this enables: swing around the code, run a `Waft`, inject
Points into it, pile short-term bookmark trails — and the change lands on the
Waft as it happens.  The OC *is* the working set.  Resetting is `git checkout`
on the real file.  Most Waft are throwaway; the occasional one carries a
keep-beyond-this-session mark and gets reviewed.

With autopush on, `LE_arm` discarding the working clone tree on a retarget is
harmless — the tree was already flushed.  Touring sheds nothing because there
was never any unflushed work to shed.

## Workup (LiesWorkup.svelte) is shelved as theory

LiesWorkup answers "I toured away from changey work and don't want to lose it":
park the clone tree at its Dip, resume on return, present the pool as a leg
above the floor, soft-commit with revert|merge.  **Autopush deletes the
problem it solves.**  There is nothing to park when every changey edit is
already on the Waft.

So Workup is not wrong — it is a premature crystallization of the soft-commit
UX *before* the substrate it should sit on exists.  The genuinely forward
pieces are deeper than Workup and want designing fresh, not salvaging:

- **Multi-checkout over one shared D sphere.**  Climb around a locale doing
  stuff, resuming `Seem:working` against the *same* D**, just different subsets
  of it.  The bones already exist: give the Selection the locale's top as
  `topD` once, then every checkout (descend, come back up, descend a sibling)
  is the same Selection re-walking subsets of the same durable D sphere —
  visited D nodes resume with their Dips and meanings, only the working subset
  changes.  No re-cloning, no identity loss.  Workup faked this with detached
  parked trees; the real version is just one Selection + one persisted D sphere
  + many working subsets.  Wants designing properly; the substrate is present.
- **Locking sub-extents.**  A Lies job: Lies owns the Waft and its persistence,
  so a lease is a particle on the What (`%lease,client,until`) that Lies
  arbitrates and syncs.  Clients take a lease on the Whats they want to commit
  to; mediation is precise because it is code.  Too complicated for now, doable
  for a big team.
- **`LE_push` over all changed checkouts.**  Push every Seem that diverged,
  not just the armed one.  Presupposes the multi-checkout substrate.
- **Two Point sources, navigating in unison.**  *Does not* need the hard
  substrate — two independent single-Seem LEs, each its own NaviCado, sharing a
  cursor.  Follow `Waft:Ghost/Tour` to find your way into things while writing a
  report into `Waft/Time/2026/05/04/1600` as an overlay; the original gets
  overlaid with relative-locator Whats and the user's own Whats, the two
  navigating together.  This one is near, not deep — it just needs a second LE
  + NaviCado and a shared cursor signal.

When that more-complicated world arrives, the soft-commit ceremony comes back —
sitting on multi-checkout, not floating above a single LE.  LiesWorkup is now
**fully out of the system**: both `LE_retarget` call sites in `req:understanding`
are reverted to bare `LE_arm` + `LE_pull`, nothing imports it, it is not mounted.
Keep the file as a design sketch only.

The one piece worth keeping was split out: **`Waft_dip` graduated to
WaftDip.svelte** — the address space is genuinely wanted (it fixed the
`each_key_duplicate` crash) and has no dependency on the park/leg/spool
machinery.  Lies mounts WaftDip and calls `Waft_dip(waft)` after `Waft_link_up`
on load and on every watch_c rebuild.  NaviCado's capsule key reads `c.Dip` with
a `?? spec_N` fallback, so it is correct with or without the dip pass having run.

## The one Workup idea worth keeping near-term: reset-after-push

A reset button that still works *after* change has been autopushed.  The
mechanism is small and does not need the rest of Workup:

- On each autopush, dump the just-pushed origin encode somewhere durable on
  `%LE` — call it `%LE/%pushed` with `snap` (what the OC looked like *before*
  this push) and `snap_after`.
- The `~`-bar reset (or a always-present `↩`) decodes `%pushed.snap` back into
  the working clone tree, marks changey, and lets autopush carry it to the OC —
  i.e. an undo expressed as a forward push of the prior state.
- This relies only on having an encode of the pre-push OC state we can apply to
  C; no park, no leg, no spool.

This is the thin slice of "intervene on the real memory" that earns its place
even in the swing-around-and-throw-out workflow: you autopushed a class change
you didn't mean, one tap puts the file back, git stays clean.

```
// < %LE/%pushed,snap|snap_after — pre/post-push OC encodes, dumped on autopush
// < reset-after-push: decode %pushed.snap → C, changey, let autopush land it
// < this is Workup's revert reduced to its irreducible core; the leg/merge/
//   spool layers wait for multi-checkout
```

## Remaining thread from the op-suite test snaps

The capsule strip is now rename/duplicate-proof (keys on `c.Dip`), but the
**graft bookmark ids still churn** on each Pmirror rebuild — `g_2 → g_3 → g_4
→ g_2` for the focus Point across steps 5–7 as the set is torn down and
reissued.  Cosmetic now (the `from/to` stays at 16), but it is the LangGraft
side of the Dip-keying work: grafts should survive via `resume_X` keyed on the
Point's `c.Dip`, not be reallocated.  Fold this into the LangGraft-Dip TODO;
not a slideshow blocker.

## Interest%in_What|in_Doc as strings — a same-named-sibling bug

Not just a smell — a correctness hole.  The string is the **leaf label only**;
it drops the parent path.  Moving the cursor from `What:uniqueness/What:tests`
to `What:otherness/What:tests` leaves `in_What:'tests'` unchanged, so:

- the understanding sig doesn't drift on the hop → checkout doesn't re-fire →
  the LE stays armed at `uniqueness/tests` while the cursor is at
  `otherness/tests`;
- any `o({ Interest:1, in_What:'tests' })` lookup matches both locations.

The live identity `Interest.sc.src` (the `%What` ref) is unambiguous and fine;
only the flattened string collapses.  `c.Dip` is the fix and it is a
*correctness* fix, not cosmetic: `in_What` → the What's Dip (`w_2_1` vs
`w_3_1`, distinct), and the sig drifts correctly on a same-named-sibling hop.
`in_Doc` stays a path (a Doc is identified by path).  Worth doing once Dip is
threaded; until then, same-named-sibling Whats are a known soft spot.
