<script lang="ts">
    import { onDestroy } from "svelte";
    import { GathererTest } from "./audio/GatherTest.svelte";
    import GatherTestAudiolet from "./GatherTestAudiolet.svelte";

    let {aud} = $props()

</script>

<div class="mach" >
    <span class="name">aud:{aud.id}</span>
    {#if aud}
        <ul>
            {#each aud.queue as wav}
                <li>{wav}</li>
            {/each}
        </ul>
    {/if}
</div>

<style>
    .mach {
        border-radius:1em;
        border:3px solid rgb(216, 196, 18);
        background: rgb(112, 72, 11);
    }
    .name {
        font-size: 130%;
        color: white;
    }
</style>
