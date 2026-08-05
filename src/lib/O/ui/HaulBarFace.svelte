<script lang="ts">
    // HaulBarFace — the CONTROLS cell of a nested %Haul (the human 2026-07-28 "one for the hierarchy, one for
    //  the list of tracks").  Under the nested glass the %Haul parent goes BARE (Vytui suppresses a scope's own
    //   face), so the chrome HaulFace used to carry — the title/from header, the filing genre, the destination
    //    path, select all|none, ▶ start, ✕ cancel, and the fold-down progress strip — lives HERE, in a
    //     %HaulBar,dontSnap child minted beside the %Pick track chips.  Props { n, H } — n is the LIVE %HaulBar;
    //      n.c.up is its %Haul (stamped in Heist_keep_step).  It reads + drives the KEEP, never itself.
    let { n, H } = $props()
    const A = H as any

    // the describe round-trip + the pull both land off the beat; a bare H.version derive can miss between
    //  bumps — poll a slow clock beside it (the HaulFace idiom this splits off from).
    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 500); return () => clearInterval(iv) })

    const safe = (s: string) => String(s || '').replace(/[^\w .&()-]+/g, '_').replace(/\s+/g, ' ').trim() || 'Unfiled'

    let face = $derived.by(() => {
        void H?.version
        void tick
        void n?.vers                    // the %HaulBar's own bumps
        const keep = n?.c?.up
        // SKELETON-FIRST reactivity (see HaulFace): read the KEEP's vers so every keep.bump() (state,
        //  asks, dose, landed_n) repaints at the beat not the 500ms poll, and query picks with .ob() so a
        //   freshly-minted %Pick trickles the sel row in-place.  Husks ride the mirror, so H.version + tick
        //    stay the honest catch for the describe landing.
        void keep?.vers
        const sc = keep?.sc ?? {}
        const state = String(sc.state || 'primed')
        const seed = String(sc.seed || '')
        const at = String(sc.pub || sc.at || '')   // `pub` since 2026-08-05; `at` fallback for a particle minted pre-rename
        const rw = A?.top_House?.()?.c?.radio_w
        const mir = (rw && at) ? A?.Ra_home_them?.(rw, at) : null
        const husks = (mir && A?.Heist_rummage_recs) ? A.Heist_rummage_recs(mir, seed) : []
        const picks = keep?.ob?.({ Pick: 1 }) ?? []
        const genre = String(sc.genre || 'Unfiled')
        return {
            state,
            title: String(sc.Haul || 'this track'),
            artist: String(sc.artist || ''),
            from: String(sc.from_name || 'a friend'),
            genre,
            dest: 'music/' + safe(genre) + '/',
            asks: +(sc.asks || 0),
            nTracks: husks.length,
            picked: picks.length,
            described: husks.length > 0,
            landed_n: +(sc.landed_n || 0),
            total_n: +(sc.total_n || 0),
            // LIVE FLOW (keep.c.flow, 0-100, off the real rx byte rate — Heist.g pulling branch): drives the
            //  data-stream pizzazz below.  On .c (never snapped, no bump), re-read each 500ms tick.  trackPct is
            //   the discrete tracks-landed fill; flow is the "bytes moving RIGHT NOW" heat that makes it blaze.
            flow: Math.max(0, Math.min(100, +(keep?.c?.flow ?? 0))),
            trackPct: (+(sc.total_n || 0) > 0) ? Math.min(100, Math.round(+(sc.landed_n || 0) / +(sc.total_n || 1) * 100)) : 0,
            folded: state === 'pulling' || state === 'committing' || state === 'done',
        }
    })

    const CATEGORIES = ['Ambient', 'Jazz', 'Electronic', 'Rock', 'Hip Hop', 'Folk', 'Classical']
    const keep = () => n?.c?.up
    // local-state category edit — see HaulFace: don't drive value= from the per-trickle derive (snaps shut).
    let catDraft = $state('')
    let catActive = $state(false)
    $effect(() => { if (!catActive) catDraft = face.genre })
    function commitCategory() { A?.post_do?.(() => { A?.Heist_keep_set_genre?.(keep(), catDraft) }, { see: 'keep category' }) }
    function cancel() { A?.post_do?.(() => { A?.Heist_keep_cancel?.(A?.top_House?.()?.c?.radio_w, keep()) }, { see: 'keep cancel' }) }
    function start() { A?.post_do?.(() => { A?.Heist_keep_start?.(keep()) }, { see: 'keep start' }) }
