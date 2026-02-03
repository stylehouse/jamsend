<script lang="ts">
    import { onMount } from "svelte";
    import { fade } from "svelte/transition";
    import FaceSucker from "./p2p/ui/FaceSucker.svelte";
    import { grop } from "./Y";
    import ActionButtons from "./p2p/ui/ActionButtons.svelte";
    import type { TrustingModus } from "./Trust.svelte";
    import ShareButton from "./p2p/ui/ShareButton.svelte";

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
        || P.needs_share_open_action && "need share"
)
    let unready = $derived(any_problems && never_ready)
    // ready means we can unfullscreen,
    //  and reveal a fullscreen UI:Cytoscape
    let can_fullscreen = $derived(unready && !quit_fullscreen)

    let a_while_passes = $state(false)

    onMount(() => {
        // remove corporate logo asap, but dont make a flicker
        setTimeout(() => {
            M.F.P.fade_splash = true
        },234)
        // reveal problems talk after a while
        setTimeout(() => {
            a_while_passes = true
        },6234)
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
    let share_act = $derived(P.needs_share_open_action)
    // gets set only once so they can dismiss it and continue
    let no_share = () => {
        P.needs_share_open_action = false
        // Introducing along:
        M.i_elvis(M.w,'noop')
    }
    // < cyto in here... can we make friends in common?
</script>




{#if !pseudofading}
<div transition:fade={{duration:3500}}>
    <div>
<FaceSucker altitude={33} {fullscreen} >
    {#snippet content()}
        <div class='uiing bottom'>
            <div class='controls'>
                <span class='rigid'>
                    {#if !P.dodgy_user}
                        <button onclick={() => toggle_fullscreen()} class='small'>etc</button>
                    {/if}
                </span>



                <div class="content">
                    {#if P.Welcome}Welcome.
                    {:else}Left cave: {quit_fullscreen}.{/if}
                    {#if M.amTyrant}amTyrant.{/if}
                    {#if P.some_feature_is_ready}Ready.
                    {:else if P.some_feature_is_nearly_ready}Nearly ready.{/if}
                    <ul>
                        {#each M.msgs as C (C.sc.msgs_id)}
                            <li class={classify(C)}>{C.sc.say}</li>
                        {/each}
                    </ul>

                    <span class='ohno'>
                        {#if a_while_passes}{any_problems}{/if}
                    </span>
                    
                    {#if share_act}
                        <span class="collections inrow" title="
                        Access to (some part of) your filesystem is required to share.
                        ">
                            To share them music,
                            <span class="arow" style="font-size:1.8em;">
                                can you please
                                <ActionButtons actions={[share_act]} />
                            </span>
                            . . . . . .<button onclick={() => no_share()}
                                style="margin:2em;"
                                >nah</button>
                        </span>
                    {/if}
                    
                    {#if M.F.P.Nobody_Is_Online}
                        <p>
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
                </div>

                <span>
                </span>
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

</style>