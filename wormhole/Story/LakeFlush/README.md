
# LakeFlush — what each step should do

The story forks LakeNets but swaps the grab-bag of marks for a tight push|pull
sequence, in and out of the Seem:origin extent.  No TimeSpool / step dige block,
so the runner respawns it and records fresh diges on first green run.

Target throughout is `What:peer` under `What:foundations` — it carries
`Doc:Ghost/test/Peeroleum.g` and `Point,method:Peeroleum`.  The flush (encode /
push / pull) runs as soon as the LE is armed on it; it does NOT wait for the CM
dock, since none of encode / replace_back / pull touch the editor or the compile
index.

## Prep 1 — open the Waft
Loads `Waft:Ghost/LakeFlush` from the snap.  Nothing armed yet; LE.sc.target absent.

## Prep 2 — land on foundations/peer
`Lies_test_cursor` resolves the What and fires `e:Lies_want{kind:test}`.  The
wants resolver lands the Spotlight on it, req:understanding checks it out:
- `%LE.sc.target` -> `%What:peer`
- `Seem:origin.C` and `Seem:working.C` both `%What:peer`
- working clones = [`Doc:Ghost/test/Peeroleum.g`, `Point,method:Peeroleum`]
- `%LE/%encode` dirty:"0"; `%State` empty (no changey, no stale)
This is the clean baseline — origin == working.

## Prep 3 — WORKING add (auto-push)
`e:mark op:add {Point:1,method:Harbour}` -> LE_add_clone -> U_serial++.
- encode_key `wv:u_serial` moves -> LE_encode_compare -> changey, !stale
- auto-push fires: LE_push encode(dirty)->replace_back->pull->encode(clean)
- replace_back writes working's clones back as `What:peer` children, so the OC
    `Waft:Ghost/LakeFlush/What:foundations/What:peer` now also holds
    `Point,method:Harbour`
- verify re-encode clears changey -> `%encode` dirty:"0"
- `%State` shows `stale` at this step — the post-push LE_pull walks origin and
    sees the just-written Harbour as a `neu`; this is a false-positive stale from
    our own write.  The encode is clean and the stale coexists harmlessly; it
    clears on the next origin-dirty pass.
    // < post-push pull should suppress stale when encode is clean (own-write case)
Assert: OC `What:peer` gained Harbour; `%encode` dirty:"0".

## Prep 4 — WORKING edit (auto-push)
`e:mark op:edit spec:Peeroleum {class:focus}` -> Object.assign(clone.sc) ->
U_serial++.
- encode dirty -> auto-push -> OC `Point,method:Peeroleum` gains `class:focus`
- `%State` shows `stale,changey` (stale carried from Prep 3, changey from edit)
- settles clean after push
Assert: OC Peeroleum now `Point,method:Peeroleum,class:focus`; `%encode` dirty:"1"
at snap time (push is pending / in-flight at this tick).

## Prep 5 — ORIGIN edit IN scope (auto-pull)
`Lies_test_waft_edit add_point STUNbeam` into `foundations/peer` — the armed
target's own OC.  waft.bump_version() -> watch_c(waft) -> e:Lies_waft_mutated.
- Lang: target is in Ghost/LakeFlush -> LE.c.origin_dirty = 1 -> ponder
- req:understanding origin-dirty branch: LE_pull sees a neu on origin (STUNbeam)
    -> %State.stale -> auto-pull: LE_arm(armed) + LE_pull re-clones working off
    the new origin
- working clones now include STUNbeam; re-encode clean (working == new origin)
- the re-arm+pull drops the stale,changey — `%State` empty after this step
- `class:focus` is gone: the re-clone works off the new origin (Peeroleum,
    Harbour, STUNbeam — no class:focus there), so the un-pushed local edit is
    superseded.  Expected: the !stale gate in auto-push held correctly.
Assert: working clone tree shows STUNbeam; `%encode` dirty:"0"; `%State` empty.
The origin change flushed INTO Lang.

## Prep 6 — ORIGIN edit OUT of scope (pull no-op)
`Lies_test_waft_edit add_point OUTOFSCOPE` into `transport/reliability` — a
different What, same Waft.  watch_c(waft) still fires; e:Lies_waft_mutated still
sets origin_dirty (same Waft key).
- req:understanding: LE_pull walks origin (still `What:peer`), whose children
    did NOT change -> no stale -> no re-arm
- working unchanged; OUTOFSCOPE never appears in Seem:working
Assert: OC `transport/reliability` gained OUTOFSCOPE, but Lang's working tree
does not; `%State` stays clean.  This is the scope boundary working as intended.

## Prep 7 — quiesce
No actions.  All stages finished, no key drifts, nothing changes besides
round/age counters.

## State is the signal; the snaps are just resumability fuel
We keep no separate before/after diff to render — the encode child already holds
snap_origin/snap_working and `%State.changey` is the live truth.  Revert a working
edit and the next encode finds working == origin again: changey clears on its own,
the push stops positing.

## Open
```
// < post-push pull sets stale even on own-write (Prep 3): when the verify
//   re-encode is clean, suppress stale — the neu is ours, not a remote change.
//   Fix: in LE_push, after after.dirty is false, call LE_clear_stale(LE).
```