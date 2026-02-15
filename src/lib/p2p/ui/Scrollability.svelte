<script lang="ts">
    import { throttle } from "$lib/Y";
    import type { Snippet } from "svelte";

    let { content,
          maxHeight = "100vh",
          class: className = ""
        }:{
        content: Snippet<[]>;
        maxHeight?: string;
        class?: string;
    } = $props();

    let scrollElement: HTMLDivElement;
    let needsScroll = $state(false);
    
    // Hysteresis: needs 20px overflow to enable scroll, 
    // but once enabled stays enabled until 20px under threshold
    let scrollState = $state({ needed: false, lastHeight: 0 });

    let checkScrollNeeded = throttle(() => {
        if (scrollElement) {
            const overflow = scrollElement.scrollHeight - scrollElement.clientHeight;
            const currentHeight = scrollElement.scrollHeight;
            
            // Add 20px hysteresis
            if (scrollState.needed) {
                // Already scrolling - need to be 20px under to disable
                if (overflow < -20) {
                    scrollState.needed = false;
                }
            } else {
                // Not scrolling - need to be 20px over to enable
                if (overflow > 20) {
                    scrollState.needed = true;
                }
            }
            
            scrollState.lastHeight = currentHeight;
            needsScroll = scrollState.needed;
        }
    }, 200);

    $effect(() => {
        if (scrollElement) {
            // Check initially
            checkScrollNeeded();
            
            // Watch for content changes
            const resizeObserver = new ResizeObserver(() => {
                checkScrollNeeded();
            });
            
            resizeObserver.observe(scrollElement);
            
            // Also watch for content mutations
            const mutationObserver = new MutationObserver(() => {
                checkScrollNeeded();
            });
            
            mutationObserver.observe(scrollElement, {
                childList: true,
                subtree: true
            });
            
            return () => {
                resizeObserver.disconnect();
                mutationObserver.disconnect();
            };
        }
    });
</script>

<div 
    class="scrollability {className}" 
    class:needs-scroll={needsScroll}
    style="max-height: {maxHeight}"
    bind:this={scrollElement}
>
    {@render content()}
</div>

<style>
    .scrollability {
        /* Base container - no overflow by default */
    }

    .scrollability.needs-scroll {
        overflow: auto;
    }
</style>