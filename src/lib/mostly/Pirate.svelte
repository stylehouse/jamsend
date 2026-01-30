<script lang="ts">
    import { onMount, untrack } from "svelte";
    import { grop, throttle } from "$lib/Y";
    import { _C, type TheN } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import Scrollability from "$lib/p2p/ui/Scrollability.svelte";
    import type { Modusmem } from "./Modus.svelte.ts";
    import Modus from "./Modus.svelte";
    import ActionButtons from "$lib/p2p/ui/ActionButtons.svelte";
    import type { ThingAction } from "$lib/data/Things.svelte.ts";
    
    // < elegance... this is not the he%heist but some meaningless container
    //   containing req, facilitating pirating, which commissions he once actionable
    // point is... this component is lifecycled with req
    //  ie when user clicks NO, it vanishes
    let {M,mem,w,heist}:{M:Modus,mem:Modusmem,heist:TheC} = $props()
    // we give one C to Stuffing
    //  it usually takes many
    //  so we have an extra container layer here
    // < heist goes undefined? though above <Pirate> is an if(heist)
    let req = $derived(heist?.o()[0] || req)
    let show_req = $state()
    let interesting_title:string = $state()

    let pls // the req/%places
    // and its /* split into:
    let collections:TheN = $state()
    let places:TheN = $state()

    let share_act:ThingAction = $state()
    
    type TheC = Object
    let progress_tally:TheC = $state()
    let blob_monitoring:TheC = $state()

    $effect(() => {
        if (req?.version) {
            // this happens whenever we A:visual/**
            //  regularly attending to the req, in A time
            setTimeout(() => {
                // as soon as you get interested in one, can't rely on np for titling
                let re = req.sc.re
                interesting_title = re ? re.sc.title : "resumed"
                // you can Stuffing the reqy
                show_req = show_req_Stuffing.sc.show_req

                // nab form
                pls = req.o({places:1})[0]
                let ok = pls && !pls.sc.finished
                places = ok && pls.o({place:1}) || null
                collections = places && grop(pl => pl.sc.collection, places)

                // needs to open a share
                share_act = req.o1({action:1,needs:"a share"})[0]

                // progress heist
                // < kBps styling nice
                let he = req.o({heist:1})[0]
                progress_tally = he ? he.sc.progress_tally : ''
                if (he?.sc.heisted) {
                    if (!req.sc.finished) {
                        console.log(`heist almost up...`)
                    }
                    else {
                        console.log(`heist is fading into the past`)
                        setTimeout(() => {
                            M.node_edger.deheist()
                        },2000)
                    }
                }

                blob_monitoring = req.o({blob_monitoring:1})[0]
            },1)
        }
    })
    function nab_places(pl,pls) {
        // < elvis -> makes sense of all those checkboxes
        M.i_elvis(w, "nab_specifically", { req,pl,pls });

    }
    function togglific_default(pl,k,checked) {
        // console.log(`Toggly heist default: ${k} -> ${checked}`)
        pl.sc[k] = checked
    }
    function togglific(pl,k,e) {
        let is = e.target.checked
        // console.log(`togglific ${keyser(pl)} -> ${is}`)
        // console.log(`Toggly heist is: ${k} -> ${is}`)
        pl.sc[k] = is
    }
    // set default checkbox states, some persist forever as user prefs
    let checkbox_defaults = mem.get('checkbox_defaults') || {}
    // console.log(`Toggly heist defaults:`,checkbox_defaults)
    // a weird interface:
    req.c.set_checkbox_defaults_setter((c) => {
        // update defaults when %places -> %heist
        checkbox_defaults = c
        mem.set('checkbox_defaults',c)
    })
    function togfault(k,def) {
        def = checkbox_defaults[k] ?? def
        return def
    }
    let show_req_Stuffing = _C({})


    // < test M.F.directory_compat_mode
</script>


{#snippet bigslash()}
    <span class="slash">/</span>
{/snippet}
{#snippet toggler(pl,k,checked=false,given_id='')}
    {@const id = given_id || `tog-${pl.sc.uri}-${k}`}
    {@const defaults_to_pl = togglific_default(pl,k,checked)}
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
        <span class="arow theoneline">
            <span class="slash">⤓</span>
            {#if blob_monitoring}
                {@const {progress_tally,bit,progress_pct,avg_kBps} = blob_monitoring.sc}
                ...
                <span class="metric">{progress_tally}</span>
                <!-- <b>{bit}</b> -->
                <span class="metric small">{progress_pct}%</span>
                <!-- <span class="metric">{avg_kBps}kB/s</span> -->
            {:else}
                <b>{interesting_title}</b>
            {/if}
            <span class="rightward">
                {@render toggler(show_req_Stuffing,'show_req',false)}
            </span>
        </span>
        
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
        {#if M.F.directory_compat_mode}
            <span class="collections inrow" title="
            Access to (some part of) your filesystem is required.
            ">
                <h3>BROWSER IS TOO OLD</h3>
                <p>You don't seem to allow Directory writing access. Sorry.</p>
                <p>Try with Chrome.</p>
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
                        {@render toggler(pls,'disbelieve_categories',
                                    togfault('disbelieve_categories',false),'disbelieve')}
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
                                {@render toggler(pl,'disbelieve_directories',
                                           togfault('disbelieve_directories',false))}
                                <label for={`tog-${pl.sc.uri}-disbelieve_directories`}>
                                    disbelieve directories altogether
                                </label>, collect random tracks in one place
                            </span>
                            {#if pl.sc.suggested_rename}
                                <span class="arow">
                                    {@render toggler(pl,'lets_rename',
                                               togfault('lets_rename',false))}
                                    <label for={`tog-${pl.sc.uri}-lets_rename`}>
                                        rename to: <b>{pl.sc.suggested_rename}</b>
                                    </label>
                                </span>
                            {/if}
                            <span class="arow">
                                {@render toggler(pl,'only_categories',
                                           togfault('only_categories',false))}
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


        {#if show_req && heist}
            <Stuffing mem={mem.further("heist")} stuff={heist} {M} />
        {/if}
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
    .theoneline {
        display: flex;
        align-items: center;
        width: 100%;
    }
    .theoneline > .rightward {
        float: right;
        opacity:0.05;
    }
    .metric {
        color: rgb(156, 140, 217);
        font-size: 1.4em;
    }
    .small {
        font-size: 0.7em;
    }
    button {
        padding:0.3em;
        transform:scale(2.2) rotate(9deg);
        transform-origin:bottom;
    }
    .bitsie > button {
        float: right;
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
        padding: 1em;
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