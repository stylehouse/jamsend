<script lang="ts">
    import Ghost    from "$lib/O/Ghost.svelte"
    import { House, Work, register_class } from "$lib/O/Housing.svelte"
    import Stuffing from "$lib/data/Stuffing.svelte"

    // A Work subclass with a withitall() method
    class WithItAll extends Work {
        override async start() {
            console.log(`WithItAll ${this.name} starting`)
            this.started = true
        }
        async withitall(A, w, e, AT, wT) {
            console.log(`WithItAll.withitall() called! from ${e?.sc.from_name}`, e?.sc)
        }
        async think(A, w, e, AT, wT) {
            console.log(`WithItAll think() — ambient`)
        }
    }
    register_class('w', WithItAll)

    // ── all House construction inside $effect ─────────────────────────────────
    let H: House = $state(null!)

    $effect(() => {
        H = new House({ name: 'Mundo' })
        setTimeout(() => {
            houses = [H]
        },1)
    })

    // ── once ghosts have arrived, wire child Houses ───────────────────────────
    let setup_done = false
    $effect(() => {
        if (!H?.started || setup_done) return
        setup_done = true

        let S = H.subHouse('Story')
        let SA = S.i({ A: 'Story' })
        SA.i({ w: 'Story', Book: 'LeafFarm' })
        S.elvisto(S, 'think')

        setTimeout(() => {
            houses = H.all_House

        },1)

        go_busily()
    })

    // ── reactive house list via H.all_House ───────────────────────────────────
    // all_House lives on House so .o() / Xify() mutations stay inside H.*
    // and don't fire mid-derived in the template.
    let houses = $state([])

    function go_busily() {
        H.elvisto(H, 'think')
    }

    function upthings() {
        H.stashed.things ||= 0
        H.stashed.things += 1
        H.elvisto(H, 'think')
    }
</script>

<h3>Here we Are</h3>

{#each houses as house (house.name)}
    <h2>{house.name}</h2>
    <Stuffing mem={house.imem('current')} stuff={house} M={house} />
{/each}

{#if H?.stashed}
    <button onclick={upthings}>upthings ({H.stashed?.things ?? 0})</button>
    <button onclick={go_busily}>think</button>
{/if}

{#if H}
    <Ghost {H} />
{/if}