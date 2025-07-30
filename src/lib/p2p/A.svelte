<script lang="ts">
    import { onDestroy } from "svelte";
    import { Idento, Peerily, type StashedListen } from "./Peerily.svelte";
    import { SvelteSet } from "svelte/reactivity";
    import Listening from "./ui/Listening.svelte";
    import ShareButton from "./ui/ShareButton.svelte";
	import QrCode from "svelte-qrcode"
    

    let errors = $state(new SvelteSet())
    let on_error = (err) => {
        errors.add(err)
        console.error(`Error ${err.type}: ${err}`)
    }


    let P = new Peerily({on_error})
    // P.stash persists
    // < identity per ?id=..., which we namespace into which stash...
    $effect(() => {
        if (localStorage.Astash) {
            console.log(`loading Astash`)
            P.stash = JSON.parse(localStorage.Astash)
        }
    })
    $effect(() => {
        if (!P.stash) return
        console.log(`saving Astash`)
        localStorage.Astash = JSON.stringify(P.stash)
    })
    onDestroy(() => {
        P.stop()
    })


    let whoto = $state("3cd0df3609e62134")
    let tryit = () => {
        if (P.addresses.has(whoto)) whoto = "e092bc4767702a42"
        P.connect_pubkey(whoto)
    }


    



    
    let Id:Idento
    let Ud:Idento
    let link = $state()
    $effect(() => {
        // escape reactivity:
        setTimeout(async () => {
            await P.startup()
            if (P.addresses.has(whoto)) {
                tryit()
            }
        }, 0)
    })
    async function sharing() {
        if (link) return link = null
        // puts this copyable link into the address bar
        link = P.Id.to_location_hash()
    }
    async function copy_link() {
        await navigator.clipboard.writeText(link);
    }
    async function showstash() {
        console.log("P.stash",P.stash)
        console.log("localStorage.Astash",JSON.parse(localStorage.Astash))
    }

    $effect(() => {
        0 &&
        setTimeout(() => {
            [455,2455,5455].map(ms => setTimeout(() => tryit(), ms))
        },1)
    })


</script>

<div>
    <pan>
        <span onclick={sharing}>
            <ShareButton />
            {#if link}
                <qrthing>
                    <p> <button onclick={copy_link}>Copy Link</button> </p>
                    <p> <QrCode value={link} /> </p>
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

    <p><a href="/A?#{whoto}">Everything.</a></p>

    <button onclick={tryit}>go</button>
    <button onclick={showstash}>stash</button>

    <div class=bitsies>
        {#each P.addresses as [pub,eer] (pub)}
            <Listening {pub} {eer} />
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
    div {
        color: green;
    }
</style>