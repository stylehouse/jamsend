<script lang="ts">
    import { onMount } from "svelte";
    import { fade } from "svelte/transition";
    import FaceSucker from "./p2p/ui/FaceSucker.svelte";
    import { grop } from "./Y";
    import type { TrustingModus } from "./Trust.svelte";
    import ShareButton from "./p2p/ui/ShareButton.svelte";
    import OverPiering from "./p2p/ui/OverPiering.svelte";

    let {M}:{M:TrustingModus} = $props()
    let F = M.F
    let P = F.P
    // < this isn't working here!?
    let uimem = M.imem("UI")
    let inmem = uimem.further('Intro')
    // oh well if we're not recursive we can just use M.stashed
    let s = $derived(M.stashed)
    
    // persists
    let quit_fullscreen = $state(s.quit_fullscreen ?? false)
    let toggle_fullscreen = () => {
        quit_fullscreen = !quit_fullscreen
        s.quit_fullscreen = quit_fullscreen
        inmem.set('quit_fullscreen',quit_fullscreen)
    }
    
    // < go back to fullscreen? it doesn't
    let never_ready = true
    let any_problems = $derived(
        !P.some_feature_is_ready && (
            !P.some_feature_is_nearly_ready ? 'none' : `nothing's`
        )
        || !P.Welcome && "try refreshing" // misleading advice but very helpful
    )

    let unready = $derived(any_problems && never_ready)
    // ready means we can unfullscreen,
    //  and reveal a fullscreen UI:Cytoscape
    let can_fullscreen = $derived(unready && !quit_fullscreen)

    let a_while_passes = $state(false)
    let refresh_talk = $state('')

    onMount(() => {
        // remove corporate logo asap, but dont make a flicker
        setTimeout(() => {
            M.F.P.fade_splash = true
        },234)
        // reveal problems talk after a while
        setTimeout(() => {
            a_while_passes = true
        },6234)
        setTimeout(() => {
            refresh_talk = `reload`
        },14234)
    })
    $effect(() => {
        if (!unready) never_ready = false
        let being = can_fullscreen ? "hidden" : "initial"
        document.body.style.setProperty('overflow',being)
    })
    function classify(C) {
        setTimeout(() => grop(C,M.msgs), 15000)
        return C.sc.mediocre ? 'mediocre'
            : C.sc.good ? 'good'
            : 'other'
    }
    // < this fade to UI:Cytoscape isn't working
    let wasfull = can_fullscreen
    let pseudofading = $state(false)
    let fullscreen = $state(can_fullscreen)
    $effect(() => {
        if (can_fullscreen != wasfull) {
            if (!can_fullscreen) {
                // only fade out
                pseudofading = true
                // bring it back unfullscreened
                setTimeout(() => {
                    pseudofading = false
                    fullscreen = can_fullscreen
                }, 300)
            }
            else {
                fullscreen = can_fullscreen
            }
            wasfull = can_fullscreen
        }
    })

    // < cyto in here... can we make friends in common?

    // take over an uninhabited instance
    //  by escaping fullscreen while !Good
    //  and setting your prepub as instance tyrant
    window.realise = () => toggle_fullscreen()

</script>

