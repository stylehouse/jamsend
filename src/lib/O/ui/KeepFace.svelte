<script lang="ts">
    // KeepFace — the ⇊ "keep what you're hearing" heist AS A TIDY VYTO CELL (the human 2026-07-28: "I DO
    //  want the Heist UI ... in a few Vyto cells ... nodulate down the folder hierarchy ... it can be left
    //   to sit there, you don't have to click start, it'll assume that at some point ... it folds down when
    //    started").  One face per %Keep (FACE_MAINKEYS/glass_kinds, imposed by mainkey — no %Keep wears
    //     sc.face).  NOT fullscreen: it sits in the clutter while PRIMED, then FOLDS DOWN to a compact
    //      progress strip once it auto-starts pulling.  Props { n, H } — n is the LIVE %Keep particle.
    //
    // TWO SEPARATE HIERARCHIES (the human 2026-07-30), never merged, never enclosing the track list they
    //  describe (that would duplicate the folder names the tree below already shows):
    //   · section    — MINE: an optional, nestable `- <name>` category (the marker is stamped automatically,
    //      never typed).  Defaults from — and updates — the GLOBAL remembered Heist setting.
    //   · directories — THEIRS: the shared source-folder prefix across every track in this keep (Fourier
    //      Four/Tagged Truth, say).  Per-disc divergence below that (CD1 vs CD2) stays in the track tree,
    //       never repeated up here.
    //  Both sit calm as a `/segment/segment/` breadcrumb; click to edit the whole thing in place (the
    //   existing genre-field technique: local draft, commit on blur — no elaborate exploded form).
    let { n, H } = $props()
    const A = H as any

    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 500); return () => clearInterval(iv) })

    // in-place editing state — declared BEFORE `face` below, which reads catEditing/dirsEditing to gate
    //  the known-category|dirs library scan.  Order matters here: a $derived closure only ever RUNS after
    //   the whole script has executed once, so a forward reference would actually be safe either way — but
    //    this session already shipped one real TDZ bug from a same-block ordering assumption, so this one
    //     reads top-to-bottom on purpose, no reliance on Svelte's lazy-eval timing to save it.
    let catDraft = $state('')
    let catEditing = $state(false)
    let dirsDraft = $state('')
    let dirsEditing = $state(false)

    // sanitise a category into a filesystem-safe folder segment — still needed for the FOLDED progress
    //  strip's "→ dest" line (untouched by this pass; only the PRIMED preview line was the noise).
    const safe = (s: string) => String(s || '').replace(/[^\w .&()-]+/g, '_').replace(/\s+/g, ' ').trim() || 'Unfiled'
    const stripMark = (s: string) => String(s || '').replace(/^(-|0) /, '')

    function dirOf(path: string): string {
        const parts = String(path || '').split('/').filter(Boolean)
        parts.pop()
        return parts.join('/')
    }
    function fileOf(path: string, fallback: string): string {
        const parts = String(path || '').split('/').filter(Boolean)
        return parts.pop() || fallback
    }
    // commonPrefix — the shared leading path segments across every husk's folder (Fourier Four/Tagged
    //  Truth), stopping at the first divergence (CD1 vs CD2 stays OUT — that's the track tree's job).
    function commonPrefix(dirs: string[]): string {
        const lists = dirs.filter((d) => d).map((d) => d.split('/').filter(Boolean))
        if (!lists.length) return ''
        const out: string[] = []
        for (let i = 0; i < lists[0].length; i++) {
            const seg = lists[0][i]
            if (lists.every((l) => l[i] === seg)) out.push(seg); else break
        }
        return out.join('/')
    }

    let face = $derived.by(() => {
        void H?.version
        void tick
        void n?.vers
        const sc = n?.sc ?? {}
        const state = String(sc.state || 'primed')
        const seed = String(sc.seed || '')
        const at = String(sc.at || '')
        const rw = A?.top_House?.()?.c?.radio_w
        const mir = (rw && at) ? A?.Ra_home_them?.(rw, at) : null
        const me = rw ? (A?.Radio_pub?.(rw) || 'me') : 'me'
        const own = rw ? A?.Ra_home_self?.(rw, me) : null

        const husks = (mir && A?.Heist_rummage_recs) ? A.Heist_rummage_recs(mir, seed) : []
        const picks = n?.ob?.({ Pick: 1 }) ?? []
        const pickedRefs = new Set(picks.map((p: any) => String(p.sc.ref ?? p.sc.id)))

        // ── section (category) — a plain nested name, marker stamped elsewhere (Heist_keep_set_genre) ──
        const catRaw = String(sc.genre || '')
        const catSegs = catRaw.split('/').map(stripMark).filter(Boolean)
        // known-category discovery scans the WHOLE library — only worth paying for while the field the
        //  suggestions feed is actually open, not on every 500ms tick regardless of state.
        const catKnown = (catEditing && own && A?.Heist_known_categories) ? A.Heist_known_categories(own) : []

        // ── directories — the shared source prefix, or the human's override ─────────────────────────────
        const dirsAuto = commonPrefix(husks.map((h: any) => dirOf(String(h.sc.path || ''))))
        const dirsRaw = (sc.dirs != null && sc.dirs !== '') ? String(sc.dirs) : dirsAuto
        const dirsSegs = dirsRaw.split('/').filter(Boolean)
        const artist = String(sc.artist || '')
        const dirsKnown = (dirsEditing && own && A?.Heist_known_dirs) ? A.Heist_known_dirs(own, artist) : []

        // ── the track tree — grouped by whatever's LEFT after the directories prefix, so a group never
        //     repeats what the breadcrumb above it already said ──────────────────────────────────────────
        const prefixParts = dirsRaw.split('/').filter(Boolean)
        function remainderOf(dir: string): string {
            const parts = dir.split('/').filter(Boolean)
            let i = 0
            while (i < prefixParts.length && parts[i] === prefixParts[i]) i++
            return parts.slice(i).join('/')
        }
        const groups: Record<string, any[]> = {}
        for (const r of husks) {
            const path = String(r.sc.path || '')
            const rem = remainderOf(dirOf(path))
            ;(groups[rem] = groups[rem] || []).push({
                ref: String(r.sc.id),
                title: String(r.sc.title || fileOf(path, String(r.sc.id))),
                file: fileOf(path, String(r.sc.title || r.sc.id)),
                artist: String(r.sc.artist || ''),
                kept: pickedRefs.has(String(r.sc.id)),
                seed: String(r.sc.re || '') === seed,
            })
        }
        const flat = (groups[''] || []).sort((a: any, b: any) => a.file.localeCompare(b.file))
        const tree = Object.keys(groups).filter((k) => k !== '').sort().map((rem) => ({
            label: rem.split('/').filter(Boolean).join(' › '),
            tracks: groups[rem].sort((a: any, b: any) => a.file.localeCompare(b.file)),
        }))

        const genre = catRaw
        return {
            state,
            title: String(sc.Keep || 'this track'),
            artist: String(sc.artist || ''),
            from: String(sc.from_name || 'a friend'),
            dest: 'music/' + safe(genre) + '/',
            asks: +(sc.asks || 0),
            catRaw, catSegs, catKnown,
            dirsRaw, dirsSegs, dirsKnown,
            flat, tree,
            nTracks: husks.length,
            picked: pickedRefs.size,
            landed_n: +(sc.landed_n || 0),
            total_n: +(sc.total_n || 0),
            describing: state === 'primed' || state === 'wanted' || state === 'asking',
            folded: state === 'pulling' || state === 'committing' || state === 'done',
        }
    })

    // in-place editing — local draft + commit-on-blur (the established genre-field technique: a live
    //  trickle can never reset the field mid-edit because the draft only re-seeds from the model when NOT
    //   focused).  Kept deliberately simple — one text field per hierarchy, not an exploded gap-form.
    //   (catDraft/catEditing/dirsDraft/dirsEditing are declared above, before `face` — see that comment.)
    function openCat() { catDraft = face.catRaw; catEditing = true }
    function commitCat() { catEditing = false; A?.post_do?.(() => { A?.Heist_keep_set_genre?.(n, catDraft) }, { see: 'keep category' }) }
    function openDirs() { dirsDraft = face.dirsRaw; dirsEditing = true }
    function commitDirs() { dirsEditing = false; A?.post_do?.(() => { A?.Heist_keep_set_dirs?.(n, dirsDraft) }, { see: 'keep directories' }) }

    function toggle(ref: string) {
        A?.post_do?.(() => { A?.Heist_keep_pick_toggle?.(n, ref) }, { see: 'keep pick' })
    }
    function cancel() {
        A?.post_do?.(() => { A?.Heist_keep_cancel?.(A?.top_House?.()?.c?.radio_w, n) }, { see: 'keep cancel' })
    }
    function start() { A?.post_do?.(() => { A?.Heist_keep_start?.(n) }, { see: 'keep start' }) }
