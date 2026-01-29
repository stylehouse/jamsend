<script lang="ts">
	import QrCode from "svelte-qrcode"
    let {P} = $props()
    P.dosharing = () => {
        if (link) link = null
        sharing()
    }

    
    let link = $state()
    async function sharing() {
        if (link) return link = null
        // already in the address bar, can become QR code
        link = P.share_url
    }
    async function copy_link() {
        await navigator.clipboard.writeText(link);
    }
    let size = $state(300)
    let qrele:HTMLElement|undefined = $state()
    $effect(() => {
        if (link && qrele) {
            let img = qrele.children[0]
            if (img.nodeName != "IMG") throw "!img"
            // in here, adjust size for smallest width|height of viewport
            const vw = window.innerWidth
            const vh = window.innerHeight
            const availableWidth = vw * 0.8
            const availableHeight = (vh - 100) * 0.8 // subtract space for button
            size = Math.min(availableWidth, availableHeight)
        }
    })
</script>

<span onclick={sharing}>
    <span id="shareicon">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640">
            <!--!Font Awesome Free v7.0.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2025 Fonticons, Inc.-->
            <path fill=white d="M448 256C501 256 544 213 544 160C544 107 501 64 448 64C395 64 352 107 352 160C352 165.4 352.5 170.8 353.3 176L223.6 248.1C206.7 233.1 184.4 224 160 224C107 224 64 267 64 320C64 373 107 416 160 416C184.4 416 206.6 406.9 223.6 391.9L353.3 464C352.4 469.2 352 474.5 352 480C352 533 395 576 448 576C501 576 544 533 544 480C544 427 501 384 448 384C423.6 384 401.4 393.1 384.4 408.1L254.7 336C255.6 330.8 256 325.5 256 320C256 314.5 255.5 309.2 254.7 304L384.4 231.9C401.3 246.9 423.6 256 448 256z"/>
        </svg>
    </span>
    {#if link}
        <qrthing>
            <span>
                <p> <button onclick={copy_link}>Copy Link</button>, oncer.</p>
                <pqr bind:this={qrele}> <QrCode value={link} {size} /> </pqr>
            </span>
        </qrthing>
    {/if}
</span>



<style>
    span#shareicon {
        width: 5em;
        height: 5em;
        display: inline-block;
    }


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
    pqr > img{
        width: 78vw;
    }
    pqr {
        display: flex;
        background: white;
        padding: 2em;
    }
    button{
        padding:1em;
    }
</style>