<script lang="ts">
    let {meta,nocover} = $props()
</script>

    <div class="meta-display">
        <div class="track-info">
            <h3 class="title">{meta.title}</h3>
            <p>
                <span class="artist">{meta.artist}</span>
                 •
                <span class="album">{meta.album}</span>
                {meta.year ? `(${meta.year})` : ""}
                <!-- {aud?.id.slice(0,8)} -->
            </p>
            
            <div class="details">
                <!-- {#if meta.duration}
                    <span class="duration">
                        {Math.floor(meta.duration / 60)}:{String(Math.floor(meta.duration % 60)).padStart(2, '0')}
                    </span>
                {/if} -->
            </div>
        </div>

        {#if meta.cover && !nocover}
            <div class="cover-container">
                <img 
                    src={URL.createObjectURL(new Blob([meta.cover], {type: 'image/jpeg'}))} 
                    alt="Album cover"
                    class="cover-art"
                />
            </div>
        {/if}
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
    
    .track-info {
        margin-bottom: 1rem;
    }

    .track-info h3 {
        margin: 0;
        font-size: 1.2rem;
        font-weight: bold;
        color: rgb(51, 90, 134);
    }
    .track-info * {
        display: inline-block;
    }

    .track-info p {
        margin: 0.5rem 0 0;
        color: #666;
        font-size: 0.9rem;
    }
    
    .title {
    }
    .artist {
        font-size: 1.1rem;
        font-style: italic;
        opacity: 0.9;
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
