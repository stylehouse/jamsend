
<script lang="ts">
    interface ThingProps {
        name: string
        type: string
        onRemove: () => void
        actions?: Array<{label: string, handler: () => void}> // Future extensibility
    }

    let { name, type, onRemove, actions = [] }: ThingProps = $props()

    function handleRemove() {
        if (confirm(`Remove ${type} "${name}"?`)) {
            onRemove()
        }
    }
</script>

<div class="thing-item" data-type={type}>
    <div class="thing-content">
        <span class="thing-name">{name}</span>
        <div class="thing-meta">
            <span class="thing-type">{type}</span>
        </div>
    </div>
    
    <div class="thing-actions">
        {#each actions as action}
            <button 
                onclick={action.handler}
                class="action-button"
                title={action.label}
            >
                {action.label}
            </button>
        {/each}
        
        <button 
            onclick={handleRemove}
            class="remove-button"
            title="Remove {type}"
        >
            ×
        </button>
    </div>
</div>

<style>
    .thing-item {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0.5rem 0.75rem;
        border: 1px solid #e0e0e0;
        border-radius: 6px;
        background: rgba(255, 255, 255, 0.8);
        transition: all 0.2s ease;
    }

    .thing-item:hover {
        background: rgba(255, 255, 255, 0.95);
        border-color: #ccc;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .thing-content {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
    }

    .thing-name {
        font-weight: 500;
        color: #333;
        font-size: 0.95rem;
    }

    .thing-meta {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .thing-type {
        font-size: 0.8rem;
        color: #666;
        background: #f0f0f0;
        padding: 0.2rem 0.4rem;
        border-radius: 3px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }

    .thing-actions {
        display: flex;
        gap: 0.3rem;
        align-items: center;
    }

    .action-button, .remove-button {
        padding: 0.3rem 0.6rem;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.8rem;
        transition: all 0.2s ease;
    }

    .action-button {
        background: #2196F3;
        color: white;
    }

    .action-button:hover {
        background: #1976D2;
    }

    .remove-button {
        background: #f44336;
        color: white;
        font-weight: bold;
        width: 24px;
        height: 24px;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
    }

    .remove-button:hover {
        background: #d32f2f;
        transform: scale(1.1);
    }

    /* Type-specific styling */
    .thing-item[data-type="share"] {
        border-left: 4px solid #4CAF50;
    }

    .thing-item[data-type="playlist"] {
        border-left: 4px solid #9C27B0;
    }

    .thing-item[data-type="bookmark"] {
        border-left: 4px solid #FF9800;
    }
</style>