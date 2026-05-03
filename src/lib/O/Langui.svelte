<script lang="ts">
    // Langui — CodeMirror view over one document, identified by `doc` (path string).
    //
    // ── Multi-doc (Option B: one view, per-path EditorState cache) ───────────!!!!!
    //
    //   One EditorView, many EditorStates.  On doc switch:
    //     1. Current EditorState (including full undo history, scroll, selection,
    //        and bookmark decorations) is saved to stateCache[prev_path].
    //     2. view.setState(stateCache[arriving]) restores a previously-seen doc,
    //        or creates a fresh EditorState from ave text for a first visit.
    //
    //   view.setState() is CM's documented multi-doc API.  It replaces all state
    //   atomically without destroying the view, so decorations and plugins
    //   survive.  All EditorStates on one view must share the same extension list
    //   (editorExtensions) — stho() theme is called once at construction.
    //
    //   Langui receives no doc prop — it is mounted by the UIs loop with only H.
    //   It waits for ave/{langtiles_doc:path} to arrive before rendering anything.
    //   Until then the whole template is suppressed via {#if docC}.
    //
    //   Every CM event carries { doc, view, state } so Lang_doc_from_event
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
    //     - any text change:  Lang_set_doc      {text}
    //     - Escape key     :  Lang_compile      {}
    //     - saveEffect     :  Lang_update_bookmarks immediately (cancels debounce)
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
    //   Signal $effect: reads H.ave.ob({active_doc:1}) + sig?.ob() to subscribe
    //     to sig.version changes.  Writes active_path ($state) and docC ($state).
    //
    //   Switch $effect: reads active_path (only reactive dep).  When it changes,
    //     saves departing state → view.setState(arriving state).  All CM state
    //     (history, scroll, selection, decorations) moves with the switch.
    //     No reactive chain needed — one $effect, one imperative call.
    //
    //   External-change $effect: handles disk-reload of the active doc only.
    //     Guards against firing during a switch (active_path !== prev_path).
    //
    // ── Echo guard / text spool (the high-frequency-git seed) ────────────────
    //
    //   The same ave/%langtiles_doc particle is used for two flows that look
    //   identical from the particle's POV but are not at all the same:
    //     (a) disk/remote pulls — Lies has loaded a new file, or in future a
    //         peer has merged something in.  These should be applied to the view.
    //     (b) echoes of our own pushes — we sent Lang_set_doc on a keystroke,
    //         it round-tripped through e_Lang_set_doc which bumped the particle,
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
    //   This is the minimum primitive that gets us toward the eventual
    //   high-frequency-git merge: pulls will later carry their parent so we
    //   can decide ancestor-vs-merge with more confidence than substring-match.
    //
    // ── Push throttle ────────────────────────────────────────────────────────
    //
    //   Lang_set_doc is throttled (~60ms) so the elvis queue isn't fed faster
    //   than it can drain.  When the trailing call fires we read the LIVE view
    //   text, not whatever was current when we scheduled — so the backend
    //   always lands on the freshest snapshot.  Doc switch flushes any pending
    //   push for the departing path before saving its state.

    import { onDestroy, untrack } from "svelte"
    import { EditorView, basicSetup } from "codemirror"
    import { EditorState, StateField, StateEffect, type Extension } from "@codemirror/state"
    import { Decoration, type DecorationSet, keymap, ViewUpdate, drawSelection } from "@codemirror/view"
    import { indentService, indentUnit } from "@codemirror/language";
    import { defaultKeymap, indentWithTab } from "@codemirror/commands";

    import { stho, simpleLezerLinter } from "$lib/O/stho"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import Actions from "$lib/O/ui/Actions.svelte"   // doc-picker dropdown + any other Lang actions
    import Langminimap from "./Langminimap.svelte"

    let { H }: { H: House } = $props()

    // container is $state so the creation $effect tracks when the div appears.
    // The div only renders once docC is truthy, so this naturally gates construction.
    let container: HTMLDivElement | undefined = $state()
    // view is $state so child components passed `view` as a prop get the
    // EditorView reference once construction has completed (otherwise the
    // prop captures undefined at mount and never updates).
    let view: EditorView | undefined = $state()

    const UPDATE_DELAY_MS = 800
    let update_timer: ReturnType<typeof setTimeout> | null = null

    // Live primary-selection range, updated from the updateListener on every
    // transaction (selection-only transactions included, so cursor moves
    // update the header readout immediately).
    let sel_from = $state(0)
    let sel_to   = $state(0)

    // ── per-doc state cache ──────────────────────────────────────────────────
    //   One EditorState per path, saved on departure and restored on arrival.
    //   CM EditorState carries full undo history, selection, scroll, and all
    //   installed StateField values (including bookmark decorations).
    //   Plain Map — not reactive.  The switch $effect is the only writer.
    const stateCache = new Map<string, EditorState>()

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

    // ── push-text throttle ───────────────────────────────────────────────────
    //   Coalesce keystrokes into one Lang_set_doc per ~60ms window.  The flush
    //   reads the LIVE view text rather than a captured snapshot, so the
    //   backend always lands on the freshest text the editor has.
    //   push_pending_path tracks which doc the pending push belongs to — doc
    //   switch flushes it for the departing path before swapping.
    const PUSH_TEXT_THROTTLE_MS = 60
    let push_timer: ReturnType<typeof setTimeout> | null = null
    let push_pending_path: string | null = null
    function flush_push_text() {
        push_timer = null
        const path = push_pending_path
        push_pending_path = null
        if (!view || !path) return
        const text = view.state.doc.toString()
        // Already remembered in spool by the updateListener that scheduled us;
        // re-remember here in case a programmatic dispatch slipped through.
        spool_remember(path, text)
        Lang_i_elvis(view, 'Lang_set_doc', { text })
    }
    function schedule_push_text(path: string) {
        push_pending_path = path
        if (push_timer) return
        push_timer = setTimeout(flush_push_text, PUSH_TEXT_THROTTLE_MS)
    }
    function flush_push_text_now() {
        if (push_timer) { clearTimeout(push_timer); flush_push_text() }
    }

    // The extension list is created once at view construction and shared by
    // every EditorState on this view.  CM requires that all states on one view
    // use the same extension set.  Stored here so makeState() can reference it.
    let editorExtensions: any[] | undefined

    // ── reactive signals from ave ─────────────────────────────────────────────
    //   lang_actions: action buttons registered by Lang ghost
    //   active_path:  path of the currently-shown doc ($state so template reacts)
    //   docC:         the langtiles_doc particle for active_path (for disk-reload)
    let lang_actions: TheC[] = $state([])
    let active_path  = $state('')
    let docC: TheC | undefined = $state()

    // Short filename for the bar header.
    let active_name = $derived(active_path ? (active_path.split('/').pop() ?? active_path) : 'no doc')

    // ── signal $effect ────────────────────────────────────────────────────────
    //   Reads H.ave for lang_actions, active_doc, and langtiles_doc.
    //   sig?.ob() subscribes to sig.version so path changes inside the same
    //   sig particle (bump_version only, no re-i()) still wake this effect.
    $effect(() => {
        const la = H.ave.ob({ lang_actions: 1 })[0] as TheC | undefined
        lang_actions = la ? la.o({ action: 1 }) as TheC[] : []

        const sig  = H.ave.ob({ active_doc: 1 })[0] as TheC | undefined
        sig?.ob()  // track sig.version — path changes bump it without re-enrolling
        const path = (sig?.sc.path as string | undefined) ?? ''
        if (path) active_path = path
        docC = path ? H.ave.ob({ langtiles_doc: path })[0] as TheC | undefined : undefined
    })

    // ── switch $effect ────────────────────────────────────────────────────────
    //   Runs whenever active_path changes.  Saves the departing EditorState,
    //   then calls view.setState() with the arriving one.
    //   view.setState() is CM's documented multi-doc API — it replaces all state
    //   atomically without destroying the view or its plugins.
    //   untrack() around the save prevents docC reads from creating a dependency.
    let prev_path = ''   // plain let — not reactive; switch $effect is sole writer
    $effect(() => {
        const arriving = active_path
        if (!view || !arriving || arriving === prev_path) return

        untrack(() => {
            // Flush any pending push for the departing path so the backend
            // has the latest editor text before context swaps.  Without this,
            // a stale Lang_set_doc could land after the switch and clobber
            // docC for the doc we just left.
            flush_push_text_now()

            // Save current state before switching (skip if no doc loaded yet).
            if (prev_path) {
                stateCache.set(prev_path, view!.state)
                // Departing text into the departing path's spool — covers the
                // case where a push for this exact text is still in the elvis
                // queue and arrives after we've come back here.
                spool_remember(prev_path, view!.state.doc.toString())
            }

            const cached = stateCache.get(arriving)
            if (cached) {
                // Restore previously-seen doc — history and decorations intact.
                view!.setState(cached)
            } else {
                // First visit: build a fresh state from ave text.
                const text = (docC?.sc.text as string | undefined) ?? ''
                view!.setState(EditorState.create({ doc: text, extensions: editorExtensions! }))
            }

            // Whatever text we've just landed on is canonically "ours" —
            // remember it so the disk-reload $effect doesn't immediately
            // try to re-apply it as a remote change.
            spool_remember(arriving, view!.state.doc.toString())

            prev_path = arriving

            // Re-register view+state with backend so CM events carry the right doc.
            Lang_i_elvis(view!, 'Lang_editorBegins',
                { addBookmarkMark, removeBookmarkMark, clearAllBookmarks, saveEffect })
        })
    })

    // ── disk-reload $effect ───────────────────────────────────────────────────
    //   When the active doc is reloaded from disk (docC.text changes externally),
    //   push the new content into the editor — replacing history is acceptable
    //   here because the file changed on disk, not in the editor.
    //   Guards with active_path === prev_path to avoid firing mid-switch.
    //
    //   Echo guard: this effect also fires when docC.sc.text changes because
    //   *we* just pushed it via Lang_set_doc.  Without the spool check below,
    //   any stale push arriving from the elvis queue (the user typed faster
    //   than the queue drained) would land here as "incoming != live" and we'd
    //   dispatch a full-doc replace at offset 0 — which the updateListener
    //   then echoes back into the queue, looping.  Recognising the incoming
    //   text as one we've recently been at breaks the loop.
    $effect(() => {
        void docC?.version
        const incoming = (docC?.sc.text as string | undefined) ?? ''
        if (!view || !incoming) return
        if (active_path !== prev_path) return   // switch in progress
        const live = view.state.doc.toString()
        if (incoming === live) return
        if (spool_has(active_path, incoming)) return   // echo of our own push
        // Genuine remote / disk change.  Apply it, and remember it so the
        // resulting updateListener push doesn't immediately come back through
        // here as "new" again.
        spool_remember(active_path, incoming)
        view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: incoming } })
    })

    // ── Lang_i_elvis ─────────────────────────────────────────────────────────
    //
    //   Central CM→backend bridge.  Stamps { doc, view, state } on every event
    //   so Lang_doc_from_event can update docC.c.view/state in one place,
    //   and the backend always knows which document the event came from.
    //   Uses active_path (not a fixed prop) so the stamp stays correct
    //   after a doc switch.
    function Lang_i_elvis(view, method, sc) {
        sc = { doc: active_path, view, state: view.state, ...(sc || {}) }
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
                Lang_i_elvis(view,'Lang_compile', {})
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
    }])

    // ── EditorView construction ──────────────────────────────────────────────
    //
    //   Deferred until container is bound, which only happens after {#if docC}
    //   becomes true (first ave/%langtiles_doc particle arrived).
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
    //   the read keeps the only reactive dep on `container` and `docC`.
    // ── ResizeObserver for late layout settling ──────────────────────────────
    //   See construction $effect for context.  Stored at module scope so
    //   onDestroy can disconnect it.
    let container_ro: ResizeObserver | undefined

    $effect(() => {
        if (!container || !docC) return
        const already = untrack(() => view)
        if (already) return

        // Read docC fresh from ave at construction-time.  active_path is set
        // before {#if docC} flips, so by the time this $effect fires the
        // langtiles_doc particle is in ave and its text is populated.
        const fresh_docC = H.ave.ob({ langtiles_doc: active_path })[0] as TheC | undefined
        const initial    = (fresh_docC?.sc.text as string) ?? (docC?.sc.text as string) ?? ''

        // Build extensions once; reused by all EditorStates on this view.
        editorExtensions = [
            basicSetup,
            simpleLezerLinter(),
            // < switchable lang via Compartment
            stho(),
            bookmarkField,
            Keys,
            EditorView.updateListener.of((v: ViewUpdate) => {
                const sel = v.state.selection.main
                sel_from = sel.from
                sel_to   = sel.to
                // saveEffect: flush bookmark positions immediately, cancel debounce
                if (v.transactions.some(tr => tr.effects.some(e => e.is(saveEffect)))) {
                    if (update_timer) { clearTimeout(update_timer); update_timer = null }
                    fire_update_bookmarks(v.view)
                    return
                }
                if (!v.docChanged) return
                const text = v.state.doc.toString()
                // Spool first, then schedule the throttled push.  Spooling
                // synchronously means even if the elvis queue gets way behind,
                // by the time stale snapshots bubble back through e_Lang_set_doc
                // and the disk-reload $effect, they're recognised as echoes.
                spool_remember(active_path, text)
                schedule_push_text(active_path)
                schedule_update_bookmarks(v.view)
            }),
            usualSetup,
        ]

        view = new EditorView({
            parent: container,
            state: EditorState.create({ doc: initial, extensions: editorExtensions }),
        })

        // Seed the spool with the initial text so the very first echo
        // (e_Lang_set_doc bumping docC after our first keystroke) is
        // recognised cleanly even before any local edits land.
        spool_remember(active_path, initial)

        // CM measures its container once at construction.  If the parent's
        // flex layout hasn't settled when this runs (common when {#if docC}
        // first flips and the editor mounts in the same tick), the measured
        // height is 0 and CM stops painting until the next forced re-measure.
        // Two-stage requestMeasure (now + next animation frame) caught the
        // common case but missed late settling — fonts loading, sibling
        // expanding, parent flex resolving on a tick we didn't anticipate.
        // ResizeObserver is the canonical signal: it fires whenever the
        // observed element's size actually changes, including the 0→N
        // transition that breaks first-load.  Kept the immediate
        // requestMeasure as a belt-and-braces nudge for the case where the
        // container is already non-zero at construction.
        view.requestMeasure()
        container_ro = new ResizeObserver(() => view?.requestMeasure())
        container_ro.observe(container)

        // Cache this first state so the switch $effect doesn't create a duplicate
        // fresh state the first time active_path is seen.
        if (active_path) stateCache.set(active_path, view.state)
        prev_path = active_path

        // Register view+state with backend.
        Lang_i_elvis(view, 'Lang_editorBegins',
            { addBookmarkMark, removeBookmarkMark, clearAllBookmarks, saveEffect })
    })

    onDestroy(() => {
        if (update_timer) clearTimeout(update_timer)
        if (push_timer)   clearTimeout(push_timer)
        container_ro?.disconnect()
        view?.destroy()
    })
