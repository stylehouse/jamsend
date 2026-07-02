// Funkcion kinds — the registry that keeps the host (Waft) generic.
//
// A %Funkcion embed's mainkey VALUE is its kind (Funkcion:Storying, Funkcion:dirlist,
//  …); the embed rides the snap, the runtime is bound per kind.  Each kind is a
//   self-contained module providing up to three halves:
//     run       — the behaviour, pumped centrally by Lies every tick (via the Waft's req:Waftica carrier).
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
// The pump-vs-strike axis IS the Funkcion taxonomy: `run` present = a monitor pumped every
//  tick (CreduFunk, journalling coherence); `run` absent = either an action struck on demand
//   (Ballistics, a drum-pad) or a light driven by an event not a poll (Storying — Lies restamps
//    it when a run_result lands, see Lies_reflect_storying).  Waft_spec §201 names the pumped
//     half but leaves this distinction implicit; here it is just "does the kind declare a run".
//
// Add a kind: write O/Funk/<Kind>.svelte (a default component, + a `<kind>_run` export if
//  it is pumped), then add one line here.

import type { TheC } from "$lib/data/Stuff.svelte"
import Storying from "$lib/O/Funk/Storying.svelte"
import Ballistics from "$lib/O/Funk/Ballistics.svelte"
import StoryTimes, { storytimes_run } from "$lib/O/Funk/StoryTimes.svelte"
import CreduFunk, { credufunk_run } from "$lib/O/Funk/CreduFunk.svelte"
import Shelver, { shelver_run } from "$lib/O/Funk/Shelver.svelte"
import IdHatch from "$lib/O/Funk/IdHatch.svelte"
import Rundar, { runner_run } from "$lib/O/Funk/Rundar.svelte"
import Relay, { relay_run } from "$lib/O/Funk/Relay.svelte"
import Sound from "$lib/O/Funk/Sound.svelte"
import Upkeep from "$lib/O/Funk/Upkeep.svelte"
import DocTing from "$lib/O/Funk/DocTing.svelte"
import DocGhostList from "$lib/O/Funk/DocGhostList.svelte"
import DocWaftMap from "$lib/O/Funk/DocWaftMap.svelte"

export type FunkKind = {
    run?:                (host: TheC, funk: TheC, ww: TheC) => void
    component?:          any   // the inline in-Waft face (FunkHost).  A small cell (Storying, a
                               //  verdict light) OR a Waft's whole BIG body when the embed is its
                               //   main Funkcion (Ting → DocTing, dirlist → DocGhostList) — same slot.
    // hoisted faces, keyed by Lens-KIND (the slot|intensity a Lens carries) — LensHost picks
    //  comp_<lens.Lens> off the Funkcion named by lens.of_Funkcion:
    comp_Panel?:         any   // → the global/fullscreen Lens dock in Otro (ui/Lens.svelte kind="Panel")
    comp_Brink?:         any   // → the Brink dock pinned inside Liesui (ui/Lens.svelte kind="Brink")
    comp_MiniBrink?:     any   // → the collapsed Brink's one-row summary face (connectivity at a glance)
    comp_InterestSmall?: any   // → popped small in the InterestStrip
    comp_InterestBig?:   any   // → popped big in the InterestStrip
}

export const FUNK_KINDS: Record<string, FunkKind> = {
    Storying:   { component: Storying },                       // verdict light — event-driven (Lies_reflect_storying), no pumped run
    Ballistics: { component: Ballistics },                      // action: a struck havoc drum-pad
    StoryTimes: { run: storytimes_run, component: StoryTimes }, // station: a struck run-all sweep, driven by a pumped tick
    CreduFunk:  { run: credufunk_run,  component: CreduFunk },  // container: holds Storying cells + journals their Credulates (coherence)
    Shelver:    { run: shelver_run,    component: Shelver },    // librarian: walks wormhole/Story, auto-files new Books onto its board by prefix
    IdHatch:    { comp_Panel: IdHatch },                        // face-only: the cluster-identity hatch, a global Lens:Panel
    Rundar:     { run: runner_run, comp_Brink: Rundar, comp_MiniBrink: Rundar }, // %Aim runner-RADAR: fleet rack (1:1 %HostedIdentity roster) + single-pair view, Lens:Brink; comp_MiniBrink = the collapsed one-row dots
    Relay:      { run: relay_run,  comp_Brink: Relay,  comp_MiniBrink: Relay },   // %Aim watcher: the relay ping (channel carrier), Lens:Brink; comp_MiniBrink = one carrier dot
    Upkeep:     { comp_Brink: Upkeep },                         // %Upkeep ledger: live %Errands (compiles, sweeps) hoisted as Lens:Brink
    Sound:      { comp_Brink: Sound, comp_MiniBrink: Sound },    // the "tap for sound" audio-gate beg — pops out of the MiniBrink (self-gates; invisible until a gat is blocked)
    Ting:       { component: DocTing },                         // big face: the attention-Ting histogram — a taker Waft's main Funkcion (data in H.ave)
    dirlist:    { component: DocGhostList },                    // big face: the GhostList ghost-index — the GhostList Waft's main Funkcion (run rides funk.c.run, installed off-snap by GhostList_funkcion)
    waftmap:    { comp_Brink: DocWaftMap, comp_MiniBrink: DocWaftMap }, // the Plank: Waft navigator + Doc-relevance Venn; MiniBrink = compact chip glance (collapsed bar), Brink = full navigator (opened stack)
}
