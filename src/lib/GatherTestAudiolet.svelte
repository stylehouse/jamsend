<script lang="ts">
    import { onDestroy } from "svelte";
    import { GathererTest } from "./audio/GatherTest.svelte";
    import Meta from "./Meta.svelte";

    let {aud} = $props()
    let distime = $state(0)
    aud.onanimationframe = () => {
        distime++
    }
    let pos = $state()
    let remains = $state()
    let awaiting = $state()
    $effect(() => {
        if (distime) {
            pos = aud.cursor()
            remains = aud.along() != null && aud.remaining_stretch()
            awaiting = aud.awaiting_mores?.length
        }

    })

</script>

<div class="mach" >
    <span class="name">aud:{aud.id}</span>
    <span>
        <span>{#if aud.playing}playing {aud.playing.length}{/if}</span>
        <span>{#if aud.stretch_size}stretch {aud.stretch_size}{/if}</span>
    </span>
    <span>
        <span>{#if aud.start_time}start_time {Math.round(aud.start_time)}ms{/if}</span>
        <span>{#if aud.spawn_time}spawn_time {Math.round(aud.spawn_time)}ms{/if}</span>
    </span>
    <span>
        <span>{#if pos != null}cursor {pos}{/if}</span>
        <span>{#if remains}remains {Math.round(remains)}ms{/if}</span>
    </span>
    <span>
        <span>morewant {aud.more_wanted}</span>
        <span>{#if aud.end_index}end_index {aud.end_index}{/if}</span>
    </span>
    <span>
        <span>awaiting {awaiting}</span>
        <span>
            {aud.is_nextly && 'is_nextly'} 
            {aud.next_stretch && 'next_stretch'}
            {aud.stopped && 'stopped'}
        </span>
    </span>
    {#if aud.meta != null}
        <Meta meta={aud.meta} />
    {/if}
    <ul class=bitsies>
        {#each aud.queue as wav, i}
            <ww>{i} {typeof wav == 'string' ? wav : ''}
                {#if pos == i} (pos){/if}
            </ww>
        {/each}
    </ul>
</div>

<style>
    ul.bitsies ww {
        display: inline-box;
        border-radius:0.3em;
        border:3px solid rgb(51, 90, 134);
    }
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
