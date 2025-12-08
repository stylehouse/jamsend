<script lang="ts">
    import Modus from '../../mostly/Modus.svelte';
    import { onDestroy, onMount } from "svelte";
    import { DirectoryModus, DirectoryShare, FileListing, type AnyShare } from './Directory.svelte';
    import FileList from './FileList.svelte';
    import Scrollability from '../ui/Scrollability.svelte';
    import { SoundSystem } from './Audio.svelte';

    // a DirectoryShare (Thing)
    // < or a RemoteShare (Thing)
    // and the ways|advice to get more
    let {S}:{S:DirectoryShare} = $props()
    // so we have a filesystem tree to display|grow
    //  along with the Modus that will be handling whatever the bot should handle
    let M:DirectoryModus
    let gat:SoundSystem
    onMount(() => {
        // S.modus = TheModus.test_Stuff()
        // S.i_action({label:'test',handler: () => S.modus = TheModus.test_Stuff() })

        // really:
        if (!S) throw "What the hell S"
        M = S.modus = new DirectoryModus({S,F:S.F})
        gat = S.gat = new SoundSystem({M})
        M.gat = gat
        touchlisten()
        console.log("Sharability onMount()!")
        setTimeout(() => initAudio(),10)
        return () => untouchlisten()
    })
    $effect(() => {
        if (S.started) {
            S.modus.main()
        }
    })



    function touchlisten() {
        document.addEventListener("click", initAudio);
        document.addEventListener("touchstart", initAudio);
    }
    function untouchlisten() {
        document.addEventListener("click", initAudio);
        document.addEventListener("touchstart", initAudio);
    }
    // Initialize AudioContext in response to user gesture
    const initAudio = async () => {
        if (gat.AC && await gat.AC_OK()) return;
        try {
            if (await gat.init()) {
                untouchlisten()
            }
        } catch (err) {
            console.error("Failed to create AudioContext:", err);
        }
    };



    function click_push(file: FileListing) {
        console.log(`Would send ${file.name}`)
    }
</script>

<p>I am a {S.constructor.name}</p>

                {#if !gat?.AC_ready}<p><a>Click Here</a> being.</p>{/if}
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