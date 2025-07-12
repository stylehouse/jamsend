<script lang="ts">
    import { onDestroy } from "svelte";
    import { Idento, Peerily } from "./Peerily.svelte";
    import Pier from "./Pier.svelte";
    import { SvelteSet } from "svelte/reactivity";

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


    let whoto = $state("24a2aac78666b4d7")
    let tryit = () => {
        if (whoto == P.Id.pretty_pubkey()) whoto = "eb0340f4d28de96f"
        P.connect_pubkey(whoto)
        setTimeout(() => P.connect_pubkey(whoto),455)
    }






    
    let Id:Idento
    let Ud:Idento
    let link
    $effect(() => {
        setTimeout(startup,5)
    })
    async function generate_keys() {
        await P.Id.generateKeys()
        P.stash.Id = P.Id.freeze()
    }
    async function startup() {
        // yourself
        if (P.stash.Id) {
            P.Id.thaw(P.stash.Id)
        }
        else {
            // become someone
            generate_keys()
        }
        P.listen_pubkey(P.Id)

        // the location may be another persons
        Ud = new Idento()
        Ud.from_location_hash()
        // if it's not us
        if (Ud.publicKey && Ud.pretty_pubkey() != P.Id.pretty_pubkey()) {
            P.connect_pubkey(Ud)
        }

        // location becomes us, so we can share it easily
        link = P.Id.to_location_hash()
    }
    async function sharing() {
        console.log("QRify", Id)
        // puts this into the address bar
        let link = P.Id.to_location_hash()
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
            <li>Listening: {pub}</li>
            <ul class=bitsies>
                {#each eer.Piers as [pub,pier] (pub)}
                    <li>Peering: {pub}</li>
                    <ul class=bitsies>
                        <Pier {pier} />
                    </ul>
                {/each}
            </ul>
        {/each}
    </ul>
</div>

<style>
    div {
        color: green;
    }
</style>