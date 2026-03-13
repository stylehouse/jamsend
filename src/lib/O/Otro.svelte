<script lang="ts">
    import Ghost    from "$lib/O/Ghost.svelte"
    import { onMount } from "svelte"
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

    // ── H:Mundo declared here so template can react to it ────────────────────
    let H = new House({ name: 'Mundo' })

    // ── once ghosts have arrived, create child Houses ─────────────────────────
    // H.ghosts flips from null → object when Ghost.svelte's shim receives
    // its first eatfunc(). The $effect runs exactly once after that.
    let setup_done = false
    $effect(() => {
        if (!H.ghosts || setup_done) return
        setup_done = true

        let S = H.subHouse('Story')
        let SA = S.i({ A: 'Story' })
        SA.i({ w: 'Story', Book: 'LeafFarm' })

        go_busily()
    })

    // ── reactive house list ───────────────────────────────────────────────────
    let houses: House[] = $derived(
        [H, ...H.o({ H: 1 }).map(n => n.sc.inst as House).filter(Boolean)]
    )

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
    {#if house.stashed}
        <h2>{house.name}</h2>
        <Stuffing mem={house.imem('current')} stuff={house} M={house} />
    {/if}
{/each}

{#if H.stashed}
    <button onclick={upthings}>upthings ({H.stashed?.things ?? 0})</button>
    <button onclick={go_busily}>think</button>
{/if}

<Ghost {H} />