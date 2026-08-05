// hold — the UItime BUFFER against Atime's transacting-empty window.
//
// THE DISEASE (root-caused 2026-08-05, the KeepFace/"directories editor snaps shut" hunt).
//  `replace()` (Stuff.svelte.ts:952) is a transaction with NO transactional visibility: it does
//   `Xify(); X_before = X; empty()` and `empty()` (:900) nulls X then re-Xifies — which, with
//    X_before set, calls `bump_version()` (:220, "so observers don't miss a beat").  X is $state().
//     So the container PUBLISHES "I have no children" to Svelte, Svelte renders that, and only THEN
//      does the awaited fn() put the children back.  Observers don't miss a beat — they are
//       guaranteed to catch the empty one.
//  The instance that cost us weeks: `agency_officing` (Hovercraft.svelte:133) runs `A.replace({w:1},
//   …)` for every actor every tick, re-adding the SAME world objects, purely so Stuffing notices sc
//    changes.  Vytui's `{#each vyto_worlds() as w (w)}` therefore got a 0-length list once per tick,
//     which DESTROYS the whole subtree (stage + faces + every KeepFace) and rebuilds it on the next
//      render with the same objects.  Nothing remounted that anyone could see: the component, the
//       world object, the mirror and the springs were all stable — only the block was recreated.
//
// THE CURE, and why it lives in the UI and not in Stuff: replace() is STANDARD and stays standard
//  (the human's call — a real fix would need a light cone around the part of reality being rewritten,
//   so a reader can be told "not yet", and we have no such concept).  So the UI stops spazzing out
//    about it instead: buffer what you took from wherever, hold it a good while, and iterate the
//     BUFFER.  A transacting container looks unchanged; a container that genuinely emptied still
//      drains, just `ms` later than it used to.
//
// WHERE TO REACH FOR IT: anywhere a UI unpacks a C and then unpacks more out of what it got — a
//  keyed {#each} over `o()`/`ob()`, or a structural {#if} whose predicate walks a container.  Those
//   are the two shapes that convert a one-render blink into a DOM teardown, and a teardown into lost
//    focus, lost typing, and "the form closed by itself".  The sibling idiom, for a UI that already
//     has an $effect, is `H.clear(async () => { …read again, assign into $state… })` (Liesui.svelte:52,
//      the +Doc form fix) — same buffering, taken at the Atime/UItime gate rather than on a hold timer.
//       Use that when you have an effect to hang it on; use these when the read happens during render.

const HOLD_MS = 1200   // "a big while" — orders of magnitude past a transaction, well under human patience

// hold_list — returns the last NON-EMPTY list while the source is transiently empty.  An emptiness
//  that persists past `ms` is believed and passed through, so a world/row that really went away
//   still leaves.  `key` buckets independent sources through one holder (per-world gates, say).
export function hold_list<T>(ms: number = HOLD_MS) {
    const held = new Map<any, T[]>()
    const since = new Map<any, number>()
    return function hold(raw: T[], key: any = null): T[] {
        if (raw.length) { held.set(key, raw); since.delete(key); return raw }
        const last = held.get(key)
        if (!last || !last.length) return raw
        const t0 = since.get(key)
        const now = Date.now()
        if (!t0) { since.set(key, now); return last }
        if (now - t0 < ms) return last
        held.set(key, [])       // believed: it really is gone
        since.delete(key)
        return raw
    }
}

// hold_true — the same shape for a boolean gate: once true, a false must PERSIST past `ms` before it
//  is published.  For a structural {#if} whose false tears a subtree down, this is the difference
//   between "the model blinked" and "the model changed".  Never holds a false up — arriving is
//    instant, leaving is deliberate.
export function hold_true(ms: number = HOLD_MS) {
    const held = new Map<any, boolean>()
    const since = new Map<any, number>()
    return function hold(raw: boolean, key: any = null): boolean {
        if (raw) { held.set(key, true); since.delete(key); return true }
        if (!held.get(key)) return false
        const t0 = since.get(key)
        const now = Date.now()
        if (!t0) { since.set(key, now); return true }
        if (now - t0 < ms) return true
        held.set(key, false)
        since.delete(key)
        return false
    }
}
