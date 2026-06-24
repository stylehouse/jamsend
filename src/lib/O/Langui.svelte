<script lang="ts">
    // Langui — CodeMirror view over one document, identified by `doc` (path string).
    //
    // ── Multi-doc (Option B: one view, per-path EditorState cache) ───────────!!!!!!
    //
    //   One EditorView, many EditorStates.  On doc switch:
    //     1. Bookmark positions for the departing doc are flushed immediately
    //        (bypassing the 800ms debounce) so dock never has stale positions.
    //     2. Scroll position is saved to scrollCache (EditorState doesn't carry it).
    //     3. Current EditorState (undo history, selection, bookmark decorations)
    //        is saved to stateCache[prev_path].
    //     4. view.setState(stateCache[arriving]) restores a previously-seen doc,
    //        or creates a fresh EditorState from ave text for a first visit.
    //     5. Scroll position is restored by dispatching view.scrollSnapshot().
    //
    //   view.setState() is CM's documented multi-doc API.  It replaces all state
    //   atomically without destroying the view, so decorations and plugins
    //   survive.  All EditorStates on one view must share the same extension list
    //   (editorExtensions) — stho() theme is called once at construction.
    //
    //   Every CM event carries { doc, view, state } so Lang_dock_from_event
    //   on the backend can DRY the state update in exactly one place.
    //
    // ── Bookmark pipeline ────────────────────────────────────────────────────
    //
    //   Ctrl+B at cursor/selection → addBookmarkMark StateEffect → bookmarkField
    //   installs a Decoration.mark carrying its bookmark_id. The field's
    //   marks.map(tr.changes) in update() automatically remaps from/to on
    //   every subsequent edit (RangeSet is the source of truth for positions).
    //
    //   On each dispatch we fire an elvis to w:Lang with doc,view,state:
    //     - Ctrl+B:           Lang_add_bookmark {from,to,label}
    //     - 800ms post-edit:  Lang_update_bookmarks {updates}
    //     - any text change:  Lang_texting   {dock_path, text}
    //     - Escape key     :  Lang_compile   {}
    //     - saveEffect     :  Lang_update_bookmarks immediately (cancels debounce)
    //
    //   Bookmark flush on switch: flush_update_bookmarks_for_path(prev_path) is
    //   called before saving the departing EditorState.  This cancels any pending
    //   800ms debounce and immediately sends the live positions to dock so they
    //   can't be clobbered by a stale timer firing after the switch.
    //   editorBegins also carries `updates` so the backend can re-apply any
    //   bookmarks that exist in dock but are absent from a freshly-restored CM state.
    //
    // ── saveEffect ───────────────────────────────────────────────────────────
    //
    //   A zero-payload StateEffect dispatched after a programmatic doc change
    //   by e_Lang_i_alterationStation to flush bookmark positions immediately
    //   without waiting for the 800ms debounce.  The updateListener detects it,
    //   cancels any pending timer, and calls fire_update_bookmarks() right away —
    //   so e_Lang_update_bookmarks receives the fresh editorState and calls think().
    //
    // ── Reactive chain ───────────────────────────────────────────────────────
    //
    //   Signal $effect: reads H.ave.ob({active_dock:1}) + sig?.ob() to subscribe
    //     to sig.version changes.  Writes active_path ($state) and dock ($state).
    //
    //   Switch $effect: reads active_path (only reactive dep).  When it changes,
    //     flushes bookmarks + scroll for departing doc → saves departing state →
    //     calls view.setState(arriving state).  All CM state (history, scroll,
    //     selection, decorations) moves with the switch.
    //
    //   External-change $effect: handles disk-reload of the active doc only.
    //     Guards against firing during a switch (active_path !== prev_path).
    //
    // ── Echo guard / text spool (the high-frequency-git seed) ────────────────
    //
    //   dock.c.text + dock/{Text:1} are used for two flows that look
    //   identical from the particle's POV but are not at all the same:
    //     (a) disk/remote pulls — Lies has loaded a new file, or in future a
    //         peer has merged something in.  These should be applied to the view.
    //     (b) echoes of our own pushes — we sent Lang_texting on a keystroke,
    //         it round-tripped through e_Lang_texting which bumped the particle,
    //         and now the disk-reload $effect sees a "change".
    //   Without distinguishing the two, fast typing drives an oscillation: a
    //   stale snapshot from the elvis queue arrives, the $effect dispatches
    //   a full-doc replace at offset 0, the updateListener fires, *that* pushes
    //   the stale text back into the queue, repeat.
    //
    //   text_spool[path] is a small ring of texts the editor has been at.
    //   On every keystroke we remember the new text.  The disk-reload $effect
    //   treats any incoming text already in the spool as an echo and skips it.
    //   Genuine remote changes (text we've never been at) still apply.
    //
    // ── Push batcher (debounce + max-wait) ──────────────────────────────────
    //
    //   Lang_texting fires 400ms after the last keystroke (trailing debounce),
    //   but never later than 5s into a continuous burst (max-wait cap).
    //   The flush reads the LIVE view text at fire time so the backend always
    //   lands on the freshest snapshot.  Doc switch flushes any pending push
    //   for the departing path before saving its state.

    import { onDestroy, untrack } from "svelte"
    import { EditorView, basicSetup } from "codemirror"
    import { EditorState, StateField, StateEffect, Compartment, type Extension } from "@codemirror/state"
    import { Decoration, type DecorationSet, keymap, ViewUpdate, ViewPlugin, WidgetType, drawSelection } from "@codemirror/view"
    import { indentService, indentUnit } from "@codemirror/language";
    import { foldEffect, unfoldEffect, unfoldAll, foldedRanges, codeFolding } from "@codemirror/language";
    import { defaultKeymap, indentWithTab } from "@codemirror/commands";
    import { diff_match_patch } from "diff-match-patch"

    import { lang, simpleLezerLinter, lang_for_path } from "$lib/O/lang/lang"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import Actions from "$lib/O/ui/Actions.svelte"   // doc-picker dropdown + any other Lang actions
    import DocMinimap from "./ui/DocMinimap.svelte"
    import DocCompost from "./ui/DocCompost.svelte"  // frozen-frame overlay; arms dock.c.compost for fly-in gotos
    import DocPoint   from "./ui/DocPoint.svelte"
    import { now_in_seconds_with_ms } from "./Peerily.svelte";

    let { H }: { H: House } = $props()

    // container is $state so the creation $effect tracks when the div appears.
    // The div only renders once dock is truthy, so this naturally gates construction.
    let container: HTMLDivElement | undefined = $state()
    // view is $state so child components passed `view` as a prop get the
    // EditorView reference once construction has completed (otherwise the
    // prop captures undefined at mount and never updates).
    let view: EditorView | undefined = $state()

    // ── per-instance language Compartment ────────────────────────────────────
    //   Wraps the lang(name) extensions so the lang dropdown can swap
    //   languages at runtime via view.dispatch({effects: reconfigure}). One
    //   Compartment per Langui instance so multi-editor setups don't collide.
    //   last_applied_lang tracks the latest applied name; the reconfigure
    //   $effect skips no-op reapplications.
    const langCompartment = new Compartment()
    let last_applied_lang: string | undefined
    // The lang editorExtensions baked into langCompartment.of() at build_editor — the
    //  grammar a freshly setState'd state carries until the reconfigure $effect corrects
    //   it.  The switch $effect resets last_applied_lang to this (not undefined) so the
    //    effect re-applies ONLY on a real mismatch, sparing a same-grammar reconfigure +
    //     its now-attached recompile on every same-language dock open.
    let baked_lang_name: string | undefined

    const UPDATE_DELAY_MS = 800
    let update_timer: ReturnType<typeof setTimeout> | null = null

    // ── auto-save timing ─────────────────────────────────────────────────────
    //   Two triggers — whichever fires first:
    //     quiet:   1.5 s of no keystrokes
    //     active: 10 s of continuous typing (prevents losing a long session)
    //   Compares CM Text objects by identity; no hashing in the hot path.
    //   Writes source to disk via e:Lies_source_write; does NOT compile.
    const AUTOSAVE_QUIET_MS  = 1_500
    const AUTOSAVE_ACTIVE_MS = 10_000
    let _autosave_last_input_ts  = 0
    let _autosave_last_save_ts   = 0
    let _autosave_last_saved_doc: import('@codemirror/state').Text | undefined
    let _autosave_interval: ReturnType<typeof setInterval> | null = null

    function fire_autosave(path: string, doc: import('@codemirror/state').Text) {
        _autosave_last_saved_doc = doc
        _autosave_last_save_ts   = Date.now()
        H.i_elvisto('Lies/Lies', 'Lies_source_write', { path, text: doc.toString() })
    }

    function check_autosave() {
        if (!view || !active_path) return
        if (_autosave_last_input_ts === 0) return   // no edits for this doc yet
        const doc = view.state.doc
        if (doc === _autosave_last_saved_doc) return   // no change since last save
        const now    = Date.now()
        const quiet  = now - _autosave_last_input_ts > AUTOSAVE_QUIET_MS
        const overdue = _autosave_last_input_ts > _autosave_last_save_ts
                     && now - _autosave_last_save_ts > AUTOSAVE_ACTIVE_MS
        if (quiet || overdue) fire_autosave(active_path, doc)
    }

    // Called on doc switch — flush any unsaved edits for the departing doc
    // before its CM state is archived to stateCache.
    // `path` is the doc the live view text belongs to — the caller passes the
    // departing path on a switch (active_path has already moved to the arrival)
    // and the live path on an Esc.  Without it this wrote the departing text to
    // whatever active_path had become.
    // Guard: if no keystrokes have landed for this doc, seed last_saved_doc
    // from the live view so the next doc's check_autosave starts clean.
    function flush_autosave_now(path: string) {
        if (!view || !path) return
        if (_autosave_last_input_ts === 0) {
            // no edits — just mark the current text as "already saved" so the
            // arriving doc's first check_autosave doesn't see a stale undefined
            _autosave_last_saved_doc = view.state.doc
        } else {
            const doc = view.state.doc
            if (doc !== _autosave_last_saved_doc) fire_autosave(path, doc)
        }
        _autosave_last_input_ts  = 0
        _autosave_last_save_ts   = 0
        _autosave_last_saved_doc = undefined
    }

    // Live primary-selection range, updated from the updateListener on every
    // transaction (selection-only transactions included, so cursor moves
    // update the header readout immediately).
    let sel_from = $state(0)
    let sel_to   = $state(0)
    // where-you-look tap throttle: a light tap at the cursor when it settles on a NEW
    //  line (the "look"), then a HELD tap if you linger there (the "dwell"), which
    //  warms the globule's bar amber→pink.  Both reset when the cursor changes line.
    let _tap_line    = -1
    let _tap_timer:   ReturnType<typeof setTimeout> | null = null
    let _dwell_timer: ReturnType<typeof setTimeout> | null = null

    // ── per-doc state cache ──────────────────────────────────────────────────
    //   One EditorState per path, saved on departure and restored on arrival.
    //   CM EditorState carries full undo history, selection, and all installed
    //   StateField values (including bookmark decorations).
    //   Plain Map — not reactive.  The switch $effect is the only writer.
    const stateCache = new Map<string, EditorState>()

    // ── per-doc scroll cache ─────────────────────────────────────────────────
    //   EditorState does not carry DOM scroll position.
    //
    //   view.scrollSnapshot() captures the full scroll state as an opaque
    //   StateEffect (a ScrollTarget with isSnapshot=true).  Dispatching it
    //   back via view.dispatch({ effects: snap }) is the only public API
    //   that correctly restores scroll after view.setState() — pixel writes to
    //   scrollDOM.scrollTop and posAtCoords-based scrollIntoView both lose
    //   the race to CM's internal measure passes that fire after setState().
    const scrollCache = new Map<string, ReturnType<EditorView['scrollSnapshot']>>()

    // ── text spool (echo guard) ──────────────────────────────────────────────
    //   text_spool[path] = recent editor texts (most-recent first), bounded.
    //   - Updated synchronously on every keystroke (updateListener).
    //   - Updated when the editor restores a cached state on doc switch.
    //   - Consulted by the disk-reload $effect to discard echoes of our own
    //     pushes — see the top-of-file comment for the why.
    //   Not reactive; pure closure state.
    const SPOOL_SIZE = 32
    const text_spool = new Map<string, string[]>()
    function spool_remember(path: string, text: string) {
        if (!path) return
        let s = text_spool.get(path)
        if (!s) { s = []; text_spool.set(path, s) }
        if (s[0] === text) return
        // de-dup: pull a deeper repeat to the front rather than letting the
        // ring fill with copies.  Common when alternating between two texts.
        const idx = s.indexOf(text)
        if (idx > 0) s.splice(idx, 1)
        s.unshift(text)
        if (s.length > SPOOL_SIZE) s.length = SPOOL_SIZE
    }
    function spool_has(path: string, text: string): boolean {
        return text_spool.get(path)?.includes(text) ?? false
    }

    // ── push-text batcher ────────────────────────────────────────────────────
    //   Trailing debounce: fire 400ms after the last keystroke.
    //   Max-wait cap: fire anyway after 5s of continuous typing so a long
    //     session doesn't build up unbounded lag in the elvis queue.
    //   flush reads the LIVE view text at fire time — always the freshest snapshot.
    //   push_pending_path tracks which doc the pending push belongs to —
    //     doc switch flushes it for the departing path before swapping.
    //   pin dock to `path`, not active_path: the switch $effect fires after
    //     active_path has already advanced; without pinning the departing text
    //     would land as a Lang_texting on the arriving dock and silently
    //     overwrite it on disk via the disk-reload $effect.
    const PUSH_QUIET_MS  = 400
    const PUSH_ACTIVE_MS = 5_000
    let push_quiet_timer:  ReturnType<typeof setTimeout> | null = null
    let push_active_timer: ReturnType<typeof setTimeout> | null = null
    let push_pending_path: string | null = null
    function flush_push_text(label='???') {
        if (push_quiet_timer)  { clearTimeout(push_quiet_timer);  push_quiet_timer  = null }
        if (push_active_timer) { clearTimeout(push_active_timer); push_active_timer = null }
        const path = push_pending_path
        push_pending_path = null
        if (!view || !path) return
        const text = view.state.doc.toString()
        // re-remember here in case a programmatic dispatch slipped through
        spool_remember(path, text)
        Lang_i_elvis(view, 'Lang_texting', { dock_path: path, text })
        // console.log(`       Langui pushtext: ${label} ${now_in_seconds_with_ms()}`)
    }
    function schedule_push_text(path: string) {
        // console.log(`       Langui pushtext!`)
        push_pending_path = path
        // trailing debounce — reset the quiet window on every keystroke
        if (push_quiet_timer) clearTimeout(push_quiet_timer)
        push_quiet_timer = setTimeout(() => flush_push_text('quiet'), PUSH_QUIET_MS)
        // max-wait cap — arm once per burst; not reset by keystrokes
        if (!push_active_timer)
            push_active_timer = setTimeout(() => flush_push_text('max-wait'), PUSH_ACTIVE_MS)
    }
    function flush_push_text_now() {
        if (push_quiet_timer || push_active_timer) flush_push_text('now')
    }

    // ── bookmark-position flush ───────────────────────────────────────────────
    //   flush_update_bookmarks_for_path(path): cancel the 800ms debounce and
    //   immediately send the live bookmark positions for `path` to the backend.
    //
    //   Called before a doc switch so the departing doc's positions land in
    //   dock before active_path changes — preventing a stale debounce timer
    //   from firing later and sending the wrong doc's (empty) bookmark list to
    //   the arriving doc's dock, which would flag all its bookmarks as vanished.
    function flush_update_bookmarks_for_path(path: string) {
        if (update_timer) { clearTimeout(update_timer); update_timer = null }
        if (!view || !path) return
        const updates = readBookmarks(view)
        H.i_elvisto('Lang/Lang', 'Lang_update_bookmarks',
            { doc: path, view, state: view.state, updates })
    }

    // The extension list is created once at view construction and shared by
    // every EditorState on this view.  CM requires that all states on one view
    // use the same extension set.  Stored here so makeState() can reference it.
    let editorExtensions: any[] | undefined

    // ── reactive signals from ave ─────────────────────────────────────────────
    //   lang_actions: action buttons registered by Lang ghost
    //   active_path:  path of the currently-shown doc ($state so template reacts)
    //   dock:         the active dock particle (from ave/Languinio/dock).
    //                 Text child + c.text live here. Holds bookmarks, state, Pmirrors.
    //   Text:         dock/{Text:1} — carries dige/disk_dige/disk_rev; $state so
    //                 the disk-reload effect tracks changes via Text.vers directly.
    let lang_actions: TheC[] = $state([])
    let active_path  = $state('')
    let no_doc       = $state(false)
    let dock:        TheC | undefined = $state()
    let Text:        TheC | undefined = $state()

    // Short filename for the bar header.
    let active_name = $derived(active_path ? (active_path.split('/').pop() ?? active_path) : 'no doc')

    let bookmarks: TheC[] = $derived(
        !dock ? []
            : (dock.ob({ bookmark: 1 }) as TheC[]).filter(bm => !bm.sc.graft)
    )

    // lang_model: the w:Lang model particle passed to each DocPoint for the eye tree.
    //
    // Must be read inside H.clear — reading H** (H.Awo traverses H's particle
    // tree) outside the mutex can catch H mid-mutation and return unstable state.
    // The model TheC itself is stable (created once in Lang_plan, never recreated);
    // we just need the reference. DocPoint subscribes to model.version via ob().
    let lang_model: TheC | undefined = $state()
    $effect(() => {
        void dock   // re-run once dock arrives (Lang_plan has run by then)
        H.clear(async () => {
            try {
                lang_model = H.Awo('Lang', 'Lang')?.c?.model as TheC | undefined
            } catch { lang_model = undefined }
        })
    })

    // minimap_open: toggled by the "map" button in the bar.
    // Toggle lives here so the button position doesn't move when the map opens.
    let minimap_open = $state(true)

    // expanded: makes cm-scroller take 80vh instead of the default 50vh.
    // V button in bar — same Λ/V rotation idiom as Storui's diff-panel expand.
    let expanded = $state(false)

    // ── signal $effect ────────────────────────────────────────────────────────
    //   Reads H.ave for lang_actions and active path.
    //   §3d: active dock comes from %Languinio/%dock (same-object hold), not a
    //   separate ave/active_dock signal.  languinio.ob() subscribes to its version
    //   so a dock change (Lang_set_active_dock → languinio.bump_version) wakes
    //   this effect.  The dock particle's sc.dock IS the path.
    //
    //   H.clear() gates the $state writes until beliefs has finished its current
    //   cycle — without it, mid-mutation ave flushes briefly produce path='' or
    //   dock=undefined, which tears down {#if active_path} / {#if dock} and
    //   destroys+recreates the container, spawning a fresh EditorView on each wave.
    //   Compare-before-write on path means a no-op flush never clears active_path.
    //
    //   The beliefs heartbeat wakes this $effect every cycle even with nothing
    //   on screen changing, so the trace + the hold warnings are deduped: the
    //   info line prints only when the (path, dock, active_dock) shape changes,
    //   and each "vanished mid-ave" warning fires once on the edge into a hold,
    //   not on every heartbeat — an idle editor stays silent.
    // ── Languinio $effect — dock from ave/Languinio/dock ─────────────────────
    //   Reads Languinio from ave (where it's enrolled by Lang setup).
    //   Languinio/%dock is a same-object hold on the active dock particle —
    //   Lang_set_active_dock re-points it atomically, so dock and active_dock
    //   always arrive together with no mid-flush gap.
    let _signal_seen    = ''
    $effect(() => {
        // The editor's actions live on the actions channel (H.actions — the same
        //  channel Otro renders per House), NOT under H.ave: nothing ever populated an
        //   ave/lang_actions child, so .lte-bar's <Actions> read an always-empty list
        //    and the language picker never appeared in the toolbar.  Subscribe to the
        //     channel here; the language actions are filtered out of it when settling below.
        const la        = (H.actions as TheC | undefined)
        la?.ob({ action: 1 })   // track H.actions.vers so a (de)register repaints the bar
        const languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
        languinio?.ob()   // track languinio.version
        const dock_C    = languinio?.ob({ dock: 1 })[0] as TheC | undefined
        const path      = (dock_C?.sc.dock as string | undefined) ?? ''
        const sig = `lang=${!!languinio} path=${path} dock=${!!dock_C}`
        if (sig !== _signal_seen) { console.log(`🔭 Languinio $effect: ${sig}`); _signal_seen = sig }
        const nd = !!languinio?.sc.no_doc
        H.clear(async () => {
            // Just the language actions — the lang_pick dropdown and the gen-parser
            //  button.  The rest of H.actions (bookmark/compile) already render in Otro's
            //   House row, so filtering here keeps the toolbar to the language picker.
            lang_actions = la
                ? (la.o({ action: 1 }) as TheC[]).filter(a =>
                    a.sc.role === 'lang_pick' || a.sc.role === 'gen_parser')
                : []
            if (path) active_path = path
            if (dock_C) dock = dock_C
            // no_doc is a deliberate flag (req_instrumentation stamps it for a
            //   title-page %What), not a transient flush — so no sticky guard:
            //   it follows the backend both ways.  The editor view is HIDDEN,
            //   never torn down — recreating EditorView per blank was the wave
            //   bug the sticky path|dock guards above exist to prevent.
            no_doc = nd
        })
    })

    // ── dock $effect — Text from dock ────────────────────────────────────────
    //   Runs whenever dock changes.  Extracts the Text child as a $state so
    //   the disk-reload effect can subscribe to Text.version independently.
    $effect(() => {
        const T = dock?.ob({ Text: 1 })[0] as TheC | undefined
        if (T) Text = T
    })

    // ── change strip ─────────────────────────────────────────────────────────────
    //   Reads w:Lang/{Languinio:1}/{Change:1}/{backend|storage|compile:1} written
    //   by Lang_update_change each Lang tick.  Languinio is enrolled in ave at
    //   Lang setup time, so H.ave.ob({Languinio:1})[0] is reactive.
    let _backend: TheC | undefined = $state()
    let _storage: TheC | undefined = $state()
    let _compile: TheC | undefined = $state()
    $effect(() => {
        const languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
        const change    = languinio?.ob({ Change: 1 })[0] as TheC | undefined
        _backend = change?.ob({ backend: 1 })[0] as TheC | undefined
        _storage = change?.ob({ storage: 1 })[0] as TheC | undefined
        _compile = change?.ob({ compile: 1 })[0] as TheC | undefined
    })

    // ── runner leg ─────────────────────────────────────────────────────────────
    //   The fourth leg of the change strip: what the RUNNER did with the version we
    //   pushed.  Read off w:Lies — reached the same way Liesui does, via the shared
    //   %examining particle's .c.w — so Lang need not own a ref to Lies.  Scoped to
    //   the active dock's path:
    //     run_result  — the runner's verdict for THIS dock (%ok / %errors / %dige).
    //     peers       — %channel_peer per facing runner; >1 runner is the "freak out"
    //                   case the editor should notice (a stale runner may still be live).
    //   `now` re-reads each tick (ave bumps) so a peer that stopped ponging ages out.
    let run_result: TheC | undefined = $state()
    let peers:      TheC[]           = $state([])
    let now = $state(0)
    $effect(() => {
        const ex = H.ave.ob({ examining: 1 })[0] as TheC | undefined
        const lw = ex?.c?.w as TheC | undefined
        if (lw) lw.ob()   // track w:Lies version so run_result lands live
        now = Date.now()
        run_result = lw && active_path
            ? (lw.ob({ run_result: 1, path: active_path })[0] as TheC | undefined)
            : undefined
        peers = lw ? (lw.ob({ channel_peer: 1 }) as TheC[]) : []
    })

    // runner-facing peers proven live by a recent pong (same 7s window as Liesui).
    //  The role is the VALUE of %channel_peer ({channel_peer:'runner'}, stamped by
    //   Lies_pong_recv) — there is no separate `role` key.  Reading p.sc.role never
    //    matched, so this set stayed empty and the card said "no runner has connected"
    //     even while a run_result verdict was held.  Match the value, as Liesui does.
    // liveness is max(last, last_heard): `last` is our-ping-home (rtt-bearing), last_heard is any
    //  inbound frame from the runner (Lies_pong) — so a half-open carrier (last frozen) still reads
    //   live off the runner's pings instead of falsely "no runner connected".
    let live_runners = $derived(peers.filter(p => {
        if (p.sc?.channel_peer !== 'runner') return false
        const heard = Math.max(Number(p.sc?.last ?? 0), Number(p.sc?.last_heard ?? 0))
        return heard > 0 && now - heard < 7000
    }))
    let runner_rtt   = $derived(live_runners[0]?.sc?.rtt as number | undefined)
    // >1 live runner: the editor can't tell which one's verdict is canonical.
    let runner_clash = $derived(live_runners.length > 1)

    // run_result.dige is the full dige; the compile leg shows a 5-char slice.
    let ran_dige = $derived(String(run_result?.sc?.dige ?? '').slice(0, 5))
    let ran_ok   = $derived(!!run_result?.sc?.ok)
    // pass fraction from the runner's Story verdict: done = steps run, ok_pct = fraction ok.
    //  Absent on an acquire-failure frame (which carries an errors count instead).
    let ran_done   = $derived(run_result?.sc?.done as number | undefined)
    let ran_passed = $derived(ran_done != null ? Math.round((run_result?.sc?.ok_pct as number ?? 0) * ran_done) : undefined)
    // "the runner confirmed the version we compiled" — its verdict's dige matches the
    //  compile leg.  A verdict for an OLDER dige is stale: it must NOT read as success.
    let ran_current = $derived(!!ran_dige && ran_dige === (_compile?.sc?.dige ?? ''))

    // ── runner phase, as the editor can see it ─────────────────────────────────
    //   ''        — no runner live, no verdict: leg hidden.
    //   'good'    — current verdict, green.
    //   'bad'     — current verdict, red.
    //   'working' — a runner is live but hasn't confirmed the compiled dige yet.  The
    //               editor can't yet split "awaiting src" from "running" — that needs a
    //               runner progress frame (run_phase over the channel); folded into one
    //               working phase until then.
    //   'stale'   — we hold an OLD verdict and nobody's currently running the new dige.
    let runner_phase = $derived.by(() => {
        if (run_result && ran_current) return ran_ok ? 'good' : 'bad'
        if (!!live_runners.length && !!_compile?.sc?.dige && !ran_current) return 'working'
        if (run_result) return 'stale'
        return live_runners.length ? 'working' : ''
    })


    // ── switch $effect ────────────────────────────────────────────────────────
    //   Runs whenever active_path changes.  Saves the departing EditorState
    //   (after flushing bookmarks and scroll position), then calls
    //   view.setState() with the arriving one.
    //   view.setState() is CM's documented multi-doc API — it replaces all state
    //   atomically without destroying the view or its plugins.
    //   untrack() around the save prevents dock reads from creating a dependency.
    let prev_path = ''   // plain let — not reactive; switch $effect is sole writer
    $effect(() => {
        const arriving = active_path
        if (!view || !arriving || arriving === prev_path) return
        console.log(`🔀 switch $effect: arriving=${arriving} prev=${prev_path}`)

        untrack(() => {
            // Flush any pending text push for the departing path.
            flush_push_text_now()

            if (prev_path) {
                // Flush any unsaved edits for the departing doc before
                // archiving its state — avoids losing a burst of typing
                // that hasn't hit the 3s quiet window yet.
                flush_autosave_now(prev_path)

                // Flush departing bookmark positions immediately — bypass the
                // 800ms debounce so dock always holds current positions.
                // A stale timer firing later would otherwise send the arriving
                // doc's (possibly empty) bookmark list to the wrong dock.
                flush_update_bookmarks_for_path(prev_path)

                // Snapshot full scroll state before departing.
                scrollCache.set(prev_path, view!.scrollSnapshot())

                // Save departing EditorState (history, selection, decorations).
                stateCache.set(prev_path, view!.state)
                spool_remember(prev_path, view!.state.doc.toString())
            }

            const cached = stateCache.get(arriving)
            if (cached) {
                // Restore previously-seen doc — history and decorations intact.
                view!.setState(cached)
            } else {
                // First visit: build a fresh state.
                // active_dock.c.initial_text is set by req_text_loaded reqonce
                // synchronously onto the dock particle, available the same tick
                // Languinio's dock hold arrives — always beats the Text oai.
                // dock.c.text is the fallback (set alongside the oai).
                const text = (dock?.c.initial_text as string | undefined)
                    ?? (dock?.c.text as string | undefined)
                    ?? ''
                view!.setState(EditorState.create({ doc: text, extensions: editorExtensions! }))
            }

            // Track the grammar the state we just installed actually carries, so the
            //  reconfigure $effect (which runs right after — it reads active_path too)
            //   dispatches+recompiles ONLY on a real mismatch.  A fresh state carries
            //    editorExtensions' baked grammar; a restored state carries the grammar it was
            //     reconfigured to when last live (its doc's wanted lang).  Setting this to the
            //      stale prior-dock name (the old bug) stranded a same-named doc; setting it to
            //       undefined re-applied on every open (a wasted recompile now that a language
            //        change drives one).
            last_applied_lang = cached
                ? ((dock?.sc.lang_override as string | undefined) ?? lang_for_path(arriving))
                : baked_lang_name

            // Which doc this view's live state belongs to — the alignment key
            //   the Atime graft|decoration dispatchers check (Lang_view_on)
            //   before mutating, since they would otherwise write marks into
            //   whatever doc happened to be installed (the cross-doc underline
            //   leak: Atime foregrounds a dock and grafts before this effect
            //   has swapped the state in).
            ;(view as any).lte_dock_path = arriving

            spool_remember(arriving, view!.state.doc.toString())
            prev_path = arriving

            // ── Scroll restoration ────────────────────────────────────────────
            // Dispatch the saved snapshot effect.  On first visit there is no
            // snapshot, so skip — CM will default to showing the top.
            const snap = scrollCache.get(arriving)
            if (snap) view!.dispatch({ effects: snap })

            // Re-register view+state with backend so CM events carry the right doc.
            // Pass current bookmark + graft positions so the backend can reconcile dock
            // and the Pmirror %graft children against the restored CM state.
            Lang_i_elvis(view!, 'Lang_editorBegins',
                { addBookmarkMark, removeBookmarkMark, clearAllBookmarks, saveEffect,
                  addGraftMark, removeGraftMark, clearAllGrafts,
                  setPointDecorations: setPointDecorationsEffect,
                  setPointFonts:       setPointFontsEffect,
                  seek:                (v: EditorView, from: number, to: number) => fire_seek(v, from, to),
                  foldToggle:          (v: EditorView, from: number, to: number) => fire_fold_toggle(v, from, to),
                  setPointFolds:       (v: EditorView, showing: any[], hiding: any[]) =>
                                           fire_point_folds(v, showing, hiding),
                  unfoldAllFolds:      (v: EditorView) => unfoldAll(v),
                  updates: readBookmarks(view!), graft_updates: readGrafts(view!) })
        })
    })

    // diff_to_changes — minimal CM ChangeSpec[] turning oldText into neu, so a
    //   disk-origin reload dispatches only the actual edits.  CM then maps the
    //   selection and fold ranges through them (and keeps the viewport), instead of
    //   the blunt full-document replace that would jump the cursor and drop folds.
    function diff_to_changes(oldText: string, neu: string): { from: number, to: number, insert: string }[] {
        const dmp = new diff_match_patch()
        const diffs = dmp.diff_main(oldText, neu)
        dmp.diff_cleanupSemantic(diffs)
        const changes: { from: number, to: number, insert: string }[] = []
        let pos = 0   // cursor into oldText
        for (const [op, text] of diffs as [number, string][]) {
            if (op === 0)       pos += text.length                                          // equal — skip
            else if (op === -1) { changes.push({ from: pos, to: pos + text.length, insert: '' }); pos += text.length }  // delete
            else                changes.push({ from: pos, to: pos, insert: text })          // insert
        }
        return changes
    }

    // ── disk-reload $effect ───────────────────────────────────────────────────
    //   When the active doc is reloaded from disk (dock text installed by a
    //   disk-origin write — open or external reload), push the new content into
    //   the editor.  Replacing history is acceptable here because the file
    //   changed on disk, not in the editor.
    //   Guards with active_path === prev_path to avoid firing mid-switch.
    //
    //   Text $effect (disk-reload): Text.vers fires on every oai — both user
    //   edits (dige changes) and disk writes (disk_dige + disk_rev change).
    //   disk_rev only advances on disk-origin writes so the key gates out
    //   editor echoes without needing to track dock.version at all.
    let _applied_disk_key: string | null = null   // `${path}#${disk_rev}` last applied
    $effect(() => {
        void Text?.vers   // subscribe to Text — fires on any oai
        const disk_rev = (Text?.sc.disk_rev as number | undefined) ?? 0
        const incoming = (dock?.c.text as string | undefined) ?? ''
        if (!view || !incoming) return
        if (active_path !== prev_path) return   // switch in progress
        const key = `${active_path}#${disk_rev}`
        if (key === _applied_disk_key) return   // editor echo, or already applied
        _applied_disk_key = key
        const live = view.state.doc.toString()
        if (incoming === live) return           // switch effect already set this text
        // Genuine disk change.  Apply as a MINIMAL diff (not a blunt from:0/to:end
        // replace) so CM maps the selection and fold ranges through the edits and the
        // viewport stays put — cursor, folds and scroll come back in just right for
        // the common near-identical case.  Replacing history is still fine: the file
        // changed on disk, not in the editor.  Remember so the resulting updateListener
        // push doesn't immediately come back through here as new.
        spool_remember(active_path, incoming)
        const changes = diff_to_changes(live, incoming)
        if (changes.length) view.dispatch({ changes })
    })

    // ── language reconfigure $effect ─────────────────────────────────────────
    //   Tracks active_dock.sc.lang_override (and falls back to lang_for_path on
    //   the active_path). When it differs from the last applied language,
    //   resolves the new lang() extensions and dispatches a Compartment
    //   reconfigure on the view — no remount, undo history and selection
    //   survive. last_applied_lang is set optimistically; if the async
    //   lang() resolve rejects we revert it so a retry can fire.
    $effect(() => {
        void dock?.version
        if (!view || !active_path) return
        const want = (dock?.sc.lang_override as string)
            ?? lang_for_path(active_path)
        if (want === last_applied_lang) return
        const my_view = view          // capture identity + target: a since-stale resolve
        const my_path = active_path    //  must not dispatch onto a swapped view/state
        const prev = last_applied_lang
        last_applied_lang = want
        lang(want).then(exts => {
            // Stale-resolve guard.  While lang() resolved, the view may have been rebuilt
            //  (a remount) OR the active doc may have moved on (a setState dock switch) —
            //   either way dispatching `want` now would strand the CURRENT doc on the wrong
            //    grammar (the way a .md ends up on the prior dock's stho parser).  Bail,
            //     reverting the optimistic mark only if it's still ours (the live doc's own
            //      effect run owns it otherwise), so that run re-applies off a clean slate.
            if (view !== my_view || active_path !== my_path) {
                if (last_applied_lang === want) last_applied_lang = prev
                return
            }
            if (exts.warnings?.length) {
                console.warn(`lang(${want}) warnings:`, exts.warnings)
            }
            view.dispatch({ effects: langCompartment.reconfigure(exts) })
            // The reconfigure produced a NEW immutable EditorState carrying the new parser.
            //  The compile reads its parser off dock.c.state and is a reqonce keyed on text,
            //   so without this it keeps the OLD grammar's Map (a .md stranded on stho) until
            //    a manual Esc. Fire the same path Esc does — Lang_i_elvis stamps the fresh
            //     state onto dock.c.state (Lang_dock_from_event) and e_Lang_compile recompiles
            //      against it — so the language change drives the recompile (and the minimap
            //       Map/Mapule rebuild) automatically. Guarded above to fire only on a real
            //        grammar change, so this is not a per-open double compile.
            Lang_i_elvis(view, 'Lang_compile', {})
        }).catch(err => {
            if (last_applied_lang === want) last_applied_lang = prev
            console.warn(`Langui: lang(${want}) failed:`, err)
        })
    })

    // ── slow-open overlay $effect ───────────────────────────────────────────────
    //   A dock open that lands fast needs no fanfare, but a furnish that has to read a file
    //    off Wormhole can take a beat — and the minimap's phase spinner is tiny and tucked in
    //     the corner.  So if the open hasn't completed within 0.2s, raise a big centred spinner
    //      over the editor until it lands.  Driven off the existing furnish|text_load %Languinio
    //       spinners (the open-phase indicators); a cached re-open sets neither, so an instant
    //        switch never flashes this.  Reads slow_open in the arm guard, so the timer→true edge
    //         re-runs this once and then no-ops — no re-arm loop.
    let slow_open = $state(false)
    let _open_timer: ReturnType<typeof setTimeout> | null = null
    $effect(() => {
        const languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
        languinio?.ob()   // track version: a spinner set|clear wakes this
        const opening = !!languinio?.ob({ spinner: 'furnish'   }).length
                     || !!languinio?.ob({ spinner: 'text_load' }).length
        if (!opening) {
            if (_open_timer) { clearTimeout(_open_timer); _open_timer = null }
            if (slow_open) slow_open = false
            return
        }
        if (!_open_timer && !slow_open)
            _open_timer = setTimeout(() => { _open_timer = null; slow_open = true }, 200)
    })

    // ── Lang_i_elvis ─────────────────────────────────────────────────────────
    //
    //   Central CM→backend bridge.  Stamps { dock, view, state } on every event
    //   so Lang_dock_from_event can update dock.c.view/state in one place, and
    //   handlers like e_Lang_texting know which dock they're updating.
    //   `dock` is the dock path (string); `view` and `state` carry the CM objects.
    //   state.doc (CM Text) is separate from the dock particle — `cmdoc` when
    //   disambiguating in code; `state.doc` as CM's own property name.
    function Lang_i_elvis(view, method, sc) {
        sc = { dock: active_path, view, state: view.state, ...(sc || {}) }
        H.i_elvisto('Lang/Lang', method, sc)
    }

    //#region bookmarks
    // ── bookmark StateField ──────────────────────────────────────────────
    //
    //   addBookmarkMark(v)    — install a Decoration.mark spanning v.from..v.to
    //                           carrying v.id in its spec. RangeSet.map handles
    //                           all future position remapping automatically.
    //
    //   readBookmarks(view)   — iterate the field and hand back the live
    //                           [{id, from, to}] so elvises can report the
    //                           current positions to w:Lang.

    const addBookmarkMark    = StateEffect.define<{ id: string, from: number, to: number }>()
    const removeBookmarkMark = StateEffect.define<{ id: string }>()
    const clearAllBookmarks  = StateEffect.define<null>()
    // saveEffect — dispatched externally to flush bookmark positions immediately.
    // Exported via Lang_editorBegins so e_Lang_i_alterationStation can dispatch it.
    const saveEffect = StateEffect.define<null>()

    const bookmarkField = StateField.define<DecorationSet>({
        create: () => Decoration.none,
        update(marks, tr) {
            marks = marks.map(tr.changes)   // auto-remap on every edit
            for (const e of tr.effects) {
                if (e.is(clearAllBookmarks)) {
                    marks = Decoration.none
                    continue
                }
                if (e.is(addBookmarkMark)) {
                    const deco = Decoration.mark({
                        class: 'cm-bookmark',
                        attributes: { 'data-bookmark-id': e.value.id },
                        // stashed in spec so readBookmarks can get it back out
                        bookmark_id: e.value.id,
                    } as any).range(e.value.from, e.value.to)
                    marks = marks.update({ add: [deco] })
                }
                if (e.is(removeBookmarkMark)) {
                    const target = e.value.id
                    marks = marks.update({
                        filter: (_f, _t, value) => (value.spec as any).bookmark_id !== target,
                    })
                }
            }
            return marks
        },
        provide: f => EditorView.decorations.from(f),
    })

    function readBookmarks(v: EditorView): Array<{ id: string, from: number, to: number }> {
        const out: Array<{ id: string, from: number, to: number }> = []
        const set = v.state.field(bookmarkField)
        const iter = set.iter()
        while (iter.value) {
            const id = (iter.value.spec as any).bookmark_id as string | undefined
            if (id) out.push({ id, from: iter.from, to: iter.to })
            iter.next()
        }
        return out
    }

    //#region grafts
    // ── graft StateField ─────────────────────────────────────────────────
    //
    //   Parallel to bookmarkField, but owned by Lang's Pmirror layer.  A
    //   graft mark exists for the lifetime of its Pmirror — born when
    //   LangGraft resolves a Point's spec to a def, dies when the Pmirror
    //   goes (cursor moved, Point deleted, spec renamed to no-match).
    //
    //   Why a separate field, not %sc,graft,1 on user-bookmark particles:
    //   the lifecycles are different (user bookmarks persist via Lies,
    //   grafts are session-only), the rendering is different (Pmirror set
    //   balloon vs user-bookmark capsule), and Langui's bookmark panel
    //   should never need to filter by a discriminator flag.

    const addGraftMark    = StateEffect.define<{ id: string, from: number, to: number }>()
    const removeGraftMark = StateEffect.define<{ id: string }>()
    const clearAllGrafts  = StateEffect.define<null>()

    const graftMarkField = StateField.define<DecorationSet>({
        create: () => Decoration.none,
        update(marks, tr) {
            marks = marks.map(tr.changes)
            for (const e of tr.effects) {
                if (e.is(clearAllGrafts)) {
                    marks = Decoration.none
                    continue
                }
                if (e.is(addGraftMark)) {
                    // idempotent on id — if a mark with this id already
                    // exists (paired-through Pmirror dispatching at its
                    // initial anchor), drop the old one first; the
                    // RangeSet has been remapping it to its current live
                    // position, but the new effect carries the def's
                    // resolved position, which is what we want as canon.
                    //
                    // < the more correct thing is to leave the existing
                    //   mark alone (it has the live position) and only
                    //   add if absent.  But idempotent-replace is
                    //   simpler and the dispatched position only differs
                    //   from the live one when CM has been doing edits
                    //   between graft passes — in which case the live
                    //   position is already stale relative to the def
                    //   anyway (the next compile picks it up).
                    const target = e.value.id
                    marks = marks.update({
                        filter: (_f, _t, value) => (value.spec as any).graft_id !== target,
                    })
                    // empty (from==to) or out-of-doc marks are skipped: a mark
                    //   decoration needs content to ride or it never draws and
                    //   never tracks; the Pmirror's %graft child still carries
                    //   the def's position for navigation either way.
                    if (e.value.from < e.value.to
                        && e.value.from >= 0
                        && e.value.to <= tr.state.doc.length) {
                        const deco = Decoration.mark({
                            class: 'cm-graft',
                            attributes: { 'data-graft-id': e.value.id },
                            graft_id: e.value.id,
                        } as any).range(e.value.from, e.value.to)
                        marks = marks.update({ add: [deco] })
                    }
                }
                if (e.is(removeGraftMark)) {
                    const target = e.value.id
                    marks = marks.update({
                        filter: (_f, _t, value) => (value.spec as any).graft_id !== target,
                    })
                }
            }
            return marks
        },
        provide: f => EditorView.decorations.from(f),
    })

    function readGrafts(v: EditorView): Array<{ id: string, from: number, to: number }> {
        const out: Array<{ id: string, from: number, to: number }> = []
        const set = v.state.field(graftMarkField)
        const iter = set.iter()
        while (iter.value) {
            const id = (iter.value.spec as any).graft_id as string | undefined
            if (id) out.push({ id, from: iter.from, to: iter.to })
            iter.next()
        }
        return out
    }

    function fire_update_grafts(v: EditorView) {
        const updates = readGrafts(v)
        if (updates.length) Lang_i_elvis(v, 'Lang_update_grafts', { updates })
    }
    //#endregion
    
    // ── pointDecorationField — Point glow|enlarge decorations ────────────────
    //
    //   Holds a DecorationSet of Decoration.line() instances, one per showing
    //   Point.  The class on each line drives font-size enlarge and the lavender
    //   glow via static CSS (see bottom of this file).  A full-replace StateEffect
    //   keeps the set atomic — no partial adds.  Remaps on every doc change so
    //   line positions track edits.
    //
    //   Lang_show_pmirrors drives this via dock.c.setPointDecorations (see
    //   e_Lang_editorBegins wiring below).  The effect carries the full current
    //   set; no per-line add/remove book-keeping.

    const setPointDecorationsEffect = StateEffect.define<
        Array<{ id: string, from: number, to: number, cls: string }>
    >()

    const pointDecorationField = StateField.define<DecorationSet>({
        create: () => Decoration.none,
        update(decos, tr) {
            decos = decos.map(tr.changes)
            for (const e of tr.effects) {
                if (!e.is(setPointDecorationsEffect)) continue
                const len   = tr.state.doc.length
                const marks: Array<ReturnType<typeof Decoration.line>> = []
                const lined = new Set<number>()
                for (const { from, cls } of e.value) {
                    // Skip offsets outside the live doc rather than letting
                    // lineAt() throw — a throw inside a StateField update fails
                    // the WHOLE transaction, so one stale Point would both keep
                    // the previous decoration set painted and block every other
                    // Point from decorating.  Skipping degrades just the one.
                    if (typeof from !== 'number' || from < 0 || from > len) continue
                    // Decoration.line() needs a line-start offset.
                    const line = tr.state.doc.lineAt(from)
                    // one decoration pair per line — RangeSet tolerates equal
                    // positions but stacking classes double-applies the enlarge.
                    // < merge classes when two Points share a line (focus wins?)
                    if (lined.has(line.from)) continue
                    lined.add(line.from)
                    // The line decoration carries the GLOW only (whole-line box-shadow).
                    marks.push(Decoration.line({
                        class: `cm-point-engaged${cls ? ` cm-point-${cls}` : ''}`,
                    }).range(line.from))
                    // The font ENLARGE rides a mark over the content AFTER the indent,
                    // so the leading whitespace stays body-size and the name keeps the
                    // same indent column as the lines around it — a whole-line font-size
                    // would swell the indent too and lift the line off the grid (hover).
                    const indent       = line.text.length - line.text.trimStart().length
                    const content_from = line.from + indent
                    if (content_from < line.to) {
                        marks.push(Decoration.mark({
                            class: `cm-point-text${cls ? ` cm-point-text-${cls}` : ''}`,
                        }).range(content_from, line.to))
                    }
                }
                // line decos and content marks share one set — sort by position, then
                // startSide so a line decoration sorts before a mark at the same offset
                // (a header with no indent), as RangeSet requires.
                marks.sort((a, b) => a.from - b.from || a.value.startSide - b.value.startSide)
                decos = Decoration.set(marks, true)
            }
            return decos
        },
        provide: f => EditorView.decorations.from(f),
    })

    // ── pointFontField — per-token font-size so surviving names grow ──────────
    //
    //   The Q climb shrinks the whole contentDOM as bodies fold away|this field
    //   pushes back on the names that survive: a folded method's name and a
    //   //#region title get an absolute px font-size that overrides the inherited
    //   shrink, so the more we fold the more the overview's headings stand out.
    //   Mark-decorations over the name SPAN only — not the whole line — so the
    //   leading indent, an async|static keyword and the arg list stay body-size and
    //   just the identifier swells.  Same full-replace-effect + remap shape as
    //   pointDecorationField, and LangPoint drives it through dock.c.setPointFonts in
    //   the same dispatch as its folds, so font and fold land in one transaction.
    //     px is absolute (not em) on purpose — em would inherit the body shrink and
    //     cancel the emphasis|absolute px is measured from the dock's cached base.

    const setPointFontsEffect = StateEffect.define<
        Array<{ from: number, to: number, px: number }>
    >()

    const pointFontField = StateField.define<DecorationSet>({
        create: () => Decoration.none,
        update(decos, tr) {
            decos = decos.map(tr.changes)
            for (const e of tr.effects) {
                if (!e.is(setPointFontsEffect)) continue
                const len   = tr.state.doc.length
                const marks: ReturnType<typeof Decoration.mark>[] = []
                const placed = new Set<number>()
                for (const { from, to, px } of e.value) {
                    // Skip stale|empty spans rather than letting the RangeSet throw —
                    // a throw here fails the whole transaction, see pointDecorationField.
                    if (typeof from !== 'number' || typeof to !== 'number') continue
                    if (from < 0 || to > len || from >= to) continue
                    if (placed.has(from)) continue
                    placed.add(from)
                    const deco = Decoration.mark({
                        attributes: { style: `font-size:${px.toFixed(2)}px` },
                    })
                    marks.push(deco.range(from, to))
                }
                marks.sort((a, b) => a.from - b.from || a.to - b.to)
                decos = Decoration.set(marks, true)
            }
            return decos
        },
        provide: f => EditorView.decorations.from(f),
    })

    // ── Fold markers — marked region folds vs invisible Q|Point folds ──────────
    //
    //   Two kinds of fold share CM's one fold state:
    //     • MARKED folds — a region body the user folded from the minimap.  Folded,
    //       they show a clickable ↤Nlines↦ placeholder; unfolded, a small green ↦
    //       sits where the marker was, to fold it up again.
    //     • INVISIBLE folds — the Q climb's body folds and the Point unshowing folds.
    //       They're driven by the dial|the Points, not clicked, so they show only a
    //       faint stub and carry no re-fold handle — the overview (shrunk bodies,
    //       grown names) is the signal, not a row of "…".
    //   What tells them apart is markedRegions: a region enters it the first time it's
    //   foldToggled, and stays (mapped through edits) so its identity as markable
    //   survives fold|unfold.  Nothing else is marked, so everything else is invisible.

    const markFoldEffect = StateEffect.define<{ from: number, to: number }>()

    // markedRegions: from → to for every region the user has foldToggled.  A plain
    //   remapped map (a RangeSet would do, but the from→to lookup the placeholder and
    //   the handle both want is one step here).  mapPos with bias keeps a marked span
    //   anchored as text around it changes|a span that collapses to nothing is dropped.
    const markedRegions = StateField.define<Map<number, number>>({
        create: () => new Map(),
        update(marks, tr) {
            let next = marks
            if (tr.docChanged) {
                next = new Map()
                for (const [from, to] of marks) {
                    const f = tr.changes.mapPos(from, 1)
                    const t = tr.changes.mapPos(to, -1)
                    if (f < t) next.set(f, t)
                }
            }
            for (const e of tr.effects) {
                if (!e.is(markFoldEffect)) continue
                if (next === marks) next = new Map(marks)
                next.set(e.value.from, e.value.to)
            }
            return next
        },
    })

    // line count a folded range hides — header line through the last body line.
    const folded_lines = (state: EditorState, from: number, to: number) =>
        state.doc.lineAt(to).number - state.doc.lineAt(from).number

    // codeFolding with our placeholder.  One type of fold: every folded range shows
    //   the same ↤Nlines↦ count arrows (no marked|invisible split).  This shares
    //   basicSetup's fold state (same singleton field) and only supplies the
    //   placeholder — combineConfig takes the first DEFINED placeholderDOM, which is
    //   ours (basicSetup's codeFolding leaves it null).
    const foldMarkers = codeFolding({
        preparePlaceholder: (state, range) => ({
            lines: folded_lines(state, range.from, range.to),
        }),
        placeholderDOM: (view, onclick, prepared: { lines: number }) => {
            const el = document.createElement('span')
            el.className = 'cm-fold-marked'
            el.textContent = `↤${prepared.lines}↦`
            el.title = `unfold ${prepared.lines} lines`
            el.onclick = onclick               // CM's unfold handler
            return el
        },
    })

    // ── re-fold handle ────────────────────────────────────────────────────────
    //   For every marked region that is currently UNFOLDED, a small green ↦ at the
    //   end of its header line that folds it back up.  This is the affordance that
    //   sits "where the fold marker was" once you've opened a region|CM leaves nothing
    //   behind on unfold, so it's a widget we place ourselves.
    class RefoldWidget extends WidgetType {
        from: number
        to:   number
        constructor(from: number, to: number) { super(); this.from = from; this.to = to }
        eq(o: RefoldWidget) { return o.from === this.from && o.to === this.to }
        toDOM(view: EditorView) {
            const b = document.createElement('span')
            b.className = 'cm-refold-handle'
            b.textContent = '↦'
            b.title = 'fold this region'
            b.onmousedown = (e) => {
                e.preventDefault()             // keep the editor selection put
                view.dispatch({ effects: [
                    foldEffect.of({ from: this.from, to: this.to }),
                    markFoldEffect.of({ from: this.from, to: this.to }),
                ] })
            }
            return b
        }
        ignoreEvent() { return false }
    }

    const refoldHandles = ViewPlugin.fromClass(class {
        decorations: DecorationSet
        constructor(view: EditorView) { this.decorations = this.build(view) }
        update(u: ViewUpdate) {
            // fold state changes arrive as transactions|cheap to rebuild on any change
            if (u.docChanged || u.viewportChanged || u.transactions.length)
                this.decorations = this.build(u.view)
        }
        build(view: EditorView): DecorationSet {
            const marks = view.state.field(markedRegions, false)
            if (!marks || !marks.size) return Decoration.none
            const folds = foldedRanges(view.state)
            const out: Array<ReturnType<typeof Decoration.widget>> = []
            for (const [from, to] of marks) {
                if (from < 0 || to > view.state.doc.length || from >= to) continue
                // skip if this region is currently folded (the ↤N↦ placeholder shows)
                let folded = false
                folds.between(from, from, () => { folded = true })
                if (folded) continue
                out.push(Decoration.widget({
                    widget: new RefoldWidget(from, to),
                    side: 1,                       // after the header-line content
                }).range(from))
            }
            out.sort((a, b) => a.from - b.from)
            return Decoration.set(out, true)
        }
    }, { decorations: v => v.decorations })

    // ── pointFoldsField — fold/unfold dispatch for unshowing Points ───────────
    //
    //   When Lang_show_pmirrors finds an unshowing Pmirror it puts it in the folds
    //   list; showing Pmirrors go to decos.  On each Lang_show_pmirrors call we:
    //     1. Unfold everything in the decos list (they should be visible).
    //     2. Fold the ranges in the folds list via foldEffect.
    //
    //   There is no actual StateField here — fold state lives inside CM's own
    //   fold extension (part of basicSetup).  We just dispatch foldEffect /
    //   unfoldEffect to set the per-range fold state.  dock.c.setPointFolds
    //   is a plain function so Lang_show_pmirrors can call it without importing CM.
    //   These are INVISIBLE folds (never entered into markedRegions).

    // ── fire_fold_toggle — toggle one fold range (a region body) ──────────────
    //
    //   Provided as dock.c.foldToggle so a Mapule.c.fold() can fold|unfold a region
    //   without importing CM.  Folded already (a fold starts at from) → unfold, else
    //   fold.  Body-only: the caller passes [end of header line, end of body], so the
    //   header stays visible — same shape as the Point folds.  Either way the range is
    //   entered into markedRegions, so it reads as a MARKED fold (↤N↦ + ↦ handle).
    function fire_fold_toggle(v: EditorView, from: number, to: number) {
        if (from >= to) return
        let folded = false
        const cursor = foldedRanges(v.state).iter()
        while (cursor.value !== null) { if (cursor.from === from) { folded = true; break } cursor.next() }
        v.dispatch({ effects: [
            folded ? unfoldEffect.of({ from, to }) : foldEffect.of({ from, to }),
            markFoldEffect.of({ from, to }),
        ] })
    }

    // ── fold_q — Ctrl+Q: toggle the block at the cursor ────────────────────────
    //
    //   Folds the innermost indent-block the cursor sits in; Ctrl+Q again unfolds it.
    //   A tiny innermost block (under ~6 lines) is skipped for its enclosing block, so
    //   a one-liner method folds its whole region — but it stays a toggle, not a climb:
    //   the second press unfolds what the first folded.
    //   Routes through fire_fold_toggle, so the fold is marked: an opened fold keeps
    //   its ↦ handle and folds up again, same as any other.
    function fold_q(v: EditorView): boolean {
        const doc = v.state.doc
        const cursorLine = doc.lineAt(v.state.selection.main.head).number
        const indent_of = (n: number): number => {
            const t = doc.line(n).text
            if (!t.trim()) return -1
            return t.match(/^[\t ]*/)![0].replace(/\t/g, '    ').length
        }
        const body_end = (h: number, ind: number): number => {
            let end = h
            for (let n = h + 1; n <= doc.lines; n++) {
                const i2 = indent_of(n)
                if (i2 < 0) continue
                if (i2 > ind) end = n
                else break
            }
            return end
        }
        // enclosing blocks, innermost first
        const chain: Array<{ h: number, end: number }> = []
        const cind = indent_of(cursorLine)
        if (cind >= 0) {
            const end = body_end(cursorLine, cind)        // cursor line itself heads a block?
            if (end > cursorLine) chain.push({ h: cursorLine, end })
        }
        let baseLine = cursorLine
        while (baseLine >= 1 && indent_of(baseLine) < 0) baseLine--
        let need = baseLine >= 1 ? indent_of(baseLine) : 0
        for (let h = baseLine - 1; h >= 1; h--) {
            const ind = indent_of(h)
            if (ind < 0) continue
            if (ind < need) {
                chain.push({ h, end: body_end(h, ind) })
                need = ind
                if (ind === 0) break
            }
        }
        if (!chain.length) return false

        // Toggle the innermost block at the cursor: fold it, Ctrl+Q again unfolds it
        // (fire_fold_toggle flips on the fold-start).  But a tiny innermost block (under
        // ~6 lines — a one- or two-line method) isn't worth folding on its own, so we go
        // up to the enclosing block instead.  Once that block is folded, the cursor sits
        // on its header (no longer inside the tiny child), so the next Ctrl+Q toggles it
        // straight back open.
        const FOLD_UP_UNDER = 6
        let target = chain[0]
        if (chain[1] && (target.end - target.h + 1) < FOLD_UP_UNDER) target = chain[1]
        const from = doc.line(target.h).to
        const to   = doc.line(target.end).to
        if (from >= to) return false
        fire_fold_toggle(v, from, to)
        return true
    }

    // ── copy_clean — copy/cut the document text, never the fold markers ────────
    //
    //   A folded range copies as its full underlying text (folding is display-only),
    //   and the ↤N↦ / ↦ marker widgets aren't document text — so slicing the doc for
    //   the selection yields clean code with no markers.  Done explicitly here so it's
    //   guaranteed regardless of any browser-native copy path.  Single-range only;
    //   multi-cursor and empty selections fall back to CM's default.
    //   < a copy that spans a fold expands it silently for now — when the warnings
    //     surface lands, fire one here offering to copy the collapsed form instead.
    function copy_clean(event: ClipboardEvent, v: EditorView, is_cut: boolean): boolean {
        const ranges = v.state.selection.ranges
        if (ranges.length !== 1 || ranges[0].empty) return false
        const { from, to } = ranges[0]
        event.clipboardData?.setData('text/plain', v.state.sliceDoc(from, to))
        event.preventDefault()
        if (is_cut) v.dispatch({ changes: { from, to }, selection: { anchor: from } })
        return true
    }

    // ── fire_seek — look at a span: unfold what hides it, select + centre it ───
    //
    //   Provided to the dock as dock.c.seek so Mapule.c.goto (and any other nav)
    //   can navigate without importing CM.  At a high Q the target's body is folded
    //   and an outer block may fold over it too|we open both in the same transaction
    //   as the scroll, so the goto lands on real code, not a fold placeholder, and
    //   the scroll measures against the unfolded geometry.
    function fire_seek(v: EditorView, from: number, to: number) {
        const doc = v.state.doc
        if (from < 0 || to > doc.length) return
        const line  = doc.lineAt(from)
        const opens: Array<{ from: number, to: number }> = []
        foldedRanges(v.state).between(0, doc.length, (f, t) => {
            // a fold starting on the target's header line is the target's own body|
            // a fold spanning the target is an ancestor hiding it — open either.
            if ((f >= line.from && f <= line.to) || (f <= from && t >= from))
                opens.push({ from: f, to: t })
        })
        // For a big target (its indent-block runs > 8 lines), don't just centre the
        //  header — scroll it ~a quarter down so the body fills the view below it.
        //  Small targets centre as before.
        const span   = block_lines(doc, line.number)
        const scroll = span > 8
            ? EditorView.scrollIntoView(from, { y: 'start', yMargin: Math.round(v.scrollDOM.clientHeight * 0.25) })
            : EditorView.scrollIntoView(from, { y: 'center' })
        v.dispatch({
            selection: { anchor: from, head: to },
            effects: [ ...opens.map(r => unfoldEffect.of(r)), scroll ],
        })
        v.focus()
        bloom_at(v, from)
    }

    // Line-count of the indent block headed by startLine (header + deeper-indented body
    //  until indentation returns to the header's level).  Cheap; used to decide how to
    //  scroll a goto target.  Regions (not indentation-nested) read as ~1 and centre —
    //  < a region's true body extent would need Lang_build_regions.
    function block_lines(doc: import('@codemirror/state').Text, startLine: number): number {
        const indent_of = (n: number): number => {
            const t = doc.line(n).text
            if (!t.trim()) return -1
            return t.match(/^[\t ]*/)![0].replace(/\t/g, '    ').length
        }
        const base = indent_of(startLine)
        if (base < 0) return 1
        let end = startLine
        for (let n = startLine + 1; n <= doc.lines; n++) {
            const ind = indent_of(n)
            if (ind < 0) continue          // blank — belongs to whatever encloses it
            if (ind > base) end = n         // deeper → inside the block
            else break                      // back to base or shallower → block ended
        }
        return end - startLine + 1
    }

    // A glowing bloom at the goto target, over the line-number gutter — measure the
    //  target's screen y AFTER the scroll lands (requestMeasure read runs post-layout),
    //  drop a fixed overlay across the gutter there, and let CSS bloom + fade it over
    //  ~1s before removing.  Pure overlay, no CM decoration to churn.
    function bloom_at(v: EditorView, pos: number) {
        // Measure AFTER the scrollIntoView lands.  A requestMeasure read can run in the
        //  same cycle as the scroll → pre-goto coords (the line hasn't moved yet); two
        //  rAFs put us past the new scroll's paint, so coordsAtPos is the real spot.
        const place = () => {
            const c = v.coordsAtPos(pos)
            const g = (v.dom.querySelector('.cm-gutters') as HTMLElement | null)?.getBoundingClientRect()
            if (!c || !g) return
            const lh = Math.max(14, c.bottom - c.top)
            const el = document.createElement('div')
            el.className = 'cm-goto-bloom'
            el.style.left   = `${g.left}px`
            el.style.width  = `${Math.max(20, g.width)}px`
            el.style.top    = `${c.top - lh}px`     // one line above → centred, ~3× tall
            el.style.height = `${lh * 3}px`
            document.body.appendChild(el)
            setTimeout(() => el.remove(), 1000)
        }
        requestAnimationFrame(() => requestAnimationFrame(place))
    }

    // ── fire_point_folds — dispatch fold|unfold for the full Point set ────────
    //
    //   Called by Lang_show_pmirrors via dock.c.setPointFolds.
    //   showing_ranges — from|to of Points that should be visible (unfold their line).
    //   hiding_ranges  — from|to of Points whose region body should be folded.
    //   Uses foldEffect|unfoldEffect on the line range: from = end of method header
    //   line, to = end of the function body (Pmirror graft.to).  If the graft range
    //   is a single line (short method), folding is a no-op — foldEffect ignores
    //   single-line ranges, which is the right behaviour.
    function fire_point_folds(
        v: EditorView,
        showing: Array<{ id: string, from: number, to: number }>,
        hiding:  Array<{ id: string, from: number, to: number }>,
    ) {
        // skip degenerate and out-of-doc ranges — a stale graft offset past the
        //   doc end must degrade to "that one Point doesn't fold", never to a
        //   failed dispatch that drops every other Point's fold state with it.
        const len = v.state.doc.length
        const ok  = (from: number, to: number) =>
            typeof from === 'number' && typeof to === 'number'
            && from >= 0 && from < to && to <= len
        const effects: ReturnType<typeof foldEffect.of | typeof unfoldEffect.of>[] = []
        for (const { from, to } of showing) {
            if (!ok(from, to)) continue
            effects.push(unfoldEffect.of({ from, to }))
        }
        for (const { from, to } of hiding) {
            if (!ok(from, to)) continue
            effects.push(foldEffect.of({ from, to }))
        }
        if (effects.length) {
            // Anchor the focus across these folds — they land from a background Point/
            //  graft settle while you're reading or navigating, so unanchored they shift
            //  the doc height above you and bump the view off what you're looking at.
            const keep = (H as any).Lang_keep_focal as
                ((view: EditorView, fn: () => void) => void) | undefined
            if (keep) keep.call(H, v, () => v.dispatch({ effects }))
            else v.dispatch({ effects })
        }
    }

    //#endregion graft / point decorations

    // ── fire_update_bookmarks ────────────────────────────────────────────────
    // Core send: read live bookmark positions from CM and elvis them to the backend.
    // Called directly for an instant flush (saveEffect path) or via the debounce wrapper.
    function fire_update_bookmarks(v: EditorView) {
        const updates = readBookmarks(v)
        Lang_i_elvis(v, 'Lang_update_bookmarks', { updates })
    }

    // ── debounced doc-change → Lang_update_bookmarks ─────────────────────────
    // Arms a timer so rapid keystrokes coalesce. saveEffect cancels it and calls
    // fire_update_bookmarks() directly so the fresh editorState reaches the backend
    // without delay.
    function schedule_update_bookmarks(v: EditorView) {
        if (update_timer) clearTimeout(update_timer)
        update_timer = setTimeout(() => {
            update_timer = null
            if (!view) return
            fire_update_bookmarks(view)
            fire_update_grafts(view)
        }, UPDATE_DELAY_MS)
    }


    //#region editor

    const autoIndent = indentService.of((context, pos) => {
        const prevLine = context.lineAt(pos, -1)
        const match = prevLine.text.match(/^(\s*)/)
        const baseIndent = match ? match[1].length : 0
        // Increase indent after lines ending with { or :
        const trimmed = prevLine.text.trimEnd()
        const extra = /[{:]$/.test(trimmed) ? 4 : 0
        return baseIndent + extra
    })
    let usualSetup = [EditorView.lineWrapping, indentUnit.of("    "), autoIndent,
        drawSelection(),
        ];
    let Keys = keymap.of([
        // makes this element inescapable by Tab to keyboard navigators
        //  the Esc,Tab is supposed to work around that, but
        indentWithTab,
        //   we bind Escape preventing the above from working
        // Esc to compile and run
        {
            key: "Escape",
            run: () => {
                // Flush any pending keystroke push before compiling so the
                // compiler always sees the editor's current text, not a
                // stale snapshot from 2s ago.
                flush_push_text_now()
                // Esc is "push everything" — save immediately, don't wait for
                // the autosave quiet/active thresholds.
                flush_autosave_now(active_path)
                Lang_i_elvis(view,'Lang_compile', {})
                // Esc also means "I'm keen to run it now" — arm a run beside the
                //  compile.  In the editor this emits the go-run signal toward the
                //   runner (the Pantheate split: the editor compiles, never runs);
                //    Lies_run_arm fills in the in-place/from-start mode preference.
                Lang_i_elvis(view,'Lang_run_now', {})
                return true;
            },
        },
        // ── Ctrl+B: add bookmark at current selection ────────────────────────
        //
        //   Empty selection → expand to the enclosing line, so single-click
        //   bookmarking gives something non-zero-width for whatsthis() to scope
        //   over.  Non-empty selection is used verbatim.
        {
        key: 'Mod-b',
        run: (view) => {
            const sel = view.state.selection.main;
            let from = sel.from, to = sel.to;
            const label = view.state.doc.sliceString(from, to).slice(0, 24).replace(/\s+/g, ' ');
            Lang_i_elvis(view,'Lang_add_bookmark', {
                from,
                to,
                label,
                view,
                state: view.state,
            });
            return true;
        },
    },
        // ── Ctrl+Q: toggle the fold of the innermost block at the cursor (again to
        //   unfold).  Ctrl (not Mod) so Mac's Cmd-Q quit isn't shadowed.
        {
        key: 'Ctrl-q',
        preventDefault: true,
        run: (view) => fold_q(view),
    }])

    // ── EditorView construction ──────────────────────────────────────────────
    //
    //   Deferred until container is bound, which only happens after {#if dock}
    //   becomes true (first dock particle arrived in ave).
    //
    //   editorExtensions is extracted and stored so every subsequent EditorState
    //   created by the switch $effect shares the identical extension set — CM
    //   requires this for view.setState() to work correctly.
    //
    //   After construction the switch $effect fires immediately (active_path is
    //   already set) and calls Lang_editorBegins to register the view with backend.
    //
    //   `view` is $state (so child components see its assignment), but reading
    //   it here would make this effect depend on itself.  untrack() around
    //   the read keeps the only reactive dep on `container` and `dock`.
    // ── ResizeObserver for late layout settling ──────────────────────────────
    //   See construction $effect for context.  Stored at module scope so
    //   onDestroy can disconnect it.
    let container_ro: ResizeObserver | undefined

    // ── construction lock ────────────────────────────────────────────────────
    //   Plain let — not $state, so the construction $effect never re-runs
    //   because this flips.  Guards against scheduling a second setTimeout while
    //   the first is still in flight, which happens because await lang(...) inside
    //   the async body suspends for tens of ms — long enough for a reactive change
    //   (active_path re-read, dock re-set) to re-fire the effect and see view===undefined.
    let constructing = false

    // ── build_editor ─────────────────────────────────────────────────────────
    //   The async body of EditorView construction, extracted from the setTimeout
    //   so the setTimeout itself is a small, easy-to-read wrapper and the lock
    //   placement is obvious.  Assumes captured_container.isConnected is already
    //   verified.  Sets view, prev_path, stateCache, fires editorBegins.
    async function build_editor(
        captured_container: HTMLDivElement,
        captured_path:      string,
        captured_dock:      TheC | undefined
    ) {
        // Read dock fresh — text may have arrived during the setTimeout delay.
        // Prefer active_dock.c.initial_text (set synchronously by req_text_loaded
        // reqonce onto the dock particle — arrives with Languinio before the oai).
        const initial    = (dock?.c.initial_text as string | undefined)
            ?? (dock?.c.text as string)
            ?? (captured_dock?.c.text as string)
            ?? ''

        // Pick the initial language by extension. The per-doc override (if
        // any) is applied a moment later by the reconfigure $effect once it
        // sees active_dock.sc.lang_override.
        const initial_lang_name = lang_for_path(captured_path)
        const initial_lang_exts = await lang(initial_lang_name)
        if (initial_lang_exts.warnings?.length) {
            console.warn(`lang(${initial_lang_name}) warnings:`, initial_lang_exts.warnings)
        }

        // Build extensions once; reused by all EditorStates on this view.
        editorExtensions = [
            basicSetup,
            simpleLezerLinter(),
            langCompartment.of(initial_lang_exts),
            bookmarkField,
            graftMarkField,
            pointDecorationField,
            pointFontField,
            markedRegions,
            foldMarkers,
            refoldHandles,
            EditorView.domEventHandlers({
                copy: (e, v) => copy_clean(e, v, false),
                cut:  (e, v) => copy_clean(e, v, true),
            }),
            Keys,
            EditorView.updateListener.of((v: ViewUpdate) => {
                const sel = v.state.selection.main
                sel_from = sel.from
                sel_to   = sel.to
                // where-you-look tap: when the cursor lands on a new line, fire the
                //  lightest tap (weight 1) at it after a short settle, so the Ting
                //  accumulates where attention actually goes — line-gated + debounced so
                //  typing within a line doesn't flood it.
                if (v.selectionSet || v.docChanged) {
                    const line = v.state.doc.lineAt(sel.head).number
                    if (line !== _tap_line) {
                        _tap_line = line
                        const head = sel.head
                        if (_tap_timer)   clearTimeout(_tap_timer)
                        if (_dwell_timer) clearTimeout(_dwell_timer)
                        // look: a light tap once the cursor settles on the line.
                        _tap_timer = setTimeout(() => {
                            if (view) Lang_i_elvis(view, 'Lang_tap', { from: head, long: false, weight: 1 })
                        }, 500)
                        // dwell: linger and it becomes a HELD tap — counts toward the
                        //  globule's held share, warming its bar amber→pink, and carries
                        //  the line as articulation (e_Lang_tap reads `say` on a long tap).
                        _dwell_timer = setTimeout(() => {
                            if (view) Lang_i_elvis(view, 'Lang_tap', { from: head, long: true, weight: 3 })
                        }, 2500)
                    }
                }
                // saveEffect: flush bookmark positions immediately, cancel debounce
                if (v.transactions.some(tr => tr.effects.some(e => e.is(saveEffect)))) {
                    if (update_timer) { clearTimeout(update_timer); update_timer = null }
                    fire_update_bookmarks(v.view)
                    fire_update_grafts(v.view)
                    return
                }
                if (!v.docChanged) return
                _autosave_last_input_ts = Date.now()
                const text = v.state.doc.toString()
                // Spool first, then schedule the throttled push.  Spooling
                // synchronously means even if the elvis queue gets way behind,
                // by the time stale snapshots bubble back through e_Lang_texting
                // and the disk-reload $effect, they're recognised as echoes.
                spool_remember(active_path, text)
                schedule_push_text(active_path)
                schedule_update_bookmarks(v.view)
            }),
            usualSetup,
        ]

        view = new EditorView({
            parent: captured_container,
            state: EditorState.create({ doc: initial, extensions: editorExtensions }),
        })
        // the scroller wears the global .scrollbig look (app.css); Langui keeps only
        //  the gutter-width override so the minimap stays in lockstep with the bar.
        view.scrollDOM.classList.add('scrollbig')
        // alignment key for Atime dispatchers — see the switch $effect's stamp.
        ;(view as any).lte_dock_path = captured_path
        last_applied_lang = initial_lang_name
        baked_lang_name   = initial_lang_name   // the grammar editorExtensions baked in
        console.log(`🏗 EditorView created: dom.clientHeight=${view.dom.clientHeight} scrollDOM.clientHeight=${view.scrollDOM.clientHeight}`)

        // Seed the spool with the initial text so the very first echo
        // (e_Lang_texting bumping dock after our first keystroke) is
        // recognised cleanly even before any local edits land.
        spool_remember(captured_path, initial)

        container_ro = new ResizeObserver(() => {
            // < CM re-measures on late layout settling (fonts, flex, minimap toggle)
            view?.requestMeasure()
        })
        container_ro.observe(captured_container)

        // Cache this first state so the switch $effect doesn't create a duplicate
        // fresh state the first time active_path is seen.
        if (captured_path) stateCache.set(captured_path, view.state)
        prev_path = captured_path

        // Arm the auto-save interval — checks every 500ms, fires when
        // quiet or overdue.  Cleared in onDestroy.
        if (!_autosave_interval)
            _autosave_interval = setInterval(check_autosave, 500)

        // Register view+state with backend.
        // Pass current bookmark + graft positions for initial sync (normally
        // empty on first construction, but included for consistency).
        Lang_i_elvis(view, 'Lang_editorBegins',
            { addBookmarkMark, removeBookmarkMark, clearAllBookmarks, saveEffect,
              addGraftMark, removeGraftMark, clearAllGrafts,
              setPointDecorations: setPointDecorationsEffect,
              setPointFonts:       setPointFontsEffect,
              seek:                (v: EditorView, from: number, to: number) => fire_seek(v, from, to),
              foldToggle:          (v: EditorView, from: number, to: number) => fire_fold_toggle(v, from, to),
              setPointFolds:       (v: EditorView, showing: any[], hiding: any[]) =>
                                       fire_point_folds(v, showing, hiding),
              unfoldAllFolds:      (v: EditorView) => unfoldAll(v),
              updates: readBookmarks(view), graft_updates: readGrafts(view) })
    }

    $effect(() => {
        if (!container || !active_path) return
        // view set === already built; constructing === a build is mid-flight.
        // Both are plain (non-$state) reads via untrack so this never self-wakes.
        if (untrack(() => view) || constructing) return
        constructing = true

        // Capture now — by the time the setTimeout fires the reactive reads may
        // have moved on, and we want the values that gated this build.
        const captured_container = container
        const captured_path      = active_path
        const captured_dock      = dock

        // Defer one task so the browser has done a layout pass after {#if dock} flips.
        // The $effect fires in the same microtask as the DOM insertion — the container
        // exists but has zero clientHeight, so CM measures 0 and stops painting.
        setTimeout(async () => {
            if (captured_container.isConnected)
                await build_editor(captured_container, captured_path, captured_dock)
            constructing = false
        }, 0)
    })

    onDestroy(() => {
        if (update_timer)       clearTimeout(update_timer)
        if (push_quiet_timer)   clearTimeout(push_quiet_timer)
        if (push_active_timer)  clearTimeout(push_active_timer)
        if (_autosave_interval) clearInterval(_autosave_interval)
        container_ro?.disconnect()
        view?.destroy()
    })
</script>
{#if active_path}
<div class="lte" class:lte-expanded={expanded}>
    {#if dock}
    <div class="lte-bar">
        <!-- doc-picker dropdown + any other Lang actions (compo/compi toggles etc) -->
        <Actions N={lang_actions} />
        <span class="lte-doc" title={active_path}>{active_name}</span>
        {#if _backend?.sc.dige}
        <span class="lte-change"
              title="version flow: editor → disk → compiled → runner">
            <span class="lte-ch-leg lte-ch-editor" title="editor text">{_backend.sc.dige}</span>
            {#if _storage?.sc.dige}
                <span class="lte-ch-arrow" class:lte-ch-dim={_storage.sc.dim}>→</span>
                <span class="lte-ch-leg lte-ch-disk" class:lte-ch-dim={_storage.sc.dim}
                      title={_storage.sc.dim ? 'on disk — behind the editor (unsaved edits)' : 'on disk — grounded'}>{_storage.sc.dige}</span>
            {/if}
            {#if _compile?.sc.dige}
                <span class="lte-ch-arrow" class:lte-ch-dim={_compile.sc.dim}>→</span>
                <span class="lte-ch-leg lte-ch-compile" class:lte-ch-dim={_compile.sc.dim} class:lte-ch-busy={_compile.sc.pending}
                      title={_compile.sc.pending ? 'compiling…' : 'compiled'}>{_compile.sc.dige}</span>
                {#if _compile.sc.secs}
                    <span class="lte-ch-secs">{_compile.sc.secs}s</span>
                {/if}
            {/if}
            <!-- runner leg — phase of whoever ran what we compiled.  Hidden until a verdict
                 lands or a runner is live; a stale verdict (older dige) reads grey, never green. -->
            {#if runner_phase}
                <span class="lte-ch-arrow" class:lte-ch-dim={runner_phase !== 'good' && runner_phase !== 'bad'}>→</span>
                <span class="lte-ch-runner lte-run-{runner_phase}"
                      title={runner_phase === 'good' ? `runner ran ${ran_dige} — green${runner_rtt != null ? ` · ${runner_rtt}ms` : ''}`
                          : runner_phase === 'bad' ? `runner ran ${ran_dige} — red (${ran_done != null ? `${ran_passed}/${ran_done} steps ok` : `${run_result?.sc.errors} err`})${runner_rtt != null ? ` · ${runner_rtt}ms` : ''}`
                          : runner_phase === 'working' ? `runner working on ${_compile?.sc.dige}${runner_rtt != null ? ` · ${runner_rtt}ms` : ''} — awaiting src / running`
                          : `stale: last verdict was ${ran_dige} (${ran_ok ? 'green' : 'red'}), older than the compiled version — no runner on it`}>
                    {#if runner_phase === 'good'}<span class="lte-ch-ico">✓</span>{ran_dige}
                    {:else if runner_phase === 'bad'}<span class="lte-ch-ico">✗</span>{ran_done != null ? `${ran_passed}/${ran_done}` : (run_result?.sc.errors ?? '')} {ran_dige}
                    {:else if runner_phase === 'working'}<span class="lte-ch-ico lte-run-spin">◴</span>{_compile?.sc.dige}
                    {:else}<span class="lte-ch-ico">⟳</span>{ran_dige}{/if}
                </span>
                <!-- ping: the live bridged round-trip to the runner, on the line beside its
                     verdict.  Independent of the verdict (it's the channel heartbeat, not the
                     run), so it shows whenever a runner is ponging — including while red/working. -->
                {#if runner_rtt != null}
                    <span class="lte-ch-ping" title="channel round-trip to the runner (bridged)">{runner_rtt}ms</span>
                {/if}
                {#if runner_clash}
                    <span class="lte-ch-clash" title="{live_runners.length} runners are live — verdicts may disagree; one may be a stale replacement">⚠{live_runners.length}</span>
                {/if}
            {/if}
        </span>
        {/if}
        <span class="lte-hint">Ctrl+B</span>
        <span class="lte-sel">{sel_from}{sel_from !== sel_to ? `..${sel_to}` : ''}</span>
        <span class="lte-len">{((dock.c.text as string) ?? '').length}c</span>
        <!-- "map" button: toggles minimap overlay, active when open -->
        <button class="lte-map-btn" class:active={minimap_open}
                onclick={() => minimap_open = !minimap_open}
                title="{minimap_open ? 'hide minimap' : 'show minimap'}">map</button>
        <!-- V button: expand editor to 80vh / collapse to 50vh.
             Λ (upside-down V) when expanded — same idiom as Storui's diff panel. -->
        <button class="lte-expand-btn" class:open={expanded}
                onclick={() => expanded = !expanded}
                title="{expanded ? 'collapse editor' : 'expand editor'}">V</button>
    </div>
    {/if}
    {#if no_doc}
    <!-- title-page %What — the cursor has no doc; CM stays alive but hidden -->
    <div class="lte-nodoc">— no doc — this What is a title page</div>
    {/if}
    <!-- Always present: destroying this div destroys the EditorView -->
    <div class="lte-cm" class:lte-cm-hidden={no_doc} bind:this={container}>
        <!-- Horizontal V chevron — always at the minimap/scrollbar junction.
             Stays in place whether or not minimap is open.
             Points left (<) when closed, right (>) when open — same V char, ±90°. -->
        <button class="lte-mm-chevron" class:open={minimap_open}
                onclick={() => minimap_open = !minimap_open}
                title="{minimap_open ? 'hide minimap' : 'show minimap'}">V</button>
        {#if minimap_open}
        <!-- lte-mm-host overlays the editor canvas; chevron floats over the top corner (z-index 3) -->
        <div class="lte-mm-host">
            <DocMinimap {H} {view} />
        </div>
        {/if}

        {#if dock}
        <!-- Frozen-frame overlay — MUST live INSIDE .lte-cm.  The editor's whole
             appearance comes from Langui's `.lte-cm :global(.cm-*)` rules (there is no
             CM theme extension), so a cloned editor only paints when it is itself a
             descendant of .lte-cm.  Mounted as a sibling it rendered blank — the green
             outline with the live editor showing through.  position:fixed still floats
             the frame over the viewport; the DOM home is purely what carries the scoped
             CSS onto the clone.  Mounting it arms dock.c.compost (gotos → fly-ins). -->
        <DocCompost {H} {view} />
        {/if}
    </div>
    {#if dock && bookmarks.length}
    <!-- Point panel: one DocPoint per bookmark on the active doc -->
    <div class="lte-points">
        {#each bookmarks as bm (bm.sc.bookmark)}
            <DocPoint {H} {bm} dock_path={active_path} {lang_model} />
        {/each}
    </div>
    {/if}
    {#if slow_open}
    <!-- Slow-open overlay: a furnish reading off Wormhole can take a beat, and the minimap
         spinner is tiny|cornered — so past 0.2s raise a big centred spinner over the editor
         until the doc lands.  pointer-events:none so it never traps a click. -->
    <div class="lte-opening" aria-hidden="true"><span class="lte-opening-spin">◴</span></div>
    {/if}
</div>
{/if}

<style>
    .lte {
        position: relative;        /* positioning context for DocMinimap overlay */
        display: flex; flex-direction: column;
        border: 1px solid #1a1a1a; border-radius: 4px;
        background: #0a0a0a; overflow: hidden;
        font-family: 'Berkeley Mono','Fira Code',ui-monospace,monospace;

        /* knob these two to move both scrollbar gutter and minimap together */
        --lte-scrollbar-w: 2em;
        --lte-minimap-w:   20%;   /* half-size, then 50% wider, one method column */
    }
    .lte-bar {
        display: flex; align-items: center; gap: 8px;
        padding: 4px 8px; background: #0f0f0f;
        border-bottom: 1px solid #181818;
        font-size: 10px; color: #666;
    }
    .lte-doc   { color: #9ab0c4; font-family: monospace; font-size: 0.78em; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .lte-hint  { color: #3a3a3a; font-style: italic; }
    .lte-sel   { color: #556; font-variant-numeric: tabular-nums; }
    .lte-len   { color: #3a3a3a; }

    /* ── change strip — inline in .lte-bar next to the filename ──
       Four legs of the version flow: editor → disk → compiled → runner.  Each leg
       is a glyph + 5-char dige; brighter than before so the chain reads at a glance,
       dimming only the stages the editor has run ahead of.  Work-in-flight shows as
       per-leg state (compile dim/busy colour, runner ◴) — the strip itself stays still. */
    .lte-change {
        display: inline-flex; align-items: center; gap: 0.2rem;
        font-family: monospace; font-size: 0.7rem;
        padding: 0 0.15rem; border-radius: 3px;
        transform-origin: bottom center;
    }
    .lte-ch-leg     { letter-spacing: 0.03em; display: inline-flex; align-items: baseline; gap: 0.16rem; }
    .lte-ch-ico     { font-size: 0.66rem; opacity: 1; line-height: 1; }   /* the per-stage glyph */
    .lte-ch-editor  { color: #8fb0d4; }   /* editor text — the live source */
    .lte-ch-disk    { color: #6a9a8a; transform: translateY(2px); }   /* on disk — sits low, the grounded one */
    .lte-ch-compile { color: #9a8ac4; }   /* compiled output */
    .lte-ch-arrow   { color: #3a3a4a; }
    .lte-ch-dim     { opacity: 0.4; }
    .lte-ch-secs    { color: #556; margin-left: 0.1rem; font-size: 0.62rem; }
    .lte-ch-busy    { color: #c4a86a; }   /* a compile is in flight on this leg */

    /* runner leg — phase of whoever ran the compiled version, with colour + glyph */
    .lte-ch-runner  {
        letter-spacing: 0.03em; cursor: help;
        padding: 0 0.2rem; border-radius: 2px;
        display: inline-flex; align-items: center; gap: 0.12rem;
    }
    .lte-run-good    { color: #6ad0a0; background: rgba(106, 208, 160, 0.1); }
    .lte-run-bad     { color: #f88;    background: rgba(255, 136, 136, 0.12); }
    .lte-run-working { color: #c4a86a; }
    .lte-run-stale   { color: #778; opacity: 0.7; }   /* old verdict — never reads as success */
    .lte-run-spin    { display: inline-block; animation: lte-run-spin-kf 1.1s linear infinite; }
    /* ping rides beside the runner leg, dimmed like compile's secs — the channel pulse */
    .lte-ch-ping    { color: #6a8; margin-left: 0.1rem; font-size: 0.62rem; cursor: help; }
    .lte-ch-clash   {
        color: #f0b040; font-size: 0.66rem; cursor: help;
        font-weight: bold; letter-spacing: 0.02em;
    }

    @keyframes -global-lte-run-spin-kf {
        from { transform: rotate(0deg); }
        to   { transform: rotate(360deg); }
    }
    @media (prefers-reduced-motion: reduce) {
        .lte-run-spin, .lte-opening-spin { animation: none; }
    }

    /* ── slow-open overlay — big centred spinner once an open passes 0.2s ────── */
    .lte-opening {
        position: absolute; inset: 0; z-index: 5;
        display: flex; align-items: center; justify-content: center;
        background: rgba(10, 10, 10, 0.55);
        pointer-events: none;   /* a loading veil, never a click trap */
    }
    .lte-opening-spin {
        display: inline-block; font-size: 56px; line-height: 1; color: #9ab0c4;
        animation: lte-run-spin-kf 1.1s linear infinite;
    }

    /* ── "map" button — minimap toggle ─────────────────────────────────── */
    /* Plain word button; active state is colour, not rotation.             */
    .lte-map-btn {
        background: none; border: none;
        color: #2a2a3a; cursor: pointer;
        font-family: monospace; font-size: 9px;
        letter-spacing: 0.08em; text-transform: lowercase;
        padding: 1px 4px; border-radius: 2px; flex-shrink: 0;
        transition: color 0.15s, background 0.15s;
    }
    .lte-map-btn:hover  { color: #7090b0 }
    .lte-map-btn.active { color: #5080a0; background: #0d0d20 }

    /* ── V / Λ expand button ────────────────────────────────────────────── */
    /* Matches Storui's .sr-expand idiom: right-side-up V = "expand",       */
    /* upside-down Λ = "collapse".  Rotates on open.                        */
    .lte-expand-btn {
        background: none; border: none;
        color: #383848; cursor: pointer;
        font-family: Georgia, 'Times New Roman', serif;
        font-size: 14px; font-weight: 400; line-height: 1;
        width: 18px; height: 18px; padding: 0; flex-shrink: 0;
        display: flex; align-items: center; justify-content: center;
        transition: color 0.15s, transform 0.2s;
        transform-origin: center;
        transform: rotate(0deg);   /* V — collapsed, points down → "expand" */
    }
    .lte-expand-btn:hover     { color: #7090b0 }
    .lte-expand-btn.open      { transform: rotate(180deg) }  /* Λ — expanded */

    /* ── editor area ────────────────────────────────────────────────────── */
    /* Height constraint lives on cm-scroller, not on .lte-cm.              */
    /*                                                                       */
    /* Why: CM's virtual-line renderer measures viewport height from         */
    /* view.scrollDOM (= cm-scroller). Putting overflow/max-height on an     */
    /* outer ancestor makes that measurement wrong — CM thinks the entire    */
    /* document is on screen and stops painting lines outside the visible    */
    /* band, which corrupts the display on long files.  Constraining the     */
    /* scroller directly keeps CM's measure loop correct and leaves          */
    /* scrollSnapshot()/dispatch restoration working without any JS changes. */
    /* wrapper: position:relative makes it the containing block for lte-mm-host */
    /* title-page shell — shown while %Languinio sc.no_doc; the editor div is
       display:none'd rather than removed so the EditorView survives the blank */
    .lte-nodoc {
        padding: 28px 16px;
        color: #678; font-size: 12px; font-style: italic;
        text-align: center;
    }
    .lte-cm-hidden { display: none; }
    /* min-height floor so the editor block never collapses to nothing — keeps it
       grabbable when content is tiny (and when the whole thing is picked up on its own
       later, e.g. a GhostList lens decided LiesStore-side).  The normal doc view is
       still governed by the cm-scroller's 200px min below. */
    .lte-cm    { position: relative; min-height: 40px; }
    .lte-cm :global(.cm-editor)  { /* auto height — driven by cm-scroller */ }
    .lte-cm :global(.cm-content) { font-size: 12px; }

    /* cm-scroller is CM's actual scroll container and the source of truth   */
    /* for scrollSnapshot().  Height caps go here; view.scrollDOM IS this.   */
    .lte-cm :global(.cm-scroller) {
        overflow: scroll;
        min-height: 200px;
        max-height: 50vh;
    }
    /* lte-expanded: V button pressed — give the editor room to breathe     */
    .lte-expanded .lte-cm :global(.cm-scroller) { max-height: 80vh }

    /* ── webkit scrollbar ─────────────────────────────────────────────────── */
    /* The bar's look (thumb/track) is the global .scrollbig (app.css), added to  */
    /* the scroller in JS.  Langui overrides only the WIDTH, because              */
    /* --lte-scrollbar-w is the gutter the minimap tucks into and also positions  */
    /* the chevron — width and minimap must move together.                       */
    .lte-cm :global(.cm-scroller)::-webkit-scrollbar {
        width:  var(--lte-scrollbar-w);   /* vertical — the minimap gutter */
        height: 0.5em;                    /* horizontal — stay out of the way */
    }
    .lte-cm :global(.cm-scroller)::-webkit-scrollbar-thumb {
        min-height: 4em;                  /* easier to grab on a tall doc */
    }

    /* .fathandle — wider thumb for when minimap gutter is wider;            */
    /* add class to cm-scroller via EditorView.scrollDOMAttributes           */
    /* < wiring fathandle to an actual minimap-width setting is future work  */
    .lte-cm :global(.cm-scroller.fathandle)::-webkit-scrollbar {
        width:  3.14em;
        height: 0.5em;
        border-radius: 0.8em;
    }
    .lte-cm :global(.cm-scroller.fathandle)::-webkit-scrollbar-thumb {
        width:  3.14em;
        border-radius: 0.8em;
    }

    /* ── horizontal V chevron ────────────────────────────────────────────── */
    /* Always rendered inside lte-cm; position:absolute keeps it at the     */
    /* minimap/scrollbar junction regardless of minimap visibility.         */
    /* Same Georgia V as the expand button, rotated ±90° to make < or >.   */
    /* < (−90°) = closed, suggesting the minimap is to the left / hidden.  */
    /* > (+90°) = open, suggesting the minimap is here, pointing into it.  */
    .lte-mm-chevron {
        position: absolute;
        top:   2px;
        right: var(--lte-scrollbar-w);
        z-index: 3;
        background: none; border: none;
        color: #2a3040; cursor: pointer;
        font-family: Georgia, 'Times New Roman', serif;
        font-size: 13px; font-weight: 400; line-height: 1;
        width: 18px; height: 18px; padding: 0;
        display: flex; align-items: center; justify-content: center;
        transition: color 0.15s, transform 0.2s;
        transform-origin: center;
        transform: rotate(-90deg);   /* < — closed */
    }
    .lte-mm-chevron:hover { color: #7090b0 }
    .lte-mm-chevron.open  { transform: rotate(90deg); }  /* > — open */

    /* ── minimap overlay host ────────────────────────────────────────────── */
    /* Absolutely positioned inside lte-cm (its containing block), so       */
    /* top/bottom track the editor area exactly — canvas starts at top:0.   */
    /* overflow:hidden clips DocMinimap's canvas to the editor viewport.    */
    /* The chevron button floats over the canvas top-right corner (z-index  */
    /* 3 vs host's 1) — no padding-top spacer needed.  The blank area at   */
    /* the chevron position when minimap is open is handled by DocMinimap   */
    /* having no header (remove its internal hide button — it's replaced by */
    /* this chevron and the "map" button in the bar).                       */
    .lte-mm-host {
        position: absolute;
        top:    0;
        bottom: 0;
        right:  var(--lte-scrollbar-w);
        width:  var(--lte-minimap-w);
        overflow:       hidden;     /* clips minimap canvas to editor viewport */
        pointer-events: none;       /* host transparent; children re-enable */
        z-index: 1;
    }
    .lte-mm-host > :global(*) { pointer-events: auto; }

    /* bookmark Decoration.mark — subtle underline + tinted bg so overlapping
       ranges read clearly. One rule works even when marks overlap because
       CodeMirror merges classes on the same span. */
    .lte-cm :global(.cm-bookmark) {
        background: rgba(122, 176, 212, 0.12);
        border-bottom: 1px solid rgba(122, 176, 212, 0.5);
        border-radius: 1px;
    }

    /* Graft marks — Pmirror-owned, session-only.  Gold accent to distinguish
       from user bookmarks (blue) at a glance. */
    .lte-cm :global(.cm-graft) {
        background: rgba(229, 192, 123, 0.12);
        border-bottom: 1px solid rgba(229, 192, 123, 0.6);
        border-radius: 1px;
    }

    /* Point decoration — line-level glow|enlarge applied by pointDecorationField.
       cm-point-engaged is the base class (default and named classes extend it).
       A fixed static set: focus, caution, dim, ghost.  No runtime CSS variables —
       classes are stamped by the StateField from clone//U%class. */
    .lte-cm :global(.cm-point-engaged) {
        box-shadow:  inset 0 0 12px #c4aaee33;
        line-height: 1.96em;
        transition:  line-height 0.15s, box-shadow 0.15s;
    }
    .lte-cm :global(.cm-point-focus) {
        box-shadow:  inset 0 0 20px #c4aaee66;
        line-height: 2.8em;
    }
    .lte-cm :global(.cm-point-caution) {
        box-shadow: inset 0 0 12px rgba(229, 192, 100, 0.25);
    }
    .lte-cm :global(.cm-point-dim) {
        line-height: 1.4em;
        box-shadow:  inset 0 0 6px #c4aaee1a;
    }
    /* font enlarge rides the content span (after the indent), not the whole line, so
       the leading whitespace stays body-size and the name keeps its indent column.
       The content (≤1.4–2em) fits inside the line-height set on the line above, so the
       header sits on the grid instead of hovering. */
    .lte-cm :global(.cm-point-text)       { font-size: 1.4em; transition: font-size 0.15s; }
    .lte-cm :global(.cm-point-text-focus) { font-size: 2em; }
    .lte-cm :global(.cm-point-text-dim)   { font-size: 1em; }

    /* goto bloom — a transient glow over the line-number gutter at a seek target.
       Appended to document.body (fixed), so it's :global with a -global- keyframe. */
    :global(.cm-goto-bloom) {
        position: fixed; pointer-events: none; z-index: 60; border-radius: 6px;
        background: radial-gradient(ellipse at center,
            rgba(255, 200, 90, 0.55), rgba(255, 190, 80, 0) 70%);
        box-shadow: 0 0 18px 6px rgba(255, 190, 80, 0.45);
        transform-origin: center center;
        animation: cm-goto-bloom-kf 1s ease-out forwards;
    }
    @keyframes -global-cm-goto-bloom-kf {
        0%   { opacity: 0;    transform: scale(0.4); }
        18%  { opacity: 0.95; transform: scale(1); }
        100% { opacity: 0;    transform: scale(1.5); }
    }
    .lte-cm :global(.cm-point-ghost) {
        opacity:    0.18;
        transform:  scaleY(0.4);
        transition: opacity 1s, transform 1s;
    }

    /* Point panel — compact list of bookmarks below the editor */
    .lte-points {
        border-top: 1px solid #141420;
        padding: 3px 4px;
        display: flex; flex-direction: column; gap: 1px;
        max-height: 19em; overflow-y: auto;
        background: #080810;
    }
    /* ── Fold markers ──────────────────────────────────────────────────────
       MARKED region folds: ↤N↦ placeholder (purple arrows, dim count) that
       unfolds on click.  INVISIBLE Q|Point folds: a faint ⋯ stub only.  The
       re-fold ↦ handle sits at the header-line end of an unfolded marked region,
       green, and folds it back up. */
    /* One type of fold.  Both markers scaled up (transform, not font-size, so they
       don't lift the header line's height) and always shown — the ↤N↦ count arrows
       when folded, the ↦ handle when open. */
    .lte-cm :global(.cm-fold-marked) {
        color: #8F82FF;
        cursor: pointer;
        padding: 0 0.3em;
        font-weight: 600;
        letter-spacing: 0.02em;
        display: inline-block;
        transform: scale(1.6);
        transform-origin: left center;
        user-select: none;   /* the marker glyph must never land in a copy */
    }
    .lte-cm :global(.cm-fold-marked:hover) { color: #b3a9ff; }

    .lte-cm :global(.cm-refold-handle) {
        color: rgb(119, 204, 153);
        cursor: pointer;
        margin-left: 0.6em;
        opacity: 0.85;          /* always show, not a faint hint */
        transition: opacity 0.12s, color 0.12s;
        user-select: none;
        display: inline-block;
        transform: scale(2);
        transform-origin: left center;
    }
    .lte-cm :global(.cm-refold-handle:hover) { opacity: 1; color: rgb(150, 230, 180); }
</style>
