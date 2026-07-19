<script lang="ts">
    // StoryRun: the UI strip for the Story test runner.
    //
    // Receives H (the Story sub-House, H:Story).
    // Reads display state from H.ave — a stable TheC whose children are
    // replicated from %watched:ave after each beliefs cycle.
    // Use .ob(filter) to read from it; ob() tracks H.ave.version for
    // Svelte reactivity without needing to touch per-child versions.
    //
    // ── This / The duality ───────────────────────────────────────────────────
    //
    //   This  — w/%This,Story:book — the live session step container.
    //           Placed into ave by Story_plan so it is visible here.
    //           Children are {Step:N} TheC particles.
    //
    //   The   — w.c.The — canonical disk record; never read here directly.
    //           story_analysis() snapshots it into display.steps as plain
    //           {n, dige} pairs so the strip can render hollow pips for steps
    //           not yet run this session.
    //
    //   live_step(n): finds the real {Step:N} TheC from This, or null if the
    //           step hasn't run yet.  Calling void Step.version inside a
    //           $derived subscribes to that particle's mutations, e.g. when
    //           exp_snap arrives asynchronously after a story_sel fetch.
    //
    // ── ave contents ─────────────────────────────────────────────────────────
    //
    //   Three particle shapes live in H.ave:
    //     {story_analysis:1}    — scalar run state written by story_analysis().
    //     {This:1, Story:book}  — the live step container (same C as w.c.This).
    //     {swatches:1}          — note colour map; children are {note_coloring,color}.
    //
    //   sw / swatchesC both point at the {swatches:1} particle; sw is the short
    //   name used internally, swatchesC the descriptive alias for readability.
    //
    // ── diff modes ────────────────────────────────────────────────────────────
    //
    //   exp       — got vs exp_snap, proper DMP diff (resyncs after insertions)
    //   exp_naive — got vs exp_snap, positional diff (line i vs line i; no resync)
    //               labelled "& exp" in the UI — useful when you want to see
    //               exactly which numbered lines shifted without any realignment.
    //   prev      — prev step got vs this step got, proper DMP diff
    //   first     — first_snap vs got_snap, DMP diff across a Resnapture session.
    //               first_snap is set by e_story_resnap just before the new snap
    //               is taken; it holds "what the snap looked like before Resnap".
    //               A popup at the top of Storui shows this diff automatically
    //               when a Resnapture fires.
    //   naive     — raw got_snap text, no diff highlighting
    //
    //   diff_mode: what this step is showing.  null = auto.
    //   sticky_mode: carried forward when navigating between steps with arrow keys
    //     or clicking a pip.  null = auto.
    //
    //   Auto logic: ok steps default to naive (raw snapshot view); mismatch steps
    //   prefer exp when exp_snap is loaded, then prev, then naive.
    //
    //   exp and prev buttons are larger — the common comparison modes.
    //   Clicking an already-active button resets diff_mode and sticky_mode to null.
    //
    // ── copy — range collection ───────────────────────────────────────────────
    //
    //   Clicking "copy diff" immediately arms this step as the anchor and enters
    //   collecting mode — the button becomes a throbbing "pick end ×".
    //   Click any other pip to collect [anchor, pip]; click × to cancel.
    //
    //   Pure text functions (compute_diff, squish_context, positional_diff,
    //   enDif, deDif, depth_of, char_diff_ops) live in Textures.svelte and
    //   arrive on H via ghostsHaunt().  Called here as T.* (T = H as any).
    //
    //   The Dif codec encodes DiffRow[] as snap lines:
    //     enDif(rows, dif_depth) → string[]
    //     deDif(lines, dif_depth) → DiffRow[]
    //
    //   collect_range output structure (all lines enL/deL/peel compatible):
    //
    //     Step:N                    depth 0
    //       Snap:1 diff:1 prev:1   depth 1  — Dif markers at depth 2
    //       Snap:1 first:1         depth 1  — no prev; raw got content at depth 2+
    //       Snap:1 not_run:1       depth 1  — step hasn't run this session
    //       Snap:1 not_loaded:1    depth 1  — ran but snap not yet fetched
    //
    // ── what stays in StoryRun ────────────────────────────────────────────────
    //
    //   ops_for_display — rendering-only, walks char ops to produce {cls,text}
    //                     spans for the intra_line snippet.  No text processing.
    //
    // ── DiffRow ───────────────────────────────────────────────────────────────
    //
    //   pair       — line present in both columns (same or internally changed)
    //   left_only  — only in reference side ('gone', red)
    //   right_only — only in got side ('neu', green)  — not 'new', JS reserved
    //   squish     — collapsed run of same lines
    //
    //   The canonical definition lives in Textures.svelte's header comment.
    //   Redeclared here for local TypeScript narrowing.
    //
    // ── note swatches ─────────────────────────────────────────────────────────
    //
    //   swatch_map is a plain Record<type,color> derived from sw.o({note_coloring:1}).
    //   ensure_swatch() in Story.svelte must be called before any note type reaches
    //   story_analysis() — it is a fatal design error to render an unswatched type.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House, TraceEvent } from "$lib/O/Housing.svelte"
    import { peel }       from "$lib/Y.svelte"
    import { fly, fade } from "svelte/transition"
    import Vexpandy       from "$lib/O/ui/Vexpandy.svelte"
    import EntropyArrest  from "$lib/O/ui/EntropyArrest.svelte"

    let { H }: { H: House } = $props()

    // story_w — the Story world (A:Story/w:Story), same lookup story_save uses.
    //   EntropyArrest reads its The/EntropyArrest bucket and elvistos commits back.
    let story_w = $derived.by((): TheC | undefined => {
        const A = H.o({ A: 'Story' })[0] as TheC | undefined
        return A?.o({ w: 'Story' })[0] as TheC | undefined
    })

    // spayers — every spayer that bites this Book (in-code story_matching defaults ∪ this
    //   test's authored caps), the same set the compare uses.  Drives the diff glow: a
    //    changed line an Entcase reaches gets marked, so you can see at a glance which diffs
    //     are acknowledged noise (would forgive) and which blew their variance band.
    let spayers = $derived.by((): any[] => {
        const The = story_w?.c.The as TheC | undefined
        void The?.version
        return H.collect_spayers([...(H.story_matching ?? []), ...H.entropy_rules(The)])
    })

    // row_spay_class — '' | 'graft' | 'blown' for a changed diff row (got=right, exp=left).
    function row_spay_class(row: DiffRow): '' | 'graft' | 'blown' {
        if (row.kind !== 'pair' || row.tag !== 'changed' || !spayers.length) return ''
        const c = H.spay_classify_line(row.right, row.left, spayers)
        return c === 'none' ? '' : c
    }

    // ea_seed — the line-sides of the last-clicked Dif:change row plus its parent line.
    //   Setting it re-points EntropyArrest's single draft (the DevTools-breadcrumb
    //   discipline); on_done clears it after commit/cancel.  A new click overwrites.
    let ea_seed = $state<{ left: string, right: string, parent?: string | null } | null>(null)

    // the rendered text of a diff row (got side preferred), or null for a squish
    function diff_row_line(r: DiffRow): string | null {
        return r.kind === 'pair' ? (r.right ?? r.left) : r.kind === 'squish' ? null : r.line
    }
    // the nearest earlier row at a shallower indent — the clicked particle's container
    //  line, so the authored locator always includes the parent's match (§8.6).
    function diff_parent_line(rows: DiffRow[], i: number): string | null {
        const cur = diff_row_line(rows[i]); if (cur == null) return null
        const depth = cur.match(/^ */)?.[0].length ?? 0
        for (let j = i - 1; j >= 0; j--) {
            const l = diff_row_line(rows[j]); if (l == null) continue
            if ((l.match(/^ */)?.[0].length ?? 0) < depth) return l
        }
        return null
    }
    function seed_spay(rows: DiffRow[], i: number) {
        const row = rows[i]
        if (row.kind !== 'pair') return
        ea_seed = { left: row.left, right: row.right, parent: diff_parent_line(rows, i) }
    }

    // covered_click — a click on a changed line a cap ALREADY reaches.  We do NOT author a new
    //  cap there (it would duplicate the existing one, and clobber an in-flight edit); instead we
    //   hand the line to EntropyArrest, which glows the cap it's for and edits it on a second
    //    click.  token bumps each click so the child re-acts even on the same line.
    let covered_click = $state<{ left: string, right: string, token: number } | null>(null)
    let _click_tok = 0

    // diff_changed — this step's changed line-pairs, fed to EntropyArrest for the per-cap match
    //  tally (how many lines each cap bites this step, shown beside its edit|×).
    let diff_changed = $derived.by((): { left: string, right: string }[] =>
        diff_rows.filter(r => r.kind === 'pair' && r.tag === 'changed')
                 .map(r => ({ left: (r as any).left as string, right: (r as any).right as string })))

    // a click on a changed diff cell.  Two guards before it ever seeds a draft:
    //   1. a live text selection means the user is grabbing regex source — a drag-select still
    //       emits a click, which used to spawn a +Entcase and clobber the edit.  Never seed then.
    //   2. a line a cap already covers (row_spay_class ≠ '') routes to covered_click (reveal/edit
    //       the existing cap), never a new draft.  Only a genuinely-uncovered line seeds.
    function diff_click(rows: DiffRow[], i: number) {
        const sel = typeof window !== 'undefined' ? window.getSelection() : null
        if (sel && !sel.isCollapsed && sel.toString().trim().length) return
        const row = rows[i]
        if (row.kind !== 'pair' || row.tag !== 'changed') return
        if (row_spay_class(row) !== '') covered_click = { left: row.left, right: row.right, token: ++_click_tok }
        else                            seed_spay(rows, i)
    }


    //#region types

    type DiffMode = 'exp' | 'exp_naive' | 'prev' | 'first' | 'naive'

    type CharOps = Array<[number, string]>

    type DiffRow =
        | { kind: 'pair';       left: string; right: string; tag: 'same' }
        | { kind: 'pair';       left: string; right: string; tag: 'changed'; ops: CharOps }
        | { kind: 'left_only';  line: string }
        | { kind: 'right_only'; line: string }
        | { kind: 'squish';     count: number }
        | GhostRow

    type StepEntry = { n: number, dige: string | undefined, desc?: string }

    // ghost: a declared %Assertion whose sworn evidence never latched — rendered as a red
    //  ghost line standing where the evidence would (see inject_ghosts).  Synthetic: in
    //  NEITHER snap, so only the render path (render_rows) ever carries one.
    type GhostRow = { kind: 'ghost'; slug: string; sentence: string; line: string }

    //#region display state 

    let display = $state({
        run_sc:    null as Record<string,any> | null,
        frontier:  0,
        open_at:   null as number | null,
        bad_count: 0,
        steps:     [] as StepEntry[],
        notes:     {} as Record<number, TheC[]>,
        avg_step:  null as number | null,   // averaged per-step seconds, set on run completion
    })

    // This      = ave/{This:1,Story:book}  — the live step container
    // sw / swatchesC = ave/{swatches:1}   — the note colour registry
    let This:      TheC | undefined = $state()
    let sw:        TheC | undefined = $state()
    let swatchesC: TheC | undefined = $state()   // alias of sw; both set together
    let swatch_map = $state<Record<string,string>>({})

    // H.ave is a stable TheC; ob() reads H.ave.version (Svelte tracks it)
    // then queries its children.  Housing's flush() mutates H.ave only after
    // all_clear(), so this $effect fires exactly once per settled beliefs cycle.
    $effect(() => {
        const an       = H.ave.ob({ story_analysis: 1 })[0] as TheC
        const sc       = H.ave.ob({ This: 1 })[0]           as TheC
        const sw_found = H.ave.ob({ swatches: 1 })[0]       as TheC

        if (an) Object.assign(display, an.sc)
        This = sc
        sw = sw_found
        swatchesC = sw_found

        const m: Record<string,string> = {}
        if (sw_found) {
            for (const s of sw_found.o({ note_coloring: 1 }) as TheC[]) {
                m[s.sc.note_coloring as string] = s.sc.color as string
            }
        }
        swatch_map = m

        // detect resnap_count bumping — open fixed popup for the resnapped step.
        // Read from an.sc directly, not display.run_sc — display is $state that
        // Object.assign just wrote above, so reading it here would subscribe the
        // effect to its own output and cause an infinite update loop.
        // an.sc is a plain TheC sc object; reading it creates no Svelte subscription.
        // _prev_resnap is plain (untracked) so writing it here doesn't re-trigger.
        const count = an?.sc.run_sc?.resnap_count as number | undefined
        if (count != null && count > 0 && count !== _prev_resnap) {
            _prev_resnap = count
            const n = (an.sc.run_sc?.resnap_n as number | undefined) ?? null
            popup_step = n
            if (H.top_House().is_house_visible?.(H)) {
                // Storui is already in the viewport — no popup needed.
                // Just open the resnapped step and focus the strip for keyboard nav.
                if (n != null) setTimeout(() => { pick(n!); strip_el?.focus({ preventScroll: true }) }, 0)
            } else {
                popup_expanded = true
                popup_open     = true
            }
        }
    })

    function live_step(n: number): TheC | null {
        if (!This) return null
        const all = This.o({ Step: 1 }) as TheC[]
        return all.find(s => s.sc.Step === n) ?? null
    }

    //#region diff mode state 

    let diff_mode   = $state<DiffMode | null>(null)
    let show_trace = $state(false)
    let copy_trace = $state(false)   // "include trace" — fold each step's Run_trace into the copied diff block
    let sticky_mode = $state<DiffMode | null>(null)

    // ── stash: persist open pip, diff mode, and expanded across reloads ──────
    // Keyed by Book so different stories don't collide.
    // restore_pip: a step number waiting to be opened once display.steps
    //   contains it — the step may not exist yet when the Book first mounts.
    let restore_pip  = $state<number | null>(null)
    // stash_loaded: one-shot guard so the restore effect never re-fires after
    //   the first book appearance. Without this, every story_analysis() creates
    //   a new display.run_sc object, re-triggering the effect and looping:
    //   restore → pick → e_story_sel → story_analysis → display.run_sc → loop.
    let stash_loaded = $state(false)

    // open_at_ts: wall-clock ms when the panel last opened; null when closed.
    // Stashed alongside open_at so restores can enforce the 5-minute recency gate.
    let open_at_ts = $state<number | null>(null)
    $effect(() => {
        const n = display.open_at
        open_at_ts = n != null ? Date.now() : null
    })

    $effect(() => {
        if (stash_loaded) return
        const book = display.run_sc?.run as string | undefined
        if (!book) return
        stash_loaded = true   // arm the guard before any mutations below
        const saved = H.stashed?.['Storui:' + book] as { open_at?: number, open_at_ts?: number, sticky_mode?: DiffMode, expanded?: boolean } | undefined
        if (!saved) return
        if (saved.expanded    != null) expanded     = saved.expanded
        if (saved.sticky_mode != null) sticky_mode  = saved.sticky_mode
        if (saved.open_at     != null) {
            // only jump back if the pip was opened within the last 5 minutes
            const age = saved.open_at_ts != null ? Date.now() - saved.open_at_ts : Infinity
            if (age <= 5 * 60 * 1000) restore_pip = saved.open_at
        }
    })

    // once the stashed step has content, open it.
    // Subscribes to run_sc.done — advances after each completed step — so the
    // effect re-fires as the run progresses, not just when step?.version bumps.
    // Gating on got_snap prevents opening a hollow skeleton before snap arrives.
    $effect(() => {
        const n = restore_pip
        if (n == null) return
        void display.run_sc?.done   // re-evaluate as steps complete
        const step = live_step(n)
        void step?.version          // also re-check when snap arrives async
        if (step?.sc.got_snap) {
            restore_pip = null
            // if the run already opened a different step (end-of-run failure/lenient),
            // defer to it — the stash restore must not stomp run.sc.open_at
            if (display.open_at != null && display.open_at !== n) return
            pick(n)
        }
    })

    // write on every interesting change
    $effect(() => {
        const book = display.run_sc?.run as string | undefined
        if (!book) return
        const open_at = display.open_at
        const _ts     = open_at_ts   // subscribe
        const _sm     = sticky_mode  // subscribe
        const _exp    = expanded     // subscribe
        H.stashed ??= {}
        H.stashed['Storui:' + book] = { open_at, open_at_ts, sticky_mode, expanded }
    })

    //#region ops_for_display 
    //
    //   Rendering-only — the one diff function that stays in StoryRun.
    //   Walks char ops over a raw snap line, skipping the indent prefix and the
    //   tab separator, producing Array<{cls, text}> for {#each} in intra_line.
    //
    //   side='left'  → renders op=-1 (deleted) spans, skips op=+1 (inserted)
    //   side='right' → renders op=+1 (inserted) spans, skips op=-1 (deleted)
    //   op=0         → always plain
    //
    //   Own-side reconstruction ensures indent_len and tab_pos are computed
    //   against the actual characters on that side — not the other side's line,
    //   which may have a tab at a different position or no tab at all when enL
    //   omits it (no objecties → tab is omitted).

    function ops_for_display(
        line: string,
        ops: CharOps,
        side: 'left' | 'right',
    ): Array<{cls: string; text: string}> {
        let own = ''
        for (const [op, text] of ops) {
            if (op === 0 || (op === -1 && side === 'left') || (op === 1 && side === 'right')) {
                own += text
            }
        }
        const indent_len = (own.match(/^ */)?.[0] ?? '').length
        const tab_pos    = own.indexOf('\t')

        const result: Array<{cls: string; text: string}> = []
        let own_pos = 0
        for (const [op, text] of ops) {
            if (op === -1 && side === 'right') continue
            if (op ===  1 && side === 'left')  continue
            let visible = ''
            for (let i = 0; i < text.length; i++) {
                const abs = own_pos + i
                if (abs < indent_len) continue   // indent rendered separately as sr-ind
                if (abs === tab_pos)  continue   // tab separator is structural, not visible
                visible += text[i]
            }
            own_pos += text.length
            if (!visible) continue
            const cls = op === 0 ? 'sr-plain' : op === -1 ? 'sr-del' : 'sr-ins'
            result.push({ cls, text: visible })
        }
        return result
    }

    //#region deriveds 

    // has_exp_snap / has_prev_snap drive which mode buttons are shown.
    // void Step.version subscribes so these update when snaps arrive async.
    let has_exp_snap = $derived.by(() => {
        const n = displayed_at
        if (n == null) return false
        const Step = live_step(n)
        void Step?.version
        return !!(Step && Step.sc.exp_snap)
    })

    let has_prev_snap = $derived.by(() => {
        const n = displayed_at
        if (n == null || n <= 1) return false
        const prev = live_step(n - 1)
        void prev?.version
        return !!(prev && prev.sc.got_snap)
    })

    let has_first_snap = $derived.by(() => {
        const n = displayed_at
        if (n == null) return false
        const Step = live_step(n)
        void Step?.version
        return !!(Step && Step.sc.first_snap)
    })

    // panel_ready: false while waiting for exp_snap on a mismatch step
    // that has a known dige (meaning there IS an expected snap to fetch).
    // Shows a simple "loading" placeholder instead of briefly flashing naive/prev.
    let panel_ready = $derived.by(() => {
        const n = display.open_at
        if (n == null) return false
        const Step = live_step(n)
        void Step?.version
        if (!Step) return true                       // hollow — show immediately
        if (Step.sc.ok || Step.sc.accepted) return true
        if (Step.sc.exp_snap) return true            // inline — not has_exp_snap
        const ts = display.steps.find(t => t.n === n)
        if (!ts?.dige) return true                   // no expected snap to wait for
        return false                                 // waiting for fetch
    })

    // displayed_at: the step actually shown in the panel.
    // Lags behind display.open_at until panel_ready is true for the new step.
    // This keeps the old diff visible while exp_snap is in flight, giving a
    // smooth transition — often the same number of lines, barely a flicker.
    let displayed_at = $state<number | null>(null)

    $effect(() => {
        if (display.open_at == null) {
            displayed_at = null   // panel closed — clear immediately
        } else if (panel_ready) {
            displayed_at = display.open_at
        }
        // if open_at is set but panel_ready is false: leave displayed_at
        // pointing at whatever was shown before — smooth hold
    })

    // eff_mode: resolved diff mode.
    // Priority: explicit diff_mode → sticky carry-over → auto by step state.
    // ok steps default to naive — just show the snapshot.
    // mismatch steps auto-prefer exp (when loaded), then prev, then naive.
    // exp_naive is never auto — it must be explicitly chosen.
    let eff_mode = $derived.by((): DiffMode => {
        if (diff_mode) return diff_mode
        // sticky_mode carries across pip nav, but only when its required snap is present.
        // Without this guard, navigating to a step whose prev/exp/first snap is absent
        // would return e.g. 'prev' while showing naive content — mode button hidden, no feedback.
        if (sticky_mode === 'naive') return sticky_mode
        if (sticky_mode === 'prev'  && has_prev_snap)  return sticky_mode
        if (sticky_mode === 'first' && has_first_snap) return sticky_mode
        if ((sticky_mode === 'exp' || sticky_mode === 'exp_naive') && has_exp_snap) return sticky_mode
        const n    = display.open_at
        const Step = n != null ? live_step(n) : null
        void Step?.version
        if (Step && Step.sc.ok) return 'naive'
        if (has_exp_snap)       return 'exp'
        // mismatch step waiting for exp_snap — hold on naive rather than
        // briefly showing vs-prev which will flip away once exp_snap arrives
        if (Step && !Step.sc.ok && !Step.sc.accepted) return 'naive'
        if (has_prev_snap)      return 'prev'
        return 'naive'
    })

    function toggle_mode(m: DiffMode) {
        const next = (diff_mode === m) ? null : m
        diff_mode   = next
        sticky_mode = next
        explorer_open = false   // choosing a diff is choosing show-diff — the mutex
    }

    // rows_for: pure function — compute DiffRow[] given a mode, reference, and got snap.
    // Reused by both the main diff panel (diff_rows) and the popup (popup_rows).
    function rows_for(mode: DiffMode, ref: string, got: string): DiffRow[] {
        const as_naive = (snap: string): DiffRow[] =>
            snap.split('\n').filter(Boolean)
                .map(line => ({ kind: 'pair' as const, left: line, right: line, tag: 'same' as const }))
        if (mode === 'naive') return as_naive(got)
        if (!ref) return as_naive(got)   // ref absent (fetch in flight) — stay on raw
        if (mode === 'exp_naive') return H.squish_context(H.positional_diff(ref, got))
        return H.squish_context(H.compute_diff(ref, got))
    }

    // diff_rows: final aligned diff for rendering.
    // Subscribes to Step.version and prev.version so it re-derives when
    // snaps arrive asynchronously (e.g. after story_sel triggers a fetch).
    // Pure diff functions come from T (H with Textures methods injected).
    let diff_rows = $derived.by((): DiffRow[] => {
        const n = displayed_at
        if (n == null) return []
        const Step = live_step(n)
        const prev = n > 1 ? live_step(n - 1) : null
        void Step?.version
        void prev?.version

        const got_snap   = (Step?.sc.got_snap   as string) ?? ''
        const exp_snap   = (Step?.sc.exp_snap   as string) ?? ''
        const first_snap = (Step?.sc.first_snap as string) ?? ''
        const prev_snap  = (prev?.sc.got_snap   as string) ?? ''
        const mode       = eff_mode

        const ref = mode === 'exp' || mode === 'exp_naive' ? exp_snap
                  : mode === 'prev'                        ? prev_snap
                  : mode === 'first'                       ? first_snap
                                                           : ''
        return rows_for(mode, ref, got_snap)
    })

    // popup_rows: first<=>got diff for the Resnapture popup.
    // Only populated while popup_step is set.  Subscribes to step version so it
    // re-derives once snap_step_after_wave overwrites %got_snap.
    let popup_rows = $derived.by((): DiffRow[] => {
        if (popup_step == null) return []
        const Step = live_step(popup_step)
        void Step?.version
        const first = (Step?.sc.first_snap as string) ?? ''
        const got   = (Step?.sc.got_snap   as string) ?? ''
        if (!first || !got) return []
        return H.squish_context(H.compute_diff(first, got))
    })

    // col_labels: column headings — left = reference, right = current got
    let col_labels = $derived(
        eff_mode === 'exp'       ? { left: 'exp',   right: 'got' } :
        eff_mode === 'exp_naive' ? { left: 'exp',   right: 'got' } :
        eff_mode === 'prev'      ? { left: 'prev',  right: 'got' } :
        eff_mode === 'first'     ? { left: 'first', right: 'got' } :
                                   { left: 'got',   right: ''    }
    )

    //#region run bar deriveds 

    let run_mode   = $derived(display.run_sc?.mode    ?? 'new')
    let run_done   = $derived(display.run_sc?.done    ?? 0)
    let run_total = $derived(
        run_mode === 'check'
            ? display.steps.length
            : (display.run_sc?.total as number | undefined)
    )
    let run_paused = $derived(!!display.run_sc?.paused)
    let run_failed = $derived(display.run_sc?.failed_at as number | undefined)

    // playhead_n: pip that gets the red downward triangle.
    // Points to the frontier when set, otherwise the first hollow pip.
    function playhead_n(): number | null {
        if (display.frontier > 0) return display.frontier
        const first_hollow = display.steps.find(ts => !live_step(ts.n))
        return first_hollow ? (first_hollow.n as number) : null
    }

    // waiting_for_exp: mismatch step where exp_snap is the natural mode but
    // hasn't loaded yet — we're showing vs-prev as a placeholder.
    // Dim the panel so it doesn't read as authoritative.
    let waiting_for_exp = $derived.by(() => {
        const n = display.open_at
        if (n == null) return false
        const Step = live_step(n)
        void Step?.version
        return !!(Step && !Step.sc.ok && !Step.sc.accepted && !has_exp_snap)
    })



    //#region note helpers 

    function note_color(type: string): string {
        const c = swatch_map[type]
        if (!c) console.error(`StoryRun: no swatch for note type "${type}"`)
        return c ?? '#666'
    }

    type NoteFlag = { type: string, color: string }
    function note_flags_for(n: number): NoteFlag[] {
        const notes = display.notes[n] ?? []
        const seen  = new Set<string>()
        const flags: NoteFlag[] = []
        for (const nc of notes) {
            const type = Object.keys(nc.sc).find(k => k !== 'note') ?? 'note'
            if (!seen.has(type)) { seen.add(type); flags.push({ type, color: note_color(type) }) }
        }
        return flags
    }

    function note_label(nc: TheC): string {
        const keys = Object.keys(nc.sc).filter(k => k !== 'note')
        if (!keys.length) return 'note'
        return keys.map(k => nc.sc[k] === 1 ? k : `${k}:${nc.sc[k]}`).join(', ')
    }

    //#region assertions — the contract vs this run's sworn evidence
    //
    //   CONTRACT: The/step=N/%Assertion:slug,sentence — the hosting step IS the by-when.
    //   EVIDENCE: the ave/%Assertioning,Story:<book> shelf, filled pre-encode by
    //    story_harvest_sworn and reset each run.  Both live OFF the snap, so this whole
    //    layer costs zero fixture bytes; a Book with no contract shows nothing of it.
    //
    //   Leniency is structural, never configured:
    //     pending — the hosting step hasn't completed this run
    //     latched — a matching %sworn stands on the shelf (n: = the step it latched)
    //     overdue — the hosting step passed with no latch, run still going (amber)
    //     red     — the run ended and the evidence never came (the gap gate's verdict)

    type AssertState = 'latched' | 'pending' | 'overdue' | 'red'
    type AssertEntry = { slug: string, sentence: string, due: number, state: AssertState,
                         latch_n: number | null, microsnap: string | null }

    // assert_entries — one row per declared %Assertion, joined to shelf evidence by
    //  byte-identical sentence (the same join Cred_assertion_gaps makes at run end).
    //  The shelf is read through H.ave.ob, which tracks H.ave.vers — bumped each flush
    //  after a harvest touches the shelf — so this derive stays live without polling.
    let assert_entries = $derived.by((): AssertEntry[] => {
        const The = story_w?.c.The as TheC | undefined
        void The?.version
        const book  = story_w?.sc.Book as string | undefined
        const shelf = book ? H.ave.ob({ Assertioning: 1, Story: book })[0] as TheC | undefined : undefined
        const ended = run_paused || run_failed != null
        const entries: AssertEntry[] = []
        for (const st of (The?.o({ step: 1 }) ?? []) as TheC[]) {
            for (const a of st.o({ Assertion: 1 }) as TheC[]) {
                const sentence = String(a.sc.sentence ?? '')
                const due      = Number(st.sc.step) || 0
                const row      = sentence ? shelf?.o({ sworn: sentence })[0] as TheC | undefined : undefined
                const state: AssertState = row ? 'latched'
                    : due <= run_done ? (ended ? 'red' : 'overdue')
                    : 'pending'
                entries.push({ slug: String(a.sc.Assertion), sentence, due, state,
                               latch_n: row ? (Number(row.sc.n) || null) : null,
                               microsnap: (row?.c as any)?.microsnap ?? null })
            }
        }
        return entries.sort((x, y) => x.due - y.due)
    })

    // undeclared — %sworn with no contract row: NOT ok.  Every sworn wants declaring;
    //  an undeclared one so far exists only in the Book's code, invisible to the gap
    //  gate.  Shown ◇ amber in the explorer.  The human's Accept is the door into the
    //  contract — never a tunable matcher (that slope is a second EntropyArrest).
    let undeclared = $derived.by(() => {
        const book = story_w?.sc.Book as string | undefined
        if (!book) return []
        const shelf = H.ave.ob({ Assertioning: 1, Story: book })[0] as TheC | undefined
        if (!shelf) return []
        const contracted = new Set(assert_entries.map(e => e.sentence))
        return (shelf.o({ sworn: 1 }) as TheC[])
            .filter(s => !contracted.has(String(s.sc.sworn)))
            .map(s => ({ sentence: String(s.sc.sworn), n: Number(s.sc.n) || 0,
                         microsnap: (s.c as any).microsnap ?? null }))
    })

    let assert_broken  = $derived(assert_entries.some(e => e.state === 'overdue' || e.state === 'red'))
    let assert_latched = $derived(assert_entries.filter(e => e.state === 'latched').length)

    // explorer — MUTEXES with show-diff: one body, one occupant.  Opening it replaces
    //  the diff; choosing any diff mode (buttons or the e/r/f keys) closes it again.
    //  explorer_focus glows the row a ghost line or pip mark was clicked through from —
    //  the clue and the navigation are one mechanism.
    let explorer_open  = $state(false)
    let explorer_focus = $state<string | null>(null)
    let ax_open        = $state<string | null>(null)   // row whose microsnap is unfolded

    function open_explorer(slug: string) {
        explorer_open  = true
        explorer_focus = slug
        ax_open        = null
    }

    // hover-desc layer — the hovered pip's %desc ALONE, absolute above the strip so it
    //  never shifts layout; instant, and the pip's native title tooltip stays.
    let hover_n    = $state<number | null>(null)
    let hover_desc = $derived(hover_n != null ? display.steps.find(ts => ts.n === hover_n)?.desc : undefined)

    // inject_ghosts — the red GHOST LINE: a missing assertion rendered at the spot its
    //  sworn evidence would stand.  story_swear mints %sworn as the newest child of the
    //  run world (w:<book> — the run world is named after the Book), so the spot is the
    //  end of that world's subtree on the got side.  If the anchor line is hidden in a
    //  squish or absent, the ghosts land at the nearest visible boundary — the LINE is
    //  the point, its exact pixel row less so.
    function inject_ghosts(rows: DiffRow[], missing: AssertEntry[], book: string | undefined): DiffRow[] {
        if (!missing.length) return rows
        const got_line = (r: DiffRow): string | null =>
            r.kind === 'pair' ? (r.right ?? r.left) : r.kind === 'right_only' ? r.line : null
        let at = rows.length, ind = '  '
        const wi = book ? rows.findIndex(r => got_line(r)?.trimStart().startsWith('w:' + book) ?? false) : -1
        if (wi >= 0) {
            const w_ind = (got_line(rows[wi])!.match(/^ */)?.[0] ?? '').length
            for (let j = wi + 1; j < rows.length; j++) {
                const l = got_line(rows[j]); if (l == null) continue
                const d = (l.match(/^ */)?.[0] ?? '').length
                if (d <= w_ind) { at = j; break }
            }
            const kid     = wi + 1 < rows.length ? got_line(rows[wi + 1]) : null
            const kid_ind = kid ? (kid.match(/^ */)?.[0] ?? '') : ''
            ind = kid_ind.length > w_ind ? kid_ind : ' '.repeat(w_ind + 2)
        }
        const ghosts: DiffRow[] = missing.map(e =>
            ({ kind: 'ghost' as const, slug: e.slug, sentence: e.sentence, line: ind + 'sworn:' + e.sentence }))
        return [...rows.slice(0, at), ...ghosts, ...rows.slice(at)]
    }

    // render_rows — diff_rows plus ghosts for the displayed step.  ONLY the render path
    //  reads this; diff_changed/EntropyArrest/collect_range stay on the real diff_rows.
    let render_rows = $derived.by((): DiffRow[] => {
        const n = displayed_at
        if (n == null) return diff_rows
        const missing = assert_entries.filter(e => e.due === n && (e.state === 'overdue' || e.state === 'red'))
        return inject_ghosts(diff_rows, missing, story_w?.sc.Book as string | undefined)
    })
    //#endregion

    //#region selection + accept 
    //
    //   All mutations go via H.i_elvisto to the Story worker.  The worker calls
    //   story_analysis() which bumps ave, which triggers the $effect above,
    //   which reassigns display — completing the reactive loop without any
    //   direct state mutation from here.

    let add_note_text = $state('')
    let adding_note    = $state(false)  // toggles the + field open/closed

    function do_add_note(n: number) {
        const text = add_note_text.trim()
        if (!text) return
        const note_sc = { note: 1, ...peel(text) }
        H.i_elvisto('Story/Story', 'story_add_note', { step_n: n, note_sc })
        add_note_text = ''
    }

    function do_delete_note(n: number, idx: number) {
        H.i_elvisto('Story/Story', 'story_delete_note', { step_n: n, note_idx: idx })
    }

    //#region diff[] collect 
    //
    //   diff_anchor: the step we started collecting from (first click).
    //   diff_collecting: true while waiting for the second click.
    //   diff_status: brief human-readable feedback shown next to the button.

    let diff_anchor     = $state<number | null>(null)
    let diff_collecting = $state(false)
    let diff_status     = $state('')

    // ── Resnapture popup ──────────────────────────────────────────────────────
    //
    //   Triggered by run.sc.resnap_count incrementing (set in e_story_resnap,
    //   spread into an.sc.run_sc by story_analysis, detected here in the ave $effect).
    //   The popup is a position:fixed Vexpandy at the top of the viewport —
    //   the user can keep interacting with the tested UI while the diff is visible.
    //
    //   popup_step: the step whose first_snap<=>got_snap is shown.
    //   popup_expanded: controls Vexpandy's V toggle inside the popup.
    //
    //   go_to_diff() closes the popup, asks Mundo to scroll to H:Story, and picks
    //   the resnapped step in the main diff panel.

    let popup_open     = $state(false)
    let popup_expanded = $state(true)
    let popup_step     = $state<number | null>(null)
    let _prev_resnap   = -1   // plain — intentionally untracked

    function go_to_diff() {
        const n = popup_step
        popup_open  = false
        sticky_mode = 'exp'   // arrive showing exp diff, not auto-resolved mode
        // short delay so the popup's layout space collapses before NaviScroll
        // measures the scroll target — avoids the viewport jumping twice
        setTimeout(() => {
            H.top_House().scroll_to_house?.(H)
            if (n != null) pick(n)
            strip_el?.focus({ preventScroll: true })   // scroll_to_house owns the viewport; don't double-scroll
        }, 50)
    }

    // Enter when the popup is expanded: same as clicking "go to diff"
    $effect(() => {
        if (!popup_open || !popup_expanded) return
        const handler = (e: KeyboardEvent) => {
            if (e.key === 'Enter') { e.preventDefault(); go_to_diff() }
        }
        window.addEventListener('keydown', handler)
        return () => window.removeEventListener('keydown', handler)
    })

    // trace_lines: serialise a Run_trace to position-indented label lines — the same
    //  time-scaled shape the per-step ⎘ copy-trace button shows.  `pad` prefixes each
    //   line so the trace can nest under a Step inside a copied Dif block.
    function trace_lines(events: TraceEvent[], pad = ''): string[] {
        if (!events?.length) return []
        const t0 = events[0].t, span = (events.at(-1)!.t - t0) || 1
        const COLS = 60
        return events.map(ev => {
            const pos   = Math.round((ev.t - t0) / span * (COLS - 1))
            const label = `${ev.kind}${ev.tag ? ':' + ev.tag : ''}`
            return pad + ' '.repeat(pos) + label
        })
    }

    // collect_range: build the multi-step Dif block and copy to clipboard.
    //
    //   All pure diff work delegated to T (Textures methods on H):
    //     T.compute_diff, T.squish_context, T.enDif
    //   deDif is the inverse — T.deDif(lines, 2) decodes back to DiffRow[].
    //
    //   from_n and to_n can be in either order; always walks min → max.
    // mode is passed explicitly from pick() so the $derived value is captured
    //   in the synchronous onclick context, not read lazily inside the async fn.
    async function collect_range(from_n: number, to_n: number, mode: DiffMode) {
        const min = Math.min(from_n, to_n)
        const max = Math.max(from_n, to_n)
        const all_lines: string[] = []

        for (let n = min; n <= max; n++) {
            all_lines.push(`Step:${n}`)

            const Step     = live_step(n)
            const got_snap = Step?.sc.got_snap as string | undefined

            // include trace: fold the step's Run_trace in under the Step header — before
            //  the Snap block, so a no-diff step still carries its trace (the whole point).
            if (copy_trace) {
                const tr = Step?.sc.Run_trace as TraceEvent[] | undefined
                if (tr?.length) { all_lines.push(`  Trace`); all_lines.push(...trace_lines(tr, '    ')) }
            }

            if (!Step) {
                all_lines.push(`  Snap,not_run`)
                continue
            }
            if (!got_snap) {
                // open this step in the UI so story_sel queues a snap fetch
                all_lines.push(`  Snap,not_loaded`)
                continue
            }

            const prev      = n > 1 ? live_step(n - 1) : null
            const prev_snap = (prev?.sc.got_snap as string) ?? ''

            // ── resolve ref snap for chosen mode ─────────────────────────
            const ref_snap = mode === 'exp' || mode === 'exp_naive'
                ? (Step.sc.exp_snap   as string) ?? ''
                : mode === 'first'
                ? (Step.sc.first_snap as string) ?? ''
                : prev_snap   // prev / naive

            // ── raw mode: naive, or ref absent for this mode ──────────────
            //   Snap,first: prev mode but no prev step — first step in run.
            //   Snap,raw:   exp/first mode ref not yet loaded, or naive.
            if (mode === 'naive' || !ref_snap) {
                const header = (!prev_snap && mode !== 'exp' && mode !== 'exp_naive' && mode !== 'first')
                    ? `  Snap,first`
                    : `  Snap,raw`
                all_lines.push(header)
                for (const line of got_snap.split('\n').filter(Boolean)) {
                    all_lines.push(`    ${line.trimEnd()}`)
                }
                continue
            }

            const diff_label = mode === 'exp'       ? 'exp'
                            : mode === 'exp_naive' ? 'exp_naive'
                            : mode === 'first'     ? 'first'
                            : 'prev'
            all_lines.push(`  Snap,diff:${diff_label}`)
            const raw_rows = mode === 'exp_naive'
                ? H.positional_diff(ref_snap, got_snap)
                : H.compute_diff(ref_snap, got_snap)
            const rows = H.squish_context(raw_rows)
            all_lines.push(...H.enDif(rows, 2, spayers))
        }

        const text = all_lines.join('\n') + '\n'

        try {
            await navigator.clipboard.writeText(text)
            diff_status = `copied ${max - min + 1} steps ✓`
        } catch {
            // clipboard write can fail in sandboxed contexts — log so nothing is lost
            diff_status = 'copy failed — see console'
            console.log('[diff range]\n' + text)
        }
        setTimeout(() => { diff_status = '' }, 3000)
    }

    async function start_diff_collect() {
        const n = display.open_at
        if (n == null) return
        try { await navigator.clipboard.writeText('') } catch { /* prompt on actual write */ }
        diff_anchor     = n
        diff_collecting = true
        diff_status     = ''
    }

    // copy_single: copies the open step alone and exits collect mode.
    async function copy_single() {
        const n = display.open_at
        if (n == null) return
        diff_collecting = false
        diff_anchor     = null
        try { await navigator.clipboard.writeText('') } catch { /* prompt on actual write */ }
        await collect_range(n, n, eff_mode)
    }

    // cancel_collect: click the pulsing button again to abort without collecting.
    function cancel_collect() {
        diff_anchor     = null
        diff_collecting = false
        diff_status     = ''
    }

    //#region pick + nav
    // pick: open/close a step panel.
    // When collecting and a different step is clicked: collect [anchor, n], done.
    // When collecting and the same step is clicked: collect that single step.
    // eff_mode is passed explicitly so collect_range captures it at call time,
    //   not lazily inside the async fn where $derived re-evaluation could differ.
    // diff_mode reset on every pick so eff_mode re-evaluates for the new step.
    // last_user_pick: plain variable, intentionally NOT $state.
    // The re-assert effect reads it for comparison — plain reads are untracked,
    // so pick() setting it cannot re-trigger the effect. $state here would create
    // a loop: pick() → last_user_pick changes → re-assert fires again mid-flight.
    let last_user_pick: number | null = null

    function pick(n: number) {
        if (diff_collecting && diff_anchor != null && n !== diff_anchor) {
            collect_range(diff_anchor, n, eff_mode)
            diff_collecting = false
            diff_anchor     = null
        } else if (diff_collecting && n === diff_anchor) {
            collect_range(diff_anchor, n, eff_mode)  // single step, same pip
            diff_collecting = false
            diff_anchor     = null
        }
        last_user_pick = n
        // opening a step pip IS a show-diff choice — the mutex swaps sworn mode away here
        //  exactly like the mode buttons do.  (The assertion-mark click still lands in the
        //   explorer: it calls pick() first, then open_explorer() re-raises it.)
        explorer_open = false
        // opening a step pip should show its diff — default the panel open (the user can
        //  still collapse it via the Vexpandy; the next pip-open re-opens).
        expanded = true
        // tell NaviScroll not to seek Story's house while the user is navigating pips
        H.stashed ??= {}
        H.stashed.pip_user_engaged_until = Date.now() + 2 * 60 * 1000
        H.i_elvisto('Story/Story', 'story_sel', { open_at: n })
    }

    function close_panel() {
        diff_mode      = null
        last_user_pick = null
        // user explicitly dismissed — NaviScroll may seek freely again
        if (H.stashed) H.stashed.pip_user_engaged_until = 0
        H.i_elvisto('Story/Story', 'story_sel', { open_at: null })
    }
    // story_nav: pip-stepping for OTHER surfaces — Cytui's focused canvas rides
    //  this for its ←/→ keys.  Published as a runtime ref on H.c (never
    //   encoded); re-published every mount so an HMR remount can't strand a
    //    stale closure.  It routes through pick(), so to the re-assert effect a
    //     remote step is indistinguishable from our own pip click — no fight —
    //      and Cyto_seek fires off display.open_at as usual.  With nothing open
    //       it enters at the END (the frontier side), so a first ← walks
    //        backward through the run from where it finished.
    function story_nav(dir: number) {
        if (!display.steps.length) return
        const idx  = display.steps.findIndex(ts => ts.n === display.open_at)
        const next = idx < 0 ? display.steps[display.steps.length - 1]
                             : display.steps[idx + dir]
        if (next) pick(next.n)
    }
    $effect(() => {
        H.c.story_nav = story_nav
        return () => { if (H.c.story_nav === story_nav) delete H.c.story_nav }
    })
    $effect(() => {
        displayed_at   // subscribe
        diff_mode = null
    })
    // re-assert when server pushes a different open_at while we have a step visible
    $effect(() => {
        const server_at = display.open_at
        if (server_at == null)            return   // server closed — fine
        if (displayed_at == null)         return   // nothing open yet — let server decide
        if (server_at === last_user_pick) return   // this was our own pick echoing back
        // server jumped to a different step — re-assert what the user was looking at
        pick(displayed_at)
    })
    // cyto seek tracks display.open_at directly — not displayed_at —
    // so the graph moves immediately when a pip is clicked, before
    // exp_snap arrives and the diff panel catches up.
    $effect(() => {
        if (display.open_at) {
            // feebly: a Book without Opt/useCyto has no A:Cyto to seek — no-op, don't throw.
            setTimeout(() => H.feebly_i_elvisto('Cyto/Cyto', 'Cyto_seek', { open_at: display.open_at }), 0)
        }
    })
    // when the panel opens from outside (server-pushed open_at: end of run,
    // failed step, stash restore), return focus to the strip so arrow keys work.
    // Guards: if focus is already inside .sr the user is driving — don't interrupt.
    //         if last_user_pick is set the user chose a step and owns focus.
    // preventScroll: a bare focus() scrolls the strip into view — i.e. yanks the
    //   whole page to Story every time a step fails. We only want the keyboard
    //   target, never the viewport jump; the user scrolls to Story if they care.
    $effect(() => {
        void display.open_at   // subscribe
        if (!display.open_at) return
        if (last_user_pick != null) return   // user is driving — don't steal focus
        if (sr_el && !sr_el.contains(document.activeElement)) {
            setTimeout(() => strip_el?.focus({ preventScroll: true }), 0)
        }
    })

    // story focus: any focused child of .sr bubbles keydown here.
    //   Guard against inputs so typing in the note field is never stolen.
    //   Arrow keys need a panel open; 'e', 'r', 't', 'a' have their own hollow guards.
    function handle_story_key(e: KeyboardEvent) {
        const tag = (e.target as HTMLElement).tagName
        if (tag === 'INPUT' || tag === 'TEXTAREA') return
        if (display.open_at == null && e.key !== 'e' && e.key !== 'a' && e.key !== 's') return
        const idx = display.steps.findIndex(ts => ts.n === display.open_at)
        if (e.key === 'ArrowRight' && idx < display.steps.length - 1) {
            e.preventDefault()
            pick(display.steps[idx + 1].n)
        } else if (e.key === 'ArrowLeft' && idx > 0) {
            e.preventDefault()
            pick(display.steps[idx - 1].n)
        } else if (e.key === 'e') {
            if (displayed_at == null || !live_step(displayed_at)) return
            e.preventDefault()
            const in_exp = eff_mode === 'exp' || eff_mode === 'exp_naive'
            if (in_exp) {
                if (has_prev_snap) toggle_mode('prev')
            } else if (eff_mode === 'prev') {
                if (has_exp_snap)  toggle_mode('exp')
            } else {
                // naive / auto — jump to first available anchor
                if      (has_exp_snap)  toggle_mode('exp')
                else if (has_prev_snap) toggle_mode('prev')
            }
        } else if (e.key === 'r') {
            // r: always go raw — one-way, pressing again does nothing
            if (displayed_at == null || !live_step(displayed_at)) return
            e.preventDefault()
            diff_mode   = 'naive'
            sticky_mode = 'naive'
            explorer_open = false   // raw is show-diff too — the mutex
        } else if (e.key === 's') {
            // s: toggle the assertions explorer (mutexes with show-diff; stands alone
            //  in the panel's seat when no step is open — assertions are run-wide)
            e.preventDefault()
            explorer_open = !explorer_open
        } else if (e.key === 'f' && !e.ctrlKey && !e.metaKey) {
            // f: toggle first mode (first_snap <=> got_snap Resnapture diff)
            // Ctrl/Cmd+F falls through so the browser's find bar can open
            if (displayed_at == null || !live_step(displayed_at)) return
            e.preventDefault()
            if (has_first_snap) toggle_mode('first')
        } else if (e.key === 't') {
            // t: toggle trace panel (persists across pip nav)
            if (displayed_at == null || !live_step(displayed_at)) return
            e.preventDefault()
            show_trace = !show_trace
        } else if (e.key === 'a') {
            // a: toggle expand (V button — upside-down A shape when closed)
            e.preventDefault()
            expanded = !expanded
        } else if (e.key === 'Escape') {
            if (popup_open) { e.preventDefault(); popup_open = false }
        }
    }

    function accept(n: number) {
        H.i_elvisto('Story/Story', 'story_accept', { accept_n: n })
        // open the next step immediately so sequences can be checked rapidly
        const idx  = display.steps.findIndex(ts => ts.n === n)
        const next = display.steps[idx + 1]
        if (next) pick(next.n)
    }
    function accept_all() {
        H.i_elvisto('Story/Story', 'story_accept_all', {})
    }

    // sr_el: the whole Storui root. tabindex=-1 lets sr_el.focus() park story
    //   focus here when clicking non-interactive areas (diff body, panel bg).
    //   onkeydown sits here so any focused child bubbles nav keys up to it.
    // strip_el: still focusable (tabindex=0) for Tab-key entry into story focus.
    let sr_el    = $state<HTMLElement | null>(null)
    let strip_el = $state<HTMLElement | null>(null)

    // expanded: toggles the whole Storui to 70vh so the diff body can breathe.
    //   The expand button lives beside the pip strip.
    let expanded = $state(false)

    // sync_col_scroll: keep left and right diff columns locked to the same scrollLeft.
    // Uses closest() so it works in any instance of the diff2 snippet — the popup
    // and the main panel each have their own sr-diff2-body without any explicit binding.
    function sync_col_scroll(e: Event) {
        const src  = e.currentTarget as HTMLElement
        const body = src.closest('.sr-diff2-body') as HTMLElement | null
        if (!body) return
        const x = src.scrollLeft
        for (const col of body.querySelectorAll<HTMLElement>('.sr-diff2-col')) {
            if (col !== src && col.scrollLeft !== x) col.scrollLeft = x
        }
    }

    //#region trace colouring
    //
    //   FNV-1a hash of ev.kind → hue (0-359) + lightness (44-67).
    //   S fixed at 68 for saturation that reads on a black background.
    //   bg: same hue, low lightness — coloured gutter behind the label.
    //   Deterministic per-kind: same word always maps to the same colour.
    function _trace_hash(s: string): number {
        let h = 0x811c9dc5
        for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193) >>> 0
        return h
    }
    function trace_fg(kind: string): string {
        const h = _trace_hash(kind)
        const hue = h % 360
        const lit  = 44 + ((_trace_hash(kind + '~')) % 24)   // 44-67
        return `hsl(${hue},68%,${lit}%)`
    }
    // trace_bg unused — labels are tinted text only, no background gutter
    //#endregion

    //#region overrun trace monitor
    //
    //   poll_step (Story.svelte) publishes the wedge tail onto an ave-held `live_poll`
    //   particle and bumps its version DIRECTLY (the reactivity_docs "lever"), so this
    //   updates even while a wedged step keeps beliefs from ever flushing ave.  We read
    //   `lp.vers` — the codebase's reactive signal — never a plain $state field.
    //
    //   poll_step owns the pacing: lp.c.batch already holds the latest ≤30 UNSHOWN events
    //   (older backlog skipped, refreshed ~every 3s while the trace grows; a static wedge
    //   holds its last batch).  Here we just render it; the old batch flashes away and the
    //   new one flashes in (keyed each + in/out transitions).  ⎘ copies the shown batch.

    type LiveRow = { kind: string, tag?: string, d: number, key: number, i: number }

    // lp — the live_poll particle, taken from the ave channel ($effect re-runs each ave
    //   flush; during a wedge it's already held, and lp.vers bumps are seen directly).
    let lp = $state<TheC | undefined>()
    $effect(() => { lp = H.ave.ob({ live_poll: 1 })[0] as TheC | undefined })

    // over: truthy while a step is overrunning.  Gated on lp.vers (the reactive signal) —
    //   the .c reads are plain, but the vers read makes the whole derive reactive.
    let over = $derived(
        (lp?.vers && lp.c.on)
            ? { step: lp.c.step as number, since: lp.c.since as number, Run: lp.c.Run as House }
            : null
    )
    let over_on  = $state(false)   // ticker toggled open
    let over_secs = $state(0)      // live elapsed seconds, for the button label
    let over_idle = $state(0)      // seconds since the newest trace event — climbs while frozen

    // the shown batch + counts, straight off the particle — reactive via lp.vers.
    let live_window = $derived(((lp?.vers && over_on && lp.c.on) ? (lp.c.batch as LiveRow[]) : null) ?? [])
    let live_total  = $derived((lp?.vers && (lp.c.total as number)) || 0)
    let live_shown  = $derived((lp?.vers && (lp.c.shown as number)) || 0)

    // elapsed-seconds clock — a plain component-local interval (the canonical Svelte
    //   counter), running whenever a step is overrunning, button or not.
    $effect(() => {
        const o = over
        if (!o) { over_secs = 0; over_idle = 0; over_on = false; return }
        const upd = () => {
            over_secs = Date.now() / 1000 - o.since
            // idle: ms since the newest trace event (performance.now clock, shared with the
            //  worker).  Static while the trace is frozen → climbs → reads as "trace dead".
            const lt = lp?.c.last_t as number | undefined
            over_idle = lt != null ? (performance.now() - lt) / 1000 : 0
        }
        upd()
        const id = setInterval(upd, 250)
        return () => clearInterval(id)
    })

    // live_copy — the currently SHOWN batch as text (Δms + kind:tag); grabs what's on
    //   screen right now.  Same shape as poll_step's old console "brutal trace tail".
    function live_copy() {
        const o = over; if (!o) return
        const lines = live_window.map(r =>
            `+${r.d.toFixed(1).padStart(8)}ms  ${r.kind}${r.tag ? ':' + r.tag : ''}`)
        const head = `step ${String(o.step).padStart(3, '0')} live trace — ${live_window.length} lines @ ${over_secs.toFixed(1)}s`
        navigator.clipboard.writeText(head + '\n' + lines.join('\n') + '\n').catch(() => {})
    }
    //#endregion
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- expanded only bites when a step panel is actually open — otherwise the 90vh
     rule would leave Storui a tall empty box just for the pip strip. -->
