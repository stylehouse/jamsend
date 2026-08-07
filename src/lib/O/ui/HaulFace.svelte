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
    lifewatch(H, 'face:Haul', () => String(n?.sc?.Haul || n?.sc?.id || '?'))

    // in-place editing — SEGMENTS, not one field (the human 2026-07-30, correcting a prior over-
    //  simplification): editing either hierarchy is a row of small chips (one per segment, its own × to
    //   remove it) with a small "+" gap BEFORE the first, BETWEEN every pair, and AFTER the last — N
    //    segments, N+1 gaps, each gap its own tiny input that inserts a new segment at exactly that
    //     position. catGaps/dirsGaps hold each gap's in-progress typing, resized to segs.length+1 whenever
    //      the segment count changes.
    // the rows are always open now, so there is no editing flag — but `dirsKnown` walks the collection and
    //  this derive re-runs on every H.version bump, so the suggestion list stays gated on FOCUS rather than
    //   being computed forever just because the row is visible.
    let dirsFocus = $state(false)
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
    // ALWAYS-OPEN EDITING (the human 2026-08-07: "if we click on directories|sections we probably want to
    //  create one. actually perhaps they're already open|editable-mode. we don't need the ticks then!").
    //   Both breadcrumbs now stand in chip form permanently, so there is no open gesture and no ✓ to
    //    forget — every gap is a live input and every chip is directly editable.  The freeze that openDirs
    //     used to do on click still has to happen (dirsAuto moves while husks materialise — see above), so
    //      it is done by the effect below instead: re-seed from the live derive until the human touches a
    //       box, then never again.  `dirsTouched` is the whole difference between "following the source"
    //        and "this is mine now"; without it a keystroke would be overwritten by the next husk to land.
    let dirsTouched = $state(false)
    $effect(() => {
        const segs = face.dirsSegs
        const auto = face.dirsAuto
        if (dirsTouched) return
        dirsSegsFrozen = segs.map(deshell)
        dirsAutoFrozen = auto
    })

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
        const at = String(sc.pub || sc.at || '')   // `pub` since 2026-08-05; `at` fallback for a particle minted pre-rename
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
        // THE CP, NOT THE RAW PATH (the human 2026-08-07: "it still isn't noticing the '0 spawn' and '0
        //  folks' are sections").  A marker-prefixed leading folder is a SECTION — the same vocabulary the
        //   category row above uses — so it belongs in `section`, not swallowed into `directories`.  Reading
        //    the raw path put `0 spawn › - folks › - arabia` in the directories breadcrumb, which then ALSO
        //     got prepended under whatever category you chose: the keep landed filed twice.  Heist_cp_path
        //      is the one door that strips them (and the one the landing itself goes through), so ask it
        //       rather than re-deriving the rule in the face.
        const cpOf = (h: any) => (typeof A?.Heist_cp_path === 'function' ? String(A.Heist_cp_path(h) || '') : String(h?.sc?.path || ''))
        const dirsAuto = commonPrefix(husks.map((h: any) => dirOf(cpOf(h))))
        const dirsRaw = (sc.dirs != null && sc.dirs !== '') ? String(sc.dirs) : dirsAuto
        const dirsSegs = dirsRaw.split('/').filter(Boolean)
        const artist = String(sc.artist || '')
        const dirsKnown = (dirsFocus && own && A?.Heist_known_dirs) ? A.Heist_known_dirs(own, artist) : []

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
            const path = cpOf(r)   // sections already off, so a group label never restates the section row
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

        // THE TRACK UNDER THE NEEDLE, for the running strip (the human 2026-08-07: "put the most recent
        //  track downloading at the end").  Heist_land walks picks IN ORDER with at most `heist_inflight`
        //   live, so the first un-landed pick IS the one moving; once they're all landed the last one is
        //    what just finished.  Titles come from the husks by ref — if the mirror has been swept the map
        //     is empty and this is simply blank, which is better than inventing a name.
        const titleByRef = new Map(husks.map((h: any) => [String(h.sc.id), String(h.sc.title || fileOf(cpOf(h), String(h.sc.id)))]))
        const ordered = picks.map((p: any) => ({ ref: String(p.sc.ref ?? p.sc.id), landed: !!p.sc.landed }))
        const moving = ordered.find((p: any) => !p.landed) || [...ordered].reverse().find((p: any) => p.landed)
        const nowTrack = moving ? (titleByRef.get(moving.ref) || '') : ''

        const genre = catRaw
        return {
            nowTrack, nowDone: !!(moving && moving.landed),
            state,
            title: String(sc.Haul || 'this track'),
            artist: String(sc.artist || ''),
            from: String(sc.from_name || 'a friend'),
            // the REAL dest-root (see HaulBarFace): no invented `music/` root, and no `Unfiled` folder —
            //  an unpinned artist prepends NOTHING and the source's own folders land at the collection root.
            dest: String(genre || '').split('/').map((p: string) => String(p || '').trim().replace(/[\/\x00]/g, '-').replace(/^-(?= )/, '0')).filter(Boolean).join('/'),
            asks: +(sc.asks || 0),
            // the wish wins until the model catches up, then it retires itself (see toggleLofi)
            lofi: (lofiWish !== null && lofiWish !== !!sc.lofi) ? lofiWish : !!sc.lofi,
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

    // openCat/openDirs are GONE (2026-08-07): the rows never close, so there is nothing to open.  The
    //  auto-focus openCat did on an empty category is covered by the gap's own placeholder prompt, and the
    //   freeze openDirs did is now the $effect above — it has to re-seed as husks land, which a one-shot
    //    click handler could never do.
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
        dirsTouched = true
        dirsSegsFrozen = segs
        A?.post_do?.(() => { A?.Heist_keep_set_dirs?.(n, segs.join('/'), dirsAutoFrozen) }, { see: 'keep directories insert' })
    }
    function dirsRemoveAt(i: number) {
        const segs = dirsSegsFrozen.slice()
        segs.splice(i, 1)
        dirsTouched = true
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
        A?.post_do?.(() => { A?.Heist_keep_set_genre?.(n, segs.join('/')) }, { see: 'keep category commit' })
    }
    function commitDirs() {
        // deshell on the way OUT: whatever the human left in the boxes, what gets written is the
        //  shell-safe form (see deshell above).
        const segs = foldGaps(dirsSegsFrozen, dirsGaps).map(deshell)
        dirsGaps = ['']
        dirsTouched = true
        dirsSegsFrozen = segs
        A?.post_do?.(() => { A?.Heist_keep_set_dirs?.(n, segs.join('/'), dirsAutoFrozen) }, { see: 'keep directories commit' })
    }
    // the rows never close now, so a commit is whatever ENDS an edit: ENTER in a box, or leaving it.  Blur
    //  matters more than it used to — with no ✓ to press, tabbing away IS the gesture, and dropping what
    //   was typed there would be the same silent loss the ✓ fix cured on 2026-08-05.

    function toggle(ref: string) {
        A?.post_do?.(() => { A?.Heist_keep_pick_toggle?.(n, ref) }, { see: 'keep pick' })
    }
    function cancel() {
        A?.post_do?.(() => { A?.Heist_keep_cancel?.(A?.top_House?.()?.c?.radio_w, n) }, { see: 'keep cancel' })
    }
    // SCRUB = cancel + delete what landed.  Two-press arm rather than a window.confirm: the confirm dialog
    //  blocks the belief loop while it sits open, and this button lives on a cell that is actively pulling.
    //   The armed state is deliberately per-cell local — it must never survive a re-render into a click.
    let scrubArmed = $state(false)
    // ✕ ARMS TOO (the human 2026-08-07: "then the X (with a cancelation confirm thing)").  Same two-press
    //  shape as 🗑 and for the same reason — never window.confirm, which blocks the belief loop while it
    //   sits open.  Dropping a keep you spent a minute filing is not recoverable, so it gets the same
    //    deliberate second press that deleting files does.
    //  THE ARM LIVES IN DeleteX NOW, and holding a second one here made it a THREE-press button: DeleteX
    //   is itself a two-press affordance (press 1 swells it to "delete?", press 2 fires `ondelete`), so
    //    an outer `cancelArmed` that only *armed* on ondelete added a third press behind a differently-
    //     worded button that appeared where the ✕ had been.  Two presses was the ask; one arm delivers it.
    // the track list, folded behind the count chip.  The header carries `Haul:n` now, so the old
    //  `<details> ×8 tracks` summary said the number twice and hid the one track you actually recognise.
    let tracksOpen = $state(false)
    // the lofi explainer — an inline popover, not a title= tooltip: a tooltip cannot be read on a phone,
    //  which is the exact device lofi exists for.
    let lofiWhy = $state(false)
    function scrub() {
        scrubArmed = false
        A?.post_do?.(() => { A?.Heist_keep_scrub?.(A?.top_House?.()?.c?.radio_w, n) }, { see: 'keep scrub' })
    }

    function start() { A?.post_do?.(() => { A?.Heist_keep_start?.(n) }, { see: 'keep start' }) }
    // lofi — the phone answer.  Framed as what it does to the TRANSFER, not as a codec setting: the friend
    //  transcodes and sends the small thing, which is the only reason to want it.  Settable while primed and
    //   read by the want-ask at ▶ start, so it must sit here beside the other pre-start tweaks.
    // OPTIMISTIC, AND ABSOLUTE (the human 2026-08-07: "clicking the LOFI tickbox can have no apparent
    //  effect (not toggle it), then later the events catch up and it becomes unticked (clicked twice) when
    //   we're hitting start. that's how it must have happened").  Two bugs in one line, both from deferral:
    //    · NO FEEDBACK — post_do runs on the next belief pass, so the box sat unmoved and invited a second
    //       click.  `wish` is the local truth until the model agrees, so the tick is instant.
    //    · A TOGGLE READ LATE — `!n.sc.lofi` was evaluated when the deferred call RAN, not when you clicked,
    //       so two queued clicks both read the same pre-state and the pair landed as one flip, or worse,
    //        raced the ▶ start that followed.  Send the ABSOLUTE value instead: N clicks settle on the Nth
    //         wish, whatever order the passes come in.
    let lofiWish = $state<boolean | null>(null)
    function toggleLofi() {
        const want = !(lofiWish ?? !!n?.sc?.lofi)
        lofiWish = want
        A?.post_do?.(() => { A?.Heist_keep_set_lofi?.(n, want) }, { see: 'keep lofi' })
    }
    function focus() { A?.post_do?.(() => { A?.Heist_keep_touch?.(n) }, { see: 'keep focus' }) }
