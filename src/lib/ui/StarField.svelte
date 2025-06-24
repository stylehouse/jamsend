<script lang="ts">
    import { onDestroy } from 'svelte';
    
    type propos = {gat:GatherStars, fullscreen?: boolean}
    let {gat, fullscreen = false}:propos = $props();
    let scrollContainer: HTMLDivElement;
    let viewport: HTMLDivElement;
    
    // Scroll dimensions - make it really wide for infinite scroll feel
    const SCROLL_WIDTH = 100000;
    
    $effect(() => {
        // Set initial scroll position to middle
        const initialScroll = SCROLL_WIDTH / 2;
        scrollContainer.scrollLeft = initialScroll;
        
        // Handle scroll events
        scrollContainer.addEventListener('scroll', handleScroll);

        // Add mouse event listeners for dragging
        scrollContainer.addEventListener('mousedown', handleMouseDown);
        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
        // Prevent default drag behavior on images/text
        scrollContainer.addEventListener('dragstart', (e) => e.preventDefault());
    });

    onDestroy(() => {
        scrollContainer?.removeEventListener('scroll', handleScroll);
        scrollContainer?.removeEventListener('mousedown', handleMouseDown);
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
        scrollContainer?.removeEventListener('dragstart', (e) => e.preventDefault());
    })
    
    function viewportWidth() {
        return scrollContainer ? scrollContainer.clientWidth : 0
    }
    function handleScroll() {
        if (!gat || !scrollContainer) return;
        
        // Convert scroll position to normalized position
        const scrollLeft = scrollContainer.scrollLeft;
        const maxScroll = SCROLL_WIDTH - viewportWidth();
        const normalizedScroll = scrollLeft / maxScroll;
        let distance_from_center = 0.5 - normalizedScroll
        // supposedly how many StarFields in a gat.field, spanning SCROLL_WIDTH
        let expanse = 5000
        // how many pixels wide is a field
        let scale = SCROLL_WIDTH / expanse

        let location = distance_from_center * scale
        // and player is centered
        location += 0.5

        
        
        gat.position = location
        console.log("Loca: "+gat.position,{
            location:location.toFixed(2)
        })
        gat.look();
        
        // Handle infinite scroll wrap-around
        if (scrollLeft < 1000) {
            // Scrolled near the left edge, jump to right side
            scrollContainer.scrollLeft = SCROLL_WIDTH - 2000;
            console.log("Wrapping left")
        } else if (scrollLeft > SCROLL_WIDTH - 1000) {
            // Scrolled near the right edge, jump to left side
            scrollContainer.scrollLeft = 2000;
            console.log("Wrapping right")
        }
    }







    let isDragging = false;
    let lastMouseX = 0;
    let dragVelocity = 0;
    let lastDragTime = 0;
    
    // Mouse drag handlers
    function handleMouseDown(e) {
        isDragging = true;
        lastMouseX = e.clientX;
        scrollContainer.style.cursor = 'grabbing';
        // Prevent text selection during drag
        document.body.style.userSelect = 'none';
    }

    function handleMouseMove(e) {
        if (!isDragging) return;
        
        const deltaX = e.clientX - lastMouseX;
        
        // Apply drag movement (invert for natural feel)
        scrollContainer.scrollLeft -= deltaX*5;
        
        lastMouseX = e.clientX;
    }

    function handleMouseUp() {
        if (!isDragging) return;
        
        isDragging = false;
        scrollContainer.style.cursor = 'grab';
        document.body.style.userSelect = '';
    }




    


    // Calculate the offset for each field relative to current position
    function getFieldOffset(fieldIndex: number) {
        const fieldOffset = fieldIndex - gat.position;
        return `${fieldOffset * 100}%`;
    }

    let local_space = $derived(gat.local_space || {})
</script>

<div class="starfield-container">
    <!-- Scroll container for horizontal movement -->
    <div 
        bind:this={scrollContainer}
        class="scroll-container"
    >
        <div 
            class="scroll-content" 
            style="width: {SCROLL_WIDTH}px;"
        ></div>
    </div>
    
