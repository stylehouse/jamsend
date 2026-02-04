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
    let size = $state(800)
    let qrsele:HTMLElement|undefined = $state()
    let space_fraction = $state(1)
    let compositeUrl = $state<string|null>(null)
    
    $effect(() => {
        if (links.length == 1 && qrsele) {
            const vw = window.innerWidth
            const vh = window.innerHeight
            const availableWidth = vw * 0.8
            const availableHeight = (vh - 100) * 0.8
            size = Math.min(availableWidth, availableHeight) * space_fraction
        }
    })

    async function blotter() {
        links = await P.Trusting.M.Idzeugnate(126)
        
        // Wait for QR codes to render
        await new Promise(resolve => setTimeout(resolve, 500))
        
        // Create composite image
        await createComposite()
    }
    async function createComposite() {
        if (!qrsele) return
        
        const OVERLAP_PERCENT = -0.18
        const PADDING = 130  // padding around edge in pixels
        
        // A4 at 300dpi: 210mm x 297mm = 2480 x 3508 pixels
        let margin = 400
        const A4_WIDTH = 2480 - margin
        const A4_HEIGHT = 3508 - margin
        
        const canvas = document.createElement('canvas')
        canvas.width = A4_WIDTH
        canvas.height = A4_HEIGHT
        const ctx = canvas.getContext('2d')
        if (!ctx) return
        
        // White background
        ctx.fillStyle = 'white'
        ctx.fillRect(0, 0, A4_WIDTH, A4_HEIGHT)
        
        // Get all QR code images
        const qrElements = qrsele.querySelectorAll('pqr img')
        const images = Array.from(qrElements) as HTMLImageElement[]
        
        if (images.length === 0) return
        
        // Calculate grid: aim for roughly square layout
        const cols = Math.ceil(Math.sqrt(images.length * 0.77)) - 1
        const rows = Math.ceil(images.length / cols) - 1
        
        // Available space after padding
        const availableWidth = A4_WIDTH - (2 * PADDING)
        const availableHeight = A4_HEIGHT - (2 * PADDING)
        
        // Calculate QR size with overlap/gap
        const effectiveCols = cols * (1 - OVERLAP_PERCENT) + OVERLAP_PERCENT
        const effectiveRows = rows * (1 - OVERLAP_PERCENT) + OVERLAP_PERCENT
        
        const qrSizeByWidth = availableWidth / effectiveCols
        const qrSizeByHeight = availableHeight / effectiveRows
        const qrSize = Math.min(qrSizeByWidth, qrSizeByHeight)
        
        const gapX = qrSize * OVERLAP_PERCENT
        const gapY = qrSize * OVERLAP_PERCENT
        
        // Draw QR codes with gap (left-to-right, top-to-bottom)
        images.forEach((img, index) => {
            const col = index % cols
            const row = Math.floor(index / cols)
            
            const x = PADDING + (col * (qrSize - gapX))
            const y = PADDING + (row * (qrSize - gapY))
            
            ctx.drawImage(img, x, y, qrSize, qrSize)
        })
        
        // Convert to JPEG
        canvas.toBlob((blob) => {
            if (blob) {
                if (compositeUrl) URL.revokeObjectURL(compositeUrl)
                compositeUrl = URL.createObjectURL(blob)
            }
        }, 'image/jpeg', 0.95)
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
                    {#if compositeUrl}
                        <a href={compositeUrl} download="qr-blotter.jpg" class='small blotter-link'>blotter ⬇</a>
                    {:else}
                        <button class='small' onclick={blotter}>blotter</button>
                    {/if}
                </p>
                
                {#if compositeUrl}
                    <div class="composite-preview">
                        <img src={compositeUrl} alt="QR Blotter" />
                        <a href={compositeUrl} download="qr-blotter.jpg" class="download-link">
                            Download A4 (210×297mm @ 300dpi)
                        </a>
                    </div>
                {/if}
                
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
    
    .composite-preview {
        background: white;
        padding: 1em;
        margin: 1em auto;
        max-width: 300px;
        border-radius: 0.5em;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    
    .composite-preview img {
        width: 100%;
        height: auto;
        border: 1px solid #ddd;
        display: block;
    }
    
    .download-link {
        display: block;
        margin-top: 0.5em;
        padding: 0.75em;
        background: #2563eb;
        color: white;
        text-decoration: none;
        text-align: center;
        border-radius: 0.25em;
        font-size: 0.9em;
    }
    
    .download-link:hover {
        background: #1d4ed8;
    }
    
    pqr {
        display: flex;
        background: white;
        padding: 0.5em;
        justify-content: center;
        align-items: center;
    }
    
    button, .blotter-link {
        padding: 1em;
        font-size: 1.5em;
    }
    
    .blotter-link {
        display: inline-block;
        background: #2563eb;
        color: white;
        text-decoration: none;
        border-radius: 0.25em;
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

    @media print {
        .noprint, .composite-preview {
            display: none !important;
        }
    }
</style>