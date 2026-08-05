<script lang="ts">
    // HaulFace — the ⇊ "keep what you're hearing" heist AS A TIDY VYTO CELL (the human 2026-07-28: "I DO
    //  want the Heist UI ... in a few Vyto cells ... nodulate down the folder hierarchy ... it can be left
    //   to sit there, you don't have to click start, it'll assume that at some point ... it folds down when
    //    started").  One face per %Haul (FACE_MAINKEYS/glass_kinds, imposed by mainkey — no %Haul wears
    //     sc.face).  NOT fullscreen: it sits in the clutter while PRIMED, then FOLDS DOWN to a compact
    //      progress strip once it auto-starts pulling.  Props { n, H } — n is the LIVE %Haul particle.
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
    import { tick as afterRender, onMount, onDestroy } from 'svelte'
    import DeleteX from './micro/DeleteX.svelte'
    import { lifewatch } from './micro/lifetell'   // DIAGNOSTIC — strip with the rest of the remount probes
    let { n, H } = $props()
    const A = H as any

    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 500); return () => clearInterval(iv) })

    // MOUNT/DESTROY TELL (Download_stall_handover.md Evening 7's "the bomb" — the directories editor
    //  snapping shut on a Story trickle): a top-level, no-dependency $effect runs its body once on mount
    //  and its cleanup once on destroy, so if this instance is being torn down and recreated under a
    //  trickle (rather than the dirs-freeze above just needing a live-shifting derive tamed) these two
    //  lines say so directly — no more inferring it from symptoms.
    // (the old $effect mount/destroy+console.trace tell was REMOVED 2026-08-02 — it read the `n`
    //  prop so it re-fired on every dep bump, spamming 22k trace lines of PHANTOM re-runs.  The
    //   lifecycle-true ◈◈ tell below is the only honest one, and the GATE-FLIP probe in Vytui names
    //    the cause.)
    // LIFECYCLE-TRUE TELL (2026-08-02): the $effect above READS the `n` prop, so it is NOT the
    //  "no-dependency" tell its old comment claimed — Svelte re-fires an $effect's cleanup+body on
    //   every dep bump, spamming destroy→mount with NO real remount (and .sc reads are plain-object,
    //    non-reactive, so `n?.sc?.Haul` subscribes to nothing — only the bare `n` prop read does).
    //     These three lines CANNOT be fooled: the script body runs exactly once per REAL instance (so
    //      myId is that instance's serial), and onMount/onDestroy fire exactly once per real DOM
    //       mount/unmount.  Read the two side by side next repro:
    //        · ◈◈ REAL SILENT while ◈ spams          ⟹ PHANTOM — no remount; "editor snaps shut" is a
    //           derive moving under the edit (tame with the dirs freeze), not a teardown.
    //        · ◈◈ REAL mount N / destroy N, N CLIMBS ⟹ genuine keyed-each teardown; chase the each
    //           identity (cell.key / ancestor {#if} / <svelte:boundary>), not component-local state.
    // (2026-08-04) this tell now rides `lifewatch` (ui/micro/lifetell.ts) — same lifecycle truth,
    //  but it ALSO lands each mount/destroy in the supply_trace ring, so the repro is read off disk
    //   with `node scripts/tracelog.mjs --watch --life` instead of copying console.  It is the
    //    INNERMOST rung of the life ladder Vytui now brackets around it (world > stage > faces >
    //     mold > this); whichever OUTER rung climbs alongside it is the actual teardown.
    lifewatch(H, 'face:Keep', () => String(n?.sc?.Haul || n?.sc?.id || '?'))

    // in-place editing — SEGMENTS, not one field (the human 2026-07-30, correcting a prior over-
    //  simplification): editing either hierarchy is a row of small chips (one per segment, its own × to
    //   remove it) with a small "+" gap BEFORE the first, BETWEEN every pair, and AFTER the last — N
    //    segments, N+1 gaps, each gap its own tiny input that inserts a new segment at exactly that
    //     position. catGaps/dirsGaps hold each gap's in-progress typing, resized to segs.length+1 whenever
    //      the segment count changes.
    let catEditing = $state(false)
    let dirsEditing = $state(false)
    let catGaps = $state<string[]>([''])
    let dirsGaps = $state<string[]>([''])
    let catFirstInput: HTMLInputElement | undefined = $state()
    // directories' segment list is FROZEN at open time (openDirs), unlike category's: catSegs echoes a
    //  persisted scalar (sc.genre) so it never moves under the user, but dirsSegs falls back to the LIVE
    //  commonPrefix over still-materialising husks whenever sc.dirs is unset — editing off that moving
    //  target is the leading suspect for "the editor snaps shut" (Download_stall_handover.md Evening 7).
    //  Freezing the segments (and the auto prefix an edit substitutes onto the keep) at open time, then
    //  updating the freeze locally on every insert/remove, keeps the edit session's display stable
    //  regardless of what the live derive does underneath it.
    let dirsSegsFrozen = $state<string[]>([])
    let dirsAutoFrozen = $state('')

    // sanitise a category into a filesystem-safe folder segment — still needed for the FOLDED progress
    //  strip's "→ dest" line (untouched by this pass; only the PRIMED preview line was the noise).
    const safe = (s: string) => String(s || '').replace(/[^\w .&()-]+/g, '_').replace(/\s+/g, ' ').trim() || 'Unfiled'
    const stripMark = (s: string) => String(s || '').replace(/^(-|0) /, '')
    // deshell — a leading '- ' is SHELL-HOSTILE: a file or folder whose name starts with a dash cannot be
    //  handed to a shell command as a non-flag (the human 2026-08-05).  '0 ' is the marker we write, which
    //   is already what the category verb migrates to (Heist_keep_set_genre, Heist.g:1877); this carries a
    //    DIRECTORY segment over the same way.  UI-SIDE ONLY, deliberately: the swap becomes real on disk the
    //     moment a keep's directories are committed (Heist_rel_for substitutes dirs_auto → dirs at land
    //      time), but an UNTOUCHED keep still lands the source's own '- name' folder.  Making that automatic
    //       means a leading-dash rule in Heist_cp_path, which would bend the cp-landing ruling ("the source's
    //        own filename and folder layout survive UNCHANGED") — the human's call, not a display edit's.
    const deshell = (s: string) => String(s || '').replace(/^- /, '0 ')

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
        //  the human 2026-07-30: no suggestions here (it's a personal name, not a lookup) — a plain typed
        //   field, auto-focused the moment you open it with nothing set yet (see openCat).
        const catRaw = String(sc.genre || '')
        const catSegs = catRaw.split('/').map(stripMark).filter(Boolean)

        // ── directories — the shared source prefix, or the human's override ─────────────────────────────
        const dirsAuto = commonPrefix(husks.map((h: any) => dirOf(String(h.sc.path || ''))))
        const dirsRaw = (sc.dirs != null && sc.dirs !== '') ? String(sc.dirs) : dirsAuto
        const dirsSegs = dirsRaw.split('/').filter(Boolean)
        const artist = String(sc.artist || '')
        const dirsKnown = (dirsEditing && own && A?.Heist_known_dirs) ? A.Heist_known_dirs(own, artist) : []

        // ── the track tree — grouped by whatever's LEFT after the directories prefix, so a group never
        //     repeats what the breadcrumb above it already said ──────────────────────────────────────────
        // the prefix match is MARKER-BLIND (2026-08-05): '- chill', '0 chill' and 'chill' are one directory
        //  as far as "has this level already been said above?" goes.  An exact-string compare failed at the
        //   FIRST segment whenever the breadcrumb and the source disagreed about the marker, so nothing
        //    stripped and every group label restated the whole path the directories row had just shown.
        const prefixParts = dirsRaw.split('/').filter(Boolean).map(stripMark)
        function remainderOf(dir: string): string {
            const parts = dir.split('/').filter(Boolean)
            let i = 0
            while (i < prefixParts.length && stripMark(parts[i]) === prefixParts[i]) i++
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
            label: rem.split('/').filter(Boolean).map(deshell).join(' › '),
            tracks: groups[rem].sort((a: any, b: any) => a.file.localeCompare(b.file)),
        }))

        const genre = catRaw
        return {
            state,
            title: String(sc.Haul || 'this track'),
            artist: String(sc.artist || ''),
            from: String(sc.from_name || 'a friend'),
            dest: 'music/' + safe(genre) + '/',
            asks: +(sc.asks || 0),
            catRaw, catSegs,
            dirsRaw, dirsSegs, dirsKnown, dirsAuto,
            flat, tree,
            nTracks: husks.length,
            picked: pickedRefs.size,
            landed_n: +(sc.landed_n || 0),
            total_n: +(sc.total_n || 0),
            // LIVE FLOW (the human 2026-07-30 "a little more pizzazz as its transferring") — keep.c.flow is
            //  the real thing, not decoration: a 0.3s-throttled % off the actual rx byte rate (Heist.g's
            //   pulling branch), already built and already driving HaulBarFace's nested variant; this is
            //    that same bar wired into the flat HaulFace everyone actually sees today.
            flow: Math.max(0, Math.min(100, +(n?.c?.flow ?? 0))),
            trackPct: (+(sc.total_n || 0) > 0) ? Math.min(100, Math.round(+(sc.landed_n || 0) / +(sc.total_n || 1) * 100)) : 0,
            describing: state === 'primed' || state === 'wanted' || state === 'asking',
            folded: state === 'pulling' || state === 'committing' || state === 'done',
            // UNFOCUSED (the human 2026-07-30 — several keeps shouldn't fight for room): Heist_keep_step
            //  already decided this — dose only rides on the one sibling most recently touched. A single
            //  keep is trivially its own focus, so this is false whenever there's nothing to compete with.
            unfocused: (state === 'primed' || state === 'wanted' || state === 'asking') && sc.dose !== '2',
        }
    })

    // keep the gap-draft arrays sized to segs.length+1, preserving whatever's mid-typed by position.
    $effect(() => {
        const want = face.catSegs.length + 1
        if (catGaps.length !== want) catGaps = Array.from({ length: want }, (_, i) => catGaps[i] ?? '')
    })
    $effect(() => {
        const want = dirsSegsFrozen.length + 1
        if (dirsGaps.length !== want) dirsGaps = Array.from({ length: want }, (_, i) => dirsGaps[i] ?? '')
    })

    async function openCat() {
        catEditing = true
        // nothing set yet — put the cursor straight in the field instead of making them click twice
        //  (the human 2026-07-30: "an input field selected immediately when there's nothing yet").
        if (!face.catSegs.length) {
            await afterRender()
            catFirstInput?.focus()
        }
    }
    function openDirs() {
        // the draft opens in the shell-safe form, so what you see in the boxes is what will be written
        dirsSegsFrozen = face.dirsSegs.map(deshell)
        dirsAutoFrozen = face.dirsAuto
        dirsEditing = true
    }
    function catInsertAt(i: number) {
        const v = (catGaps[i] || '').trim()
        if (!v) return
        const segs = face.catSegs.slice()
        segs.splice(i, 0, v)
        catGaps[i] = ''
        A?.post_do?.(() => { A?.Heist_keep_set_genre?.(n, segs.join('/')) }, { see: 'keep category insert' })
    }
    function catRemoveAt(i: number) {
        const segs = face.catSegs.slice()
        segs.splice(i, 1)
        A?.post_do?.(() => { A?.Heist_keep_set_genre?.(n, segs.join('/')) }, { see: 'keep category remove' })
    }
    function dirsInsertAt(i: number) {
        const v = (dirsGaps[i] || '').trim()
        if (!v) return
        const segs = dirsSegsFrozen.slice()
        segs.splice(i, 0, v)
        dirsGaps[i] = ''
        dirsSegsFrozen = segs
        A?.post_do?.(() => { A?.Heist_keep_set_dirs?.(n, segs.join('/'), dirsAutoFrozen) }, { see: 'keep directories insert' })
    }
    function dirsRemoveAt(i: number) {
        const segs = dirsSegsFrozen.slice()
        segs.splice(i, 1)
        dirsSegsFrozen = segs
        A?.post_do?.(() => { A?.Heist_keep_set_dirs?.(n, segs.join('/'), dirsAutoFrozen) }, { see: 'keep directories remove' })
    }

    // ── committing an edit ────────────────────────────────────────────────────────────────────────
    // THE TICK COMMITS (the human 2026-08-05: "the user would assume clicking the tick would enter
    //  whatever's in the box").  It used to only close the editor, so anything typed into a gap and not
    //   confirmed with ENTER was silently dropped — the worst kind of small bug, because the human watched
    //    themselves type it.  foldGaps weaves every pending gap into its position in one pass, so ✓ is
    //     "enter everything, in order" rather than N remembered keystrokes.
    function foldGaps(segs: string[], gaps: string[]): string[] {
        const out: string[] = []
        for (let i = 0; i < segs.length; i++) {
            const g = (gaps[i] || '').trim()
            if (g) out.push(g)
            out.push(segs[i])
        }
        const tail = (gaps[segs.length] || '').trim()
        if (tail) out.push(tail)
        return out.map((s) => s.trim()).filter(Boolean)
    }
    function commitCat() {
        const segs = foldGaps(face.catSegs, catGaps)
        catGaps = ['']
        catEditing = false
        A?.post_do?.(() => { A?.Heist_keep_set_genre?.(n, segs.join('/')) }, { see: 'keep category commit' })
    }
    function commitDirs() {
        // deshell on the way OUT: whatever the human left in the boxes, what gets written is the
        //  shell-safe form (see deshell above).
        const segs = foldGaps(dirsSegsFrozen, dirsGaps).map(deshell)
        dirsGaps = ['']
        dirsSegsFrozen = segs
        dirsEditing = false
        A?.post_do?.(() => { A?.Heist_keep_set_dirs?.(n, segs.join('/'), dirsAutoFrozen) }, { see: 'keep directories commit' })
    }

    function toggle(ref: string) {
        A?.post_do?.(() => { A?.Heist_keep_pick_toggle?.(n, ref) }, { see: 'keep pick' })
    }
    function cancel() {
        A?.post_do?.(() => { A?.Heist_keep_cancel?.(A?.top_House?.()?.c?.radio_w, n) }, { see: 'keep cancel' })
    }
    function start() { A?.post_do?.(() => { A?.Heist_keep_start?.(n) }, { see: 'keep start' }) }
    function focus() { A?.post_do?.(() => { A?.Heist_keep_touch?.(n) }, { see: 'keep focus' }) }
