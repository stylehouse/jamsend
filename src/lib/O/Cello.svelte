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
    // Nothing commissions a w:Cello yet (no Sounditron-style tick), so the deposited Cello_plan would never
    //  run and the UI:Cello particle would never register — Cello stayed INERT (task #43).  Fire it directly
    //   here, now that eatfunc has grafted the methods onto every House: register UI:'Cello' on H:Mundo so
    //    Otro.svelte (which mounts EVERY house.UIs.ob({UI:1})) shows it.  Passing H as the `w` only sets a
    //     plan_done flag on it — harmless.  BigSoundland is untouched: it selects Vyto>Cyto and never looks
    //      for Cello, so the live music page can't accidentally mount it.  Guarded so a missing method or a
    //       pre-graft House can't throw at boot.
    try { (H as any)?.Cello_plan?.(H) } catch (e) {}
    })
</script>
