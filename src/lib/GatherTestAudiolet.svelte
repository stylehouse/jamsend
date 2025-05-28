<script lang="ts">
    import { onDestroy } from "svelte";
    import { GathererTest } from "./audio/GatherTest.svelte";

    let {aud} = $props()
    let distime = $state(0)
    aud.onanimationframe = () => {
        distime++
    }
    let pos = $state()
    $effect(() => {
        pos = aud.cursor()

    })

</script>

<div class="mach" >
    <span class="name">aud:{aud.id}</span>
    {#if aud.stretch_size}playing *{aud.stretch_size}{/if}
    <span>
        <span>{#if aud.start_time}start_time {Math.round(aud.start_time)}ms{/if}</span>
        <span>{#if aud.spawn_time}spawn_time {Math.round(aud.spawn_time)}ms{/if}</span>
    </span>
    <ul>
        {#each aud.queue as wav}
            <li>{wav}</li>
        {/each}
        
    </ul>
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
    span { display:inline-table; margin:0.2em }
    span span { display:table-row }
</style>
