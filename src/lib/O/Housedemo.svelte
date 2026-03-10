<script lang="ts">
    import Agency from "$lib/ghost/Agency.svelte"
    import { House, Work, register_class } from "$lib/O/Housing.svelte"

    // A Work subclass with a withitall() method
    class WithItAll extends Work {
        override async start() {
            console.log(`WithItAll ${this.name} starting`)
            this.started = true
        }
        async withitall(e) {
            console.log(`withitall() called`, e.sc)
        }
    }
    register_class('w', WithItAll)

    let H = new House({ name: 'Mundo' })
    let M = H

    // plant the A/w particles
    H.i({ A: 'something' })
    H.o({ A: 'something' })[0].i({ w: 'withitall' })

    $effect(() => {
        if (H.todo.length) H.answer_calls()
    })

    function fire() {
        H.post_do(async () => {
            await H.channel_beliefs(H.i({
                elvis: 'withitall',
                Aw: 'something/withitall',
                payload: 'hello',
            }))
        })
    }
</script>

<h3>Here we Are</h3>
<button onclick={fire}>Fire withitall</button>
<Agency {M} />