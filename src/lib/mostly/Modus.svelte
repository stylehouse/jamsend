<script lang="ts">
    import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte";
    import type { DirectoryShare } from "$lib/p2p/ftp/Directory.svelte";
    import type { Modus as SomeModus , Modusmem } from "$lib/mostly/Modus.svelte.ts";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import { onDestroy, onMount } from "svelte";
    import Strata from "$lib/data/Strata.svelte";
    import { SoundSystem } from "$lib/p2p/ftp/Audio.svelte";
    import Scrollability from "$lib/p2p/ui/Scrollability.svelte";
    import GatHaving from "$lib/p2p/ui/GatHaving.svelte";
    import { objectify } from "$lib/data/Stuff.svelte";
    import { ThingsIsms,ThingIsms } from "$lib/data/Things.svelte.ts";
    import ActionButtons from "$lib/p2p/ui/ActionButtons.svelte";
    import { PierFeature } from "$lib/p2p/Peerily.svelte";
    import { ShareeModus } from "./Radio.svelte";

    type Sthing = PeeringSharing | PierSharing | DirectoryShare
    let {S,do_start,do_drawing}:{S:Sthing,do_start?:any,do_drawing?:any} = $props()
    do_drawing ||= true // < store this?
    let init_do_drawing = do_drawing

    let M:SomeModus = $state()
    let gat:SoundSystem = $state()
    onMount(async () => {
        if (!S) throw "!S"
        // < better way to instantiate Modus?
        //    above us, doing eg this:
        //     <Modus S={F} M={new SharesModus({F})} />
        //    causes
        //     in constructor / init_stashed_mem() / on gizmo_mem.set()
        //      Svelte error: state_unsafe_mutation Updating state inside a derived or a
        //   but doing construction in modus_init() from here is ok...
        M = S.modus = S.modus_init()
        gat = M.gat = new SoundSystem({M})
        
        // do the first drawing almost immediately, but after M.stashed appears
        do_drawing = null
        M.on_first_have_time = () => {
            console.log(`started|stashed|perm -> main() ${objectify(S)}`)
            if (S.modus != M) debugger

            // start drawing as intended
            do_drawing = init_do_drawing
            // allow it to change over time via stashed
            if (M.stashed?.do_drawing != null) {
                do_drawing = M.stashed.do_drawing
            }
        }

        if (do_start) {
            // if S isn't a Thing, nothing will try to start it
            await S.start()
        }
    })

    onDestroy(() => {
        M.stop()
    })

    let redraw_version = $state(1)
    let lets_redraw = () => {
        let N = M.o()
        // console.log("reacting to M.current.version=="+M.current.version, N)
        redraw_version++
    }
    $effect(() => {
        if (do_drawing != null && M.stashed) {
            M.stashed.do_drawing = do_drawing
        }
    })
    // turns off the Stuffing compute
    let tog_draw = () => do_drawing = !do_drawing
    let drawingness = $derived(do_drawing ? "hide" : "show")


    let strata = $derived(M.a_Strata)
    // get handled by UI:Thing(s)
    let no_actions = S instanceof ThingsIsms
        || S instanceof ThingIsms
    let actions = $derived(no_actions ? null : S.actions)

</script>

{#if M}
<p>
    I am a {M.constructor.name} 
    {#if gat}with a gat. <GatHaving {gat}/>{/if}
    <button onclick={tog_draw}>{drawingness}</button>
    <button onclick={lets_redraw}>redraw</button>
    {#if actions}<ActionButtons {actions} />{/if}
</p>
<Scrollability maxHeight="80vh" class="content-area">
    {#snippet content()}
    {#if do_drawing}
    {#key redraw_version}

        <Stuffing mem={M.imem('current')} stuff={M.current} {M} />

        {#if M.coms} <Stuffing mem={M.imem('coms')} stuff={M.coms} />{/if}

        {#if strata}
            <Strata {M} {strata} mem={M.imem('Strata')} />
        {/if}
        
    {/key}
    {/if}
    {/snippet}
</Scrollability>
{/if}



<style>
</style>