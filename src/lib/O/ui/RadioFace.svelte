<script lang="ts">
    // RadioFace — the radio's face in the glass: mounted by Cytui on a %Radio particle wearing
    //  sc.face:'Radio' (glass_kinds.ts).  Reads the particle's sc each H.version bump; the
    //   buttons call the Radio ghost's verbs straight on H (ghost methods mix onto the House).
    //  Pointer events: the overlay div is pointer-events:none (the glass must stay pannable),
    //   so ONLY the buttons re-arm them — a drag anywhere else falls through to the graph.
    let { n, H } = $props()

    // the second-hand: sc.at is written WITHOUT a version bump (a bump/sec would re-tessellate
    //  the glass), so the face polls its own clock — H.version still folds in real changes.
    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let face = $derived.by(() => {
        void H?.version
        void tick
        const sc = n?.sc ?? {}
        // the first-time read: never played, nothing dialed — teach what ▶ will do, using the
        //  stoker's census (stock standing = the preheat already dug) so the promise is honest.
        const stock = +((n?.c?.w?.o?.({ Stoker: 1 })?.[0]?.sc?.stock) ?? 0)
        // the POOL: friend tracks standing in the %MusuThem mirrors (the live share fill) —
        //  the radio dials across them too, and the face says so only when it's true.
        let pool = 0
        for (const home of (n?.c?.w?.o?.({ MusuThem: 1 }) ?? [])) {
            pool += home?.o?.({ stock: 1 })?.[0]?.o?.({ Record: 1 })?.length ?? 0
        }
        return {
            pool,
            state:  (sc.Radio as string) ?? 'off',
            title:  sc.title as string | undefined,
            artist: sc.artist as string | undefined,
            at:     +(sc.at ?? 0),
            of:     +(sc.of ?? 0),
            played: +(sc.played ?? 0),
            drops:  +(sc.drops ?? 0),
            note:   sc.note as string | undefined,
            first:  ((sc.Radio ?? 'off') === 'off') && !sc.title && !+(sc.played ?? 0),
            stock,
        }
    })

    const mmss = (s: number) => {
        const m = Math.floor(s / 60), r = Math.floor(s % 60)
        return `${m}:${r < 10 ? '0' : ''}${r}`
    }
    const ICON: Record<string, string> = { off: '📻', digging: '⛏', playing: '♪', paused: '⏸', starved: '…' }
</script>

<div class="rf" class:on={face.state === 'playing'}>
    <div class="rf-row">
        <button class="rf-btn" onclick={() => (H as any)?.Radio_toggle?.(n)}
            title={face.state === 'playing' ? 'pause' : 'play'}>
            {face.state === 'playing' || face.state === 'digging' || face.state === 'starved' ? '⏸' : '▶'}
        </button>
        <div class="rf-mid">
            <div class="rf-title">{ICON[face.state] ?? '📻'} {face.title ?? 'the radio'}</div>
            {#if face.artist}<div class="rf-artist">{face.artist}</div>{/if}
            {#if face.note}<div class="rf-note">{face.note}</div>{/if}
        </div>
        <button class="rf-btn rf-skip" onclick={() => (H as any)?.Radio_skip?.(n)} title="next">⏭</button>
        {#if face.title}
            <button class="rf-btn rf-skip" onclick={() => (H as any)?.Radio_mag_pop?.(n?.c?.w, n?.c?.rec)}
                title="pop this track into your Faves mag">★</button>
        {/if}
    </div>
    {#if face.of > 0}
        <div class="rf-bar"><div class="rf-fill" style="width:{Math.min(100, 100 * face.at / face.of)}%"></div></div>
        <div class="rf-time">{mmss(face.at)} / {mmss(face.of)}
            {#if face.played > 0}&nbsp;· {face.played} played{/if}
            {#if face.drops > 0}&nbsp;· {face.drops} drops{/if}</div>
    {:else if face.state === 'digging'}
        <div class="rf-time">digging the crates…</div>
    {:else if face.first}
        <div class="rf-time">{face.pool > 0 ? `▶ plays the pool — ${face.stock} of yours + ${face.pool} from friends` : face.stock > 0 ? `▶ plays your music — ${face.stock} records stand ready` : '▶ starts the radio — the stoker will dig your share'}</div>
    {/if}
    {#if face.pool > 0 && !face.first}
        <div class="rf-time">⚯ {face.pool} friend {face.pool === 1 ? 'track rides' : 'tracks ride'} the dial</div>
    {/if}
</div>

<style>
    .rf {
        pointer-events: none;
        width: max-content;
        max-width: 300px;
        padding: 8px 12px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e8dcc0;
        text-align: left;
    }
    .rf-row { display: flex; align-items: center; gap: 8px; }
    .rf-btn {
        pointer-events: auto;
        cursor: pointer;
        background: #1a2f38;
        color: #e8dcc0;
        border: 1px solid #d9a026;
        border-radius: 50%;
        width: 34px;
        height: 34px;
        font-size: 14px;
        line-height: 1;
        flex: none;
    }
    .rf-btn:hover { background: #d9a026; color: #04202a; }
    .rf-skip { width: 26px; height: 26px; font-size: 10px; }
    .rf-mid { min-width: 90px; }
    .rf-title { font-size: 12px; font-weight: 700; }
    .rf-artist { font-size: 10px; opacity: 0.8; }
    .rf-note { font-size: 9px; opacity: 0.6; font-style: italic; }
    .rf-bar {
        margin-top: 6px;
        height: 3px;
        background: #1a2f38;
        border-radius: 2px;
        overflow: hidden;
    }
    .rf-fill { height: 100%; background: #d9a026; transition: width 0.4s linear; }
    .rf-time { font-size: 9px; opacity: 0.7; margin-top: 3px; }
    .on .rf-title { color: #ffd869; }
</style>