</script>

<div class="kf" class:folded={face.folded || face.unfocused}>
    <div class="kf-head">
        <span class="kf-badge">{face.state === 'done' ? '✓' : '⇊'}</span>
        <span class="kf-title" title={face.title}>{face.title}</span>
        {#if face.artist}<span class="kf-artist">{face.artist}</span>{/if}
        <span class="kf-from">from {face.from}</span>
    </div>

    {#if face.unfocused}
        <!-- QUEUED, not the one you're touching right now — several keeps read as a compact list instead
             of everyone fighting for the same room.  Click to bring this one into focus. -->
        <button class="kf-queued" onclick={focus} title="click to work on this one">
            queued — {face.nTracks ? `${face.picked} of ${face.nTracks} tracks` : 'finding the folder…'}
        </button>
    {:else if face.folded}
        <!-- FOLDED: it started — a compact progress strip, no browsing -->
        <div class="kf-prog">
            {#if face.state === 'done'}
                ✓ kept {face.landed_n} → {face.dest}
            {:else}
                downloading {face.landed_n}/{face.total_n || '?'} tracks → {face.dest}
            {/if}
        </div>
        {#if face.state !== 'done'}
            <!-- the data-stream pizzazz: a solid fill = tracks landed; a bright band SWEEPS across, its glow
                 scaled by the live flow % so it blazes while bytes actually land and calms when the wire
                 stalls — no fake motion when nothing is transferring. -->
            <div class="kf-flow" class:live={face.flow > 4} style="--flow:{face.flow}">
                <div class="kf-flow-fill" style="width:{face.trackPct}%"></div>
                <div class="kf-flow-stream"></div>
            </div>
        {/if}
    {:else}
        <!-- PRIMED: sits in the clutter, tweakable, until you press ▶ start (no auto-start) -->

        <!-- SECTION — mine, optional, nestable. click the breadcrumb to edit; editing = one chip per
             segment (its own × to remove) with a small "+" gap before/between/after every chip, each gap
             its own tiny input that inserts a new segment right there. -->
        {#if catEditing}
            <div class="kf-chips">
                {#each face.catSegs as seg, i}
                    <input class="kf-gap" placeholder="+" value={catGaps[i]}
                        oninput={(e) => { catGaps[i] = (e.currentTarget as HTMLInputElement).value }}
                        onkeydown={(e) => { if (e.key === 'Enter') catInsertAt(i) }} />
                    <span class="kf-chip cat">{seg}<DeleteX ondelete={() => catRemoveAt(i)} title="remove this category level" /></span>
                {/each}
                <input class="kf-gap" placeholder="+" value={catGaps[face.catSegs.length]}
                    bind:this={catFirstInput}
                    oninput={(e) => { catGaps[face.catSegs.length] = (e.currentTarget as HTMLInputElement).value }}
                    onkeydown={(e) => { if (e.key === 'Enter') catInsertAt(face.catSegs.length) }} />
                <button class="kf-chips-done" onclick={commitCat} title="done — enters whatever's in the boxes">✓</button>
            </div>
        {:else}
            <button class="kf-stair" onclick={openCat} title="click to edit">
                <span class="kf-stair-lbl">section</span>
                <span class="kf-stair-path">
                    {#each face.catSegs as seg, i}
                        <span class="bit">{#if i === 0}<span class="sl">/</span>{/if}<span class="seg cat">{seg}</span><span class="sl">/</span></span>
                    {/each}
                    {#if !face.catSegs.length}<span class="kf-stair-empty">none</span>{/if}
                </span>
            </button>
        {/if}

        <!-- DIRECTORIES — theirs: the shared source prefix, same chip+gap editing, different accent, never
             a box around the track list (that's what "spilled out" below is for). -->
        {#if dirsEditing}
            <div class="kf-chips">
                {#each dirsSegsFrozen as seg, i}
                    <input class="kf-gap dirs" placeholder="+" list="kf-dirs-known" value={dirsGaps[i]}
                        oninput={(e) => { dirsGaps[i] = (e.currentTarget as HTMLInputElement).value }}
                        onkeydown={(e) => { if (e.key === 'Enter') dirsInsertAt(i) }} />
                    <!-- the chunk itself is EDITABLE (the human 2026-08-05) — a directory level is usually
                         nearly right, so retyping it whole through remove+insert was the wrong gesture.  It
                         edits the frozen draft; ENTER or ✓ commits the row. -->
                    <span class="kf-chip dirs">
                        <input class="kf-chipin" bind:value={dirsSegsFrozen[i]} size={Math.max(2, seg.length)}
                            title="edit this directory level"
                            onkeydown={(e) => { if (e.key === 'Enter') commitDirs() }} />
                        <DeleteX ondelete={() => dirsRemoveAt(i)} title="remove this directory level" />
                    </span>
                {/each}
                <input class="kf-gap dirs" placeholder="+" list="kf-dirs-known" value={dirsGaps[dirsSegsFrozen.length]}
                    oninput={(e) => { dirsGaps[dirsSegsFrozen.length] = (e.currentTarget as HTMLInputElement).value }}
                    onkeydown={(e) => { if (e.key === 'Enter') dirsInsertAt(dirsSegsFrozen.length) }} />
                <button class="kf-chips-done" onclick={commitDirs} title="done — enters whatever's in the boxes">✓</button>
            </div>
            <datalist id="kf-dirs-known">
                {#each face.dirsKnown as d}<option value={d}></option>{/each}
            </datalist>
        {:else}
            <button class="kf-stair" onclick={openDirs} title="click to edit">
                <span class="kf-stair-lbl">directories</span>
                <span class="kf-stair-path">
                    {#if face.dirsSegs.length}
                        {#each face.dirsSegs as seg, i}
                            <span class="bit dirs">{#if i === 0}<span class="sl">/</span>{/if}<span class="seg dirs">{deshell(seg)}</span><span class="sl">/</span></span>
                        {/each}
                    {:else}
                        <span class="kf-stair-empty">…</span>
                    {/if}
                </span>
            </button>
        {/if}

        {#if face.nTracks}
            <div class="kf-tree">
                {#if face.flat.length > 5}
                    <details class="kf-group">
                        <summary class="kf-dir"><span class="kf-car">▸</span> ×{face.flat.length} tracks</summary>
                        {#each face.flat as t}
                            <button class="kf-track" class:kept={t.kept} class:seed={t.seed} onclick={() => toggle(t.ref)}
                                title={t.seed ? 'the track you\'re hearing' : (t.kept ? 'keeping — click to skip' : 'skipped — click to keep')}>
                                <span class="kf-tick">{t.kept ? '✓' : '·'}</span>
                                <span class="kf-tname">{t.title}{#if t.seed} ♪{/if}</span>
                            </button>
                        {/each}
                    </details>
                {:else if face.flat.length}
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
    .kf-queued {
        pointer-events: auto; cursor: pointer; width: 100%; text-align: left;
        background: none; border: none; color: #a894a0; font: inherit;
        font-size: 10px; opacity: 0.75; margin-top: 3px; padding: 0;
    }
    .kf-queued:hover { color: #e0cfd8; opacity: 1; text-decoration: underline; text-decoration-color: #55414f; }
    .kf-dim { font-size: 9px; opacity: 0.55; }

    /* section / directories — a calm, non-enclosing breadcrumb; slashes stay neutral so the eye reads
       structure, segment names carry the colour.  A plain button, no border/background at rest — this must
       NOT read as a box that could also hold the track list (that's the duplication the human flagged). */
    .kf-stair {
        pointer-events: auto;
        cursor: pointer;
        display: flex;
        align-items: baseline;
        flex-wrap: wrap;
        gap: 2px 5px;
        width: 100%;
        background: transparent;
        border: none;
        padding: 3px 0 0;
        text-align: left;
        font: inherit;
        color: inherit;
    }
    .kf-stair:hover .kf-stair-path .bit { text-decoration: underline; text-decoration-color: #66495a; }
    .kf-stair-lbl { font-size: 8.5px; text-transform: uppercase; letter-spacing: 0.05em; opacity: 0.45; flex: none; }
    /* wrap between path bits, never inside one — min-width:0 is the flexbox fix that lets this shrink
       and wrap instead of overflowing its row (a flex item won't shrink below content size otherwise). */
    .kf-stair-path { font-size: 10.5px; flex: 1 1 auto; min-width: 0; white-space: normal; }
    .kf-stair-path .bit { display: inline-block; white-space: nowrap; }
    /* DIRECTORIES break INSIDE a chunk (the human 2026-08-05: "word-breaky chunks").  Theirs are source
       folder names — '2009 Resonating Earth (2009) [WEB, Album, NL, …]' — routinely wider than the whole
       cell, so nowrap made one segment decide the cell's width.  Section names are the human's own short
       words and keep the tidy never-break-a-name rule. */
    .kf-stair-path .bit.dirs { white-space: normal; overflow-wrap: anywhere; }
    .kf-stair-path .sl { color: #6b5a68; }
    .kf-stair-path .seg.cat { color: #7fe8bf; }
    .kf-stair-path .seg.dirs { color: #c9a5e8; }
    .kf-stair-empty { color: #6b5a68; font-style: italic; }

    /* chip + gap editing — small, inline, no restated summary alongside it (the rest-view breadcrumb
       above is hidden while this shows).  Gaps are DELIBERATELY tiny (a "+" you grow by typing into),
       not full-width boxes — the segments themselves carry the visual weight, not the empty slots. */
    .kf-chips { display: flex; flex-wrap: wrap; align-items: center; gap: 3px; margin-top: 3px; pointer-events: auto; }
    .kf-gap {
        width: 16px;
        background: transparent;
        color: #f0dbe6;
        border: 1px dashed #55414f;
        border-radius: 5px;
        font-size: 10px;
        text-align: center;
        padding: 2px 1px;
        font-family: inherit;
        transition: width 0.12s;
    }
    .kf-gap:focus, .kf-gap:not(:placeholder-shown) { width: 64px; text-align: left; padding-left: 5px; }
    .kf-gap.dirs { border-color: #52456a; }
    .kf-gap::placeholder { color: #6b5a68; }
    .kf-chip {
        display: inline-flex; align-items: center; gap: 3px;
        background: #241820; border-radius: 6px; padding: 2px 3px 2px 7px;
        font-size: 10.5px; color: #7fe8bf; white-space: nowrap;
    }
    .kf-chip.dirs { color: #c9a5e8; white-space: normal; overflow-wrap: anywhere; max-width: 100%; }
    /* the in-place chunk editor: an input that looks like the chip's own text (no box, no chrome) until
       it has focus, so the row still reads as chips rather than a form.  `size` on the element keeps it
       content-width; max-width lets a long one wrap-shrink instead of pushing the cell wide. */
    .kf-chipin {
        background: transparent; border: none; padding: 0; margin: 0;
        color: inherit; font: inherit; font-size: 10.5px; max-width: 100%;
        border-bottom: 1px solid transparent;
    }
    .kf-chipin:hover { border-bottom-color: #52456a; }
    .kf-chipin:focus { outline: none; border-bottom-color: #c9a5e8; }
    .kf-chips-done {
        cursor: pointer; background: none; border: none; color: #57c777;
        font-size: 11px; padding: 0 2px; line-height: 1;
    }

    .kf-tree { margin-top: 6px; display: flex; flex-direction: column; gap: 1px; }
    .kf-group { border-radius: 5px; }
    .kf-dir, .kf-dir-flat { font-size: 9px; opacity: 0.7; margin-top: 3px; color: #cfc0d8; display: flex; align-items: center; gap: 5px; cursor: default; }
    summary.kf-dir { pointer-events: auto; cursor: pointer; list-style: none; }
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
