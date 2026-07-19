<script lang="ts">
    // RiffFace — ONE card of the riffle's spread, a cell of its own (the display system: the
    //  deck deals CELLS, never rows inside a panel).  Three shapes by the mainkey's value:
    //   a track (▶ tunes it — stocking on demand when only a path stands), a folder (open
    //    descends + re-deals the level), and '..' (climb).  The card is pointer-events:none,
    //     only its button re-arms — the glass stays pannable.
    let { n, H } = $props()

    let face = $derived.by(() => {
        void H?.version
        const sc = n?.sc ?? {}
        const v = sc.Riff
        return {
            kind: v === 'dir' ? 'dir' : v === 'up' ? 'up' : 'track',
            title: sc.title as string | undefined,
            artist: sc.artist as string | undefined,
            tuning: !!sc.tuning,
            note: sc.note as string | undefined,
        }
    })
    function act() {
        if (face.kind === 'track') (H as any)?.Riffle_tune?.(n)
        else (H as any)?.Riffle_enter?.(n)
    }
    // ★ pops a STANDING record into the Faves mag — path-only cards earn it once tuned
    let has_rec = $derived.by(() => { void H?.version; return !!n?.c?.rec })
    function pop() { (H as any)?.Radio_mag_pop?.(n?.c?.up?.c?.w, n?.c?.rec) }
</script>

<div class="rc" class:folder={face.kind !== 'track'}>
    <button class="rc-act" onclick={act}
        title={face.kind === 'track' ? 'play this now' : face.kind === 'up' ? 'up a folder' : 'open this folder'}>
        {face.kind === 'track' ? (face.tuning ? '⏳' : '▶') : face.kind === 'up' ? '⬆' : '📁'}
    </button>
    <span class="rc-name">{face.title ?? '…'}{#if face.artist}<span class="rc-artist">&nbsp;— {face.artist}</span>{/if}</span>
    {#if face.kind === 'track' && has_rec}
        <button class="rc-act rc-star" onclick={pop} title="pop into your Faves mag">★</button>
    {/if}
    {#if face.note}<span class="rc-note">{face.note}</span>{/if}
</div>

<style>
    .rc {
        pointer-events: none;
        display: flex;
        align-items: center;
        gap: 5px;
        width: max-content;
        max-width: 210px;
        padding: 4px 8px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e0d2ee;
    }
    .rc.folder { color: #cbb98a; }
    .rc-act {
        pointer-events: auto;
        cursor: pointer;
        background: #241733;
        color: #b797dd;
        border: 1px solid #8a6fae;
        border-radius: 50%;
        width: 22px;
        height: 22px;
        font-size: 10px;
        line-height: 1;
        flex: none;
    }
    .rc.folder .rc-act { border-color: #a08a4f; color: #cbb98a; background: #2a2314; }
    .rc-act:hover { background: #8a6fae; color: #16091f; }
    .rc.folder .rc-act:hover { background: #a08a4f; color: #16091f; }
    .rc-star { width: 18px; height: 18px; font-size: 8px; opacity: 0.7; }
    .rc-star:hover { opacity: 1; }
    .rc-name { font-size: 10px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 170px; }
    .rc-artist { opacity: 0.7; font-size: 9px; }
    .rc-note { font-size: 8px; opacity: 0.6; font-style: italic; }
</style>
