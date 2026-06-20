// Funkcion kinds — the registry that keeps the host (Waft) generic.
//
// A %Funkcion embed's mainkey VALUE is its kind (Funkcion:Storying, Funkcion:dirlist,
//  …); the embed rides the snap, the runtime is bound per kind.  Each kind is a
//   self-contained module providing two halves:
//     run       — the behaviour, pumped centrally by Lies (one req:Funkcion per cell).
//     component — the UI, mounted by the generic host (FunkHost) inside the Waft.
//   The host knows only "mount the kind's component"; the kind owns everything else.
//
// Add a kind: write O/Funk/<Kind>.svelte (export a `<kind>_run` + a default component),
//  then add one line here.  Ballistics (the havoc drum-pad, today hardwired in Waft) is
//   the obvious next migration into this shape.

import type { TheC } from "$lib/data/Stuff.svelte"
import Storying, { storying_run } from "$lib/O/Funk/Storying.svelte"

export type FunkKind = {
    run:       (host: TheC, funk: TheC, ww: TheC) => void
    component: any
}

export const FUNK_KINDS: Record<string, FunkKind> = {
    Storying: { run: storying_run, component: Storying },
}
