<script lang="ts">
    import type { TheN } from "./Stuff.svelte";
    import Stuffing from "./Stuffing.svelte";

    let {innered}:{innered:TheN} = $props()
    let openness = $state(false)
    function toggle() {
        openness = !openness
    }
    
</script>

    {#each innered as inner}
        {@const many = inner.X.z.length}
        <button class="btn" onclick={toggle}>
            .../*{many}
        </button>
        {#if openness}
            <Stuffing stuff={inner} />
        {/if}
    {/each}