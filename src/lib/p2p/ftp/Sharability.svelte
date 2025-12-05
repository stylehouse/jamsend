<script lang="ts">
    import Modus from '../../mostly/Modus.svelte';
    import { onMount } from "svelte";
    import { DirectoryModus, DirectoryShare, FileListing, type AnyShare } from './Directory.svelte';
    import FileList from './FileList.svelte';
    import Scrollability from '../ui/Scrollability.svelte';

    // a DirectoryShare (Thing)
    // < or a RemoteShare (Thing)
    // and the ways|advice to get more
    let {S}:{S:DirectoryShare} = $props()
    // so we have a filesystem tree to display|grow
    //  along with the Modus that will be handling whatever the bot should handle
    
    onMount(() => {
        // S.modus = TheModus.test_Stuff()
        // S.i_action({label:'test',handler: () => S.modus = TheModus.test_Stuff() })

        // really:
        if (!S) throw "What the hell S"
        S.modus = new DirectoryModus({S,F:S.F})
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

<p>I am a {S.constructor.name}</p>

    {#if S.modus}
        <Scrollability maxHeight="80vh" class="content-area">
            {#snippet content()}
                <Modus M={S.modus}></Modus>
            {/snippet}
        </Scrollability>
    {/if}

    {#if false && S.started}
        <FileList
                title="Local Files" 
                list={S.list} 
                onFileClick={click_push}
                onRefreshClick={() => S.refresh()}
            >
        </FileList>
    {/if}