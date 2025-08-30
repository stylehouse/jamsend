<script lang="ts">
    import type { Snippet } from "svelte";

    interface ScrollabilityProps {
        content: Snippet<[]>;
        maxHeight?: string;
        class?: string;
    }

    let { content, maxHeight = "100vh", class: className = "" }: ScrollabilityProps = $props();

    let scrollElement: HTMLDivElement;
    let needsScroll = $state(false);

    function checkScrollNeeded() {
        if (scrollElement) {
            needsScroll = scrollElement.scrollHeight > scrollElement.clientHeight;
        }
    }

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