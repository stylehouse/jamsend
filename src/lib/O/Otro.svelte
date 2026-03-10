<script lang="ts">
    import Agency from "$lib/ghost/Agency.svelte";
    import { onMount } from "svelte";
    import { House, Work, register_class } from "$lib/O/Housing.svelte"

    // A Work subclass with a withitall() method
    class WithItAll extends Work {
        override async start() {
            console.log(`WithItAll ${this.name} starting`)
            this.started = true
        }

        // called when an elvis targets this w exactly
        async withitall(A,w,e,AT,wT) {
            console.log(`withitall() called from ${e?.sc.from_name}`, e?.sc)
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

    // our machinery
    H.i({ A: 'something' })
    H.o({ A: 'something' })[0].i({ w: 'withitall' })

    // the first thing to do
    //  now that H has been injected with Agency ghost
    onMount(() => {
        H.post_do(async () => {
            console.log(`lets...`)
            await H.channel_beliefs(H.i({
                elvis: 'withitall',
                Aw: 'something/withitall',
                payload: 'hello',
            }))
        })
    })
</script>
<h3>Here we Are</h3>

<Agency {M} />

