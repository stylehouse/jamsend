<script lang="ts">
    import Agency from "$lib/ghost/Agency.svelte";
    import { onMount } from "svelte";
    import { House, Work, register_class } from "$lib/O/Housing.svelte"
    import Stuffing from "$lib/data/Stuffing.svelte";
    import Machinery from "$lib/ghost/Machinery.svelte";

    // A Work subclass with a withitall() method
    class WithItAll extends Work {
        override async start() {
            console.log(`WithItAll ${this.name} starting`)
            this.started = true
        }

        // called when an elvis targets this w exactly
        async withitall(A,w,e,AT,wT) {
            console.log(`WithItAll.withitall() called! from ${e?.sc.from_name}`, e?.sc)
        }

        // ambient pass — called every main() cycle
        async think(A,w,e,AT,wT) {
            console.log(`WithItAll think() — ambient`)
        }
    }
    register_class('w', WithItAll)




    // top level!
    let H = new House({name:'Mundo'})
    let M = H // was named Modus
    $effect(() => {
        if (H.todo.length) {
            H.answer_calls()
        }
    })

    function go_busily() {
        console.log(`🔥`)
        H.elvisto(H,'think')
    }

    // the first thing to do
    //  now that H has been injected with Agency ghost
    onMount(() => {
        console.log(`Otro onMount`)
        setTimeout(() => {
            // our machinery arrives
            //  if H/* is blank when eatfunc(), it won't dispatch main() 
            H.i({ A: 'farm' })
            H.i({ A: 'plate' })
            H.i({ A: 'enzymeco' })

            // and also !?
            // H.i({ A: 'something' })
            // H.o({ A: 'something' })[0].i({ w: 'withitall' })
            // H.elvisto('something/withitall', 'withitall', { payload: 'hello' })
        },3)
        setTimeout(go_busily,30)
        setTimeout(go_busily,60)
        setTimeout(go_busily,90)
    })
    function upthings() {
        H.stashed.things ||= 0
        H.stashed.things += 1
        H.elvisto(H,'think')
    }
</script>
<h3>Here we Are</h3>

{#if H.stashed}
    <h2>memory: {H.stashed?.things}</h2>
    <button onclick={upthings}>upthings</button>


    <Stuffing mem={H.imem('current')} stuff={H} M={H} />
{/if}

<Agency {M} />
<Machinery {M} />

