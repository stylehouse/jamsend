// lifetell — a LIFECYCLE-TRUE mount/destroy tell, landed in the supply_trace ring so
//  `node scripts/tracelog.mjs --watch --life` reads it OFF DISK (no console copying, no
//   browser driver).  Written for the KeepFace remount hunt (Migration_handover §5A,
//    Download_stall_handover "Evening 8"), where every existing probe is a VALUE-comparison
//     detector — it fires on a field flipping — and so is structurally blind to the case
//      that matters: the DOM identity being recreated while every value stays equal.
//       (An ancestor {#each} re-keying, or a block being rebuilt, destroys the whole subtree
//        with `prev === next` at every probe.  All of them stay silent.  This one cannot.)
//
// THE LADDER it exists to read.  Apply it at each nesting level, then watch which level's
//  serial CLIMBS in lockstep with the innermost one.  The OUTERMOST climbing level is the
//   culprit; every level below it is just being carried:
//     world  climbs ⟹ the `{#each vyto_worlds() as w (w)}` block is re-keying
//     stage  climbs ⟹ the `{#if show_viewport(w)}` gate is tearing the stage down
//     faces  climbs ⟹ the faces overlay wrapper is being rebuilt
//     mold   climbs ⟹ the cell {#each} key or the inner {#if cell.face && …} gate
//     ONLY the face component climbs ⟹ the <Face>/<svelte:boundary> instantiation itself
//  And the ones that DON'T climb are the answer to "where is stuff NOT remounting too much" —
//   a silent level is a proven-stable level, which is the half no transition probe can give you.
//
// Volume: marks fire ONLY on real mount/destroy, never per frame.  The ring is capped 300 and
//  the file is OVERWRITTEN each ~5s flush, so a wide sweep (every mold, every face) is fine for
//   a short watch window but is NOT something to leave armed — strip these once the bug is named.
import { onMount, onDestroy } from 'svelte'

// per-`what` creation serials, module-scope so every instance of a level shares one counter —
//  a CLIMBING serial is the proof of a real recreation (the same reasoning as KeepFace's
//   __kf_serial, generalised so any level can carry it).
const serials: Record<string, number> = {}

function push(H: any, ev: string, what: string, id: string, n: number) {
    try {
        const M: any = H?.top_House?.()
        if (!M) return
        const log = M.c.supply_trace || (M.c.supply_trace = [])
        log.push({ t: Date.now(), ev, id: `${what}:${id}`, n })
        if (log.length > 300) log.splice(0, log.length - 300)
    } catch { /* a tell must never be able to break the thing it watches */ }
}

// the ACTION form — `use:lifetell={{ H, what: 'stage', id: '…' }}` on any element.  An action's
//  create/destroy are DOM-true (a param change calls update(), never a teardown), so this reports
//   the element's real lifetime and nothing else.
export function lifetell(node: Element, p: { H: any, what: string, id: string }) {
    let cur = p
    const n = (serials[cur.what] = (serials[cur.what] ?? 0) + 1)
    console.log('◈◈ life mount', cur.what, n, cur.id)
    push(cur.H, 'life-mount', cur.what, cur.id, n)
    return {
        update(q: { H: any, what: string, id: string }) { cur = q },   // param churn is NOT a remount
        destroy() {
            console.log('◈◈ life destroy', cur.what, n, cur.id)
            push(cur.H, 'life-destroy', cur.what, cur.id, n)
        },
    }
}

// the COMPONENT form — call once at the top level of a face's <script>.  Uses onMount/onDestroy
//  (not an $effect, which re-fires cleanup+body on every dep bump and lies about remounts —
//   the 22k-line console.trace lesson).
export function lifewatch(H: any, what: string, id: () => string) {
    const n = (serials[what] = (serials[what] ?? 0) + 1)
    onMount(() => { console.log('◈◈ life mount', what, n, id()); push(H, 'life-mount', what, id(), n) })
    onDestroy(() => { console.log('◈◈ life destroy', what, n, id()); push(H, 'life-destroy', what, id(), n) })
}
