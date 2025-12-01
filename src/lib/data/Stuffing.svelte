<script lang="ts">
    import Strata from '$lib/data/Strata.svelte';
    import Modus from '$lib/mostly/Modus.svelte';
    import { hak } from '$lib/Y';
    import { Modusmem, Stuff,Stuffing, type TheUniversal } from './Stuff.svelte';
    import Stuffusion from './Stuffusion.svelte'

    let { mem,stuff,see,hide,M }:{ 
        mem:Modusmem, 
        stuff:Stuff,
        see?:Array<TheUniversal>,
        hide?:Array<TheUniversal>,
        M?:Modus
        } = $props()
    mem = mem.further("Stuffing")
    let stuff_length = $state(0)
    let stufflen = () => { stuff_length = stuff?.X?.z?.length || 0 }

    // Create Stuffing in an effect
    let stuffing: Stuffing | null = $state(null)

    let new_stuffing: Stuffing | null = $state(null)
    let spinner = $state(false)
    $effect(() => {
        // we have to wait for the new version
        //  if in transaction that went async
        //   after starting to change stuff
        if (stuff.version) {
            new_stuffing = new Stuffing(stuff,{
                matches: see,
                unmatches: hide,
            })
            spinner = true
            // console.log(`Stuffing new...`)
        }
        stufflen()
    })
    $effect(() => {
        // it finished! bumping version agaion
        if (new_stuffing && new_stuffing.started) {
            // console.log(`Stuffing installed!`)
            stuffing = new_stuffing
            new_stuffing = null
            setTimeout(() => {
                spinner = false
            }, 333)
            if (M) {
                // first layer of Stuffing inside Modus, look for %%Strata
                setTimeout(() => {
                    check_for_strata()
                }, 11)
            }
        }
        stufflen()
    })

    let strata_version = $state(0)
    let stratum = $state()
    let match = null
    let see = null
    let nameclick = null
    function check_for_strata() {
        let N = []
        // Stuff/%nib/%Strata,match/%Tree:1     # what to find first
        //           /*%Strata,see/*%the:1,Stuffing:1,matches:1
        //           /%Tree                     # as per %Strata,match/*%*
        match = null
        see = null
        nameclick = null
        stuff.o().map(n => {
            if (!n.oa({Strata:1})) return
            if (match) throw "< multi Strata"
            n.o({Strata:1,match:1}).map(ma => {
                ma.o().map(m => {
                    if (match) throw "< multi basis Strata"
                    match = {...m.sc}
                })
            })
            // > or is it hide?
            n.o({Strata:1,see:1}).map(se => {
                // *%the:1,Stuffing:1,matches:1
                se.o().map(m => {
                    see ||= []
                    see.push({...m.sc})
                })
            })
            n.o({Strata:1,nameclick_fn:1}).map(na => {
                nameclick = na.sc.nameclick_fn
            })
            if (match && !see) throw "Strata!see"
            if (see && !match) throw "Strata!match"
            

            if (match) {
                // find the first %Tree
                N.push(...n.o(match))
            }
        })
        // may not
        stratum = N[0]
        strata_version++
    }

</script>

{#if stuffing}
    {#if stratum}
        <div class="strata">
            {#key strata_version}
                <Strata mem={mem.further('Strata')} C={stratum} {match} {see} {nameclick} ></Strata>
            {/key}
        </div>
    {/if}
    <div class="stuffing">
        <div class="content">
            {#each Array.from(stuffing.groups.values()) as stuffusion:Stuffusion (stuffusion.name)}
                <Stuffusion {mem} {stuffusion} />
            {/each}
        </div>
        {#if spinner}
            <div class="spinner"></div>
        {/if}
    </div>
{/if}



<style>
.strata {
    display:block;
}
.stuffing {
    margin: 0.1em;
    border-radius: 4em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgb(5, 46, 46);
    display: inline-block;
    /* filter: hue-rotate(-50deg); */
    padding: 0.1em;
    position: relative;
}
.spinner {
    position: absolute;
    top: 0%;
    left: -1em;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0.3em 0.6em;
    color: rgb(38, 110, 217);
    font-size: 1.6em;
    animation: pulse 1s ease-in-out infinite;
    text-shadow: 2px 2px 2px rgb(12, 28, 51);
}
.spinner::before {
    content: "⟳";
    display: inline-block;
    animation: spin 0.3s linear infinite;
}
@keyframes spin {
    to { transform: rotate(360deg); }
}
@keyframes pulse {
    0%, 100% { opacity: 0.6; }
    50% { opacity: 1; }
}
.content {
    display: inline-block;
    min-height:1em;
    min-width:1em;
}
</style>