</script>

<div class="kb" class:folded={face.folded}>
    <div class="kb-head">
        <span class="kb-badge">{face.state === 'done' ? '✓' : '⇊'}</span>
        <span class="kb-title" title={face.title}>{face.title}</span>
        {#if face.artist}<span class="kb-artist">{face.artist}</span>{/if}
        <span class="kb-from">from {face.from}</span>
    </div>

    {#if face.folded}
        <!-- FOLDED: it started — a compact progress strip; the track chips carry the per-track ✓ -->
        <div class="kb-prog">
            {#if face.state === 'done'}
                ✓ kept {face.landed_n} → {face.dest}
            {:else}
                downloading {face.landed_n}/{face.total_n || face.picked || '?'} → {face.dest}
            {/if}
        </div>
        {#if face.state !== 'done'}
            <!-- the data-stream bar (the human 2026-07-30 "a little more pizzazz as its transferring"): a solid
                 fill = tracks landed; a bright band SWEEPS across, its glow scaled by the live flow % so it
                 blazes while bytes land and calms to nothing when the wire stalls (honest — doubles as the
                 "is it actually flowing?" tell beside the ⇊⚠ NO PROGRESS watchdog). -->
            <div class="kb-flow" class:live={face.flow > 4} style="--flow:{face.flow}">
                <div class="kb-flow-fill" style="width:{face.trackPct}%"></div>
                <div class="kb-flow-stream"></div>
            </div>
        {/if}
    {:else}
        <!-- PRIMED: the setup form — tweakable until you press ▶ start (no auto-start on track-end / skip) -->
        <div class="kb-file">
            <span class="kb-dim">category</span>
            <input class="kb-genre" list="kb-cats" bind:value={catDraft} placeholder="(none — keep source folders)"
                onfocus={() => catActive = true}
                onblur={() => { catActive = false; commitCategory() }} />
            <datalist id="kb-cats">{#each CATEGORIES as g}<option value={g}></option>{/each}</datalist>
        </div>
        <div class="kb-dest" title="where these land — the artist/album folders ride underneath">⤓ {face.dest}<span class="kb-dim"> …artist / album</span></div>
        {#if face.described}
            <div class="kb-sel">
                <span class="kb-dim">{face.picked} of {face.nTracks} — the whole folder, click a track to skip one</span>
            </div>
        {:else}
            <!-- SKELETON: the controls shell stands; the track chips arrive as their OWN cells once picks
                 land.  A describing line + shimmer stand in for the list until the folder describes; when the
                 first husk lands face.described flips and the sel row (with counts) replaces this in place. -->
            <div class="kb-skel" aria-busy="true">
                <div class="kb-note">
                    {#if face.asks > 1}looking through the album… ({face.asks}){:else}finding the folder…{/if}
                </div>
                <div class="kb-shim"></div>
                <div class="kb-shim short"></div>
            </div>
        {/if}
        <div class="kb-foot">
            <button class="kb-start" onclick={start} title="start downloading these tracks into your collection">▶ start</button>
            <span class="kb-dim">nothing downloads until you start</span>
            <button class="kb-x" onclick={cancel} title="don't keep — drop this">✕</button>
        </div>
    {/if}
</div>

<style>
    /* the voronoi cell bbox overlaps its neighbours, so the ROOT must not eat pointer events; each
       control re-arms pointer-events (the HaulFace hard contract this splits off from). */
    .kb {
        pointer-events: none;
        width: max-content;
        max-width: 260px;
        padding: 6px 10px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e0cfd8;
        text-align: left;
    }
    .kb.folded { max-width: 210px; opacity: 0.92; }
    .kb-head { display: flex; align-items: baseline; gap: 6px; }
    .kb-badge { font-size: 12px; color: #7fe8bf; }
    .kb-title { font-size: 12px; font-weight: 700; color: #e8a9c0; max-width: 170px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .kb-artist { font-size: 9px; opacity: 0.7; color: #cfc0d8; max-width: 110px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .kb-from { font-size: 9px; opacity: 0.6; }
    .kb-prog { font-size: 10px; opacity: 0.85; color: #7fe8bf; margin-top: 3px; }
    /* the data-stream pizzazz — a progress track (tracks-landed fill) with a sweeping band overlay whose glow
       is driven by --flow (keep.c.flow 0-100).  The sweep runs continuously in CSS (smooth regardless of the
       500ms value poll); only its OPACITY breathes with the live rate, so it blazes on real traffic and fades
       to calm when the wire goes quiet — no fake motion when nothing is landing. */
    .kb-flow {
        position: relative; height: 5px; margin-top: 4px;
        border-radius: 3px; background: #241820; overflow: hidden;
    }
    .kb-flow-fill {
        position: absolute; top: 0; bottom: 0; left: 0;
        background: linear-gradient(90deg, #3f9a6a, #7fe8bf);
        border-radius: 3px; transition: width 0.5s ease;
    }
    .kb-flow-stream {
        position: absolute; top: 0; right: 0; bottom: 0; left: 0;
        background: linear-gradient(90deg, transparent 0%, rgba(159, 232, 191, 0.95) 50%, transparent 100%);
        background-size: 42% 100%; background-repeat: no-repeat;
        opacity: calc(var(--flow, 0) / 130);   /* flow 100 → ~0.77 blaze; flow 0 → invisible */
        animation: kb-stream 1s linear infinite;
    }
    .kb-flow.live { box-shadow: 0 0 5px rgba(127, 232, 191, calc(var(--flow, 0) / 260)); }
    @keyframes kb-stream {
        0%   { background-position: -42% 0; }
        100% { background-position: 142% 0; }
    }
    .kb-file { display: flex; align-items: center; gap: 5px; margin-top: 4px; }
    .kb-dim { font-size: 9px; opacity: 0.55; }
    .kb-genre {
        pointer-events: auto;
        background: #241820;
        color: #f0dbe6;
        border: 1px solid #66495a;
        border-radius: 6px;
        font-size: 10px;
        padding: 1px 6px;
        width: 110px;
    }
    .kb-dest { font-size: 9px; margin-top: 3px; color: #7fe8bf; font-family: monospace; }
    .kb-sel { display: flex; align-items: center; gap: 6px; margin-top: 5px; }
    .kb-note { font-size: 9px; opacity: 0.6; font-style: italic; margin-top: 3px; }
    /* the loading skeleton — shimmer bars standing in for the track list until the folder describes.
       pointer-events stay off (only controls re-arm); the pulse is the DoorFace breathe idiom. */
    .kb-skel { margin-top: 3px; }
    .kb-shim {
        height: 8px; margin: 4px 0 0 8px; max-width: 160px;
        border-radius: 4px;
        background: linear-gradient(90deg, #2c1d27 0%, #3a2733 50%, #2c1d27 100%);
        animation: kb-shim 1.4s ease-in-out infinite;
    }
    .kb-shim.short { max-width: 100px; }
    .kb-shim:nth-child(3) { animation-delay: 0.25s; }
    @keyframes kb-shim {
        0%, 100% { opacity: 0.35; }
        50%      { opacity: 0.8; }
    }
    .kb-foot { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-top: 5px; }
    .kb-start {
        pointer-events: auto; cursor: pointer;
        background: #1f3a2a; color: #9fe8bf; border: 1px solid #3f9a6a; border-radius: 8px;
        font-size: 10px; padding: 1px 9px; line-height: 1.4; flex: none; font-weight: 600;
    }
    .kb-start:hover { background: #57c777; color: #04202a; }
    .kb-x {
        pointer-events: auto; cursor: pointer;
        background: #38141f; color: #e8a9c0; border: 1px solid #a03f5a; border-radius: 7px;
        font-size: 9px; padding: 0 6px; line-height: 1.5; flex: none;
    }
    .kb-x:hover { background: #d94f7a; color: #1a0810; }
</style>
