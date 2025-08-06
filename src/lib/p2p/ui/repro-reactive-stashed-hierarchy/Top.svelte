<script lang="ts">
    import { throttle } from "$lib/Y";
    import { NotPeerily } from "./NotPeerily.svelte";
    import NotPeering from "./NotPeering.svelte";
    let stashed = $state()
    let save_stash = throttle(() => {
        console.log(`saving Astash`)
        stashed = JSON.stringify(P.stash)
    },200)

    let P = $state()
    function around() {
        P = new NotPeerily({save_stash})
        P.startup()
    }
    // another P (another time), 
    function more() {
        P = new NotPeerily({save_stash})
        P.stash = JSON.parse(stashed)
        P.startup()
    }
    function huh() {
        console.log(P)
    }

    $effect(() => {
        setTimeout(() => around(), 5)
    })
</script>

<button onclick={more}>more</button>
<button onclick={huh}>huh</button>
<p>:P</p>

    <div class=bitsies>
        {#each P?.addresses as [pub,eer] (pub)}
            <NotPeering {pub} {eer} />
        {/each}
    </div>