<script lang="ts">
    import { onDestroy } from "svelte";
    import { Idento, Peerily } from "./Peerily.svelte";
    import { SvelteSet } from "svelte/reactivity";
    import Listening from "./ui/Listening.svelte";

    let errors = $state(new SvelteSet())
    let on_error = (err) => {
        errors.add(err)
        console.error(`Error ${err.type}: ${err}`)
    }
    let P = new Peerily({on_error})
    // P.stash persists
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
        if (whoto == P.Id.pretty_pubkey()) whoto = "e092bc4767702a42"
        P.connect_pubkey(whoto)
    }






    
    let Id:Idento
    let Ud:Idento
    let link
    $effect(() => {
        // escape reactivity:
        setTimeout(async () => {
            await P.startup()
            if (whoto == P.Id.pretty_pubkey()) {
                tryit()
                console.log("Tryit")
            }
        }, 0)
    })
    async function sharing() {
        console.log("QRify", Id)
        // puts this into the address bar
        link = P.Id.to_location_hash()
        // < QR code, copyable link?
    }

    $effect(() => {
        0 &&
        setTimeout(() => {
            [455,2455,5455].map(ms => setTimeout(() => tryit(), ms))
        },1)
    })


</script>

<div>
    <button onclick={sharing} >share</button>
    -----
    <button onclick={generate_keys} >regen</button>

    <p><a href="/A?#{whoto}">Everything.</a></p>

    <button onclick={tryit}>go</button>

    <ul class=bitsies>
        {#each P.addresses as [pub,eer] (pub)}
            <Listening {pub} {eer} />
        {/each}
    </ul>
</div>

<style>
    div {
        color: green;
    }
</style>