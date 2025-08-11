<script lang="ts">
    import { throttle } from "$lib/Y";
    import { NotPeerily } from "./NotPeerily.svelte";
    import NotPeering from "./NotPeering.svelte";
    // persistence, spans many lives of P in this test
    let this_test_number = $state(0)
    let stashed = $state()
    let save_stash = throttle(() => {
        console.log(`saving Astash`)
        stashed = JSON.stringify(P.stash)
    },100)

    async function wait() {
        return new Promise((resolve) => {
            setTimeout(() => {resolve()},250)
        })
    }
    let OKs = $state([])
    let okify = (label,data) => {
        console.info("Tested: "+label,data)
        OKs.push(label)
    }
    function eer_ok(stashedkey,is,label) {
        let in_situ = P.pier.stashed[stashedkey]
        let disk = JSON.parse(stashed)
        if (disk?.Peerings?.length != 1) console.warn(`n!=1 Peerings`)
        if (disk?.Peerings?.[0]?.Piers?.length != 1) console.warn(`n!=1 Piers`)
        let on_disk = disk?.Peerings?.[0]?.Piers?.[0]?.[stashedkey]
        if (typeof is == 'object') {
            is = JSON.stringify(is)
            in_situ = in_situ && JSON.stringify(in_situ)
            on_disk = on_disk && JSON.stringify(on_disk)
        }
        let ok = in_situ == is && on_disk == is
        if (ok) {
            okify(`✅ ${label}`)
        }
        else {
            let bad = in_situ == is ? "situ✅" : `situ❌(${in_situ})`
            bad += "\t"
            bad += on_disk == is ? "disk✅" : `disk❌(${on_disk})`
            okify(`❌ ${label}: ${bad}\twanted:${is}`)
            console.warn("Pier on disk: ",disk?.Peerings?.[0]?.Piers?.[0])
        }
    }


    let P:NotPeerily|null = $state()
    async function top() {
        console.warn(`Starting test case...`)
        this_test_number = this_test_number + 1
        stashed = "{}"
        OKs = []
        P = new NotPeerily({save_stash})
        P.startup()
        await wait()
        nudge()
        await wait()
        eer_ok('leg',3,'pier creates stashed properties')
        eer_ok('waft',["Blah"],'pier creates array')
        nudge()
        await wait()
        eer_ok('leg',4,'pier updates again')
        eer_ok('waft',["Blah","Blah"],'pier also grows array')

        more()
    }
    // another P (another time), 
    // < this never works...
    async function more() {
        P.stash = JSON.parse(stashed)
        P = new NotPeerily({save_stash})
        P.stash = JSON.parse(stashed)
        P.stash.Peerings[0].Piers[0].leg = 17
        P.startup()
        // have to recreate the UI to get a new pier.tweakstash()
        this_test_number = this_test_number + 1
        await wait()
        let pier = P.pier
        eer_ok('leg',17,'pier restores from stash')
        nudge()
        await wait()
        eer_ok('leg',18,'pier updates continue')
        eer_ok('waft',["Blah","Blah","Blah"],'pier grows array')



        P.pier.tweakwaft()
        await wait()
        eer_ok('waft',["Blah","Blah","Blah","Blah"],'pier grows array only')
        P.pier.tweakdeeply()
        await wait()
        eer_ok('swan',{of:{did:3}},'pier creates deep object')
        P.pier.tweakdeeply()
        await wait()
        eer_ok('swan',{of:{did:4}},'pier updates deep object')
    }
    function huh() {
        console.log(P)
    }
    function nudge() {
        // this is in Pier.svelte
        P.pier.tweakstash()
    }
    $inspect(P)
    async function showstash() {
        console.log("Pstash",{Pstash:P.stash,situ:P.eer.stashed})
        console.log("disk",JSON.parse(stashed))
    }

    $effect(() => {
        setTimeout(() => top(), 5)
    })
</script>

<button onclick={top}>top</button>
<button onclick={more}>more</button>
<button onclick={nudge}>nudge</button>
<button onclick={huh}>huh</button>
<button onclick={showstash}>stash</button>
{#key this_test_number}
    <pre>Disk: {stashed}</pre>

    <pre>{OKs?.join("\n\n")}</pre>

    <div class=bitsies>
        {#each P?.addresses as [pub,eer] (pub)}
            <NotPeering {pub} {eer} />
        {/each}
    </div>
{/key}