<div class="sr" class:expanded={expanded && displayed_at != null} bind:this={sr_el} tabindex="-1" onkeydown={handle_story_key}>

    {#if !This}
        <div class="sr-empty">no Story</div>

    {:else}

        <!-- ── run bar ──────────────────────────────────────────────────── -->
        <div class="sr-bar"
             class:is-new={run_mode==='new'}
             class:is-check={run_mode==='check'}
             class:is-fail={!!run_failed}>
            <span class="sr-runname">{display.run_sc?.run ?? '—'}</span>
            <span class="sr-mode">{run_mode}</span>
            <span class="sr-steps">
                {String(run_done).padStart(3,'0')}
                {#if run_total}&nbsp;/&nbsp;{String(run_total).padStart(3,'0')}{/if}
            </span>
            <!-- sworn: the assertions explorer toggle — declared latched/total, ◇ undeclared.
                 Run-wide, so it lives on the run bar; the explorer mutexes with show-diff. -->
            {#if assert_entries.length || undeclared.length}
                <button class="sr-assert-btn" class:active={explorer_open} class:broken={assert_broken}
                        class:warn={!assert_broken && undeclared.length > 0}
                        onclick={() => explorer_open = !explorer_open}
                        title="declared %Assertions latched/total{undeclared.length ? ' — plus ' + undeclared.length + ' undeclared (want declaring)' : ''} — opens the explorer in the diff's seat ([s])">
                    sworn {assert_latched}/{assert_entries.length}{#if undeclared.length}&nbsp;◇{undeclared.length}{/if}
                </button>
            {/if}
            {#if run_failed}
                <span class="sr-status fail">✗ {String(run_failed).padStart(3,'0')}</span>
            {:else if run_paused}
                <span class="sr-status ok">✓ done</span>
            {:else}
                <span class="sr-status running">▶</span>
            {/if}
            {#if over}
                <button class="sr-over-btn" class:active={over_on}
                        onclick={() => over_on = !over_on}
                        title="step {String(over.step).padStart(3,'0')} has run {over_secs.toFixed(0)}s — show the live trace tail">
                    ⏱ {over_secs.toFixed(0)}s
                </button>
            {/if}
            {#if display.avg_step}
                <span class="sr-mode" title="average per-step time, averaged over recent runs">~{display.avg_step}s/step</span>
            {/if}
            {#if display.bad_count > 1}
                <button class="sr-accept-all" onclick={accept_all}>Accept All ({display.bad_count})</button>
            {/if}
        </div>

        <!-- ── live overrun trace ticker ──────────────────────────────────── -->
        <!-- Raised while a step overruns 5s and the ⏱ button is toggled on.    -->
        <!-- Every 3s the latest ≤30 unshown lines flash in (old batch flashes   -->
        <!-- away); ⎘ copies the shown batch.  Same trace_fg() colouring as the  -->
        <!-- per-step trace panel.                                               -->
        {#if over && over_on}
            <div class="sr-live">
                <div class="sr-trace-axis">
                    <span class="sr-trace-axis-lbl">live · step {String(over.step).padStart(3,'0')}</span>
                    <span>{over_secs.toFixed(1)}s</span>
                    <span class="sr-live-idle" class:stale={over_idle > 3}
                          title="seconds since the newest trace event — if this climbs while the step clock runs, the trace is frozen (a beliefs-drain deadlock), not churning">
                        idle {over_idle.toFixed(1)}s
                    </span>
                    <span class="sr-live-cur">{live_shown}/{live_total}</span>
                    <button class="sr-trace-copy" onclick={live_copy} title="copy the shown batch">⎘</button>
                </div>
                <div class="sr-live-rows">
                    {#each live_window as row (row.key)}
                        <div class="sr-trace-row"
                             in:fly={{ y: 8, duration: 220, delay: row.i * 18 }}
                             out:fade={{ duration: 120 }}>
                            <span class="sr-live-d">{row.d ? '+' + row.d.toFixed(0) + 'ms' : ''}</span>
                            <span class="sr-trace-lbl" style="color:{trace_fg(row.kind)}"
                            >{row.kind}{row.tag ? ':' + row.tag : ''}</span>
                        </div>
                    {/each}
                    {#if !live_window.length}
                        <div class="sr-live-wait">waiting for trace…</div>
                    {/if}
                </div>
            </div>
        {/if}

        <!-- ── Resnapture popup (fixed modal) ──────────────────────────────── -->
        <!-- Appears at top of viewport when 📸 is clicked in the actions bar.  -->
        <!-- Stays visible while poking at the tested UI — position:fixed so     -->
        <!-- no scrolling needed.  V collapses to a slim bar; × closes entirely. -->
        {#if popup_open}
            {@const popup_s    = popup_step != null ? live_step(popup_step) : null}
            {@const _pv        = popup_s?.version}
            <Vexpandy bind:expanded={popup_expanded} popup={true}>
                {#snippet header()}
                    <span class="sr-resnap-title">
                        📸 step {popup_step != null ? String(popup_step).padStart(3,'0') : '—'} — first ↔ got
                        {#if popup_rows.length === 0}
                            <span class="sr-resnap-dim">(no change yet)</span>
                        {/if}
                    </span>
                    <button class="sr-resnap-goto" onclick={go_to_diff}
                            title="close popup, scroll to diff, open step (Enter)">go to diff ↓</button>
                    <button class="sr-resnap-close" onclick={() => popup_open = false}
                            title="close popup">×</button>
                {/snippet}
                {#snippet children()}
                    {#if popup_rows.length > 0}
                        {@render diff2_view(popup_rows, {left:'first', right:'got'}, 'first')}
                    {:else}
                        <div class="sr-hollow-body sr-resnap-empty">
                            {popup_s?.sc.first_snap ? 'no change between snaps' : 'snap in progress…'}
                        </div>
                    {/if}
                {/snippet}
            </Vexpandy>
        {/if}

        <!-- ── pip strip ────────────────────────────────────────────────── -->
        <!-- One cell per step from The (skeleton); live Step data overlaid.   -->
        <!-- hollow: step in The but not yet reached this session.             -->
        <!-- is-anchor: diff[] collection started from this step — teal ring.  -->
        <!-- tabindex=0: Tab-key entry point for story focus; arrow/e/r/t keys -->
        <!--   bubble from any focused child up to the .sr root handler.       -->
        <div class="sr-strip-wrap">
        <!-- hover-desc layer: the hovered pip's %desc alone, floating above the strip
             (absolute — zero layout shift; instant; pointer-events:none so it never
             intercepts the very mouse travel that raised it).  Native titles stay. -->
        {#if hover_n != null && hover_desc}
            <div class="sr-hoverdesc">
                <span class="sr-hd-n">step {String(hover_n).padStart(3,'0')}</span>{hover_desc}
            </div>
        {/if}
        <div class="sr-strip scrollsmall" tabindex="0" bind:this={strip_el}>
            {#each display.steps as ts (ts.n)}
                {@const n         = ts.n}
                {@const Step      = live_step(n)}
                {@const ok        = !!(Step && Step.sc.ok)}
                {@const hollow    = !Step}
                {@const accepted  = !!(Step && Step.sc.accepted)}
                {@const caveat    = !!(Step && Step.sc.caveat)}
                {@const on        = display.open_at === n}
                {@const ph        = n === playhead_n()}
                {@const flags     = note_flags_for(n)}
                {@const amarks    = assert_entries.filter(e => e.due === n)}
                {@const is_anchor = diff_collecting && n === diff_anchor}
                <div class="sr-pip-cell"
                     onmouseenter={() => hover_n = n}
                     onmouseleave={() => { if (hover_n === n) hover_n = null }}>
                    <div class="sr-flags">
                        {#each flags as f (f.type)}
                            <span class="sr-flag" style="background:{f.color}" title={f.type}></span>
                        {/each}
                        <!-- assertion marks: diamonds beside the square note flags — one per
                             %Assertion hosted at this step, loudest when broken.  Click-through:
                             the mark opens its step AND the explorer focused on that assertion. -->
                        {#each amarks as e (e.slug)}
                            <span class="sr-amark {e.state}" role="button" tabindex="-1"
                                  title="%Assertion «{e.slug}» — {e.sentence} — {e.state}{e.latch_n != null ? ' (sworn at step ' + e.latch_n + ')' : ''}"
                                  onclick={ev => { ev.stopPropagation(); pick(n); open_explorer(e.slug) }}></span>
                        {/each}
                    </div>
                    <button
                        class="sr-pip"
                        class:ok
                        class:accepted
                        class:caveat={caveat && !accepted}
                        class:fail={!ok && !hollow && !accepted}
                        class:hollow
                        class:on
                        class:playhead={ph}
                        class:has-notes={flags.length > 0}
                        class:is-anchor={is_anchor}
                        onclick={() => pick(n)}
                        title="step {String(n).padStart(3,'0')}{hollow?' (hollow)':accepted?' (accepted)':caveat?' (caveat — forgiven noise)':''}{ts.desc ? ' — ' + ts.desc : ''}  {(Step && Step.sc.dige || ts.dige) ?? ''}"
                    >{hollow ? '○' : caveat && !accepted ? '≈' : ok ? '·' : '✗'}</button>
                </div>
            {/each}
        </div>
        <Vexpandy bind:expanded={expanded} />
        </div>

        <!-- ── snap panel ───────────────────────────────────────────────── -->
         {#if displayed_at != null}
            {@const n          = displayed_at}
            {@const ts_sel     = display.steps.find(t => t.n === n)}
            {@const Step       = live_step(n)}
            <!-- void Step.version subscribes this block to Step mutations —
                 disk_ok arrives async from check_snap, so without this the
                 ⚠ disk stale badge would never appear after initial render -->
            {@const _sv        = Step?.version}
            {@const ok         = !!(Step && Step.sc.ok)}
            {@const hollow     = !Step}
            {@const accepted   = !!(Step && Step.sc.accepted)}
            {@const caveat     = !!(Step && Step.sc.caveat)}
            {@const dige       = String(Step && Step.sc.dige || ts_sel && ts_sel.dige || '').slice(0, 8)}
            <!-- A disk-stale step is ok against toc but its NNN.snap fixture on disk
                 drifted (disk_ok===false) — Accept rewrites the fixture, so offer it
                 here too, not just for outright mismatches. -->
            {@const can_accept = !hollow && (!ok || Step.sc.disk_ok === false)}
            {@const step_notes = display.notes[n] ?? []}
            <!-- trace_span: ms from first to last trace event — the step's wall clock -->
            {@const trace_events = Step?.sc.Run_trace as TraceEvent[] | undefined}
            {@const trace_span   = trace_events?.length ? (trace_events.at(-1)!.t - trace_events[0].t) : null}

            <div class="sr-panel">
                {#if explorer_open}
                    <!-- SWORN MODE: the mutex is TOTAL — the whole panel belongs to the
                         explorer; every piece of diff furniture (mode buttons, copy diff,
                         trace, Accept, notes) is show-diff's and stands down with it. -->
                    {@render sworn_panel()}
                {:else}

                <!-- header ────────────────────────────────────────────── -->
                <div class="sr-phdr">
                    <span class="sr-pn">step {String(n).padStart(3,'0')}</span>
                    {#if ts_sel?.desc}<span class="sr-pdesc" title="the step's %desc — a few words from the beat that made it">{ts_sel.desc}</span>{/if}
                    <span class="sr-pdige">{dige}</span>
                    {#if hollow}
                        <span class="sr-plabel hollow">hollow</span>
                    {:else if accepted}
                        <span class="sr-plabel accepted">accepted</span>
                    {:else if caveat}
                        <!-- forgiven value-noise (EntropyArrest §8): OK with a caveat -->
                        <span class="sr-plabel caveat" title="virtually OK — acknowledged value-noise was forgiven (an Entcase grafted got→exp)">≈ caveat</span>
                    {:else if !ok}
                        <span class="sr-plabel mm">mismatch</span>
                    {/if}
                    <!-- disk_ok=false: NNN.snap on disk doesn't match toc.snap dige;
                         set by check_snap both for mismatches and snap_checking steps -->
                    {#if Step && Step.sc.disk_ok === false}
                        <span class="sr-warn" title="NNN.snap on disk does not match toc.snap dige">⚠ disk stale</span>
                    {/if}

                    <!-- diff mode buttons ──────────────────────────────── -->
                    <!-- vs exp: DMP diff, resyncs after insertions.        -->
                    <!-- & exp:  positional diff, line i vs line i.         -->
                    <!-- vs prev: sequential DMP diff since last step.      -->
                    <!-- raw: got_snap verbatim.                            -->
                    <!-- Clicking the active button resets to auto.         -->
                    <!-- [e] key cycles exp ↔ prev while strip has focus.  -->
                    {#if !hollow}
                        <span class="sr-diff-modes">
                            {#if has_exp_snap}
                                <button class="primary" class:active={eff_mode==='exp'}
                                        onclick={() => toggle_mode('exp')}>exp</button>
                                <button class:active={eff_mode==='exp_naive'}
                                        onclick={() => toggle_mode('exp_naive')}>&amp; exp</button>
                            {/if}
                            {#if has_prev_snap}
                                <button class="primary" class:active={eff_mode==='prev'}
                                        onclick={() => toggle_mode('prev')}>prev</button>
                            {/if}
                            {#if has_first_snap}
                                <button class="primary sr-first-btn" class:active={eff_mode==='first'}
                                        onclick={() => toggle_mode('first')}>first</button>
                            {/if}
                            <button class:active={eff_mode==='naive'}
                                    onclick={() => toggle_mode('naive')}>raw</button>
                            <span class="sr-ekey">[e r t a f s]</span>
                        </span>
                    {/if}


                    <!-- copy: range collector ─────────────────────────── -->
                    <!-- idle: "copy diff" immediately arms this step as    -->
                    <!--   the anchor — button becomes throbbing "pick end ×". -->
                    <!-- collecting: "to NNN" always shown — copies this    -->
                    <!--   step alone when NNN = anchor, range otherwise.   -->
                    <!--   "pick end ×" cancels on click.                   -->
                    <!-- Output: Step/Snap/Dif:* block, enL-compatible.     -->
                    <!-- T.deDif(lines, 2) decodes it back to DiffRow[].    -->
                    {#if !hollow}
                        {#if diff_collecting}
                            <!-- "just NNN": copy this single step and done. -->
                            <button class="sr-diffrange" onclick={() => { collect_range(diff_anchor!, n, eff_mode); diff_collecting = false; diff_anchor = null }}>
                                just {String(n).padStart(3,'0')}
                            </button>
                            <button class="sr-diffrange collecting" onclick={cancel_collect}>
                                pick end ×
                            </button>
                            <label class="sr-inctrace" title="fold each step's trace into the copied block (the whole content where there's no diff)">
                                <input type="checkbox" bind:checked={copy_trace} /> trace
                            </label>
                        {:else}
                            <button class="sr-diffrange" onclick={start_diff_collect}>copy diff</button>
                        {/if}
                    {/if}

                    {#if Step?.sc.Run_trace?.length}
                        <button class="sr-trace-btn" class:active={show_trace}
                                onclick={() => show_trace = !show_trace}>trace</button>
                    {/if}

                    <!-- brief status after collect_range finishes -->
                    {#if diff_status && !diff_collecting}
                        <span class="sr-diffstatus">{diff_status}</span>
                    {/if}

                    {#if can_accept}
                        <!-- Accept: promote dige into The, save, resume drive -->
                        <button class="sr-accept" onclick={() => accept(n)}>Accept</button>
                    {/if}
                    {#if trace_span != null}
                        <span class="sr-ptime">{trace_span.toFixed(1)}ms</span>
                    {/if}
                    <button class="sr-close" onclick={close_panel}>×</button>
                </div>

                <!-- body ──────────────────────────────────────────────── -->
                <!-- waiting_for_exp: exp_snap is in flight — dim the     -->
                <!-- vs-prev placeholder so it doesn't read as final.     -->
                <!-- sr-body: flex child of sr-panel that owns flex:1;    -->
                <!--   without this class the diff/pre would push trace   -->
                <!--   below the panel's overflow:hidden in expanded view. -->
                <div class="sr-body" style="opacity:{waiting_for_exp ? 0.5 : 1}; transition:opacity 0.3s">
                {#if hollow}
                    <div class="sr-hollow-body">step {String(n).padStart(3,'0')} not yet run this session</div>
                {:else if !(Step?.sc.got_snap)}
                    <!-- snap ran but content not yet fetched; story_sel will queue the load -->
                    <div class="sr-hollow-body">snap not yet loaded</div>
                {:else if eff_mode === 'naive'}
                    <!-- raw: single pre, full got_snap text, no diff colouring (ghost lines still stand) -->
                    <pre class="sr-pre sr-tree-pre scrollbig">{#each render_rows as row, i (i)}{#if row.kind === 'pair'}{@render snap_line(row.left, 'same')}{:else if row.kind === 'ghost'}{@render ghost_line(row)}{/if}{/each}</pre>

                {:else}
                    <!-- two-column proper diff — rendered via the diff2_view snippet -->
                    <!-- so the same markup can be reused in the Resnapture popup     -->
                    {@render diff2_view(render_rows, col_labels, eff_mode)}
                {/if}
                </div>

                <!-- entropy arrest: author/CRUD acknowledged-noise Entcases.
                     Shows iff a diff line was clicked (a draft is in flight) or this
                     test already holds caps.  Mints into The/EntropyArrest on OK;
                     restart re-reads them via entropy_rules. -->
                <EntropyArrest
                    H={H}
                    w={story_w}
                    seed={ea_seed}
                    covered={covered_click}
                    diff_changed={diff_changed}
                    step_n={n}
                    on_done={() => ea_seed = null} />

                {#if show_trace && Step?.sc.Run_trace?.length}
                    {@render trace_panel(Step.sc.Run_trace)}
                {/if}

                <!-- notes: swatch badges + big + toggle; input replaces badges while open -->
                <div class="sr-notes">
                    <div class="sr-notes-hdr">
                        <span class="sr-notes-title">notes</span>
                        <button class="sr-note-plus" onclick={() => { adding_note = !adding_note; if(adding_note) setTimeout(()=>document.querySelector<HTMLElement>('.sr-note-input')?.focus(),0) }}>+</button>
                        {#if adding_note}
                            <input class="sr-note-input"
                                placeholder="frontier  /  todo:text  /  key:val"
                                bind:value={add_note_text}
                                onkeydown={e => { if(e.key==='Enter'){ do_add_note(n); adding_note=false } if(e.key==='Escape') adding_note=false }} />
                            <button class="sr-note-submit" onclick={() => { do_add_note(n); adding_note=false }}>+</button>
                        {:else}
                            {#each Object.entries(swatch_map) as [type, color] (type)}
                                <span class="sr-note-badge" style="border-color:{color};color:{color}">{type}</span>
                            {/each}
                        {/if}
                    </div>
                    {#each step_notes as nc, idx (idx)}
                        {@const type = Object.keys(nc.sc).find(k => k !== 'note') ?? 'note'}
                        <div class="sr-note-row">
                            <span class="sr-note-dot" style="background:{note_color(type)}"></span>
                            <span class="sr-note-label">{note_label(nc)}</span>
                            <button class="sr-note-del" onclick={() => do_delete_note(n, idx)} title="delete">×</button>
                        </div>
                    {/each}
                </div>
                {/if}

            </div>
        {:else if explorer_open}
            <!-- explorer with no step open: assertions are run-wide, so the sworn button
                 (run bar) / [s] can raise it standalone in the panel's seat -->
            <div class="sr-panel">
                {@render sworn_panel()}
            </div>
        {/if}

    {/if}
</div>

<!-- ── snippets ─────────────────────────────────────────────────────────── -->

<!-- diff2_view: reusable two-column DMP diff renderer.
     Used by the main snap panel and the Resnapture popup alike.
     rows:   DiffRow[] precomputed by diff_rows or popup_rows.
     labels: {left, right} column headings.
     accent: 'prev' | 'first' | other — drives background tint class.
     sync_col_scroll uses closest() so no binding is needed here. -->
{#snippet diff2_view(rows: DiffRow[], labels: {left: string, right: string}, accent: string)}
    <div class="sr-diff2" class:prev-bg={accent === 'prev'} class:first-bg={accent === 'first'}>
        <div class="sr-diff2-hdr">
            <div class="sr-dlabel ref">{labels.left}</div>
            <div class="sr-dlabel got">{labels.right}</div>
        </div>
        <div class="sr-diff2-body scrollbig">
        <div class="sr-diff2-grid">
            <div class="sr-diff2-col" onscroll={sync_col_scroll}>
                {#each rows as row, i (i)}
                    {#if row.kind === 'squish'}
                        <div class="sr-squish">… {row.count} unchanged</div>
                    {:else if row.kind === 'pair' && row.tag === 'same'}
                        <div class="sr-diff2-cell">{@render line_content(row.left)}</div>
                    {:else if row.kind === 'pair' && row.tag === 'changed'}
                        {@const sc = row_spay_class(row)}
                        <div class="sr-diff2-cell changed sr-spayable"
                             class:spay-graft={sc === 'graft'} class:spay-blown={sc === 'blown'}
                             title={sc === 'blown' ? 'an Entcase matches here but the value blew its variance band — click to reveal it, again to edit'
                                  : sc === 'graft' ? 'acknowledged noise — an Entcase forgives this line; click to reveal it, again to edit'
                                  : 'silence this noise — click to author an Entcase'}
                             onclick={() => diff_click(rows, i)}>{@render intra_line(row.left, row.ops, 'left')}</div>
                    {:else if row.kind === 'left_only'}
                        <div class="sr-diff2-cell gone">{@render line_content(row.line)}</div>
                    {:else if row.kind === 'right_only'}
                        <div class="sr-diff2-cell neu sr-empty-cell"></div>
                    {:else if row.kind === 'ghost'}
                        <div class="sr-diff2-cell sr-ghost-cell sr-empty-cell"></div>
                    {/if}
                {/each}
            </div>
            <div class="sr-diff2-col" onscroll={sync_col_scroll}>
                {#each rows as row, i (i)}
                    {#if row.kind === 'squish'}
                        <div class="sr-squish">… {row.count} unchanged</div>
                    {:else if row.kind === 'pair' && row.tag === 'same'}
                        <div class="sr-diff2-cell">{@render line_content(row.right)}</div>
                    {:else if row.kind === 'pair' && row.tag === 'changed'}
                        {@const sc = row_spay_class(row)}
                        <div class="sr-diff2-cell changed sr-spayable"
                             class:spay-graft={sc === 'graft'} class:spay-blown={sc === 'blown'}
                             title={sc === 'blown' ? 'an Entcase matches here but the value blew its variance band — click to reveal it, again to edit'
                                  : sc === 'graft' ? 'acknowledged noise — an Entcase forgives this line; click to reveal it, again to edit'
                                  : 'silence this noise — click to author an Entcase'}
                             onclick={() => diff_click(rows, i)}>{@render intra_line(row.right, row.ops, 'right')}</div>
                    {:else if row.kind === 'left_only'}
                        <div class="sr-diff2-cell gone sr-empty-cell"></div>
                    {:else if row.kind === 'right_only'}
                        <div class="sr-diff2-cell neu">{@render line_content(row.line)}</div>
                    {:else if row.kind === 'ghost'}
                        <!-- the got column is where the evidence would stand — the ghost lives there -->
                        <div class="sr-diff2-cell sr-ghost-cell" role="button" tabindex="-1"
                             title="declared %Assertion «{row.slug}» — its sworn evidence never latched; click to open the assertions explorer"
                             onclick={() => open_explorer(row.slug)}
                        ><span class="sr-ind">{row.line.match(/^ */)?.[0] ?? ''}</span><span class="sr-ghost-txt">sworn:{row.sentence}</span>  <span class="sr-ghost-tag">— never latched</span></div>
                    {/if}
                {/each}
            </div>
        </div>
        </div>
    </div>
{/snippet}

<!-- snap_line: full line block used in naive/tree single-column pre.
     Snap line format: "${indent}${stringies}\t${objecties}" when objecties present,
     or "${indent}${stringies}" when not (enL omits the tab).
     stringies sit on the left; objecties are the blue coherent keys on the right.
     A missing tab gives -1, so everything after the indent is stringies. -->
{#snippet snap_line(line: string, tag: string)}
    {@const indent = line.match(/^ */)?.[0] ?? ''}
    {@const tab    = line.indexOf('\t')}
    {@const str    = tab >= 0 ? line.slice(indent.length, tab) : line.slice(indent.length)}
    {@const obj    = tab >= 0 ? line.slice(tab + 1) : ''}
    <span class="sr-line {tag}"><span class="sr-ind">{indent}</span><span class="sr-str">{str}</span>{#if obj}  <span class="sr-obj">{obj}</span>{/if}&#10;</span>
{/snippet}

<!-- line_content: inline content for two-column diff cells.
     Same codec as snap_line — stringies left, blue objecties on the right. -->
{#snippet line_content(line: string)}
    {@const indent = line.match(/^ */)?.[0] ?? ''}
    {@const tab    = line.indexOf('\t')}
    {@const str    = tab >= 0 ? line.slice(indent.length, tab) : line.slice(indent.length)}
    {@const obj    = tab >= 0 ? line.slice(tab + 1) : ''}
    <span class="sr-ind">{indent}</span><span class="sr-str">{str}</span>{#if obj}  <span class="sr-obj">{obj}</span>{/if}
{/snippet}

<!-- intra_line: changed diff cell with per-character highlights.
     op=0 → plain, op=-1 → sr-del (left cell), op=+1 → sr-ins (right cell).
     Runs on the full raw line string so snap codec re-parsing is not needed. -->
{#snippet intra_line(line: string, ops: Array<[number, string]>, side: 'left' | 'right')}
    {@const indent = (line.match(/^ */)?.[0] ?? '')}<span class="sr-ind">{indent}</span>{#each ops_for_display(line, ops, side) as span}<span class={span.cls}>{span.text}</span>{/each}
{/snippet}

<!-- ghost_line: naive-pre form of the red ghost line — a declared assertion whose
     evidence never latched, standing where the sworn would.  Click-through to the
     explorer: the clue and the navigation are one mechanism. -->
{#snippet ghost_line(row: GhostRow)}
    {@const indent = row.line.match(/^ */)?.[0] ?? ''}
    <span class="sr-line sr-ghost" role="button" tabindex="-1"
          title="declared %Assertion «{row.slug}» — its sworn evidence never latched; click to open the assertions explorer"
          onclick={() => open_explorer(row.slug)}
    ><span class="sr-ind">{indent}</span><span class="sr-ghost-txt">sworn:{row.sentence}</span>  <span class="sr-ghost-tag">— never latched</span>&#10;</span>
{/snippet}

<!-- sworn_panel: the WHOLE panel in sworn mode — its own green header, zero diff furniture.
     × returns to the diff; the e/r/f keys exit the same way (toggle_mode closes the explorer). -->
{#snippet sworn_panel()}
    <div class="sr-phdr sworn">
        <span class="sr-sworn-title">sworn</span>
        <span class="sr-sworn-counts">{assert_latched}/{assert_entries.length} declared latched{#if undeclared.length}&nbsp;·&nbsp;◇{undeclared.length} undeclared{/if}</span>
        <span class="sr-ekey">[s]</span>
        <button class="sr-close" onclick={() => explorer_open = false} title="back to the diff">×</button>
    </div>
    <div class="sr-body">
        {@render assert_explorer()}
    </div>
{/snippet}

<!-- assert_explorer: the contract vs this run's evidence, in the diff's seat (the mutex).
     One row per declared %Assertion: state glyph, slug, sentence, the hosting step
     (clickable — the by-when), latch n.  A latched row with a microsnap (⌖) unfolds it
     on click — what the assertion pointed at, frozen at go-off time.  Below: unclaimed
     evidence (◇) — sworn beyond the contract; Accept is the door in, never a matcher. -->
{#snippet assert_explorer()}
    <div class="sr-ax scrollbig">
        <div class="sr-ax-sec">declared %Assertions</div>
        {#each assert_entries as e (e.slug)}
            {@const unfolded = ax_open === e.slug}
            <div class="sr-ax-row {e.state}" class:focus={explorer_focus === e.slug}
                 role="button" tabindex="-1"
                 onclick={() => ax_open = unfolded ? null : e.slug}>
                <span class="sr-ax-ico">{e.state === 'latched' ? '✓' : e.state === 'pending' ? '◌' : '✗'}</span>
                <span class="sr-ax-slug">{e.slug}</span>
                <span class="sr-ax-sent">«{e.sentence}»</span>
                <button class="sr-ax-due" title="the hosting step — the by-when; click to open it"
                        onclick={ev => { ev.stopPropagation(); explorer_focus = e.slug; pick(e.due) }}
                >step {String(e.due).padStart(3,'0')}</button>
                {#if e.state === 'latched'}
                    <span class="sr-ax-n">sworn at {String(e.latch_n ?? 0).padStart(3,'0')}</span>
                {:else}
                    <span class="sr-ax-state">{e.state}</span>
                {/if}
                {#if e.microsnap}<span class="sr-ax-has-micro" title="carries a microsnap — click the row to unfold it">⌖</span>{/if}
            </div>
            {#if unfolded && e.microsnap}
                <pre class="sr-ax-micro">{e.microsnap}</pre>
            {/if}
        {/each}
        {#if !assert_entries.length}
            <div class="sr-ax-none">no declared %Assertions yet</div>
        {/if}
        {#if undeclared.length}
            <!-- NOT ok: every sworn wants declaring — these so far exist only in the Book's
                 code, invisible to the gap gate.  Accept is the door into the contract. -->
            <div class="sr-ax-sec undecl">undeclared %Assertions — want declaring</div>
            {#each undeclared as a (a.sentence)}
                {@const unfolded = ax_open === a.sentence}
                <div class="sr-ax-row sr-ax-undecl" role="button" tabindex="-1"
                     onclick={() => ax_open = unfolded ? null : a.sentence}>
                    <span class="sr-ax-ico">◇</span>
                    <span class="sr-ax-sent">«{a.sentence}»</span>
                    <span class="sr-ax-n">sworn at {String(a.n).padStart(3,'0')}</span>
                    <!-- the door into the contract: mints The/step=N/%Assertion (N = where it
                         swore) and saves the toc — from the next run on its absence complains -->
                    <button class="sr-ax-declare"
                            title="declare it — the sentence joins the contract at step {a.n} and its absence complains from the next run on"
                            onclick={ev => { ev.stopPropagation(); H.i_elvisto('Story/Story', 'story_declare', { sentence: a.sentence }) }}
                    >declare ↑</button>
                    {#if a.microsnap}<span class="sr-ax-has-micro" title="carries a microsnap — click the row to unfold it">⌖</span>{/if}
                </div>
                {#if unfolded && a.microsnap}
                    <pre class="sr-ax-micro">{a.microsnap}</pre>
                {/if}
            {/each}
        {/if}
    </div>
{/snippet}

{#snippet trace_panel(events: TraceEvent[])}
    {@const t0   = events[0].t}
    {@const tN   = events.at(-1)!.t}
    {@const span = (tN - t0) || 1}
    {@const COLS = 60}
    {@const scale = (t: number) => Math.round((t - t0) / span * (COLS - 1))}
    <div class="sr-trace scrollbig">
        <div class="sr-trace-axis">
            <span class="sr-trace-axis-lbl">trace</span>
            <span>{span.toFixed(1)}ms</span>
            <button class="sr-trace-copy" onclick={async () => {
                try { await navigator.clipboard.writeText(trace_lines(events).join('\n') + '\n') } catch {}
            }} title="copy trace">⎘</button>
        </div>
        {#each events as ev, i}
            {@const pos         = scale(ev.t)}
            {@const ms_in_step  = (ev.t - t0).toFixed(1)}
            {@const last_snap_t = (() => { for (let j = i-1; j >= 0; j--) { const k = events[j].kind; if (k === 'snap' || k === 'snapped' || k.startsWith('snap')) return events[j].t } return null })()}
            {@const ms_later    = last_snap_t != null ? (ev.t - last_snap_t).toFixed(1) : null}
            {@const tip         = ms_later != null ? `${ms_later}ms later at ${ms_in_step}ms` : `at ${ms_in_step}ms`}
            {@const label       = `${ev.kind}${ev.tag ? ':' + ev.tag : ''}`}
            {@const prefix      = ' '.repeat(pos)}
            <div class="sr-trace-row" title={tip}>
                {prefix}<span class="sr-trace-lbl" style="color:{trace_fg(ev.kind)}">{label}</span>
            </div>
        {/each}
    </div>
{/snippet}



<!-- ═══════════════════════════════════════════════════════════════════════ -->
<style>
/* ── container ─────────────────────────────────────────────────────────── */
.sr {
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px; color: #ccc; background: #111;
    border: 1px solid #2a2a2a; border-radius: 4px;
    overflow: hidden; min-width: 320px;
}
.sr-empty { padding: 8px 12px; color: #555; }

/* ── run bar ────────────────────────────────────────────────────────────── */
.sr-bar {
    display: flex; align-items: center; gap: 8px;
    padding: 5px 10px; background: #181818; border-bottom: 1px solid #222;
}
.sr-runname { color: #888; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sr-mode    { color: #555; }
.sr-steps   { color: #888; letter-spacing: 0.02em; }
.sr-status  { font-weight: 600; }
.sr-status.ok      { color: #4a9; }
.sr-status.fail    { color: #c55; }
.sr-status.running { color: #77a; }
.sr-bar.is-fail    { border-bottom-color: #4a1a1a; }
.sr-bar.is-new   .sr-mode { color: #6a9; }
.sr-bar.is-check .sr-mode { color: #79b; }

/* ── pip strip ──────────────────────────────────────────────────────────── */
/* padding-top leaves room for the playhead triangle above pips.            */
/* align-items:flex-end keeps pips bottom-aligned when flag rows vary.      */
.sr-strip-wrap {
    position: relative;
    border-bottom: 1px solid #1e1e1e;
}
.sr-strip {
    display: flex; flex-wrap: wrap; gap: 2px;
    padding: 10px 8px 6px; background: #0e0e0e;
    max-height: 100px; overflow-y: auto; align-items: flex-end;
    padding-right: 28px;  /* clear the expand button */
}
/* strip is focusable for Tab-key story-focus entry; no visible outline —
   story focus is implicit (any child focused), not a ring on the strip */
.sr-strip:focus { outline: none; }
/* .sr itself suppresses outline too; focus is tracked via activeElement */
.sr:focus { outline: none; }

/* Vexpandy V button positioned in the strip-wrap corner — same slot as the old .sr-expand */
.sr-strip-wrap :global(.vx-btn) {
    position: absolute; top: 4px; right: 6px;
}

/* ── expanded layout ────────────────────────────────────────────────────── */
/* .sr.expanded grows to 70vh with a flex column so the diff body fills     */
/* the middle and the pip strip pins to the top.                            */
.sr.expanded {
    height: 90vh;
    display: flex; flex-direction: column;
}
.sr.expanded .sr-panel {
    flex: 1; display: flex; flex-direction: column;
    min-height: 0; overflow: hidden;
}
/* sr-body is the opacity-wrapper around the diff/pre area.                  */
/* It must be flex:1 so the diff fills available space in the panel column;  */
/* without this, the diff expands to full content height, pushing trace      */
/* and notes below overflow:hidden and making them unreachable.              */
.sr.expanded .sr-body {
    flex: 1; min-height: 0; overflow: hidden;
    display: flex; flex-direction: column;
}
/* sr-diff2 must also propagate flex:1 down to sr-diff2-body */
.sr.expanded .sr-diff2 {
    flex: 1; min-height: 0; overflow: hidden;
    display: flex; flex-direction: column;
}
/* let the vertical scroll wrapper fill the panel and scroll both columns together */
.sr.expanded .sr-diff2-body {
    flex: 1; min-height: 0; max-height: none; overflow-y: auto;
}
/* grid inside it: no height constraint, just grows to content */
.sr.expanded .sr-diff2-grid { max-height: none; }
.sr.expanded .sr-pre {
    flex: 1; min-height: 0; max-height: none; overflow-y: auto;
}
/* trace caps at 30vh in expanded so the diff always has ~40vh of the 70vh panel */
.sr.expanded .sr-trace { flex-shrink: 0; max-height: 30vh; }
/* strip-wrap pins to top (it's before the panel in DOM order); strip max-height relaxes */
.sr.expanded .sr-strip-wrap { flex-shrink: 0; }
.sr.expanded .sr-strip      { max-height: 140px; }
.sr-pip-cell { display: flex; flex-direction: column; align-items: center; gap: 1px; }
/* flags row: always rendered as spacer so pips stay bottom-aligned */
.sr-flags    { display: flex; flex-direction: row; gap: 1px; min-height: 8px; align-items: flex-end; }
.sr-flag     { display: inline-block; width: 7px; height: 7px; border-radius: 1px; flex-shrink: 0; }

/* assertion marks: diamonds (rotated squares) so they read apart from the square
   note flags at 7px.  Loudest when broken: red pulses, amber holds steady. */
.sr-amark {
    display: inline-block; width: 6px; height: 6px; flex-shrink: 0;
    margin: 0 1px 1px; transform: rotate(45deg); border-radius: 1px;
    border: 1px solid transparent; cursor: pointer;
}
.sr-amark.latched { background: #2a8; }
.sr-amark.pending { background: transparent; border-color: #3a4a3a; }
.sr-amark.overdue { background: #c93; }
.sr-amark.red     { background: #c33; animation: sr-amark-pulse 1.2s ease-in-out infinite; }
@keyframes sr-amark-pulse { 0%,100% { box-shadow: 0 0 0 0 #c3333300 } 50% { box-shadow: 0 0 4px 1px #c33399 } }

/* hover-desc layer: floats just above the strip (over the run bar's bottom edge) —
   absolute so hovering never shifts layout; no transition so it's instant. */
.sr-hoverdesc {
    position: absolute; bottom: calc(100% + 1px); left: 6px; right: 6px; z-index: 6;
    pointer-events: none;
    background: #10140fee; border: 1px solid #2a3a2a; border-radius: 3px;
    padding: 3px 8px; font-size: 11px; font-style: italic; color: #9a8;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.sr-hd-n { color: #567; font-style: normal; font-size: 9px; margin-right: 7px; }

.sr-pip {
    position: relative; width: 28px; height: 28px; border: none; border-radius: 3px;
    font-size: 13px; line-height: 28px; text-align: center; cursor: pointer;
    background: #222; color: #555; padding: 0; transition: background 0.1s;
}
.sr-pip.ok       { background: #1a3a25; color: #4a9; }
.sr-pip.fail     { background: #3a1a1a; color: #c55; }
/* accepted: mismatch acknowledged — green background, red glyph */
.sr-pip.accepted { background: #1a3a25; color: #c55; }
/* caveat: forgiven value-noise — virtually OK (an Entcase relaxed it) */
.sr-pip.caveat   { background: #12333a; color: #6cc; }
/* hollow: step in The but not yet reached this session */
.sr-pip.hollow   { background: #1a1a1a; color: #555; border: 1px solid #383838; }
.sr-pip.on       { outline: 1px solid #79b; outline-offset: 1px; }
.sr-pip.has-notes { border-bottom: 2px solid #444; }
.sr-pip:hover    { background: #333; }
/* is-anchor: step diff[] is collecting from — teal ring */
.sr-pip.is-anchor { outline: 2px solid #4a9; outline-offset: 2px; }
/* playhead: red downward triangle marking frontier or first hollow pip */
.sr-pip.playhead::before {
    content: ''; position: absolute; top: -11px; left: 50%;
    transform: translateX(-50%); width: 0; height: 0;
    border-left: 6px solid transparent; border-right: 6px solid transparent;
    border-top: 9px solid #c55; pointer-events: none;
}

/* ── snap panel shell ───────────────────────────────────────────────────── */
.sr-panel { border-top: 1px solid #222; }
.sr-phdr {
    display: flex; align-items: center; gap: 6px; flex-wrap: wrap;
    padding: 4px 10px; background: #161616; border-bottom: 1px solid #1e1e1e;
}
.sr-pn    { color: #79b; font-weight: 600; }
.sr-pdige { color: #555; font-size: 10px; }
/* the step's %desc — a few words riding the toc step line */
.sr-pdesc { color: #9a8; font-size: 11px; font-style: italic; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 22em; }
.sr-plabel { font-size: 10px; }
.sr-plabel.mm       { color: #c55; }
.sr-plabel.accepted { color: #4a9; }
.sr-plabel.caveat   { color: #6cc; }
.sr-plabel.hollow   { color: #444; }
/* dige integrity warning — disk/toc mismatch surfaced by check_snap */
.sr-warn {
    font-size: 10px; font-weight: 600; color: #e67;
    background: #2a1010; border: 1px solid #4a2020; border-radius: 2px; padding: 0 5px;
}

/* diff mode toggle buttons in the panel header */
.sr-diff-modes { display: flex; gap: 3px; margin-left: 2px; }
.sr-diff-modes button {
    background: #181818; border: 1px solid #2a2a2a; border-radius: 2px;
    color: #444; cursor: pointer; font-size: 9px; font-family: inherit;
    padding: 0 5px; line-height: 15px;
}
/* primary: vs exp / vs prev — the common comparison modes, shown larger */
.sr-diff-modes button.primary {
    font-size: 13.5px; padding: 0 7px; line-height: 17px;
    border-color: #333;
}
.sr-diff-modes button.active { background: #0e1e18; border-color: #2a4a3a; color: #6bc; }
.sr-diff-modes button:hover:not(.active) { color: #888; }

/* ── diff[] range collector ─────────────────────────────────────────────── */
/* sits after the mode buttons, before Accept.                               */
.sr-ekey {
    font-size: 9px; color: #333; letter-spacing: 0.05em;
    margin-left: 3px; user-select: none;
}

/* collecting: pulses teal while waiting for the second click.               */
/* sr-diffstatus: brief feedback badge, auto-clears after 3s.               */
.sr-diffrange {
    background: #181818; border: 1px solid #2a3a2a; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 9px; font-family: inherit;
    padding: 0 7px; line-height: 15px; margin-left: 4px;
}
.sr-diffrange:hover { background: #1a2a1a; }
.sr-diffrange.collecting {
    background: #1a2a1a; border-color: #4a9; color: #7bc;
    animation: sr-pulse 1.2s ease-in-out infinite;
}
@keyframes sr-pulse { 0%,100%{opacity:1} 50%{opacity:.55} }
.sr-diffstatus { font-size: 9px; color: #4a9; margin-left: 4px; }

.sr-close {
    background: none; border: none;
    color: #555; cursor: pointer; font-size: 14px; line-height: 1; padding: 0 2px;
}
.sr-close:hover { color: #aaa; }
.sr-accept {
    background: #1a3a25; border: 1px solid #2a5a35; border-radius: 3px;
    color: #4a9; cursor: pointer; font-size: 18px; font-family: inherit; padding: 1px 10px;
    margin-left: auto;
}
.sr-accept-all {
    background: #1a3a25; border: 1px solid #2a5a35; border-radius: 3px;
    color: #4a9; cursor: pointer; font-size: 18px; font-family: inherit; padding: 1px 12px;
    margin-left: auto;
}
.sr-accept-all:hover, .sr-accept:hover { background: #2a4a35; }
.sr-hollow-body { padding: 12px; color: #444; font-size: 10px; }

/* ── naive / tree pre ───────────────────────────────────────────────────── */
.sr-pre {
    margin: 0; padding: 4px 0; overflow: auto; min-height: 12em; max-height: min(30vh, 666px);
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px; line-height: 1.55; color: #bbb;
    background: transparent; white-space: pre; tab-size: 2;
}
.sr-tree-pre { padding: 4px 8px; }
.sr-line { display: block; padding: 0 8px; border-left: 2px solid transparent; }
.sr-line:hover   { background: #181818; }
.sr-line.changed { background: #1e1600; border-left-color: #a80; }
.sr-line.neu     { background: #001a10; border-left-color: #4a9; }
.sr-line.gone    { background: #1a0000; border-left-color: #c55; opacity: 0.6; }

/* ── two-column proper diff ─────────────────────────────────────────────── */
/* .sr-diff2-body is a 2-column grid; each .sr-diff2-col scrolls horizontally */
/* as one unit and they stay in lockstep via sync_col_scroll.                 */
/* Vertical scroll is on the body; columns are overflow-y:hidden inside it.   */
.sr-diff2-hdr {
    display: grid; grid-template-columns: 1fr 1fr;
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px;
    border-bottom: 1px solid #1e1e1e;
}
/* sr-diff2-body: vertical scroll wrapper — constrains height and scrolls both
   columns together. The grid inside grows to full content height, unclipped. */
.sr-diff2-body {
    overflow-y: auto; min-height: 12em; max-height: min(30vh, 666px);
}
/* sr-diff2-grid: the actual 2-column grid — full content height, no overflow.
   Grid rows align both columns automatically; wrapper above does the scrolling. */
.sr-diff2-grid {
    display: grid; grid-template-columns: 1fr 1fr;
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px; line-height: 1.55;
}
/* each column clips and scrolls horizontally only; vertical is the wrapper's job */
.sr-diff2-col {
    overflow-x: auto; overflow-y: visible;
    scrollbar-width: none; min-width: 0; white-space: pre;
}
.sr-diff2-col::-webkit-scrollbar { display: none; }
.sr-diff2-col:last-child { border-left: 1px solid #1a1a1a; }

.sr-diff2-cell {
    padding: 0 8px; border-left: 2px solid transparent;
    /* empty placeholder cells (left_only/right_only) have no content, so they'd collapse
       to zero height without this — causing column height drift over many such rows */
    min-height: 1lh;
}
.sr-diff2-cell:hover { background: #181818; }
/* row-kind backgrounds and accents — applied per-cell now that rows are gone */
.sr-diff2-cell.changed                    { background: #1e1600; border-left-color: #a80; }
.sr-diff2-cell.gone                       { background: #1a0000; }
.sr-diff2-cell.gone:not(.sr-empty-cell)   { border-left-color: #c55; }
.sr-diff2-cell.neu                        { background: #001a10; }
.sr-diff2-cell.neu:not(.sr-empty-cell)    { border-left-color: #4a9; }
.sr-empty-cell { opacity: 0.12; }
/* a changed line is the click target for authoring an Entcase (entropy arrest) */
.sr-spayable { cursor: pointer; }
.sr-spayable:hover { background: #2a2008; box-shadow: inset 2px 0 0 #ca0; }

/* a changed line an Entcase reaches: acknowledged noise (would forgive) RECEDES — a teal
   left-tick marks it as spayed, and the content is dimmed right down so the eye skates past
   it to the diffs that matter.  Hover restores full contrast to read/re-click it.  A blown
   band keeps the loud amber+pulse (below): it still diffs badly and must not hide. */
.sr-diff2-cell.changed.spay-graft {
    background: #06140f; border-left-color: #2a8; box-shadow: inset 3px 0 0 #2a8;
    filter: contrast(0.6) brightness(0.45);
}
.sr-diff2-cell.changed.spay-graft:hover { filter: none; }
.sr-diff2-cell.changed.spay-blown {
    background: #1d0c00; border-left-color: #e83;
    animation: spay-pulse 1.6s ease-in-out infinite;
}
@keyframes spay-pulse {
    0%, 100% { box-shadow: inset 3px 0 0 #e83, 0 0 3px #c6330033; }
    50%      { box-shadow: inset 3px 0 0 #fb5, 0 0 8px #e8773399; }
}

/* ── assertions: ghost lines + the sworn button + the explorer ──────────── */
/* ghost: a declared assertion whose evidence never latched — a red dashed line
   standing where the sworn would.  Clickable → the explorer (clue = navigation). */
.sr-diff2-cell.sr-ghost-cell { background: #1a0408; }
.sr-diff2-cell.sr-ghost-cell:not(.sr-empty-cell) {
    border-left-color: #c33; cursor: pointer;
    outline: 1px dashed #722; outline-offset: -1px;
}
.sr-diff2-cell.sr-ghost-cell:not(.sr-empty-cell):hover { background: #2a080c; }
.sr-line.sr-ghost {
    background: #1a0408; border-left-color: #c33; cursor: pointer;
    outline: 1px dashed #722; outline-offset: -1px;
}
.sr-line.sr-ghost:hover { background: #2a080c; }
.sr-ghost-txt { color: #e77; font-style: italic; }
.sr-ghost-tag { color: #944; font-size: 9px; font-style: italic; }

/* sworn button: latched/total (+ ◇ unclaimed); pulses red while broken */
.sr-assert-btn {
    background: #181818; border: 1px solid #2a3a2a; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 9px; font-family: inherit;
    padding: 0 6px; line-height: 15px;
}
.sr-assert-btn.active { background: #0e1e18; border-color: #2a4a3a; color: #6bc; }
.sr-assert-btn.broken { border-color: #a33; color: #c55; animation: sr-pulse 1.4s ease-in-out infinite; }
.sr-assert-btn.broken.active { background: #1a0808; }
/* warn: no contract break, but undeclared sworn exist — they want declaring */
.sr-assert-btn.warn { border-color: #6a4a1a; color: #c93; }

/* the explorer body — sits in the diff's seat while open (the mutex) */
.sr-ax { padding: 4px 0 6px; min-height: 12em; max-height: min(40vh, 666px); overflow-y: auto; background: #0c120e; }
.sr.expanded .sr-ax { flex: 1; max-height: none; }
.sr-ax-sec {
    font-size: 9px; font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase;
    color: #446; padding: 5px 10px 3px;
}
.sr-ax-row {
    display: flex; align-items: baseline; gap: 8px; padding: 2px 10px;
    cursor: pointer; border-left: 2px solid transparent;
}
.sr-ax-row:hover { background: #161a16; }
.sr-ax-row.latched .sr-ax-ico { color: #4a9; }
.sr-ax-row.pending { opacity: 0.55; }
.sr-ax-row.pending .sr-ax-ico   { color: #567; }
.sr-ax-row.pending .sr-ax-state { color: #555; }
.sr-ax-row.overdue { border-left-color: #c93; }
.sr-ax-row.overdue .sr-ax-ico   { color: #c93; }
.sr-ax-row.overdue .sr-ax-state { color: #c93; }
.sr-ax-row.red { border-left-color: #c33; background: #180608; }
.sr-ax-row.red .sr-ax-ico   { color: #c55; }
.sr-ax-row.red .sr-ax-state { color: #c55; }
/* focus: the row a ghost line / pip mark clicked through to */
.sr-ax-row.focus { outline: 1px dashed #c55; outline-offset: -1px; }
.sr-ax-ico  { flex-shrink: 0; width: 1em; text-align: center; }
.sr-ax-slug { color: #79b; flex-shrink: 0; }
.sr-ax-sent { color: #999; flex: 1; font-style: italic; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 8em; }
.sr-ax-due {
    background: none; border: 1px solid #2a2a3a; border-radius: 2px; flex-shrink: 0;
    color: #567; cursor: pointer; font-size: 9px; font-family: inherit; padding: 0 5px; line-height: 14px;
}
.sr-ax-due:hover { color: #79b; border-color: #3a3a5a; }
.sr-ax-n { color: #4a9; font-size: 9px; flex-shrink: 0; }
.sr-ax-state { font-size: 9px; flex-shrink: 0; }
.sr-ax-has-micro { color: #567; font-size: 10px; flex-shrink: 0; }
/* sworn mode: the panel wears the evidence green (the matstyle:sworn swatch) —
   unmistakably not a diff.  The counts ride beside the title; [s]+× push right. */
.sr-phdr.sworn { background: #0c1a10; border-bottom-color: #1e3a26; }
.sr-phdr.sworn .sr-ekey { margin-left: auto; }
.sr-sworn-title {
    color: #29d638; font-weight: 700; font-size: 11px;
    letter-spacing: 0.12em; text-transform: uppercase;
}
.sr-sworn-counts { color: #4a9; font-size: 10px; }

/* undeclared: NOT ok — amber, wants declaring; the declare button IS the door in */
.sr-ax-sec.undecl { color: #6a4a1a; }
.sr-ax-undecl { border-left-color: #6a4a1a; }
.sr-ax-undecl .sr-ax-ico { color: #c93; }
.sr-ax-declare {
    background: #1a2a1a; border: 1px solid #2a4a2a; border-radius: 2px; flex-shrink: 0;
    color: #4a9; cursor: pointer; font-size: 9px; font-family: inherit; padding: 0 6px; line-height: 14px;
}
.sr-ax-declare:hover { background: #234a28; color: #7dc; }
/* the unfolded microsnap — what the assertion pointed at, frozen at go-off time */
.sr-ax-micro {
    margin: 0 10px 4px 28px; padding: 4px 8px;
    background: #0a0c10; border-left: 2px solid #2a3a4a;
    color: #7aa8c7; font-size: 10px; line-height: 1.5;
    white-space: pre; overflow-x: auto;
}
.sr-ax-none { padding: 8px 12px; color: #444; font-style: italic; font-size: 10px; }

/* squish: collapsed run of uninteresting same lines */
.sr-squish {
    color: #2a2a2a; font-size: 9px; font-family: inherit;
    padding: 1px 10px; background: #0a0a0a;
    border-top: 1px solid #161616; border-bottom: 1px solid #161616;
    white-space: pre;
}

/* prev-bg: dark navy for the whole diff area in prev mode — visually distinct from exp */
.sr-diff2.prev-bg,
.sr-diff2.prev-bg .sr-diff2-hdr  { background: #020d1a; }
.sr-diff2.prev-bg .sr-diff2-col:last-child { border-left-color: #0d1a2a; }
.sr-diff2.prev-bg .sr-squish { background: #030e1a; border-top-color: #0a1520; border-bottom-color: #0a1520; }

/* first-bg: warm amber tint — Resnapture diff, distinct from exp (blue) and prev (navy) */
.sr-diff2.first-bg,
.sr-diff2.first-bg .sr-diff2-hdr  { background: #141008; }
.sr-diff2.first-bg .sr-diff2-col:last-child { border-left-color: #261e08; }
.sr-diff2.first-bg .sr-squish { background: #100c04; border-top-color: #1e1604; border-bottom-color: #1e1604; }

/* first mode button — amber accent only when active */
.sr-diff-modes button.sr-first-btn.active  { background: #1a1208; border-color: #4a3818; color: #cb9; }

/* ── Resnapture popup content (inside Vexpandy fixed modal) ─────────────── */
/* Buttons and labels that live in the Vexpandy header snippet.              */
.sr-resnap-title {
    color: #b97; font-size: 10px; font-weight: 600; letter-spacing: 0.04em; flex: 1;
}
.sr-resnap-dim   { color: #664; font-style: italic; font-weight: 400; }
.sr-resnap-goto {
    background: #1a1208; border: 1px solid #3a2808; border-radius: 2px;
    color: #b97; cursor: pointer; font-size: 9px; font-family: inherit;
    padding: 0 8px; line-height: 15px;
}
.sr-resnap-goto:hover { background: #2a1e0c; color: #cb9; }
.sr-resnap-close {
    background: none; border: none;
    color: #664; cursor: pointer; font-size: 14px; line-height: 1; padding: 0 2px;
}
.sr-resnap-close:hover { color: #cb9; }
/* empty state inside the popup body */
.sr-resnap-empty { color: #554; font-style: italic; }

.sr-dlabel {
    font-size: 9px; font-weight: 700; letter-spacing: 0.1em;
    text-transform: uppercase; padding: 3px 8px; background: #141414;
}
.sr-dlabel.got { color: #4a9; }
.sr-dlabel.ref { color: #79b; }

/* shared inline span styles used in both pre and diff cells */
.sr-obj { color: #7aa8c7; }
.sr-ind { white-space: pre; }
.sr-str { color: #bbb; }

/* ── trace panel ────────────────────────────────────────────────────────── */
.sr-trace-btn {
    background:#181818; border:1px solid #2a3a2a; border-radius:2px;
    color:#4a9; cursor:pointer; font-size:9px; font-family:inherit;
    padding:0 6px; line-height:15px;
}
.sr-trace-btn.active { background:#0e1e18; border-color:#2a4a3a; }
.sr-inctrace { display:inline-flex; align-items:center; gap:3px; font-size:11px; color:#4a7a64; cursor:pointer; user-select:none; }
.sr-inctrace input { margin:0; accent-color:#2a4a3a; }
.sr-trace {
    font-family:'Berkeley Mono','Fira Code',ui-monospace,monospace;
    font-size:10px; line-height:1.4; background:#090909;
    padding:4px 0; overflow-x:auto; overflow-y:auto; white-space:pre;
    border-top:1px solid #1a1a1a;
    max-height: 26vh; min-height: 6em;
}
.sr-trace-axis {
    display:flex; justify-content:space-between; gap:8px;
    color:#333; font-size:8px; padding:0 4px 2px;
    border-bottom:1px solid #161616;
}
.sr-trace-axis-lbl { color:#254535; letter-spacing:0.08em; text-transform:uppercase; }
/* copy button in the axis bar — quiet until hovered */
.sr-trace-copy {
    background:none; border:none; color:#2a4a3a; cursor:pointer;
    font-size:11px; line-height:1; padding:0 2px; margin-left:auto;
}
.sr-trace-copy:hover { color:#4a9; }
.sr-trace-row { white-space:pre; }
/* sr-trace-lbl: colour inline via trace_fg(); no background — just tinted text trickling down */
.sr-trace-lbl { }
.sr-trace-row:hover .sr-trace-lbl { filter:brightness(1.4); }

/* ── overrun monitor — button on the run bar + live ticker ──────────────── */
/* amber, distinct from the green trace button; pulses so a wedged step nags */
.sr-over-btn {
    background:#1e1606; border:1px solid #4a3a1a; border-radius:2px;
    color:#d99; cursor:pointer; font-size:9px; font-family:inherit;
    padding:0 6px; line-height:15px; white-space:nowrap;
    animation: sr-over-pulse 1.4s ease-in-out infinite;
}
.sr-over-btn.active { background:#2a1e08; border-color:#6a4a1a; color:#fb8; animation:none; }
@keyframes sr-over-pulse { 0%,100% { border-color:#4a3a1a } 50% { border-color:#8a6a2a } }
.sr-live {
    font-family:'Berkeley Mono','Fira Code',ui-monospace,monospace;
    font-size:10px; line-height:1.4; background:#0c0a06;
    border-bottom:1px solid #2a1e08; overflow:hidden;
}
.sr-live-rows {
    display:flex; flex-direction:column; justify-content:flex-end;
    max-height:30vh; min-height:8em; overflow:hidden; padding:2px 6px 4px;
}
.sr-live-d   { display:inline-block; width:62px; text-align:right; color:#7a5a2a; padding-right:8px; }
.sr-live-idle { color:#5a5230; }
.sr-live-idle.stale { color:#e08a3a; font-weight:600; }   /* trace frozen — the wedge signal */
.sr-live-cur { margin-left:auto; color:#6a4a1a; }
.sr-live-wait { color:#5a4a2a; padding:4px 0; }
/* step wall-clock — right-aligned in the panel header, dimmer than the dige */
.sr-ptime {
    margin-left: auto; color: #4a6a5a;
    font-size: 9px; letter-spacing: 0.04em;
}

/* ── notes panel ────────────────────────────────────────────────────────── */
.sr-notes {
    border-top: 1px solid #1a1a1a; padding: 4px 8px 6px; background: #101010;
}
.sr-notes-hdr  { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
.sr-notes-title {
    font-size: 9px; font-weight: 700; letter-spacing: 0.1em;
    text-transform: uppercase; color: #444; margin-right: 4px;
}
.sr-note-badge { font-size: 8px; padding: 0 4px; border-radius: 2px; border: 1px solid; opacity: 0.7; line-height: 14px; }
.sr-note-row   { display: flex; align-items: center; gap: 5px; padding: 1px 0; }
.sr-note-dot   { flex-shrink: 0; width: 6px; height: 6px; border-radius: 50%; }
.sr-note-label { flex: 1; color: #999; font-size: 10px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sr-note-del   { background: none; border: none; color: #444; cursor: pointer; font-size: 12px; line-height: 1; padding: 0 2px; }
.sr-note-del:hover { color: #c55; }
.sr-note-add  { display: flex; gap: 4px; margin-top: 4px; }
.sr-note-input {
    flex: 1; background: #181818; border: 1px solid #2a2a2a; border-radius: 2px;
    color: #bbb; font-family: inherit; font-size: 10px; padding: 2px 6px; outline: none; min-width: 0;
}
.sr-note-input:focus       { border-color: #3a3a3a; }
.sr-note-input::placeholder { color: #333; }
.sr-note-submit {
    background: #1a2a1a; border: 1px solid #2a3a2a; border-radius: 2px;
    color: #4a9; cursor: pointer; font-size: 14px; font-family: inherit; padding: 0 6px; line-height: 1;
}
.sr-note-submit:hover { background: #2a3a2a; }

/* ── intra-line character highlights ───────────────────────────────────── */
/* del: deleted chars in reference (left) cell — red background            */
.sr-del   { background: #3d0a0a; color: #ff9090; border-radius: 1px; }
/* ins: inserted chars in got (right) cell — green background              */
.sr-ins   { background: #0a2a0a; color: #90ff90; border-radius: 1px; }
/* plain: equal chars — inherits cell colour, no decoration                */
.sr-plain { }

/* ── scrollbars ─────────────────────────────────────────────────────────────
   The strip rides the global .scrollsmall; the grabbable pre/diff/trace panes
   ride the global .scrollbig (see app.css).  Both classes are on the elements. */
</style>