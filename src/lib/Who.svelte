<script lang="ts">
	import QrCode from "svelte-qrcode"
    import SvelteCopyUrlButton from 'svelte-copy-url-button';
    import { untrack } from 'svelte';
    import { exportKeyHex, Idento } from './Peer.svelte';
    // your id, we save
    // < privacy: dont share user_pub? or regen for each streamer_pub
    //    simply avoid peers sharing pubkeys?
    // < privacy: consent to share user_name with room
    let user = new Idento()
    // the streamer, who runs the room, could become you
    let A = new Idento()
    // status messages
    let stat = $state("");

    let user_pub_hex = $state('')
    let streamer_pub_hex = $state("");
    $effect(async () => {
        if (!user.publicKey) return
        user_pub_hex = await exportKeyHex(user.publicKey)
    })
    $effect(async () => {
        if (!A.publicKey) return
        streamer_pub_hex = await exportKeyHex(A.publicKey)
    })


    async function newStream() {
        if (!user.publicKey) {
            stat = "no keys"
            return
        }
        A.replaceKeys(user)
        await A.to_location_hash()
        stat = "newStream()"
    }
    let sharable_link = $state("")

    // init the streamer
    //  who is identified by the URL, which can change
    let streamer_init = false;
    $effect(() => {
        if (streamer_init) return
        streamer_init = true
        get_streamer();
        window.addEventListener("popstate", get_streamer);
        window.addEventListener("pushstate", get_streamer);
    });
    let hash = $state('')
    async function get_streamer() {
        hash = window.location.hash
        await A.from_location_hash()
        if (!A.publicKey) return
        stat  = "got streamer"
    }
    $effect(() => {
        if (streamer_pub_hex) {
            // they followed a link to someone's room
            //  have their name in the URL for human-friendliness of the link itself
            // or, they might have just become the streamer
            
            if (untrack(() => A.publicKey == user.publicKey)) {
                // your room
                stat = "TODO sharable link + QR code";
                sharable_link = window.location+''
            } else {
                // < connect there
                stat = "TODO finding the streamer...";
            }
        } else {
            // they left the room or followed a non-room link
            stat = "non-room link";
        }
    });



    // persist the user
    //  so they can reload the page and resume as the peer they were
    let user_init = async () => {
        if (localStorage.jamsend_user) {
            await user.from_json(localStorage.jamsend_user)
        }
        user_init = () => {}
    }
    $effect(async () => {
        user_init()
    });
    $effect(async () => {
        if (user.publicKey) {
            localStorage.jamsend_user = await user.to_json()
        }
    });





    // pubkeys prototyping
    let signature = $state();
    let noise = $state();
    let verified = $state();

    // Generate a key pair
    async function generateKey() {
        stat = "Generating..."
        user.generateKeys()
        signature = undefined;
        verified = undefined;
        stat = "Got keys..."
    }

    // Generate some random noise (as Uint8Array)
    function makeNoise() {
        noise = crypto.getRandomValues(new Uint8Array(32))
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
        {#if hash}<small>{hash}</small>{/if}
        <small>({streamer_pub_hex})</small>
</p>
    {#if user_pub_hex}<p>You: <small>({user_pub_hex})</small></p>{/if}
    {#if stat}<p>><small>{stat}</small></p>{/if}
    
</div>
<div>
    {#if sharable_link}
        <p>Sharable link: <SvelteCopyUrlButton url={sharable_link} />
             <!-- <details>
                <summary>QR code</summary>
                <QrCode value={sharable_link} />
            </details> -->
        </p>
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

<style>
    button {
        border: 1px solid green;
    }
</style>