</script>

<div class="kf" class:folded={face.folded}>
    <div class="kf-head">
        <span class="kf-badge">{face.state === 'done' ? '✓' : '⇊'}</span>
        <span class="kf-title" title={face.title}>{face.title}</span>
        {#if face.artist}<span class="kf-artist">{face.artist}</span>{/if}
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
        <!-- PRIMED: sits in the clutter, tweakable, until you press ▶ start (no auto-start) -->

        <!-- SECTION — mine, optional, nestable. click the whole breadcrumb to edit it in place. -->
        {#if catEditing}
            <input class="kf-stair-edit" bind:value={catDraft} list="kf-cat-known" autofocus
                onblur={commitCat} onkeydown={(e) => { if (e.key === 'Enter') (e.currentTarget as HTMLInputElement).blur(); if (e.key === 'Escape') catEditing = false }}
                placeholder="no section — type one, or nest with /" />
            <datalist id="kf-cat-known">
                {#each face.catKnown as k}<option value={k.path.split('/').map(stripMark).join('/')}>{k.tracks} tracks already</option>{/each}
            </datalist>
        {:else}
            <button class="kf-stair" onclick={openCat} title="click to edit">
                <span class="kf-stair-lbl">section</span>
                <span class="kf-stair-path">
                    <span class="sl">/</span>{#each face.catSegs as seg}<span class="seg cat">{seg}</span><span class="sl">/</span>{/each}
                    {#if !face.catSegs.length}<span class="kf-stair-empty">none</span>{/if}
                </span>
            </button>
        {/if}

        <!-- DIRECTORIES — theirs: the shared source prefix. same breadcrumb, different accent, never a box
             around the track list (that's what "spilled out" below is for). -->
        {#if dirsEditing}
            <input class="kf-stair-edit dirs" bind:value={dirsDraft} list="kf-dirs-known" autofocus
                onblur={commitDirs} onkeydown={(e) => { if (e.key === 'Enter') (e.currentTarget as HTMLInputElement).blur(); if (e.key === 'Escape') dirsEditing = false }} />
            <datalist id="kf-dirs-known">
                {#each face.dirsKnown as d}<option value={d}></option>{/each}
            </datalist>
        {:else}
            <button class="kf-stair" onclick={openDirs} title="click to edit">
                <span class="kf-stair-lbl">directories</span>
                <span class="kf-stair-path">
                    {#if face.dirsSegs.length}
                        <span class="sl">/</span>{#each face.dirsSegs as seg}<span class="seg dirs">{seg}</span><span class="sl">/</span>{/each}
                    {:else}
                        <span class="kf-stair-empty">…</span>
                    {/if}
                </span>
            </button>
        {/if}

        {#if face.nTracks}
            <div class="kf-total"><span class="kf-dim">{face.picked} of {face.nTracks} tracks — the whole folder, click one to skip it</span></div>
        {/if}

        {#if face.nTracks}
            <div class="kf-tree">
                {#if face.flat.length}
                    {#each face.flat as t}
                        <button class="kf-track" class:kept={t.kept} class:seed={t.seed} onclick={() => toggle(t.ref)}
                            title={t.seed ? 'the track you\'re hearing' : (t.kept ? 'keeping — click to skip' : 'skipped — click to keep')}>
                            <span class="kf-tick">{t.kept ? '✓' : '·'}</span>
                            <span class="kf-tname">{t.title}{#if t.seed} ♪{/if}</span>
                        </button>
                    {/each}
                {/if}
                {#each face.tree as grp}
                    {#if grp.tracks.length > 5}
                        <details class="kf-group">
                            <summary class="kf-dir"><span class="kf-car">▸</span> 📁 {grp.label} <span class="kf-cnt">{grp.tracks.length} tracks</span></summary>
                            {#each grp.tracks as t}
                                <button class="kf-track" class:kept={t.kept} class:seed={t.seed} onclick={() => toggle(t.ref)}
                                    title={t.seed ? 'the track you\'re hearing' : (t.kept ? 'keeping — click to skip' : 'skipped — click to keep')}>
                                    <span class="kf-tick">{t.kept ? '✓' : '·'}</span>
                                    <span class="kf-tname">{t.title}{#if t.seed} ♪{/if}</span>
                                </button>
                            {/each}
                        </details>
                    {:else}
                        <div class="kf-dir-flat">📁 {grp.label} <span class="kf-cnt">{grp.tracks.length}</span></div>
                        {#each grp.tracks as t}
                            <button class="kf-track" class:kept={t.kept} class:seed={t.seed} onclick={() => toggle(t.ref)}
                                title={t.seed ? 'the track you\'re hearing' : (t.kept ? 'keeping — click to skip' : 'skipped — click to keep')}>
                                <span class="kf-tick">{t.kept ? '✓' : '·'}</span>
                                <span class="kf-tname">{t.title}{#if t.seed} ♪{/if}</span>
                            </button>
                        {/each}
                    {/if}
                {/each}
            </div>
        {:else}
            <!-- SKELETON: the shell already stands (head · section · directories above); this is the guts
                 still arriving. -->
            <div class="kf-skel" aria-busy="true">
                <div class="kf-note">
                    {#if face.asks > 1}looking through the album… ({face.asks}){:else}finding the folder…{/if}
                </div>
                <div class="kf-shim"></div>
                <div class="kf-shim"></div>
                <div class="kf-shim short"></div>
            </div>
        {/if}
        <div class="kf-foot">
            <button class="kf-start" onclick={start} title="start downloading these tracks into your collection">▶ start</button>
            <span class="kf-dim">nothing downloads until you start</span>
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
    .kf-artist { font-size: 9px; opacity: 0.7; color: #cfc0d8; max-width: 120px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .kf-from { font-size: 9px; opacity: 0.6; }
    .kf-prog { font-size: 10px; opacity: 0.85; color: #7fe8bf; margin-top: 3px; }
    .kf-dim { font-size: 9px; opacity: 0.55; }

    /* section / directories — a calm, non-enclosing breadcrumb; slashes stay neutral so the eye reads
       structure, segment names carry the colour.  A plain button, no border/background at rest — this must
       NOT read as a box that could also hold the track list (that's the duplication the human flagged). */
    .kf-stair {
        pointer-events: auto;
        cursor: pointer;
        display: flex;
        align-items: baseline;
        gap: 5px;
        width: 100%;
        background: transparent;
        border: none;
        padding: 3px 0 0;
        text-align: left;
        font: inherit;
        color: inherit;
    }
    .kf-stair:hover .kf-stair-path { text-decoration: underline; text-decoration-color: #66495a; }
    .kf-stair-lbl { font-size: 8.5px; text-transform: uppercase; letter-spacing: 0.05em; opacity: 0.45; flex: none; }
    .kf-stair-path { font-size: 10.5px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .kf-stair-path .sl { color: #6b5a68; }
    .kf-stair-path .seg.cat { color: #7fe8bf; }
    .kf-stair-path .seg.dirs { color: #c9a5e8; }
    .kf-stair-empty { color: #6b5a68; font-style: italic; }
    .kf-stair-edit {
        pointer-events: auto;
        width: 100%;
        margin-top: 3px;
        background: #241820;
        color: #f0dbe6;
        border: 1px solid #66495a;
        border-radius: 6px;
        font-size: 10.5px;
        padding: 2px 7px;
        font-family: inherit;
    }
    .kf-stair-edit.dirs { border-color: #6a5580; }
    .kf-stair-edit::placeholder { color: #6b5a68; }

    .kf-total { margin-top: 6px; }

    .kf-tree { margin-top: 6px; display: flex; flex-direction: column; gap: 1px; }
    .kf-group { border-radius: 5px; }
    .kf-dir, .kf-dir-flat { font-size: 9px; opacity: 0.7; margin-top: 3px; color: #cfc0d8; display: flex; align-items: center; gap: 5px; cursor: default; }
    summary.kf-dir { cursor: pointer; list-style: none; }
    summary.kf-dir::-webkit-details-marker { display: none; }
    .kf-car { font-size: 8px; opacity: 0.6; }
    details[open] > summary.kf-dir .kf-car { transform: rotate(90deg); display: inline-block; }
    .kf-cnt { margin-left: auto; opacity: 0.6; font-size: 8.5px; }
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
    .kf-skel { margin-top: 3px; }
    .kf-shim {
        height: 8px; margin: 4px 0 0 10px; max-width: 180px;
        border-radius: 4px;
        background: linear-gradient(90deg, #2c1d27 0%, #3a2733 50%, #2c1d27 100%);
        animation: kf-shim 1.4s ease-in-out infinite;
    }
    .kf-shim.short { max-width: 110px; }
    .kf-shim:nth-child(3) { animation-delay: 0.2s; }
    .kf-shim:nth-child(4) { animation-delay: 0.4s; }
    @keyframes kf-shim {
        0%, 100% { opacity: 0.35; }
        50%      { opacity: 0.8; }
    }
    .kf-foot { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-top: 8px; }
    .kf-start {
        pointer-events: auto; cursor: pointer;
        background: #1f3a2a; color: #9fe8bf; border: 1px solid #3f9a6a; border-radius: 8px;
        font-size: 10px; padding: 1px 9px; line-height: 1.4; flex: none; font-weight: 600;
    }
    .kf-start:hover { background: #57c777; color: #04202a; }
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
