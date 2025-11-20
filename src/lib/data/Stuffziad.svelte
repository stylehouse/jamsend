<script lang="ts">
    import Modus from '$lib/mostly/Modus.svelte';
    import type { Modusmem } from './Stuff.svelte';
    import Stuffziad from './Stuffziad.svelte'
    import Stuffzipper from './Stuffzipper.svelte';
    let { mem,stuffziad }: { mem:Modusmem, stuffziad: Stuffziad } = $props()
    mem = mem.further("Stuffziad:"+stuffziad.name)

    // thaw|freeze our openness to persistent memory
    let openness = $state(mem.get('openness') || false);
    function toggle() {
        openness = !openness;
        mem.set('openness',openness)
    }

    // Get all Stuffziado values
    const stuffziados = $derived(Array.from(stuffziad.values.values()))

    function ziadostyle(stuffziado):string {
        return stuffziado.is_string ? "" : "objectify"
    }
    
</script>

{#snippet ziado(stuffziado)}
    {#if stuffziado.is_C}
        <span class="count">C</span>
    {/if}
    <span class="{ziadostyle(stuffziado)}">{stuffziado?.display_name}</span>
    {#if stuffziado.innered}
        <ziadoin>
            <Stuffzipper {mem} innered={stuffziado.innered} {stuffziado} ></Stuffzipper>
        </ziadoin>
    {/if}

{/snippet}

<div class="stuffziad">
    <button class="btn" onclick={toggle}>
        <span class="name">{stuffziad.name}</span>
        <span class="colon">:</span>
        
        {#if stuffziad.values.size !== 1}
            <span class="count {openness && 'open'}">∇{stuffziad.values.size}</span>
        {/if}
    </button>

    {#if openness && stuffziad.values.size > 1}
        <div class="values">
            {#each stuffziados as stuffziado (stuffziado.name)}
                <div class="stuffziado">
                    {@render ziado(stuffziado)}
                    {#if stuffziado.rows.length != 1}
                        <span class="count">x{stuffziado.rows.length}</span>
                    {/if}
                </div>
            {/each}
        </div>
    {:else if stuffziad.values.size === 1}
        {@const stuffziado = stuffziados[0]}
        <span class="inline">
            {@render ziado(stuffziado)}
        </span>
    {/if}
</div>

<style>
.open {
    background: black;
    min-height:2em;
}
.stuffziad {
    margin: 0.2em;
    border-radius: 2em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgba(20, 70, 80, 0.4);
    display: inline-block;
    padding: 0.2em 0.5em;
    filter: hue-rotate(20deg);

    & button {
        background: none;
        border: none;
        cursor: pointer;
        padding: 0;
        display: inline-flex;
        align-items: center;
        gap: 0.25em;
    }

    & .name {
        color: rgb(208, 245, 61);
        font-size: 100%;
    }

    & .colon {
        color: rgb(228, 163, 245);
    }

    & .count {
        color: rgb(156, 140, 217);
        font-size: 85%;
    }

    & .arrow {
        color: rgb(228, 163, 245);
        font-size: 85%;
    }

    &>.values {
        margin-top: 0.3em;
        margin-left: 0.5em;
        display: flex;
        flex-wrap: wrap;
        gap: 0.2em;
    }
    &.inline {
        color: rgb(208, 245, 61);
        filter: brightness(0.7) hue-rotate(-10deg);
        margin-left: 0.2em;
        font-size: 95%;
    }
}

.stuffziado {
    margin: 0.1em;
    padding: 0.1em 0.3em;
    border-radius: 1em;
    background-color: rgba(50, 90, 100, 0.3);
    display: inline-block;
    filter: hue-rotate(-30deg);
    &>.name {
        color: rgb(208, 245, 61);
        filter: brightness(0.7);
        margin-left: 0.2em;
        font-size: 90%;
    }
    &>.count {
        color: rgb(156, 140, 217);
        font-size: 90%;
    }
}

.objectify {
    color: rgb(61, 245, 159);
    background-color: rgba(14, 26, 29, 0.3);
}
</style>