</script>

{#if docC}
<div class="lte">
    <div class="lte-bar">
        <!-- doc-picker dropdown + any other Lang actions (compo/compi toggles etc) -->
        <Actions N={lang_actions} />
        <span class="lte-doc" title={active_path}>{active_name}</span>
        <span class="lte-hint">Ctrl+B</span>
        <span class="lte-sel">{sel_from}{sel_from !== sel_to ? `..${sel_to}` : ''}</span>
        <span class="lte-len">{(docC.sc.text as string ?? '').length}c</span>
    </div>
    <div class="lte-cm" bind:this={container}></div>
    <Langminimap {H} {view} {active_path} />
</div>
{/if}

<style>
    .lte {
        position: relative;        /* positioning context for Langminimap overlay */
        display: flex; flex-direction: column;
        border: 1px solid #1a1a1a; border-radius: 4px;
        background: #0a0a0a; overflow: hidden;
        font-family: 'Berkeley Mono','Fira Code',ui-monospace,monospace;
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
    .lte-cm    { min-height: 200px; max-height: 50vh; overflow: auto; }
    .lte-cm :global(.cm-editor)  { height: 100%; }
    .lte-cm :global(.cm-content) { font-size: 12px; }

    /* bookmark Decoration.mark — subtle underline + tinted bg so overlapping
       ranges read clearly. One rule works even when marks overlap because
       CodeMirror merges classes on the same span. */
    .lte-cm :global(.cm-bookmark) {
        background: rgba(122, 176, 212, 0.12);
        border-bottom: 1px solid rgba(122, 176, 212, 0.5);
        border-radius: 1px;
    }
</style>
