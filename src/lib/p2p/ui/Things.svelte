<script lang="ts">
    import Thing from './Thing.svelte'

    interface ThingsProps {
        Ss: any // The collection (DirectoryShares, etc) with .things SvelteMap
        type: string           // e.g. "share", "playlist", "bookmark"
        title?: string        // Display title
        placeholder?: string   // Placeholder for add input
    }

    let {
        Ss,
        type,
        title = `${type}s`,
        placeholder = `Add ${type}...`
    }: ThingsProps = $props()

    // UI state
    let newItemName = $state('')
    let isLoading = $state(true)

    // Auto-start collection, respecting no_autostart
    $effect(() => {
        if (Ss && !Ss.started && !isLoading) {
            if (!Ss.no_autostart) {
                Ss.start?.()
            } else {
                isLoading = false // Don't auto-start but stop loading
            }
        } else if (Ss?.started) {
            isLoading = false
        }
    })

    async function addItem() {
        if (!newItemName.trim()) return
        
        const trimmedName = newItemName.trim()
        
        try {
            // Use the collection's spawn method
            if (Ss.spawn_share) {
                await Ss.spawn_share(trimmedName)
            } else if (Ss.addShare) {
                await Ss.addShare(trimmedName)
            } else if (Ss.add) {
                await Ss.add(trimmedName)
            }
            
            newItemName = ''
        } catch (err) {
            console.warn(`Failed to add ${type}:`, err)
        }
    }

    async function removeItem(name: string) {
        try {
            if (Ss.removeShare) {
                await Ss.removeShare(name)
            } else if (Ss.remove) {
                await Ss.remove(name)
            }
        } catch (err) {
            console.warn(`Failed to remove ${type}:`, err)
        }
    }

    function handleKeydown(event: KeyboardEvent) {
        if (event.key === 'Enter') {
            addItem()
        }
    }
</script>

<div class="things-container">
    <div class="things-header">
        <h3 class="things-title">{title}</h3>
        
        <!-- Collection-level actions -->
        {#if Ss?.actions}
            <div class="collection-actions">
                {#each Ss.actions as action}
                    <button 
                        onclick={action.handler}
                        class="collection-action-button"
                        style={action.style}
                    >
                        {action.label}
                    </button>
                {/each}
            </div>
        {/if}
    </div>
    
    {#if isLoading}
        <div class="loading">Loading {type}s...</div>
    {:else}
        <div class="things-list">
            {#each Ss.things as [name, S] (name)}
                <Thing 
                    {S}
                    {name}
                    {type}
                    onRemove={() => removeItem(name)}
                />
            {/each}
        </div>

        <div class="add-item">
            <input 
                bind:value={newItemName}
                onkeydown={handleKeydown}
                placeholder={placeholder}
                class="add-input"
            />
            <button 
                onclick={addItem}
                disabled={!newItemName.trim()}
                class="add-button"
            >
                Add
            </button>
        </div>
    {/if}
</div>

<style>
    .things-container {
        border: 1px solid #ddd;
        border-radius: 8px;
        padding: 1rem;
        margin: 0.5rem 0;
        background: rgba(255, 255, 255, 0.05);
    }

    .things-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.75rem;
    }

    .things-title {
        margin: 0;
        font-size: 1.1rem;
        font-weight: 600;
        color: #333;
        text-transform: capitalize;
    }

    .collection-actions {
        display: flex;
        gap: 0.5rem;
    }

    .collection-action-button {
        padding: 0.3rem 0.8rem;
        background: #2196F3;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.8rem;
        transition: background 0.2s;
    }

    .collection-action-button:hover {
        background: #1976D2;
    }

    /* Big action style for important actions */
    .collection-action-button[style*="big"] {
        padding: 0.5rem 1.2rem;
        font-size: 0.9rem;
        font-weight: 600;
    }

    .loading {
        color: #666;
        font-style: italic;
        padding: 1rem 0;
    }

    .things-list {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        margin-bottom: 1rem;
    }

    .add-item {
        display: flex;
        gap: 0.5rem;
        align-items: center;
    }

    .add-input {
        flex: 1;
        padding: 0.5rem;
        border: 1px solid #ccc;
        border-radius: 4px;
        font-size: 0.9rem;
    }

    .add-input:focus {
        outline: none;
        border-color: #4CAF50;
    }

    .add-button {
        padding: 0.5rem 1rem;
        background: #4CAF50;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.9rem;
        transition: background 0.2s;
    }

    .add-button:hover:not(:disabled) {
        background: #45a049;
    }

    .add-button:disabled {
        background: #ccc;
        cursor: not-allowed;
    }
</style>