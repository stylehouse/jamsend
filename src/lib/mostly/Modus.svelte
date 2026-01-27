<script lang="ts">
    import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte";
    import type { DirectoryShare } from "$lib/p2p/ftp/Directory.svelte";
    import type { Modus as SomeModus } from "$lib/mostly/Modus.svelte.ts";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import { onDestroy, onMount } from "svelte";
    import Strata from "$lib/data/Strata.svelte";
    import { SoundSystem } from "$lib/p2p/ftp/Audio.svelte";
    import Scrollability from "$lib/p2p/ui/Scrollability.svelte";
    import GatHaving from "$lib/p2p/ui/GatHaving.svelte";
    import { objectify } from "$lib/data/Stuff.svelte";
    import { ThingsIsms,ThingIsms } from "$lib/data/Things.svelte.ts";
    import ActionButtons from "$lib/p2p/ui/ActionButtons.svelte";
    import Agency from "$lib/ghost/Agency.svelte";
    import Thingstashed from "$lib/data/Thingstashed.svelte";

    type Sthing = PeeringSharing | PierSharing | DirectoryShare
    let {S,do_start,do_drawing}:{S:Sthing,do_start?:any,do_drawing?:any} = $props()
    do_drawing ||= true // < store this?
    let init_do_drawing = do_drawing
    // drawing also covers:
    let do_strata = $state()

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
        M = S.modus = S.M = S.modus_init()
        gat = M.gat
        
        // do the first drawing almost immediately, but after M.stashed appears
        do_drawing = null
        M.on_first_main = () => {
            console.log(`M:${objectify(M)} had first main()`)
            if (S.modus != M) debugger

            // start drawing as intended
            do_drawing = init_do_drawing
            // allow it to change over time via stashed
            if (M.stashed.do_drawing != null) {
                do_drawing = M.stashed.do_drawing
            }
            if (M.stashed.do_strata != null) {
                do_strata = M.stashed.do_strata
            }
            do_strata ??= true
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
        // console.log("reacting to M.version=="+M.version, N)
        redraw_version++
    }
    $effect(() => {
        if (do_drawing != null && M.stashed) {
            M.stashed.do_drawing = do_drawing
        }
    })
    $effect(() => {
        if (do_strata != null && M.stashed) {
            M.stashed.do_strata = do_strata
        }
    })
    // turns off the Stuffing compute
    let tog_draw = () => do_drawing = !do_drawing
    let tog_strata = () => do_strata = !do_strata
    let drawingness = $derived(do_drawing ? "hide" : "show")
    let strataness = $derived(do_strata ? "-strata" : "strata")


    let strata = $derived(M.a_Strata)

    // get handled by UI:Thing(s)
    let no_actions = S instanceof ThingsIsms
        || S instanceof ThingIsms
    let actions = $derived(no_actions ? null : S.actions)

    // putting this in $derived() avoids error when M is undefined
    // a frontend!
    let UI_component = $derived(M.UI_component)
    // one that wants M.stashed
    let stashy_UI_component = $derived(M.stashy_UI_component)
    // another way to put a frontend
    let VJ = $derived(M.VJ)

</script>

{#if M}
    <p>
        I am a {M.constructor.name} 
        {#if gat}with a gat. <GatHaving {gat}/>{/if}
        <button onclick={tog_draw}>{drawingness}</button>
        <button onclick={tog_strata}>{strataness}</button>
        <button onclick={lets_redraw}>redraw</button>
        {#if actions}<ActionButtons {actions} />{/if}
    </p>
    {#if VJ}
        <p>
            VJ'd
            <svelte:component this={VJ.sc.UI_component} {VJ} {M} ></svelte:component>
        </p>
    {/if}
    
    <Agency {M} ></Agency>
    {#if UI_component}
        <p>
            UI'd
            <svelte:component this={UI_component} {M} ></svelte:component>
        </p>
    {/if}
    {#if stashy_UI_component && M.stashed}
        <p>
            UI'd
            <svelte:component this={stashy_UI_component} {M} ></svelte:component>
        </p>
    {/if}
<Scrollability maxHeight="80vh" class="content-area">
    {#snippet content()}
    {#if do_drawing}
    {#key redraw_version}

        <Stuffing mem={M.imem('current')} stuff={M} {M} />

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