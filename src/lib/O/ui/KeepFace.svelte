<script lang="ts">
    // KeepFace — the ⇊ "keep what you're hearing" heist AS A TIDY VYTO CELL (the human 2026-07-28: "I DO
    //  want the Heist UI ... in a few Vyto cells ... nodulate down the folder hierarchy ... it can be left
    //   to sit there, you don't have to click start, it'll assume that at some point ... it folds down when
    //    started").  One face per %Keep (FACE_MAINKEYS/glass_kinds, imposed by mainkey — no %Keep wears
    //     sc.face).  NOT fullscreen: it sits in the clutter while PRIMED (the folder shown as a node tree so
    //      you can tweak the filing genre + un/keep tracks), then FOLDS DOWN to a compact progress strip once
    //       it auto-starts pulling at end-of-track.  Props { n, H } — n is the LIVE %Keep particle.
    let { n, H } = $props()
    const A = H as any

    // the describe round-trip + the pull both land off the beat (a C-tree mutation on the tick), which a
    //  bare H.version derive can miss between bumps — poll a slow clock beside it (the HeistFace/IdHatch idiom).
    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 500); return () => clearInterval(iv) })

    function dirOf(path: string): string {
        const parts = String(path || '').split('/').filter(Boolean)
        parts.pop()
        return parts.join('/')
    }
    function fileOf(path: string, fallback: string): string {
        const parts = String(path || '').split('/').filter(Boolean)
        return parts.pop() || fallback
    }

    let face = $derived.by(() => {
        void H?.version
        void tick
        const sc = n?.sc ?? {}
        const state = String(sc.state || 'primed')
        const seed = String(sc.seed || '')
        const at = String(sc.at || '')
        const rw = A?.top_House?.()?.c?.radio_w
        const mir = (rw && at) ? A?.Ra_home_them?.(rw, at) : null
        // the folder husks the SOURCE described back (metadata-only, tagged rummage:<seed>).  Nodulate by
        //  DIRECTORY: group tracks under their folder node instead of a flat right-aligned filename list.
        const husks = (mir && A?.Heist_rummage_recs) ? A.Heist_rummage_recs(mir, seed) : []
        const picks = n?.o?.({ Pick: 1 }) ?? []
        const pickedRefs = new Set(picks.map((p: any) => String(p.sc.ref ?? p.sc.id)))
        const groups: Record<string, any[]> = {}
        for (const r of husks) {
            const path = String(r.sc.path || '')
            const dir = dirOf(path) || '·'
            ;(groups[dir] = groups[dir] || []).push({
                ref: String(r.sc.id),
                title: String(r.sc.title || fileOf(path, String(r.sc.id))),
                file: fileOf(path, String(r.sc.title || r.sc.id)),
                artist: String(r.sc.artist || ''),
                kept: pickedRefs.has(String(r.sc.id)),
                seed: String(r.sc.re || '') === seed,
            })
        }
        const tree = Object.keys(groups).sort().map((dir) => ({
            dir,
            label: dir === '·' ? '(loose files)' : dir.split('/').filter(Boolean).join(' › '),
            tracks: groups[dir].sort((a: any, b: any) => a.file.localeCompare(b.file)),
        }))
        const genre = String(sc.genre || 'Unfiled')
        return {
            state,
            title: String(sc.Keep || 'this track'),
            from: String(sc.from_name || 'a friend'),
            genre,
            dest: 'music/' + safe(genre) + '/',
            asks: +(sc.asks || 0),
            tree,
            nTracks: husks.length,
            picked: pickedRefs.size,
            landed_n: +(sc.landed_n || 0),
            total_n: +(sc.total_n || 0),
            folded: state === 'pulling' || state === 'committing' || state === 'done',
        }
    })

    // the genre a track files under — one keystroke (a datalist), applied to the pull's filing decision.
    const GENRES = ['Unfiled', 'Ambient', 'Jazz', 'Electronic', 'Rock', 'Hip Hop', 'Folk', 'Classical']
    function setGenre(v: string) {
        A?.post_do?.(() => { A?.Heist_keep_set_genre?.(n, v) }, { see: 'keep genre' })
    }
    function toggle(ref: string) {
        A?.post_do?.(() => { A?.Heist_keep_pick_toggle?.(n, ref) }, { see: 'keep pick' })
    }
    function cancel() {
        A?.post_do?.(() => { A?.Heist_keep_cancel?.(A?.top_House?.()?.c?.radio_w, n) }, { see: 'keep cancel' })
    }
    function pickAll() { A?.post_do?.(() => { A?.Heist_keep_pick_all?.(n) }, { see: 'keep all' }) }
    function pickNone() { A?.post_do?.(() => { A?.Heist_keep_pick_none?.(n) }, { see: 'keep none' }) }
    function start() { A?.post_do?.(() => { A?.Heist_keep_start?.(n) }, { see: 'keep start' }) }
</script>

