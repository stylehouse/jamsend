<script lang="ts">
    import { onMount, untrack } from "svelte";
    import { grop, throttle } from "$lib/Y";
    import { keyser, objectify, TheC, type TheN } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import Scrollability from "$lib/p2p/ui/Scrollability.svelte";
    import type { Modusmem } from "./Modus.svelte.ts";
    import Modus from "./Modus.svelte";
    import ActionButtons from "$lib/p2p/ui/ActionButtons.svelte";
    import type { ThingAction } from "$lib/data/Things.svelte.ts";
    
    let {M,mem,w,heist}:{M:Modus,mem:Modusmem,heist:TheC} = $props()
    // we give one C to Stuffing
    //  it usually takes many
    //  so we have an extra container layer here
    let req = $derived(heist.o()[0])

    let pls // the req/%places
    // and its /* split into:
    let collections:TheN = $state()
    let places:TheN = $state()

    let share_act:ThingAction = $state()

    let blob_monitoring:TheC = $state()

    $effect(() => {
        if (req?.version) {
            setTimeout(() => {
                // nab form
                pls = req.o({places:1})[0]
                let ok = pls && !pls.sc.finished
                places = ok && pls.o({place:1}) || null
                collections = places && grop(pl => pl.sc.collection, places)

                // needs to open a share
                share_act = req.o1({action:1,needs:"a share"})[0]

                // progress heist
                // < kBps styling nice
                blob_monitoring = req.o({blob_monitoring:1})[0]
            },1)
        }
    })
    function nab_places(pl,pls) {
        // < elvis -> makes sense of all those checkboxes
        M.i_elvis(w, "nab_specifically", { req,pl,pls });

    }
    function togglific(pl,k,e) {
        let is = e.target.checked
        // console.log(`togglific ${keyser(pl)} -> ${is}`)
        pl.sc[k] = is
    }
</script>


{#snippet bigslash()}
    <span class="slash">/</span>
{/snippet}
{#snippet toggler(pl,k,checked=false,given_id='')}
    {@const id = given_id || `tog-${pl.sc.uri}-${k}`}
    <input type="checkbox"
        onchange={(e) => togglific(pl,k,e)}
        {id} {checked} /> 
{/snippet}
{#snippet collection(pl)}
    <span class="collection">
        {@render toggler(pl,'use_collection',true)}
        <label for={`tog-${pl.sc.uri}-use_collection`}>
            {pl.sc.real_name ?? pl.sc.bit}
        </label>
    </span>
{/snippet}
{#snippet item(pl)}
    <span class="inrow ">
        <b>{pl.sc.bit}</b>
    </span>
{/snippet}


<Scrollability maxHeight="60vh" class="content-area">
    {#snippet content()}
        <div>
        {#if blob_monitoring}
            {@const {progress_tally,bit,progress_pct,avg_kBps} = blob_monitoring.sc}
            <span class="arow">
                <span class="metric">{progress_tally}</span>
                <!-- <b>{bit}</b> -->
                <span class="metric">{progress_pct}%</span>
                <!-- <span class="metric">{avg_kBps}kB/s</span> -->
            </span>
        {/if}
        
        {#if share_act}
            <span class="collections inrow" title="
            Access to (some part of) your filesystem is required.
            ">
                Your shares are not opened so we can't download it anywhere.
                <span class="arow">
                    Can you please
                    <ActionButtons actions={[share_act]} />
                </span>
            </span>
        {/if}

        {#if places}
            {#if collections?.length}
                <span class="collections inrow" title="
                a collection is meta-biographical directory
                 eg a directory for a genre
                they will have a dash prepended to sort topward etc.
                ">
                    <span class="arow">
                        {#each collections as pl (pl.sc.uri)}
                            {#if pl.sc.collection}
                                {@render collection(pl)}
                            {/if}
                            {#if pl != collections.slice(-1)[0]}
                                {@render bigslash()}
                            {/if}
                        {/each}
                    </span>
                    <span class="arow">
                        {@render toggler(pls,'disbelieve_categories',false,'disbelieve')}
                        <label for='disbelieve'>disbelieve categories</label>
                    </span>
                </span>
                {@render bigslash()}
            {/if}

            <span class="bitsies inrow">
                {#each places as pl (pl.sc.uri)}
                    <span class="bitsie inrow beigebox">
                        
                        {@render item(pl)}

                        {#if pl.sc.heistable}
                            <button onclick={() => nab_places(pl)}>nab</button>
                        {/if}
                        {#if pl.sc.directory}
                            <span class="arow">
                                {@render toggler(pl,'disbelieve_directory',false)}
                                <label for={`tog-${pl.sc.uri}-disbelieve_directory`}>
                                    disbelieve directory
                                </label>
                            </span>
                        {/if}
                        {#if pl.sc.many}
                            <!-- directories have many items inside, you nab them all -->
                            <span class="arow" style="margin-left:0.5em;">
                                <details>
                                    <summary> 
                                        <span class="metric">
                                            x{pl.sc.many}
                                        </span>
                                         items: </summary>
                                    {#each pl.o({place:1}).slice(0,300) as ipl (ipl.sc.uri)}
                                        <span class="arow">
                                            {@render item(ipl)}
                                        </span>
                                    {/each}
                                </details>
                            </span>
                        {/if}
                        {#if pl.sc.blob}
                            <!-- the one single file -->
                            <span class="arow">
                                {@render toggler(pl,'disbelieve_directories',false)}
                                <label for={`tog-${pl.sc.uri}-disbelieve_directories`}>
                                    disbelieve directories altogether
                                </label>
                                , collect random tracks in one place
                            </span>
                            {#if pl.sc.suggested_rename}
                                <span class="arow">
                                    {@render toggler(pl,'lets_rename',false)}
                                    <label for={`tog-${pl.sc.uri}-lets_rename`}>
                                        rename to: <b>{pl.sc.suggested_rename}</b>
                                    </label>
                                </span>
                            {/if}
                            <span class="arow">
                                {@render toggler(pl,'only_categories',false)}
                                <label for={`tog-${pl.sc.uri}-only_categories`}>
                                    place in those categories but not directories
                                </label>
                            </span>
                        {/if}
                    </span>
                    {#if pl != places.slice(-1)[0]}
                        {@render bigslash()}
                    {/if}
                {/each}
            </span>
        {/if}


        <Stuffing mem={mem.further("heist")} stuff={heist} {M} />
        </div>
    {/snippet}
</Scrollability>

<style>
    input {
        font-size:3em;
        transform:scale(2.2);
        filter:invert(1);
        transform-origin:right;
        margin:0.2em;
    }
    .metric {
        color: rgb(156, 140, 217);
        font-size: 1.4em;
    }
    button {
        padding:0.3em;
        transform:scale(2.2);
        transform-origin:left;
        
    }
    .slash {
        padding: 0.3em;
        font-size:2.3em;
        line-height: 0.4em;
    }
    .arow b {
        font-size:1.3em;
    }
    div {
        padding: 2em;
        font-size:1.5em;
    }
    .collections {
        border: 0.3em solid rgb(35, 141, 160);
    }
    .beigebox {
        border: 0.3em solid rgb(99, 97, 27);
        margin:0.2em;
    }
    .inrow {
        border-radius:1em;
        display:inline-block;
        padding:0.2em;
    }
    .arow {
        display:block;
    }
</style>