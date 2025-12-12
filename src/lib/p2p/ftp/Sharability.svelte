<script lang="ts">
    import Modus from '../../mostly/Modus.svelte';
    import { Modus as aModus } from "$lib/mostly/Modus.svelte.ts";
    import { onDestroy, onMount } from "svelte";
    import { DirectoryModus, DirectoryShare, FileListing, type AnyShare } from './Directory.svelte';
    import FileList from './FileList.svelte';
    import Scrollability from '../ui/Scrollability.svelte';
    import { SoundSystem } from './Audio.svelte';
    import GatHaver from '../ui/GatHaving.svelte';
    import type { PeeringSharing, PierSharing } from './Sharing.svelte';

    // a DirectoryShare (Thing)
    // < or a RemoteShare (Thing)
    // and the ways|advice to get more
    let {F,PF,S, spawnModus}:{
        F?:PeeringSharing,
        PF?:PierSharing,
        S?:DirectoryShare, // a filesystem tree to display|grow

        spawnModus:Function, // take opt, return a Modus
        // < passing the BlahModus class itself to instantiate in here goes awry
    } = $props()

    // S is the object to put .modus on, it may == F
    S = S || PF || F
    // F is always the PeeringFeature, eg PeeringSharing
    F ||= S.F || PF?.F
    
    // they all have instances of
    let M:aModus = $state()
    let gat:SoundSystem = $state()
    onMount(() => {
        if (!S) throw "!S"
        if (!F) throw "!F"

        console.log("Premodus")
        M = S.modus = spawnModus({S,F})
        console.log("postmodus")
        gat = S.gat = new SoundSystem({M})
        M.gat = gat
        console.log("Sharability onMount()!")
    })
    $effect(() => {
        if (S.started) {
            S.modus.main()
        }
    })



    function click_push(file: FileListing) {
        console.log(`Would send ${file.name}`)
    }
</script>

<p>
    I am a {S.constructor.name} 
    {#if gat}with a gat. <GatHaver {gat}/>{/if}
</p>
    {#if M}
        <Scrollability maxHeight="80vh" class="content-area">
            {#snippet content()}
                <Modus {M}></Modus>
            {/snippet}
        </Scrollability>
    {/if}
