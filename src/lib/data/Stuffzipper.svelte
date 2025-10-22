<script lang="ts">
    import type { TheN } from "./Stuff.svelte";
    import Stuffing from "./Stuffing.svelte";

    let { innered }: { innered: TheN } = $props();
    let openness = $state(false);
    function toggle() {
        openness = !openness;
    }
    // some rows here, have yay many rows in them
    let inner_sizing = $state()
    $effect(() => {
        let sizo = { here: 0, therein: 0 };
        for (const inn of innered) {
            sizo.here += 1;
            sizo.therein += inn?.X?.z?.length || 0;
        }
        inner_sizing = (sizo.here == 1 ? '' : ("x" + sizo.here))
             + "/*" + sizo.therein
    });
</script>

<button class="btn {openness && 'open'}" onclick={toggle}> {inner_sizing} </button>
<span class="inner">
    {#if openness}
        {#each innered as inner}
            <Stuffing stuff={inner} />
        {/each}
    {/if}
</span>

<style>
    .inner {
        display: block;
        filter:hue-rotate(33deg)
    }
    .btn {
        display: inline-block;
        background: none;
        border: none;
        cursor: pointer;
        padding: 0;
        display: inline-flex;
        align-items: center;
        gap: 0.25em;
        color: rgb(156, 140, 217);
        font-size: 95%;
        &.open {
            text-decoration: underline;
        }
    }
</style>
