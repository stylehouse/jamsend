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
    <thislot class="{openness && 'onaline'} ">
        <button class="btn" onclick={toggle}>
            /*{many}
        </button>
        {#if openness}
            <Stuffing stuff={inner} />
        {/if}
    </thislot>
{/each}

<style>
    .onaline {
        display:block;
    }
    .btn {
        display:inline-block;
        background: none;
        border: none;
        cursor: pointer;
        padding: 0;
        display: inline-flex;
        align-items: center;
        gap: 0.25em;
        color: rgb(156, 140, 217);
        font-size: 95%;
    }
</style>