{#if gat.local_space}
    <!-- Fixed viewport overlay for stars and player -->
    <div bind:this={viewport} class="viewport">
        <!-- Render StarFields from gat.local_space -->
        {#each local_space as field, i (i)}
            {#if field}
                <div 
                    class="starfield-block"
                    style="left: {getFieldOffset(field.index)};"
                >
                    <!-- Render stars within this field -->
                    {#each field.stars as star}
                        <div 
                            class="star"
                            class:active={star.isActive}
                            style="
                                left: {star.x * 100}%;
                                top: {star.y * 100}%;
                                font-size: {star.size * 0.25}em;
                                opacity: {star.brightness};
                            "
                        >
                            ☯
                        </div>
                    {/each}
                </div>
            {/if}
        {/each}
        
        <!-- Player in center -->
        <div class="player">☯</div>
        
        <!-- Scroll hints -->
        <div class="scroll-hint">←</div>
        <div class="scroll-hint right">→</div>
    </div>
    
    <!-- UI overlays -->
    <div class="info-overlay">
        <div>Scroll horizontally to explore the cosmos</div>
        <div>Field: {Math.floor(gat.position)}</div>
        {#if gat.star_visiting}
            <div>♪ Tuned to star at ({gat.star_visiting.x.toFixed(2)}, {gat.star_visiting.y.toFixed(2)})</div>
        {/if}
    </div>
    
    <div class="position-info">
        <div>Position: {gat.position?.toFixed(2) || '0.00'}</div>
        <div>Fields loaded: {gat.local_space.filter(f => f).length}</div>
        <div>Total stars: {gat.local_space.reduce((sum, f) => sum + (f?.stars?.length || 0), 0)}</div>
    </div>
{/if}
</div>

<style>
    .starfield-container {
        position: relative;
        width: 100%;
        height: 100vh;
        overflow: hidden;
        max-height: 14em;
        background: radial-gradient(ellipse at center, #001122 0%, #000008 100%);
    }
    
    .scroll-container {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        overflow-x: auto; /* Enable horizontal scrolling */
        overflow-y: hidden; /* Disable vertical scrolling */
        scrollbar-width: none; /* Firefox - hide scrollbar */
        -ms-overflow-style: none; /* IE/Edge - hide scrollbar */
    }
    .scroll-container::-webkit-scrollbar {
        display: none; /* Webkit browsers - hide scrollbar */
    }
    
    .scroll-content {
        height: 100%;
    }
    
    .viewport {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        pointer-events: none;
        z-index: 10;
    }
    
    .starfield-block {
        position: absolute;
        top: 0;
        width: 100%;
        height: 100%;
        /* pointer-events: none; */
        border:2px solid burlywood;
        border-radius:2em;
    }
    
    .star {
        position: absolute;
        font-size: 20px;
        color: white;
        text-shadow: 0 0 10px currentColor;
        transform: translate(-50%, -50%);
        transition: all 0.3s ease;
        user-select: none;
    }
    
    .star.active {
        color: #ffff88;
        font-size: 28px;
        text-shadow: 0 0 20px currentColor, 0 0 40px rgba(255, 255, 136, 0.3);
        animation: pulse 2s ease-in-out infinite alternate;
    }
    
    @keyframes pulse {
        from { 
            text-shadow: 0 0 20px currentColor, 0 0 40px rgba(255, 255, 136, 0.3);
        }
        to { 
            text-shadow: 0 0 30px currentColor, 0 0 60px rgba(255, 255, 136, 0.5);
        }
    }
    
    .player {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        font-size: 32px;
        color: #88ff88;
        text-shadow: 0 0 15px currentColor, 0 0 30px rgba(136, 255, 136, 0.4);
        z-index: 20;
        user-select: none;
    }
    
    .info-overlay {
        position: fixed;
        bottom: 20px;
        left: 20px;
        color: #88ffaa;
        font-family: 'Courier New', monospace;
        font-size: 14px;
        text-shadow: 0 0 5px currentColor;
        pointer-events: none;
        z-index: 30;
    }
    
    .position-info {
        position: fixed;
        top: 20px;
        right: 20px;
        color: #88ccff;
        font-family: 'Courier New', monospace;
        font-size: 14px;
        text-shadow: 0 0 5px currentColor;
        pointer-events: none;
        z-index: 30;
    }
    
    .scroll-hint {
        position: fixed;
        top: 50%;
        left: 20px;
        transform: translateY(-50%);
        color: #ffffff44;
        font-size: 24px;
        animation: fade-pulse 3s ease-in-out infinite;
        pointer-events: none;
        z-index: 25;
    }
    
    .scroll-hint.right {
        left: auto;
        right: 20px;
    }
    
    @keyframes fade-pulse {
        0%, 100% { opacity: 0.3; }
        50% { opacity: 0.8; }
    }
    
    /* Hide scrollbar but keep functionality */
    .scroll-container::-webkit-scrollbar {
        display: none;
    }
    
    .scroll-container {
        -ms-overflow-style: none;
        scrollbar-width: none;
    }
</style>