<div class="kf" class:folded={face.folded}>
    <div class="kf-head">
        <span class="kf-badge">{face.state === 'done' ? '✓' : '⇊'}</span>
        <span class="kf-title" title={face.title}>{face.title}</span>
        <span class="kf-from">from {face.from}</span>
    </div>

    {#if face.folded}
        <!-- FOLDED: it started — a compact progress strip, no browsing -->
        <div class="kf-prog">
            {#if face.state === 'done'}
                ✓ kept {face.landed_n} → {face.dest}
            {:else}
                downloading {face.landed_n}/{face.total_n || '?'} tracks → {face.dest}
            {/if}
        </div>
    {:else}
        <!-- PRIMED: sits in the clutter, tweakable, until it auto-starts at end-of-track -->
        <div class="kf-file">
            <span class="kf-dim">file under</span>
            <input class="kf-genre" list="kf-genres" value={face.genre}
                onchange={(e: any) => setGenre(e.currentTarget.value)} />
            <datalist id="kf-genres">{#each GENRES as g}<option value={g}></option>{/each}</datalist>
        </div>
        <div class="kf-dest" title="where these land — the artist/album folders ride underneath">⤓ {face.dest}<span class="kf-dim"> …artist / album</span></div>
        {#if face.tree.length}
            <div class="kf-sel">
                <span class="kf-dim">{face.picked} of {face.nTracks}</span>
                <button class="kf-mini" onclick={pickAll} title="keep every track">all</button>
                <button class="kf-mini" onclick={pickNone} title="keep none">none</button>
            </div>
            {#each face.tree as grp}
                <div class="kf-dir">📁 {grp.label}</div>
                {#each grp.tracks as t}
                    <button class="kf-track" class:kept={t.kept} class:seed={t.seed} onclick={() => toggle(t.ref)}
                        title={t.seed ? 'the track you\'re hearing' : (t.kept ? 'keeping — click to skip' : 'skipped — click to keep')}>
                        <span class="kf-tick">{t.kept ? '✓' : '·'}</span>
                        <span class="kf-tname">{t.title}{#if t.seed} ♪{/if}</span>
                    </button>
                {/each}
            {/each}
        {:else}
            <div class="kf-note">
                {#if face.asks > 1}looking through the album… ({face.asks}){:else}reading the album it came from…{/if}
            </div>
        {/if}
        <div class="kf-foot">
            <button class="kf-start" onclick={start} title="download now instead of waiting for the track to end">▶ start</button>
            <span class="kf-dim">will auto-start at track end</span>
            <button class="kf-x" onclick={cancel} title="don't keep — drop this">✕</button>
        </div>
    {/if}
</div>

<style>
    /* the voronoi cell bbox overlaps its neighbours, so the ROOT must not eat pointer events; each
       button re-arms pointer-events (the HeistFace hard contract). */
    .kf {
        pointer-events: none;
        width: max-content;
        max-width: 300px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e0cfd8;
        text-align: left;
    }
    .kf.folded { max-width: 220px; opacity: 0.92; }
    .kf-head { display: flex; align-items: baseline; gap: 6px; }
    .kf-badge { font-size: 12px; color: #7fe8bf; }
    .kf-title { font-size: 12px; font-weight: 700; color: #e8a9c0; max-width: 180px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .kf-from { font-size: 9px; opacity: 0.6; }
    .kf-prog { font-size: 10px; opacity: 0.85; color: #7fe8bf; margin-top: 3px; }
    .kf-file { display: flex; align-items: center; gap: 5px; margin-top: 4px; }
    .kf-dim { font-size: 9px; opacity: 0.55; }
    .kf-genre {
        pointer-events: auto;
        background: #241820;
        color: #f0dbe6;
        border: 1px solid #66495a;
        border-radius: 6px;
        font-size: 10px;
        padding: 1px 6px;
        width: 110px;
    }
    .kf-dest { font-size: 9px; margin-top: 3px; color: #7fe8bf; font-family: monospace; }
    .kf-sel { display: flex; align-items: center; gap: 6px; margin-top: 5px; }
    .kf-mini {
        pointer-events: auto; cursor: pointer;
        background: #241820; color: #cbb; border: 1px solid #66495a; border-radius: 6px;
        font-size: 9px; padding: 0 6px; line-height: 1.5;
    }
    .kf-mini:hover { background: #66495a; color: #fff; }
    .kf-start {
        pointer-events: auto; cursor: pointer;
        background: #1f3a2a; color: #9fe8bf; border: 1px solid #3f9a6a; border-radius: 8px;
        font-size: 10px; padding: 1px 9px; line-height: 1.4; flex: none; font-weight: 600;
    }
    .kf-start:hover { background: #57c777; color: #04202a; }
    .kf-dir { font-size: 9px; opacity: 0.7; margin-top: 4px; color: #cfc0d8; }
    .kf-track {
        pointer-events: auto;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 5px;
        width: 100%;
        background: transparent;
        border: none;
        color: inherit;
        font: inherit;
        font-size: 10px;
        padding: 1px 2px 1px 10px;
        text-align: left;
        opacity: 0.55;
    }
    .kf-track.kept { opacity: 1; }
    .kf-track.seed .kf-tname { color: #7fe8bf; }
    .kf-tick { width: 8px; color: #7fe8bf; }
    .kf-tname { max-width: 210px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .kf-note { font-size: 9px; opacity: 0.6; font-style: italic; margin-top: 3px; }
    .kf-foot { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-top: 5px; }
    .kf-x {
        pointer-events: auto;
        cursor: pointer;
        background: #38141f;
        color: #e8a9c0;
        border: 1px solid #a03f5a;
        border-radius: 7px;
        font-size: 9px;
        padding: 0 6px;
        line-height: 1.5;
        flex: none;
    }
    .kf-x:hover { background: #d94f7a; color: #1a0810; }
</style>
