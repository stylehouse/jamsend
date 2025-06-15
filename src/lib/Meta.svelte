<script lang="ts">
    let {meta} = $props()
</script>

    <div class="meta-display">
        {#if meta.cover}
            <div class="cover-container">
                <img 
                    src={URL.createObjectURL(new Blob([meta.cover], {type: 'image/jpeg'}))} 
                    alt="Album cover"
                    class="cover-art"
                />
            </div>
        {/if}
        
        <div class="meta-info">
            {#if meta.title}
                <h2 class="title">{meta.title}</h2>
            {/if}
            
            {#if meta.artist}
                <div class="artist">by {meta.artist}</div>
            {/if}
            
            {#if meta.album}
                <div class="album">from "{meta.album}"</div>
            {/if}
            
            <div class="details">
                {#if meta.year}
                    <span class="year">{meta.year}</span>
                {/if}
                
                {#if meta.duration}
                    <span class="duration">
                        {Math.floor(meta.duration / 60)}:{String(Math.floor(meta.duration % 60)).padStart(2, '0')}
                    </span>
                {/if}
            </div>
        </div>
    </div>

<style>
    .meta-display {
        display: block;
        margin-bottom: 1rem;
        padding: 1rem;
        background: rgba(51, 90, 134, 0.1);
        border-radius: 0.5rem;
        border: 2px solid rgb(51, 90, 134);
    }
    
    .cover-container {
        width: 100%;
        margin-bottom: 1rem;
    }
    
    .cover-art {
        width: 100%;
        height: auto;
        object-fit: cover;
        border-radius: 0.3rem;
        border: 2px solid rgb(51, 90, 134);
    }
    
    .meta-info {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    
    .title {
        margin: 0;
        font-size: 1.2rem;
        font-weight: bold;
        color: rgb(51, 90, 134);
    }
    
    .artist {
        font-style: italic;
        opacity: 0.8;
    }
    
    .album {
        opacity: 0.7;
        font-size: 0.9rem;
    }
    
    .details {
        display: flex;
        gap: 1rem;
        margin-top: auto;
        font-size: 0.9rem;
        opacity: 0.7;
    }
</style>
