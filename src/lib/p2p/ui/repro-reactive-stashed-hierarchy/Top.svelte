<script lang="ts">
    import { throttle } from "$lib/Y";
    import { NotPeerily } from "./NotPeerily.svelte";
    import NotPeering from "./NotPeering.svelte";
    // persistence, spans many lives of P in this test
    let stashed = $state()
    let save_stash = throttle(() => {
        console.log(`saving Astash`)
        stashed = JSON.stringify(P.stash)
    },200)

    async function wait() {
        return new Promise((resolve) => {
            setTimeout(() => {resolve()},50)
        })
    }
    let OKs = $state([])
    function eer_ok(stashedkey,is,label) {
        let in_situ = P.eer.stashed[stashedkey]
        let on_disk = JSON.parse(stashed)?.Peerings?.[0]?.Piers?.[0]?.[stashedkey]
        let ok = in_situ == is && on_dist == is
        if (ok) {
            return OKs.push(`✅ ${label}`)
        }
        let bad = in_situ == is ? "situ✅" : `situ❌(${in_situ})`
        bad += "\t"
        bad += on_disk == is ? "disk✅" : `disk❌(${on_disk})`
        OKs.push(`❌ ${label}: ${bad}\twanted:${is}`)
    }


    let P = $state()
    async function around() {
        P = new NotPeerily({save_stash})
        P.startup()
        await wait()
        nudge()
        await wait()
        eer_ok('leg',4,'ininudge')
        nudge()
        await wait()
        eer_ok('leg',5,'nudge')

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
    function nudge() {
        // this is in Pier.svelte
        P.pier.tweakstash()
    }

    $effect(() => {
        setTimeout(() => around(), 5)
    })
</script>

<button onclick={more}>more</button>
<button onclick={nudge}>nudge</button>
<button onclick={huh}>huh</button>
<pre>:P {OKs?.join("\n\n")}</pre>

    <div class=bitsies>
        {#each P?.addresses as [pub,eer] (pub)}
            <NotPeering {pub} {eer} />
        {/each}
    </div>