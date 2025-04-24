<script lang="ts">
    import * as ed from '@noble/ed25519';
	import QrCode from "svelte-qrcode"
    import SvelteCopyUrlButton from 'svelte-copy-url-button';
    import { untrack } from 'svelte';
    // your id, we save
    // < privacy: dont share user_pub? or regen for each streamer_pub
    //    simply avoid peers sharing pubkeys?
    // < privacy: consent to share user_name with room
    let user = $state({ name: "", sec: "", pub: "" });
    // who runs the room, could become you
    let streamer_name = $state("");
    let streamer_pub_hex = $state("");
    let streamer_pub = $state("");
    // status messages
    let stat = $state("");


    async function newStream() {
        streamer_name = "Loud"
        streamer_pub = user.pub
        streamer_pub_hex = ed.etc.bytesToHex(user.pub)
        stat = "newStream()"
    }
    let sharable_link = $state("")

    // init the streamer
    //  who is identified by the URL, which can change
    let streamer_init = false;
    $effect(() => {
        if (streamer_init) return
        streamer_init = true
        get_streamer_name();
        window.addEventListener("popstate", get_streamer_name);
        window.addEventListener("pushstate", get_streamer_name);
    });
    function get_streamer_name() {
        let m = window.location.hash.match(/^#(\w+)_(\w+)$/);
        streamer_name = (m && m[1]) || "";
        streamer_pub_hex = (m && m[2] || "");
        streamer_pub = streamer_pub_hex && ed.etc.hexToBytes(streamer_pub_hex)
    }
    $effect(() => {
        if (streamer_pub_hex) {
            // they followed a link to someone's room
            //  have their name in the URL for human-friendliness of the link itself
            // or, they might have just become the streamer
            window.location.hash = `${streamer_name}_${streamer_pub_hex}`;
            if (untrack(() => streamer_pub == user.pub)) {
                // your room
                stat = "TODO sharable link + QR code";
                sharable_link = window.location
            } else {
                // < connect there
                stat = "TODO finding the streamer...";
            }
        } else {
            // they left the room or followed a non-room link
            stat = "non-room link";
        }
    });

    // init the user
    let user_init = false;
    $effect(() => {
        if (!user_init) {
            if (localStorage.jamsend_user) {
                user = JSON.parse(localStorage.jamsend_user)
            }
            user_init = true;
        }
    });
    $effect(() => {
        if (user.name || user.pub) {
            localStorage.jamsend_user = JSON.stringify(user)
        }
    });
    // init user's keys
    // pubkeys prototyping
    let signature = $state();
    let noise = $state();
    let verified = $state();

    // Generate a key pair
    async function generateKey() {
        stat = "Generating..."
        user.sec = ed.utils.randomPrivateKey()
        user.pub = await ed.getPublicKeyAsync(user.sec)
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
        if (!user.sec || !noise) return
        signature = await ed.signAsync(noise, user.sec)
        verified = undefined
    }

    // Verify the signature
    async function verifySignature() {
        if (!user.pub || !signature || !noise) return;
        verified = await ed.verifyAsync(signature,noise,user.pub)
    }

    let user_pub_hex = $state('')
    $effect(() => {
        if (!user.pub) return
        user_pub_hex = untrack(() => { user.pub && ed.etc.bytesToHex(user.pub) || '' })
        
    })
</script>

<div>
    <p>{streamer_name} <small>({streamer_pub_hex})</small></p>
    {#if user_pub_hex}<p>You: <small>({user_pub_hex})</small></p>{/if}
    {#if stat}<p>><small>{stat}</small></p>{/if}
</div>
<div>
    {#if sharable_link}
        <p>Sharable link: <SvelteCopyUrlButton url={sharable_link} />
             <details>
                <summary>QR code</summary>
                <QrCode value={sharable_link} />
            </details>
        </p>
    {/if}
</div>

<div>
    <button on:click={generateKey}>generate</button>
    <button on:click={newStream}>New Stream</button>
    <button on:click={makeNoise}>noise</button>
    <button on:click={signNoise}>sign</button>
    <button on:click={verifySignature}>Verify</button>
</div>



<div>
    {#if noise}
        <p>Noise: {Array.from(noise).join(", ")}</p>
    {/if}
    {#if signature}
        <p>Signature: {Array.from(new Uint8Array(signature)).join(", ")}</p>
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
