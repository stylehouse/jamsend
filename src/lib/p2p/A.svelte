<script lang="ts">
    import { onDestroy } from "svelte";
    import { Idento, Peerily } from "./Peerily.svelte";
    import Pier from "./Pier.svelte";

    let P = new Peerily()
    let whoto = "706f0190cfe9b497"
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
    $effect(() => {
    })
    let tryit = () => {
        if (whoto == P.Id.pretty_pubkey()) return
        P.connect_pubkey(whoto)
        setTimeout(() => P.connect_pubkey(whoto),455)
    }
    onDestroy(() => {
        P.stop()
    })






    
    let Id:Idento
    let Ud:Idento
    let link
    $effect(() => {
        setTimeout(startup,5)
    })
    async function startup() {
        // yourself
        if (P.stash.Id) {
            P.Id.thaw(P.stash.Id)
        }
        else {
            // become someone
            await P.Id.generateKeys()
            P.stash.Id = P.Id.freeze()
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
        setTimeout(() => tryit(),455)
    })


</script>

<button onclick={sharing} >share</button>

<p><a href="/A?#{whoto}">Everything.</a></p>

<button onclick={tryit}>go</button>



    <ul class=bitsies>
        {#each Array.from(Object.values(P.peers_by_pub)) as pier (pier.pub)}
            <Pier {pier} />
        {/each}
    </ul>