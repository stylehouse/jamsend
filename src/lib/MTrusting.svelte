<script lang="ts">
    import FaceSucker from "./p2p/ui/FaceSucker.svelte";

    let {M} = $props()
    let F = M.F
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
    
    let jamming = $derived(M.want_fullscreen)
    let fullscreen = $derived(jamming && !quit_fullscreen)

    // < cyto in here... can we make friends in common?
</script>




<FaceSucker altitude={33} {fullscreen}>
    {#snippet content()}
        <div class='uiing bottom'>
            <div class='controls'>
                <span>
                    <button onclick={() => toggle_fullscreen()} class='small'>etc</button>
                </span>

                Introducing jamsend. Left cave: {quit_fullscreen}. 


                <div class="content">
                    <ul>
                        {#each M.msgs as C (C.sc.msgs_id)}
                            <li>{C.sc.say}</li>
                        {/each}
                    </ul>
                </div>

                <span>
                    <a href="https://github.com/stylehouse/jamsend">README</a>
                </span>
            </div>
        </div>
    {/snippet}
</FaceSucker>


<style>
    
    button.big {
        font-size:1.6em;
    }
    button.small {
        font-size:0.75em;
        opacity:0.35;
    }
    .uiing {
        width: 100%;
        position:absolute;
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

</style>