// Funkcion kinds — the registry that keeps the host (Waft) generic.
//
// A %Funkcion embed's mainkey VALUE is its kind (Funkcion:Storying, Funkcion:dirlist,
//  …); the embed rides the snap, the runtime is bound per kind.  Each kind is a
//   self-contained module providing up to two halves:
//     run       — the behaviour, pumped centrally by Lies every tick (one req:Funkcion).
//                 OPTIONAL: a kind with no `run` is an ACTION, not a MONITOR — it is never
//                  pumped; it just renders and reacts to a click (e.g. Ballistics).
//     component — the UI, mounted by the generic host (FunkHost) inside the Waft.
//   The host knows only "mount the kind's component"; the kind owns everything else.
//
// The pump-vs-strike axis IS the Funkcion taxonomy: `run` present = a monitor (Storying,
//  a verdict light); `run` absent = an action (Ballistics, a drum-pad struck on demand).
//   Waft_spec §201 names the pumped half but leaves this distinction implicit; here it is
//    just "does the kind declare a run".
//
// Add a kind: write O/Funk/<Kind>.svelte (a default component, + a `<kind>_run` export if
//  it is pumped), then add one line here.

import type { TheC } from "$lib/data/Stuff.svelte"
import Storying, { storying_run } from "$lib/O/Funk/Storying.svelte"
import Ballistics from "$lib/O/Funk/Ballistics.svelte"

export type FunkKind = {
    run?:      (host: TheC, funk: TheC, ww: TheC) => void
    component: any
}

export const FUNK_KINDS: Record<string, FunkKind> = {
    Storying:   { run: storying_run, component: Storying },   // monitor: a pumped verdict light
    Ballistics: { component: Ballistics },                    // action: a struck havoc drum-pad
}
