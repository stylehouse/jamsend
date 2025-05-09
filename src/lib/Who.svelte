<script lang="ts">
	import QrCode from "svelte-qrcode"
    import SvelteCopyUrlButton from 'svelte-copy-url-button';
    import { Idento } from './Peer.svelte';
    import Peers from "./Room.svelte";
    import Room from "./Room.svelte";

    // your id, we save
    // < privacy: dont share user_pub? or regen for each streamer_pub
    //    simply avoid peers sharing pubkeys?
    // < privacy: consent to share user_name with room
    let user = new Idento()
    // the streamer, who runs the room, could become you
    let A = new Idento()
    // status messages
    let statmsg = $state("");
    let labelled_stat = (label:string) => {
        return (m,data?) => {
            statmsg = `${label}: ${m}`
            if (data) console.info(statmsg,data)
        }
    }
    let stat = labelled_stat('Who')


    async function newStream() {
        if (!user.publicKey) {
            stat("no keys")
            return
        }
        A.replaceKeys(user)
        await A.to_location_hash()
        stat("newStream()")
        getApubkey()
        get_streamer();
    }
    let sharable_link = $state()

    // init the streamer
    //  who is identified by the URL, which can change
    let streamer_init = async () => {
        window.addEventListener("popstate", get_streamer);
        window.addEventListener("pushstate", get_streamer);
        streamer_init = () => {}
        get_streamer();
    }
    $effect(() => streamer_init());
    async function get_streamer() {
        await A.from_location_hash()
        if (!A.publicKey) return
        stat("got streamer")
        begin()
    }



    let user_pub_hex = $state('')
    let streamer_pub_hex = $state("")
    $effect(async () => {
        if (!user.publicKey) return
        user_pub_hex = user.pub
    })
    function getApubkey() {
        if (!A.publicKey) return
        streamer_pub_hex = A.pub

    }
    $effect(async () => {
        getApubkey()
    })

    // we decide to connect to peers
    let room = $state()
    // we are the origin of the stream
    let is_host = $state(false)
    function begin() {
        if (!streamer_pub_hex) {
            debugger
        }
        
        room = A.pub
        sharable_link = window.location+''
        is_host = A.pub == user.pub
    }

    // persist the user
    //  so they can reload the page and resume as the peer they were
    let user_init = async () => {
        if (localStorage.jamsend_user) {
            await user.thaw(JSON.parse(localStorage.jamsend_user))
        }
        user_init = () => {}
    }
    $effect(user_init)
    $effect(async () => {
        if (user.publicKey) {
            localStorage.jamsend_user = JSON.stringify(await user.freeze())
        }
    })





    // pubkeys prototyping
    let signature = $state();
    let noise = $state();
    let verified = $state();

    // Generate a key pair
    async function generateKey() {
        stat("Generating...")
        await user.generateKeys()
        signature = undefined;
        verified = undefined;
        stat("Got keys...")
    }

    // Generate some random noise (as Uint8Array)
    function makeNoise() {
        noise = crypto.getRandomValues(new Uint8Array(32))
        noise = "Blah"
        // noise = new TextEncoder().encode(noise)
        signature = undefined
        verified = undefined
    }

    // Sign the noise
    async function signNoise() {
        if (!user.privateKey || !noise) return
        let sig = await user.sign(noise)
        // sig = sig.slice(1)+'e'
        signature = sig
        verified = undefined
    }

    // Verify the signature
    async function verifySignature() {
        if (!user.publicKey || !signature || !noise) return;
        verified = await user.verify(signature,noise)
    }

</script>













<div>
    <p>tuned to:
        <small>({streamer_pub_hex})</small>
</p>
    {#if user_pub_hex}<p>You: <small>({user_pub_hex})</small></p>{/if}
    {#if statmsg}<p>><small>{statmsg}</small></p>{/if}
    
</div>
<div>
    {#if sharable_link}
        <div>Sharable link: <SvelteCopyUrlButton url={sharable_link} />
            <small>{sharable_link}</small>
            <!-- <QrCode value={sharable_link} /> -->
             Here:
             <details>
                <summary>QR code</summary>
                <p> <QrCode value={sharable_link} /> </p>
            </details>
        </div>
    {/if}
</div>

<div>
    <button onclick={generateKey}>generate</button>
    <button onclick={newStream}>New Stream</button>
    <button onclick={makeNoise}>noise</button>
    <button onclick={signNoise}>sign</button>
    <button onclick={verifySignature}>Verify</button>
</div>



<div>
    {#if noise}
        <p>Noise: {Array.from(noise).join(", ")}</p>
    {/if}
    {#if signature}
        <p>Signature: {signature}</p>
    {/if}
    {#if verified !== undefined}
        <p>Signature Verified: {verified ? "✅" : "❌"}</p>
    {/if}
</div>

{#if room}
    <div> Room:
        <Room {room} {is_host}
            stat={labelled_stat('Room')} />
    </div>
{/if}

<style>
    button {
        border: 1px solid green;
    }
    details p {
        mix-blend-mode: multiply;
    }
</style>