{#snippet ice_table()}
    <div class="ice-diagnostics">
        <table>
            {#each Object.entries(P.iceStatus) as [name, status]}
                <tr>
                    <td class="ice-name">{name}</td>
                    <td class="ice-val">{status}</td>
                </tr>
            {/each}
        </table>
    </div>
{/snippet}

{#snippet those_Active()}
    {#if M.F.P.Nobody_Is_Online && M.F.P.Welcome}
        <p class="Nobodyonline">
            Nobody is online
            <span>
                <span style="position:absolute; 
                    pointer-events:none;">🌱</span>
                <span style="font-size:0.5em">
                    <ShareButton {P} />
                </span>
            </span>
        </p>
    {/if}


    {#if M.Active.length}
        <h3>Active <span class="title">{M.mainPeering?.instance?.Id.pretty_pubkey()}</span></h3>
        <div class="valued">
            {#each M.Active as En (En.sc.name)}

                
                <div>
                    Pier: <span class="title">{En.sc.name} </span>
                    <span class="tech">
                        {#each En.sc.Pier.instance.inhibited_features as [to,n] (to)}
                            {to}:{n}
                        {/each}
                    </span>
                </div>

            {/each}
        </div>
    {/if}

    <OverPiering {M} />
{/snippet}


<!-- plateau of mostly introductory language -->

{#snippet nice_conversation()}
    {#if P.Welcome}
        Brilliant...
    {:else}
        Left cave: {quit_fullscreen}.
        {#if P.dodgy_user}
            <span style="font-size: 24px; display: inline-block; transform: scaleY(-1);">🐢</span>
        {/if}
    {/if}
    {#if M.amTyrant}amTyrant.{/if}
    {#if P.some_feature_is_ready}Ready.
    {:else if P.some_feature_is_nearly_ready}Nearly ready.{/if}
    <ul>
        {#each M.msgs as C (C.sc.msgs_id)}
            <li class={classify(C)}>{C.sc.say}</li>
        {/each}
    </ul>

    <span class='ohno'>
        {#if a_while_passes && M.F.P.Welcome}
            {any_problems}  
            <a href="/" onclick={(e) => { e.preventDefault(); location.reload(); }}>
                {refresh_talk}
            </a>
        {/if}
    </span>

{/snippet}


<!-- also, project it on the screen -->

{#if !pseudofading}
    <div transition:fade={{duration:3500}}>
        <div>
    <FaceSucker altitude={33} {fullscreen} >
        {#snippet content()}
            <div class="relief">
                <div class="wall"></div>

                <div class='uiing bottom'>
                    <div class='controls'>
                        <span class='rigid'>
                            {#if !P.dodgy_user}
                                <button onclick={() => toggle_fullscreen()} class='small'>etc</button>
                            {/if}
                        </span>



                        <div class="content">
                            {@render nice_conversation()}
                        </div>

                        <span>
                            {@render ice_table()}
                        </span>
                    </div>
                    <div class='controls'>
                        <div class="content Activos">
                            {@render those_Active()}
                        </div>
                    </div>
                </div>
            </div>
        {/snippet}
    </FaceSucker>
        </div>
    </div>
{/if}

    <!-- {#if M.stashed}
        M.stashed: {JSON.stringify(M.stashed)}
    {/if} -->

    
<style>
    div.relief {
        background:#1a4e2e;
        width:100%;
        height: 100%;
    }
    div.wall {
        background:url('seapiano.webp');
        background-size:cover;
        mix-blend-mode: multiply;
        opacity: 0.2;
        width:100%;
        height: 100%;
        position:absolute;
        pointer-events:none;
    }
    .Activos {
        font-size: 0.4em;
        white-space:pre;
    }
    .Nobodyonline {
        font-size: 1.7em;
    }
    .valued {
        object-fit: cover;
        border-radius: 0.3rem;
        border: 2px solid rgb(51, 90, 134);
    }
    .title {
        font-size: 1.6em;
    }
    .mediocre {
        color: #7e7a47;
    }
    .good {
        color:lightgreen;
    }
    .rigid {
        width:3em;
    }
    
    div.controls {
        font-size:1.6em;
    }
    button.big {
        font-size:1.6em;
    }
    button.small {
        font-size:0.75em;
        opacity:0.02;
    }
    .uiing {
        width: 100%;
        top:0;
        left:0;
        border-radius:3em;
        display: flex;
        flex-direction: column;
        font-family:Arial, Helvetica, sans-serif;
    }
    .bottom {
        top:initial;
        bottom:0;
    }
    .uiing button {
        padding:0.7em;
    }
    .controls {
        display: flex;
        align-items: center;
        width: 100%;
    }

    .controls > span:last-of-type {
        margin-left: auto;
        display: flex;
        align-items: center;
        gap: 0.5em;
    }
    .content { 
        padding:1em;
    }


    .ice-diagnostics {
        opacity: 0.3;
        font-family: monospace;
        font-size: 0.5em;
        margin-right: 1em;
        pointer-events: none;
        user-select: none;
    }
    .ice-diagnostics table {
        border-spacing: 2px;
    }
    .ice-name {
        text-align: right;
        padding-right: 5px;
        text-transform: uppercase;
        letter-spacing: 1px;
    }
    .ice-val {
        font-weight: bold;
    }

</style>