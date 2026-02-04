<script lang="ts">
	import QrCode from "svelte-qrcode"
    let {P} = $props()
    
    let links = $state([])
    async function sharing() {
        if (links.length) return links = []
        links = await P.Trusting.M.Idzeugnate(1)
    }
    async function copy_link() {
        await navigator.clipboard.writeText(links[0]);
    }
    let size = $state(300)
    let qrsele:HTMLElement|undefined = $state()
    let space_fraction = $state(1)
    
    $effect(() => {
        if (links.length && qrsele) {
            const vw = window.innerWidth
            const vh = window.innerHeight
            const availableWidth = vw * 0.8
            const availableHeight = (vh - 100) * 0.8
            
            // Calculate grid dimensions
            const count = links.length
            const cols = Math.ceil(Math.sqrt(count))
            const rows = Math.ceil(count / cols)
            
            // Size to fit grid
            const sizeByWidth = (availableWidth / cols) * space_fraction
            const sizeByHeight = (availableHeight / rows) * space_fraction
            
            size = Math.min(sizeByWidth, sizeByHeight)
        }
    })

    async function blotter() {
        space_fraction = 0.85
        links = await P.Trusting.M.Idzeugnate(90)
    }
</script>

<span onclick={sharing}>
    <span id="shareicon">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640">
            <path fill=#2563eb d="M448 256C501 256 544 213 544 160C544 107 501 64 448 64C395 64 352 107 352 160C352 165.4 352.5 170.8 353.3 176L223.6 248.1C206.7 233.1 184.4 224 160 224C107 224 64 267 64 320C64 373 107 416 160 416C184.4 416 206.6 406.9 223.6 391.9L353.3 464C352.4 469.2 352 474.5 352 480C352 533 395 576 448 576C501 576 544 533 544 480C544 427 501 384 448 384C423.6 384 401.4 393.1 384.4 408.1L254.7 336C255.6 330.8 256 325.5 256 320C256 314.5 255.5 309.2 254.7 304L384.4 231.9C401.3 246.9 423.6 256 448 256z"/>
        </svg>
    </span>
    {#if links.length}
        <qrthing>
            <span>
                <p class="noprint"> 
                    <button onclick={copy_link}>Copy Link</button>, oncer.
                    <button class='small' onclick={blotter}>blotter</button>
                </p>
                <div class="qr-grid" bind:this={qrsele}>
                    {#each links as link (link)}
                        <pqr> <QrCode value={link} {size} /> </pqr>
                    {/each}
                </div>
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
        bottom: 0;
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
    
    .qr-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
        gap: 1em;
        max-width: 80vw;
        max-height: calc(80vh - 100px);
        overflow: auto;
    }
    
    pqr {
        display: flex;
        background: white;
        padding: -1.5em;
        justify-content: center;
        align-items: center;
    }
    
    button {
        padding: 1em;
        font-size: 1.5em;
    }
    
    p {
        font-size: 2em;
    }
    
    .small {
        font-size: 0.5em;
        float: right;
        padding: 0.3em;
        transform: scale(2.2) rotate(9deg);
        transform-origin: bottom;
        opacity: 0.1;
    }

    /* Print styles */
    @media print {
        .noprint {
            display: none !important;
        }
        
        qrthing {
            position: static;
            background: white;
            backdrop-filter: none;
            width: auto;
            height: auto;
        }
        
        .qr-grid {
            max-width: 100%;
            max-height: none;
            overflow: visible;
            gap: 0.5cm;
        }
        
        pqr {
            padding: 0.2cm;
            break-inside: avoid;
        }
    }
</style>