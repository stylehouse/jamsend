<script lang="ts">
    import { onDestroy } from "svelte";
    import { Idento, Peerily, type StashedPeering } from "./Peerily.svelte";
    import { SvelteSet } from "svelte/reactivity";
    import Peering from "./ui/Peering.svelte";
    import ShareButton from "./ui/ShareButton.svelte";
	import QrCode from "svelte-qrcode"
    import { throttle } from "$lib/Y";
    import { Sharing } from "./ftp/Sharing.svelte";
    

    let errors = $state(new SvelteSet())
    let on_error = (err) => {
        errors.add(err)
        console.error(`Error ${err.type}: ${err}`)
    }

    function load_stash() {
        console.log(`loading Astash`)
        P.stash = JSON.parse(localStorage.Astash)
    }
    let save_stash = throttle(() => {
        console.log(`saving Astash`)
        localStorage.Astash = JSON.stringify(P.stash)
    },200)

    let P = new Peerily({on_error,save_stash})
    P.feature(new Sharing({P}))

    // P.stash persists
    // < identity per ?id=..., which we namespace into which stash...
    $effect(() => {
        if (!localStorage.Astash) return
        load_stash()
    })
    $effect(() => {
        if (!P.stash) return
        save_stash()
    })
    onDestroy(() => {
        P.stop()
    })


    let whoto = $state("ef281478ab8a9620")
    let tryit = () => {
        if (P.addresses.has(whoto)) whoto = "e092bc4767702a42"
        // P.connect_pubkey(whoto)
    }


    


    
    let Id:Idento
    let Ud:Idento
    let link = $state()
    $effect(() => {
        // escape reactivity:
        setTimeout(() => P.startup(), 0)
    })
    async function sharing() {
        if (link) return link = null
        // already in the address bar, can become QR code
        link = P.share_url + ",blaggablagga,hitech"
    }
    async function copy_link() {
        await navigator.clipboard.writeText(link);
    }

    async function showstash() {
        console.log("P.stash",P.stash)
        let data = JSON.parse(localStorage.Astash)
        let bit = data.Peerings[0]?.Piers[0]
        console.log("localStorage.Astash.Peerings[0].Piers[0]",bit)
        console.log("localStorage.Astash",data)
    }
    async function dropstashedPeerings() {
        P.stash.Peerings = []
    }

    $effect(() => {
        0 &&
        setTimeout(() => {
            [455,2455,5455].map(ms => setTimeout(() => tryit(), ms))
        },1)
    })
    $inspect(P.stash)


</script>

<div>
    <pan>
        <span onclick={sharing}>
            <ShareButton />
            {#if link}
                <qrthing>
                    <p> <button onclick={copy_link}>Copy Link</button> </p>
                    <pqr> <QrCode value={link} /> </pqr>
                </qrthing>
            {/if}
        </span>
        
        <span>
            <label for="onramptype" >onramp</label>
            <select id="onramptype">
                <option>figaro</option>
                <option>figaro</option>
            </select>
        </span>
    </pan>

    <button onclick={tryit}>go</button>
    <!-- <button onclick={showstash}>stash</button> -->
    <!-- <button onclick={dropstashedPeerings}>--</button> -->

    <div class=bitsies>
        {#each P.addresses as [pub,eer] (pub)}
            <Peering {pub} {eer} />
        {/each}
    </div>
</div>

<style>
    qrthing {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 1000;
        backdrop-filter: blur(4px);
    }
    pqr {
        background: white;
        padding-left: 26px;
        padding-top: 30px;
    }
    div {
        color: green;
    }
</style>