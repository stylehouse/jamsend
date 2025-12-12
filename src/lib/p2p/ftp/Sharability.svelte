<script lang="ts">
    import Modus from '../../mostly/Modus.svelte';
    import { onDestroy, onMount } from "svelte";
    import { DirectoryModus, DirectoryShare, FileListing, type AnyShare } from './Directory.svelte';
    import FileList from './FileList.svelte';
    import Scrollability from '../ui/Scrollability.svelte';
    import { SoundSystem } from './Audio.svelte';
    import GatHaver from '../ui/GatHaving.svelte';

    // a DirectoryShare (Thing)
    // < or a RemoteShare (Thing)
    // and the ways|advice to get more
    let {S}:{S:DirectoryShare} = $props()
    // so we have a filesystem tree to display|grow
    //  along with the Modus that will be handling whatever the bot should handle
    let M:DirectoryModus
    let gat:SoundSystem = $state()
    onMount(() => {
        if (!S || !S.F) throw "!S"
        // < this UI should be Local|Remote indifferent, spawn some *Modus
        M = S.modus = new DirectoryModus({S,F:S.F})
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
                {#if !gat?.AC_ready}<p><a>Click Here</a> being.</p>{/if}
    {#if S.modus}
        <Scrollability maxHeight="80vh" class="content-area">
            {#snippet content()}
                <Modus M={S.modus}></Modus>
            {/snippet}
        </Scrollability>
    {/if}
