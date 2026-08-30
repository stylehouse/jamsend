<script lang="ts">
    // Cello.svelte — logic ghost for the Cello renderer (Cyto-style).
    //  Registers Cellui as a UI component via the UIs watched channel so
    //  Otro.svelte mounts it automatically for every House that has one.
    //  See spec/Cello_todo.md for design intent and build recipe.
    import { onMount }  from 'svelte'
    import type { TheC } from '$lib/data/Stuff.svelte'
    import type { House } from '$lib/O/Housing.svelte'
    import Cellui from './Cellui.svelte'

    let { M, H } = $props()

    onMount(async () => {
    await M.eatfunc({

    Cello_plan(w: TheC) {
        if ((w as any).c?.cello_plan_done) return
        const uis = this.oai_enroll(this, { watched: 'UIs' })
        uis.oai({ UI: 'Cello' }, { component: Cellui })
        ;(w as any).c.cello_plan_done = true
    },

    async Cello(A: TheC, w: TheC) {
        if (!(w as any).c?.cello_plan_done) this.Cello_plan(w)
    },

    })
    // DO NOT auto-register UI:'Cello' on H:Mundo (owner 2026-08-30: "Cello is still appearing on
    //  /Otro?E=Editron").  That registration existed (task #43) ONLY so Otro's sprawl — which mounts EVERY
    //   house.UIs.ob({UI:1}) — would show Cello back when there was no other way to reach it.  There is now:
    //    the player reaches Cello through SchemeSwitcher, which imports Cellui DIRECTLY (no UI-registration
    //     lookup), so registering it as a House UI does nothing for the player and everything for the leak —
    //      Otro (the editor at ?E=, a runner at ?B=, an idle grid at ?I=) auto-mounts it in its guts view.
    //       Cello_plan stays DEFINED above as an explicit opt-in (a future w:Cello commission can call it),
    //        but nothing fires it at boot, so a plain editor|runner tab never grows a Cello UI.
    // (BigSoundland's own SchemeSwitcher is separately gated to the player via critique_surface = !?B=.)
    })
</script>