</script>

<div class="kf" class:folded={face.folded || face.unfocused}>
    <!-- THE HEAD IS THE PARTICLE (the human 2026-08-07: "better than opening the x8 tracks thing is to
         heading it as a Heist:$n (or whatever key we use there)").  The key is `Haul` — this cell IS one
         %Haul — so the head reads `Haul:8` and the count stops being a thing you open a disclosure to
         learn.  The TRACK NAME moves down below the filing rows, where it sits beside "+n tracks": you
         choose where it lands first, then confirm what it is. -->
    <div class="kf-head">
        <span class="kf-badge">{face.state === 'done' ? '✓' : '⇊'}</span>
        {#if face.folded || face.unfocused}
            <!-- once it's running the name is what you're looking for, not the shape of the particle -->
            <span class="kf-title" title={face.title}>{face.title}</span>
            {#if face.artist}<span class="kf-artist">{face.artist}</span>{/if}
        {:else}
            <span class="kf-mk">Haul{#if face.nTracks}<span class="kf-mkv">:{face.nTracks}</span>{/if}</span>
        {/if}
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
        <!-- THE RUNNING STRIP (the human 2026-08-07: "can we redo the Heisting look... make the 5/13 bigger,
             and include all the DIRECTORIES as well, but in different colours, and put the most recent track
             downloading at the end. fun.").  It used to flatten the destination into one grey `dest` string,
             which threw away the very distinction the primed view spends two rows teaching: SECTION is mine,
             DIRECTORIES are theirs.  Same two colours here as up there (mint / lilac), so the place you filed
             it to is legible at a glance while it runs — and the count leads, big, because that is the number
             you actually came back to look at. -->
        <div class="kf-prog">
            <span class="kf-count" class:done={face.state === 'done'}>
                {face.landed_n}<span class="kf-count-of">/{face.total_n || '?'}</span>
            </span>
            <span class="kf-dest-bits">
                {#each face.catSegs as seg}<span class="seg cat">{seg}</span><span class="sl">/</span>{/each}
                {#each face.dirsSegs as seg}<span class="seg dirs">{deshell(seg)}</span><span class="sl">/</span>{/each}
                {#if !face.catSegs.length && !face.dirsSegs.length}<span class="kf-dim">your collection</span>{/if}
            </span>
            {#if face.nowTrack}
                <span class="kf-nowtrack" class:done={face.nowDone}>{face.nowTrack}</span>
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
        <!-- CANCEL A RUNNING HEIST (the human 2026-08-05).  A started heist had NO way out at all — the ✕
             lived only in the primed footer below, so once it folded down your only options were to let it
             finish or reload.  Two distinct exits, because they are genuinely different intentions:
             ✕ stops asking for more and KEEPS what already landed (a half album you decided is enough);
             🗑 stops AND takes back every file this heist wrote, which is the one you want when testing. -->
        <div class="kf-foot">
            <span class="kf-dim">{face.landed_n ? `${face.landed_n} track${face.landed_n === 1 ? '' : 's'} already on disk` : 'nothing landed yet'}</span>
            <span class="kf-exits">
                <button class="kf-x" onclick={cancel} title="stop this heist — keep the tracks that already landed">✕ stop</button>
                {#if face.landed_n}
                    {#if scrubArmed}
                        <button class="kf-scrub armed" onclick={scrub}
                            title="really delete the {face.landed_n} landed file{face.landed_n === 1 ? '' : 's'}">delete {face.landed_n}?</button>
                        <button class="kf-x" onclick={() => (scrubArmed = false)} title="never mind">↩</button>
                    {:else}
                        <button class="kf-scrub" onclick={() => (scrubArmed = true)}
                            title="stop this heist AND delete what it already downloaded">🗑 undo</button>
                    {/if}
                {/if}
            </span>
        </div>
    {:else}
        <!-- PRIMED: sits in the clutter, tweakable, until you press ▶ start (no auto-start) -->

        <!-- SECTION — mine, optional, nestable. click the breadcrumb to edit; editing = one chip per
             segment (its own × to remove) with a small "+" gap before/between/after every chip, each gap
             its own tiny input that inserts a new segment right there. -->
        <!-- THE LABEL RIDES IN THE FLOW (the human 2026-08-07: "the section|directories headings should be
             inline with them all, that way we can get that first ' + ' button with something else").  It was
             a fixed 60px column, which cost a whole column of width on a narrow cell AND forced a leading
             gap-input nobody wanted.  Inline, the label is simply the first thing in the run, and the
             hanging indent (.kf-row) keeps wrapped lines clear of it. -->
        <div class="kf-row">
            <span class="kf-stair-lbl">section</span>
            <!-- THE LEADING GAP IS LOAD-BEARING (the human 2026-08-07: "the leading ' + ' button is gone!
                 it should be there, to unshift a toplevel classification").  Going inline, I read "we can
                 get that first ' + ' button with something else" as "drop it" — it meant the LABEL takes
                 that spot in the reading order, not that the control goes away.  Without it there is no
                 gesture at all for prepending a level above everything: every other gap inserts AFTER a
                 chip, so the top of the hierarchy was the one position you could not reach. -->
            {#if face.catSegs.length}
                <input class="kf-gap" placeholder="+" value={catGaps[0]} title="add a section above these"
                    oninput={(e) => { catGaps[0] = (e.currentTarget as HTMLInputElement).value }}
                    onblur={commitCat}
                    onkeydown={(e) => { if (e.key === 'Enter') catInsertAt(0) }} />
            {/if}
            {#each face.catSegs as seg, i}
                <span class="kf-chip cat">{seg}<DeleteX ondelete={() => catRemoveAt(i)} title="remove this section level" /></span>
                <input class="kf-gap" placeholder="+" value={catGaps[i + 1]}
                    oninput={(e) => { catGaps[i + 1] = (e.currentTarget as HTMLInputElement).value }}
                    onblur={commitCat}
                    onkeydown={(e) => { if (e.key === 'Enter') catInsertAt(i + 1) }} />
            {/each}
            {#if !face.catSegs.length}
                <input class="kf-gap wide" placeholder="name a section…"
                    value={catGaps[0]} bind:this={catFirstInput}
                    oninput={(e) => { catGaps[0] = (e.currentTarget as HTMLInputElement).value }}
                    onblur={commitCat}
                    onkeydown={(e) => { if (e.key === 'Enter') catInsertAt(0) }} />
            {/if}
        </div>

        <!-- DIRECTORIES — theirs: the shared source prefix, same chip+gap editing, different accent, never
             a box around the track list (that's what "spilled out" below is for). -->
        <div class="kf-row">
            <span class="kf-stair-lbl">directories</span>
            {#if dirsSegsFrozen.length}
                <input class="kf-gap dirs" placeholder="+" list="kf-dirs-known" value={dirsGaps[0]}
                    title="add a directory above these"
                    onfocus={() => (dirsFocus = true)}
                    oninput={(e) => { dirsGaps[0] = (e.currentTarget as HTMLInputElement).value }}
                    onblur={commitDirs}
                    onkeydown={(e) => { if (e.key === 'Enter') dirsInsertAt(0) }} />
            {/if}
            {#each dirsSegsFrozen as seg, i}
                <!-- the chunk itself is EDITABLE (the human 2026-08-05) — a directory level is usually
                     nearly right, so retyping it whole through remove+insert was the wrong gesture.  It
                     edits the frozen draft; ENTER or leaving the box commits the row. -->
                <span class="kf-chip dirs">
                    <input class="kf-chipin" bind:value={dirsSegsFrozen[i]} size={Math.max(2, seg.length)}
                        title="edit this directory level"
                        onfocus={() => (dirsFocus = true)}
                        oninput={() => (dirsTouched = true)}
                        onblur={commitDirs}
                        onkeydown={(e) => { if (e.key === 'Enter') commitDirs() }} />
                    <DeleteX ondelete={() => dirsRemoveAt(i)} title="remove this directory level" />
                </span>
                <input class="kf-gap dirs" placeholder="+" list="kf-dirs-known" value={dirsGaps[i + 1]}
                    onfocus={() => (dirsFocus = true)}
                    oninput={(e) => { dirsGaps[i + 1] = (e.currentTarget as HTMLInputElement).value }}
                    onblur={commitDirs}
                    onkeydown={(e) => { if (e.key === 'Enter') dirsInsertAt(i + 1) }} />
            {/each}
            {#if !dirsSegsFrozen.length}
                <input class="kf-gap dirs wide" placeholder="no folders — add one?"
                    list="kf-dirs-known" value={dirsGaps[0]}
                    onfocus={() => (dirsFocus = true)}
                    oninput={(e) => { dirsGaps[0] = (e.currentTarget as HTMLInputElement).value }}
                    onblur={commitDirs}
                    onkeydown={(e) => { if (e.key === 'Enter') dirsInsertAt(0) }} />
            {/if}
        </div>
        <datalist id="kf-dirs-known">
            {#each face.dirsKnown as d}<option value={d}></option>{/each}
        </datalist>

        <!-- WHAT IT IS, after WHERE IT GOES.  One line: the track you recognise, and the count of everything
             riding with it.  "+n tracks" is a button because the picking UI still has to live somewhere —
             it just no longer greets you with a disclosure triangle you must open to see a track name. -->
        <div class="kf-what">
            <span class="kf-wtitle" title={face.title}>{face.title}</span>
            {#if face.artist}<span class="kf-wartist">{face.artist}</span>{/if}
            {#if face.nTracks > 1}
                <button class="kf-more" class:on={tracksOpen} onclick={() => (tracksOpen = !tracksOpen)}
                        title={tracksOpen ? 'hide the other tracks' : 'choose which tracks to keep'}>
                    +{face.nTracks - 1} track{face.nTracks - 1 === 1 ? '' : 's'}
                </button>
            {/if}
        </div>

        {#if face.nTracks && tracksOpen}
            <div class="kf-tree">
                {#each face.flat as t}
                    <button class="kf-track" class:kept={t.kept} class:seed={t.seed} onclick={() => toggle(t.ref)}
                        title={t.seed ? 'the track you\'re hearing' : (t.kept ? 'keeping — click to skip' : 'skipped — click to keep')}>
                        <span class="kf-tick">{t.kept ? '✓' : '·'}</span>
                        <span class="kf-tname">{t.title}{#if t.seed} ♪{/if}</span>
                    </button>
                {/each}
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
        {/if}
        <!-- NO SKELETON (the human 2026-08-07: "is what is pointlessly hanging around in the Haul").  Three
             shimmer bars and "finding the folder…" promised guts that are still coming — but the folder
             answer is a single round trip that either lands or never does (measured 2026-08-07: zero
             %Rummage asks in the world while it sat there "finding" forever), so the animation was a
             progress indicator for something that was not in progress.  The head already says `Haul:n`,
             which reads honestly as "no tracks known yet" when n is absent. -->
        {#if lofiWhy}
            <!-- the explainer the "?" opens.  Inline, not a title= tooltip: lofi exists FOR the phone, and a
                 phone has no hover — an explanation you can only reach with a mouse is no explanation. -->
            <div class="kf-why">
                <strong>lofi</strong> asks your friend to re-encode each track as a small <strong>.ogg</strong>
                (Opus, 128kbps) and send that instead of the original file. A typical album drops from a few
                hundred MB to a few tens — much faster over the wire, and much kinder to a phone that hasn't
                the room for lossless. The original stays on <em>their</em> disk untouched; you just receive
                the smaller rendition. Leave it off when you want the exact files, bit for bit.
                <button class="kf-why-x" onclick={() => (lofiWhy = false)} title="close">✕</button>
            </div>
        {/if}
        <div class="kf-foot">
            <button class="kf-start" onclick={start} title="start downloading these tracks into your collection">▶ start</button>
            <!-- lofi and its "?" are ONE unit (the human 2026-08-07: "the '?' should be closer to the
                 LOFI") — the gap that separates groups in this footer must not fall between a control and
                 its own explainer. -->
            <span class="kf-lofi-grp">
                <button class="kf-lofi" class:on={face.lofi} onclick={toggleLofi}
                        title="ask your friend to send a small .ogg instead of the original file">
                    <span class="kf-lofi-box">{face.lofi ? '☑' : '☐'}</span>
                    <span class="kf-lofi-lbl">lofi</span>
                </button>
                <button class="kf-q" onclick={() => (lofiWhy = !lofiWhy)} title="what does lofi do?">?</button>
            </span>
            <span class="kf-exits">
                {#if face.landed_n}
                    {#if scrubArmed}
                        <button class="kf-scrub armed" onclick={scrub}
                            title="really delete the {face.landed_n} landed file{face.landed_n === 1 ? '' : 's'}">delete {face.landed_n}?</button>
                        <button class="kf-x" onclick={() => (scrubArmed = false)} title="never mind">↩</button>
                    {:else}
                        <button class="kf-scrub" onclick={() => (scrubArmed = true)}
                            title="drop this AND delete what it already downloaded">🗑 undo</button>
                    {/if}
                {/if}
                <!-- the standard delete affordance (the human 2026-08-07: "the 'x' button should use the
                     standard UI for doing that, like the path bits do") — micro/DeleteX, the same component
                     every chip's × already is, so dropping a heist looks like dropping anything else.  The
                     ARM stays (it is DeleteX's own two-press), and `big` gives this one the red orb: a
                     chip is one typed word, a heist is a minute of filing, so its exit is findable. -->
                <DeleteX big ondelete={cancel} title="don't keep — drop this heist" />
            </span>
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

    /* the row LABEL is all that survives of the old read-only breadcrumb (.kf-stair* went with the
       always-open rework — the chips ARE the display now, so a separate rendering of the same path was
       two things to keep in agreement and one of them was always a click behind). */
    .kf-stair-lbl { font-size: 8.5px; text-transform: uppercase; letter-spacing: 0.05em; opacity: 0.45; flex: none; }

    /* lofi — sits with the two breadcrumb rows because it is the same kind of thing: a pre-start decision
       about what lands.  Reads as one line off by default, so it never competes with section|directories. */
    .kf-lofi {
        pointer-events: auto;
        cursor: pointer;
        display: flex;
        align-items: baseline;
        gap: 5px;
        width: 100%;
        background: transparent;
        border: none;
        padding: 4px 0 0;
        text-align: left;
        font: inherit;
        color: inherit;
        opacity: 0.6;
    }
    .kf-lofi:hover, .kf-lofi.on { opacity: 1; }
    .kf-lofi-box { font-size: 11px; color: #7fe8bf; flex: none; }
    .kf-lofi-lbl { font-size: 9.5px; text-transform: uppercase; letter-spacing: 0.05em; flex: none; }
    .kf-lofi.on .kf-lofi-lbl { color: #7fe8bf; }

    /* chip + gap editing — small, inline, no restated summary alongside it (the rest-view breadcrumb
       above is hidden while this shows).  Gaps are DELIBERATELY tiny (a "+" you grow by typing into),
       not full-width boxes — the segments themselves carry the visual weight, not the empty slots. */
    /* .kf-chips (the flex wrapper) is gone with the rows going inline — see .kf-row's hanging indent for
       why flex had to go.  Its pointer-events:auto moved onto the chips and gaps themselves. */
    .kf-chip, .kf-gap { pointer-events: auto; }
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
    /* .kf-chips-done went with the ✓ button — "we don't need the ticks then!" */

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
    /* .kf-skel / .kf-shim / .kf-note went with the skeleton — a shimmer is a promise that something is
       coming, and this one was made on behalf of a round trip that had never been sent. */
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
    /* the two exits sit together at the right of the footer — stop (keep the files) beside undo (delete
       them).  `undo` stays quiet until armed, then goes loud: a destructive verb should look like one
       only once it is actually one click from happening. */
    .kf-exits { display: flex; align-items: center; gap: 6px; }
    .kf-scrub {
        border: 1px solid #6b3a4a; background: transparent; color: #c98ea0;
        border-radius: 5px; padding: 2px 7px; font-size: 11px; cursor: pointer; white-space: nowrap;
    }
    .kf-scrub:hover { border-color: #d94f7a; color: #ffd7e2; }
    .kf-scrub.armed { background: #d94f7a; border-color: #d94f7a; color: #1a0810; font-weight: 600; }

    /* ── the always-open filing rows (2026-08-07) ─────────────────────────────────────────────────── */
    /* label and chips on ONE line, the label a fixed narrow column so section and directories align
       vertically — they are a pair and read as a stack of two decisions, not two unrelated widgets. */
    /* HANGING INDENT, and it is why these are BLOCKS rather than flex rows (the human 2026-08-07: "do that
       thing so the non-first line (the wrapped lines) are indented, it's a css property... but each
       section|directories|tracks is a block").  `text-indent: -N` pulls the FIRST line back to the margin
       while `padding-left: N` holds every wrapped line in — so the label starts flush and the chips that
       wrap below it line up in their own column.  Flex cannot do this at all: flex items don't participate
       in inline layout, so there are no "wrapped lines" for an indent to act on.  Hence inline-block chips
       in normal flow, and `text-indent: 0` on the children so none of them inherits the negative pull. */
    .kf-row, .kf-what {
        display: block; margin-top: 5px;
        padding-left: 16px; text-indent: -16px;
        line-height: 1.9;
    }
    .kf-row > *, .kf-what > * { text-indent: 0; }
    .kf-row .kf-stair-lbl { margin-right: 5px; vertical-align: middle; }
    .kf-row .kf-chip, .kf-row .kf-gap { vertical-align: middle; }
    /* an empty row has no chips to hint what it's for, so its lone gap grows and carries the prompt */
    .kf-gap.wide { width: auto; min-width: 108px; font-style: italic; }

    /* the mainkey head — same vocabulary as TreeFace (mainkey bright, its value dimmer beside it) */
    .kf-mk { color: #ffd869; font-weight: 700; font-size: 11px; letter-spacing: 0.02em; }
    .kf-mkv { color: #d8b45a; font-weight: 400; }

    /* WHAT IT IS — the track you recognise, under the two WHERE-IT-GOES rows (block + hanging indent above) */
    .kf-what { margin-top: 7px; }
    .kf-what > * { margin-right: 6px; }
    .kf-wtitle { font-size: 12px; color: #f3e8ef; font-weight: 600; min-width: 0; overflow-wrap: anywhere; }
    .kf-wartist { font-size: 10px; color: #b89ab0; }
    .kf-more {
        pointer-events: auto;
        background: rgba(201, 165, 232, 0.13); border: 1px solid rgba(201, 165, 232, 0.28);
        border-radius: 999px; padding: 1px 7px; cursor: pointer;
        color: #c9a5e8; font-size: 9.5px; font-family: inherit;
    }
    .kf-more:hover, .kf-more.on { background: rgba(201, 165, 232, 0.24); color: #e8d7f6; }

    /* the lofi explainer — a real panel, because a phone cannot hover a tooltip */
    /* lofi + "?" as one unit, so the footer's justify gap falls BETWEEN groups, never inside this one */
    .kf-lofi-grp { display: inline-flex; align-items: center; gap: 3px; }
    .kf-q {
        pointer-events: auto;
        background: none; border: 1px solid #66495a; border-radius: 999px;
        width: 15px; height: 15px; padding: 0; flex: none; cursor: pointer;
        color: #b89ab0; font-size: 9px; line-height: 1; font-family: inherit;
    }
    .kf-q:hover { border-color: #7fe8bf; color: #7fe8bf; }
    .kf-why {
        position: relative; margin-top: 7px; padding: 7px 20px 7px 8px;
        background: rgba(127, 232, 191, 0.07); border: 1px solid rgba(127, 232, 191, 0.22);
        border-radius: 4px; font-size: 9.5px; line-height: 1.5; color: #cfe8dd;
    }
    .kf-why strong { color: #7fe8bf; font-weight: 600; }
    .kf-why-x {
        pointer-events: auto; position: absolute; top: 3px; right: 4px;
        background: none; border: 0; padding: 0; cursor: pointer; color: #6b8a7e; font-size: 9px;
    }
    .kf-why-x:hover { color: #7fe8bf; }

    /* ── the running strip ────────────────────────────────────────────────────────────────────────── */
    /* hanging indent again, so a long destination wraps clear of the big count instead of under it */
    .kf-prog { display: block; padding-left: 18px; text-indent: -18px; line-height: 1.8; }
    .kf-prog > * { text-indent: 0; vertical-align: baseline; }
    .kf-count { font-size: 17px; font-weight: 700; color: #f3e8ef; margin-right: 7px; letter-spacing: -0.01em; }
    .kf-count.done { color: #7fe8bf; }
    .kf-count-of { font-size: 11px; font-weight: 400; color: #9a8a96; }
    /* the SAME two colours the primed rows teach: mint = my section, lilac = their directories */
    .kf-dest-bits .seg.cat { color: #7fe8bf; font-size: 11px; }
    .kf-dest-bits .seg.dirs { color: #c9a5e8; font-size: 11px; overflow-wrap: anywhere; }
    .kf-dest-bits .sl { color: #6b5a68; margin: 0 3px 0 1px; }
    /* the track at the end — dimmer than the count, because it changes constantly and must not pull the eye
       away from the number.  Goes mint when it's the one that just FINISHED rather than the one moving. */
    .kf-nowtrack { font-size: 10px; color: #b89ab0; font-style: italic; overflow-wrap: anywhere; }
    .kf-nowtrack.done { color: #8fcfb4; font-style: normal; }
</style>
