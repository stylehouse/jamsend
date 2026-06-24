// Funkcion kinds — the registry that keeps the host (Waft) generic.
//
// A %Funkcion embed's mainkey VALUE is its kind (Funkcion:Storying, Funkcion:dirlist,
//  …); the embed rides the snap, the runtime is bound per kind.  Each kind is a
//   self-contained module providing up to three halves:
//     run       — the behaviour, pumped centrally by Lies every tick (one req:Funkcion).
//                 OPTIONAL: a kind with no `run` is an ACTION, not a MONITOR — it is never
//                  pumped; it just renders and reacts to a click (e.g. Ballistics).
//     component — the INLINE face, mounted by FunkHost inside the Waft (the in-document cell).
//     comp_<LensKind> — a HOISTED face, one per Lens-KIND.  A Lens is plural by design: its
//                  mainkey VALUE is the kind = the presentation SLOT + INTENSITY a hoisted face
//                   wants.  comp_Panel rides the bottom Lens dock (the accreting stack over
//                    Lies); comp_InterestSmall|comp_InterestBig pop out in the InterestStrip at
//                     two intensities.  LensHost mounts comp_<LensKind> for a particle
//                      Lens:<LensKind>,of_Funkcion:<this kind>.  A face-only kind (no inline
//                       component, no run) is a pure hoisted applet (e.g. IdHatch — comp_Panel only).
//   The host knows only "mount the kind's component / comp_<LensKind>"; the kind owns the rest.
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
import StoryTimes, { storytimes_run } from "$lib/O/Funk/StoryTimes.svelte"
import CreduFunk, { credufunk_run } from "$lib/O/Funk/CreduFunk.svelte"
import IdHatch from "$lib/O/ui/IdHatch.svelte"
import Runner, { runner_run } from "$lib/O/Funk/Runner.svelte"
import Relay, { relay_run } from "$lib/O/Funk/Relay.svelte"
import Upkeep from "$lib/O/Funk/Upkeep.svelte"

export type FunkKind = {
    run?:                (host: TheC, funk: TheC, ww: TheC) => void
    component?:          any   // the inline in-Waft face (FunkHost)
    // hoisted faces, keyed by Lens-KIND (the slot|intensity a Lens carries) — LensHost picks
    //  comp_<lens.Lens> off the Funkcion named by lens.of_Funkcion:
    comp_Panel?:         any   // → the global/fullscreen Lens dock in Otro (ui/Lens.svelte kind="Panel")
    comp_Brink?:         any   // → the Brink dock pinned inside Liesui (ui/Lens.svelte kind="Brink")
    comp_InterestSmall?: any   // → popped small in the InterestStrip
    comp_InterestBig?:   any   // → popped big in the InterestStrip
}

export const FUNK_KINDS: Record<string, FunkKind> = {
    Storying:   { run: storying_run,   component: Storying },   // monitor: a pumped verdict light
    Ballistics: { component: Ballistics },                      // action: a struck havoc drum-pad
    StoryTimes: { run: storytimes_run, component: StoryTimes }, // station: a struck run-all sweep, driven by a pumped tick
    CreduFunk:  { run: credufunk_run,  component: CreduFunk },  // container: holds Storying cells + journals their Credulates (coherence)
    IdHatch:    { comp_Panel: IdHatch },                        // face-only: the cluster-identity hatch, a global Lens:Panel
    Runner:     { run: runner_run, comp_Brink: Runner },        // %Aim watcher: the peer ping (%channel_peer), hoisted as Lens:Brink
    Relay:      { run: relay_run,  comp_Brink: Relay },         // %Aim watcher: the relay ping (channel carrier), hoisted as Lens:Brink
    Upkeep:     { comp_Brink: Upkeep },                         // %Upkeep ledger: live %Errands (compiles, sweeps) hoisted as Lens:Brink
}
