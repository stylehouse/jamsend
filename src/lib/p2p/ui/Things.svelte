<script lang="ts">
    import { CollectionStorage } from '$lib/data/IndexedDBStorage'
    import Thing from './Thing.svelte'

    interface ThingsProps {
        type: string           // e.g. "share", "playlist", "bookmark"
        pfId: string          // PierFeature identifier for scoping
        defaultItems?: string[] // Items to create if empty
        placeholder?: string   // Placeholder for add input
        title?: string        // Display title
    }

    let {
        type,
        pfId,
        defaultItems = [],
        placeholder = `Add ${type}...`,
        title = `${type}s`
    }: ThingsProps = $props()

    // Living reactive state
    let items: string[] = $state([])
    let newItemName = $state('')
    let storage: CollectionStorage<string>
    let isLoading = $state(true)

    // Initialize storage and load items
    async function initialize() {
        storage = new CollectionStorage(`peerily-${type}s`, `pf-${type}s-${pfId}`)
        
        try {
            const existingItems = await storage.getAll()
            
            if (existingItems.length === 0 && defaultItems.length > 0) {
                // Autovivify with defaults
                for (const item of defaultItems) {
                    await storage.add(item, item)
                }
                items = [...defaultItems]
            } else {
                items = existingItems
            }
        } catch (err) {
            console.warn(`Failed to initialize ${type}s:`, err)
            items = [...defaultItems] // Fallback to defaults
        }
        
        isLoading = false
    }

    // Auto-save when items change
    $effect(() => {
        if (!isLoading && storage && items) {
            saveItems()
        }
    })

    async function saveItems() {
        try {
            // Clear and re-populate (simple approach)
            await storage.clear()
            for (const item of items) {
                await storage.add(item, item)
            }
        } catch (err) {
            console.warn(`Failed to save ${type}s:`, err)
        }
    }

    async function addItem() {
        if (!newItemName.trim()) return
        
        const trimmedName = newItemName.trim()
        if (items.includes(trimmedName)) return // Avoid duplicates
        
        items = [...items, trimmedName]
        newItemName = ''
    }

    function removeItem(itemName: string) {
        items = items.filter(item => item !== itemName)
    }

    function handleKeydown(event: KeyboardEvent) {
        if (event.key === 'Enter') {
            addItem()
        }
    }

    // Initialize on mount
    initialize()
</script>

<div class="things-container">
    <h3 class="things-title">{title}</h3>
    
    {#if isLoading}
        <div class="loading">Loading {type}s...</div>
    {:else}
        <div class="things-list">
            {#each items as item (item)}
                <Thing 
                    name={item} 
                    {type}
                    onRemove={() => removeItem(item)}
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

    .things-title {
        margin: 0 0 0.75rem 0;
        font-size: 1.1rem;
        font-weight: 600;
        color: #333;
        text-transform: capitalize;
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
