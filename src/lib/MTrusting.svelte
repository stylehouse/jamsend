<script lang="ts">
    import { onMount } from "svelte";
    import { fade } from "svelte/transition";
    import FaceSucker from "./p2p/ui/FaceSucker.svelte";
    import { grop } from "./Y";

    let {M} = $props()
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
    let unready = $derived(!P.some_feature_is_ready && never_ready)
    let can_fullscreen = $derived(unready && !quit_fullscreen)
    onMount(() => {
        // remove corporate logo asap, but dont make a flicker
        setTimeout(() => {
            M.F.P.fade_splash = true
        },234)
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
</script>



{#if !pseudofading}
<div transition:fade={{duration:3500}}>
    <div>
<FaceSucker altitude={33} {fullscreen} >
    {#snippet content()}
        <div class='uiing bottom'>
            <div class='controls'>
                <span>
                    <button onclick={() => toggle_fullscreen()} class='small'>etc</button>
                </span>



                <div class="content">
                    Left cave: {quit_fullscreen}.
                    {#if P.Welcome}Welcome.{/if}
                    {#if P.some_feature_is_ready}Ready.
                    {:else if P.some_feature_is_nearly_ready}Nearly ready.{/if}
                    <ul>
                        {#each M.msgs as C (C.sc.msgs_id)}
                            <li class={classify(C)}>{C.sc.say}</li>
                        {/each}
                    </ul>
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
    
    div.controls {
        font-size:1.6em;
    }
    button.big {
        font-size:1.6em;
    }
    button.small {
        font-size:0.75em;
        opacity:0.05;
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