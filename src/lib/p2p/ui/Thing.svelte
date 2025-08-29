<script lang="ts">
    import Thingness from './Thingness.svelte'

    interface ThingProps {
        S: any // The ThingIsms instance (DirectoryShare, etc)
        name: string
        type: string
        onRemove: () => void
    }

    let { S, name, type, onRemove }: ThingProps = $props()

    function handleRemove() {
        if (confirm(`Remove ${type} "${name}"?`)) {
            onRemove()
        }
    }
</script>

<div 
    class="thing-item" 
    data-type={type}
    class:started={S.started}
    class:needs-attention={S.no_autostart}
>
    <div class="thing-content">
        <div class="thing-name-row">
            <span class="thing-name">{name}</span>
        </div>
        
        <div class="thing-meta">
            <span class="thing-type">{type}</span>
        </div>
    </div>
    
    <div class="thing-controls">
        <Thingness {S} {type} />
        
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

    .thing-item.started {
        border-left: 4px solid #4CAF50;
        background: rgba(76, 175, 80, 0.05);
    }

    .thing-item.needs-attention {
        border-left: 4px solid #FF9800;
        background: rgba(255, 152, 0, 0.05);
    }

    .thing-content {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
    }

    .thing-name-row {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .thing-name {
        font-weight: 500;
        color: #333;
        font-size: 0.95rem;
    }

    .status-indicators {
        display: flex;
        align-items: center;
    }

    .status-badge {
        font-size: 0.8rem;
        font-weight: bold;
    }

    .status-badge.started {
        color: #4CAF50;
    }

    .status-badge.stopped {
        color: #666;
    }

    .status-badge.attention {
        color: #FF9800;
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

    .thing-state {
        font-size: 0.75rem;
        color: #888;
        font-style: italic;
    }

    .thing-controls {
        display: flex;
        gap: 0.3rem;
        align-items: center;
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
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: all 0.2s ease;
    }

    .remove-button:hover {
        background: #d32f2f;
        transform: scale(1.1);
    }

    /* Type-specific styling */
    .thing-item[data-type="share"] {
        border-left: 2px solid #4CAF50;
    }

    .thing-item[data-type="playlist"] {
        border-left: 2px solid #9C27B0;
    }

    .thing-item[data-type="bookmark"] {
        border-left: 2px solid #FF9800;
    }
</style>