<script lang="ts">
    // Langui — CodeMirror view over one document, identified by `doc` (path string).
    //
    // ── Multi-doc (Option B: one view, per-path EditorState cache) ───────────!!!!!!
    //
    //   One EditorView, many EditorStates.  On doc switch:
    //     1. Bookmark positions for the departing doc are flushed immediately
    //        (bypassing the 800ms debounce) so docC never has stale positions.
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
    //   Bookmark flush on switch: flush_update_bookmarks_for_path(prev_path) is
    //   called before saving the departing EditorState.  This cancels any pending
    //   800ms debounce and immediately sends the live positions to docC so they
    //   can't be clobbered by a stale timer firing after the switch.
    //   editorBegins also carries `updates` so the backend can re-apply any
    //   bookmarks that exist in docC but are absent from a freshly-restored CM state.
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
    //     flushes bookmarks + scroll for departing doc → saves departing state →
    //     calls view.setState(arriving state).  All CM state (history, scroll,
    //     selection, decorations) moves with the switch.
    //
    //   External-change $effect: handles disk-reload of the active doc only.
    //     Guards against firing during a switch (active_path !== prev_path).
    //
    // ── Echo guard / text spool (the high-frequency-git seed) ────────────────
    //
    //   The same ave/%lang_doc particle is used for two flows that look
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
    // ── Push throttle ────────────────────────────────────────────────────────
    //
    //   Lang_set_doc is throttled (~60ms) so the elvis queue isn't fed faster
    //   than it can drain.  When the trailing call fires we read the LIVE view
    //   text, not whatever was current when we scheduled — so the backend
    //   always lands on the freshest snapshot.  Doc switch flushes any pending
    //   push for the departing path before saving its state.

    import { onDestroy, untrack } from "svelte"
    import { EditorView, basicSetup } from "codemirror"
    import { EditorState, StateField, StateEffect, Compartment, type Extension } from "@codemirror/state"
    import { Decoration, type DecorationSet, keymap, ViewUpdate, drawSelection } from "@codemirror/view"
    import { indentService, indentUnit } from "@codemirror/language";
    import { defaultKeymap, indentWithTab } from "@codemirror/commands";

    import { lang, simpleLezerLinter, lang_for_path } from "$lib/O/lang/lang"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import Actions from "$lib/O/ui/Actions.svelte"   // doc-picker dropdown + any other Lang actions
    import DocMinimap from "./ui/DocMinimap.svelte"
    import DocPoint   from "./ui/DocPoint.svelte"

    let { H }: { H: House } = $props()

    // container is $state so the creation $effect tracks when the div appears.
    // The div only renders once docC is truthy, so this naturally gates construction.
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

    const UPDATE_DELAY_MS = 800
    let update_timer: ReturnType<typeof setTimeout> | null = null

    // Live primary-selection range, updated from the updateListener on every
    // transaction (selection-only transactions included, so cursor moves
    // update the header readout immediately).
    let sel_from = $state(0)
    let sel_to   = $state(0)

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

    // ── bookmark-position flush ───────────────────────────────────────────────
    //   flush_update_bookmarks_for_path(path): cancel the 800ms debounce and
    //   immediately send the live bookmark positions for `path` to the backend.
    //
    //   Called before a doc switch so the departing doc's positions land in
    //   docC before active_path changes — preventing a stale debounce timer
    //   from firing later and sending the wrong doc's (empty) bookmark list to
    //   the arriving doc's docC, which would flag all its bookmarks as vanished.
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
    //   docC:         the ave/{lang_doc:path} particle (text length display,
    //                 disk-reload detection)
    //   active_doc:   the actual {doc:path} particle from w:Lang
    //                 (holds bookmarks; sig.c.doc set by Lang_set_active_doc)
    let lang_actions: TheC[] = $state([])
    let active_path  = $state('')
    let docC:       TheC | undefined = $state()   // text-sync particle
    let active_doc: TheC | undefined = $state()   // {doc:path} particle — has bookmarks

    // Short filename for the bar header.
    let active_name = $derived(active_path ? (active_path.split('/').pop() ?? active_path) : 'no doc')

    let bookmarks: TheC[] = $derived(
        !active_doc ? []
            : (active_doc.ob({ bookmark: 1 }) as TheC[]).filter(bm => !bm.sc.graft)
    )

    // minimap_open: toggled by the "map" button in the bar.
    // Toggle lives here so the button position doesn't move when the map opens.
    let minimap_open = $state(true)

    // expanded: makes cm-scroller take 80vh instead of the default 50vh.
    // V button in bar — same Λ/V rotation idiom as Storui's diff-panel expand.
    let expanded = $state(false)

    // ── signal $effect ────────────────────────────────────────────────────────
    //   Reads H.ave for lang_actions, active_doc, and lang_doc.
    //   sig?.ob() subscribes to sig.version so path changes inside the same
    //   sig particle (bump_version only, no re-i()) still wake this effect.
    //
    //   sig.c.doc is the {doc:path} particle stamped by Lang_set_active_doc.
    //   It lives on .c (not .sc) because TheC references don't belong in the
    //   index; the signal's version bump is what wakes this effect up.
    $effect(() => {
        const la = H.ave.ob({ lang_actions: 1 })[0] as TheC | undefined
        lang_actions = la ? la.o({ action: 1 }) as TheC[] : []

        const sig  = H.ave.ob({ active_doc: 1 })[0] as TheC | undefined
        sig?.ob()  // track sig.version — path changes bump it without re-enrolling
        const path = (sig?.sc.path as string | undefined) ?? ''
        if (path) active_path = path
        docC       = path ? H.ave.ob({ lang_doc: path })[0] as TheC | undefined : undefined
        active_doc = sig?.c.doc as TheC | undefined
        console.log(`🔭 signal $effect: sig=${!!sig} path=${path} docC=${!!docC} active_doc=${!!active_doc}`)
    })

    // ── switch $effect ────────────────────────────────────────────────────────
    //   Runs whenever active_path changes.  Saves the departing EditorState
    //   (after flushing bookmarks and scroll position), then calls
    //   view.setState() with the arriving one.
    //   view.setState() is CM's documented multi-doc API — it replaces all state
    //   atomically without destroying the view or its plugins.
    //   untrack() around the save prevents docC reads from creating a dependency.
    let prev_path = ''   // plain let — not reactive; switch $effect is sole writer
    $effect(() => {
        const arriving = active_path
        console.log(`🔀 switch $effect: arriving=${arriving} prev=${prev_path} view=${!!untrack(()=>view)}`)
        if (!view || !arriving || arriving === prev_path) return

        untrack(() => {
            // Flush any pending text push for the departing path.
            flush_push_text_now()

            if (prev_path) {
                // Flush departing bookmark positions immediately — bypass the
                // 800ms debounce so docC always holds current positions.
                // A stale timer firing later would otherwise send the arriving
                // doc's (possibly empty) bookmark list to the wrong docC.
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
                // First visit: build a fresh state from ave text.
                const text = (docC?.sc.text as string | undefined) ?? ''
                view!.setState(EditorState.create({ doc: text, extensions: editorExtensions! }))
            }

            spool_remember(arriving, view!.state.doc.toString())
            prev_path = arriving

            // ── Scroll restoration ────────────────────────────────────────────
            // Dispatch the saved snapshot effect.  On first visit there is no
            // snapshot, so skip — CM will default to showing the top.
            const snap = scrollCache.get(arriving)
            if (snap) view!.dispatch({ effects: snap })

            // Re-register view+state with backend so CM events carry the right doc.
            // Pass current bookmark positions so the backend can reconcile docC
            // against the restored CM state (re-anchoring any that drifted).
            Lang_i_elvis(view!, 'Lang_editorBegins',
                { addBookmarkMark, removeBookmarkMark, clearAllBookmarks, saveEffect,
                  updates: readBookmarks(view!) })
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

    // ── language reconfigure $effect ─────────────────────────────────────────
    //   Tracks active_doc.sc.lang_override (and falls back to lang_for_path on
    //   the active_path). When it differs from the last applied language,
    //   resolves the new lang() extensions and dispatches a Compartment
    //   reconfigure on the view — no remount, undo history and selection
    //   survive. last_applied_lang is set optimistically; if the async
    //   lang() resolve rejects we revert it so a retry can fire.
    $effect(() => {
        void active_doc?.version
        if (!view || !active_path) return
        const want = (active_doc?.sc.lang_override as string)
            ?? lang_for_path(active_path)
        if (want === last_applied_lang) return
        const prev = last_applied_lang
        last_applied_lang = want
        lang(want).then(exts => {
            if (!view) return
            if (exts.warnings?.length) {
                console.warn(`lang(${want}) warnings:`, exts.warnings)
            }
            view.dispatch({ effects: langCompartment.reconfigure(exts) })
        }).catch(err => {
            last_applied_lang = prev
            console.warn(`Langui: lang(${want}) failed:`, err)
        })
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
                    const deco = Decoration.mark({
                        class: 'cm-graft',
                        attributes: { 'data-graft-id': e.value.id },
                        graft_id: e.value.id,
                    } as any).range(e.value.from, e.value.to)
                    marks = marks.update({ add: [deco] })
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
    //   becomes true (first ave/%lang_doc particle arrived).
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
        console.log(`🏗 construction $effect: container=${!!container} docC=${!!docC} view=${!!untrack(()=>view)}`)
        if (!container || !active_path) return
        const already = untrack(() => view)
        if (already) { console.log(`🏗 construction $effect: already have view, bailing`); return }

        // Capture what we need from reactive scope before the setTimeout.
        const captured_container = container
        const captured_path      = active_path
        const captured_docC      = docC
        console.log(`🏗 construction $effect: scheduling setTimeout for path=${captured_path} container.clientHeight=${captured_container.clientHeight}`)

        // Defer EditorView construction by one task so the browser has done
        // a layout pass after {#if docC} flips.  The $effect fires in the
        // same microtask as the DOM insertion — the container exists but has
        // zero clientHeight, so CM measures 0 and stops painting.
        // HMR works because Svelte remounts into a settled layout; cold load
        // now behaves the same way.
        setTimeout(async () => {
        console.log(`🏗 setTimeout fired: isConnected=${captured_container.isConnected} clientHeight=${captured_container.clientHeight}`)
        if (!captured_container.isConnected) return   // destroyed while we waited

        // Read docC fresh — text may have arrived during the delay.
        const fresh_docC = H.ave.ob({ lang_doc: captured_path })[0] as TheC | undefined
        const initial    = (fresh_docC?.sc.text as string) ?? (captured_docC?.sc.text as string) ?? ''

        // Pick the initial language by extension. The per-doc override (if
        // any) is applied a moment later by the reconfigure $effect once it
        // sees active_doc.sc.lang_override.
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
            Keys,
            EditorView.updateListener.of((v: ViewUpdate) => {
                const sel = v.state.selection.main
                sel_from = sel.from
                sel_to   = sel.to
                // saveEffect: flush bookmark positions immediately, cancel debounce
                if (v.transactions.some(tr => tr.effects.some(e => e.is(saveEffect)))) {
                    if (update_timer) { clearTimeout(update_timer); update_timer = null }
                    fire_update_bookmarks(v.view)
                    fire_update_grafts(v.view)
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
            parent: captured_container,
            state: EditorState.create({ doc: initial, extensions: editorExtensions }),
        })
        last_applied_lang = initial_lang_name
        console.log(`🏗 EditorView created: dom.clientHeight=${view.dom.clientHeight} scrollDOM.clientHeight=${view.scrollDOM.clientHeight}`)

        // Seed the spool with the initial text so the very first echo
        // (e_Lang_set_doc bumping docC after our first keystroke) is
        // recognised cleanly even before any local edits land.
        spool_remember(captured_path, initial)

        // No requestMeasure() here — layout has already settled by the time
        // this setTimeout fires.  ResizeObserver handles any subsequent changes
        // (e.g. sidebars opening, fonts loading late).
        container_ro = new ResizeObserver((entries) => {
            const h = entries[0]?.contentRect.height ?? 0
            console.log(`🏗 ResizeObserver fired: height=${h}`)
            view?.requestMeasure()
        })
        container_ro.observe(captured_container)

        // Cache this first state so the switch $effect doesn't create a duplicate
        // fresh state the first time active_path is seen.
        if (captured_path) stateCache.set(captured_path, view.state)
        prev_path = captured_path

        // Register view+state with backend.
        // Pass current bookmark + graft positions for initial sync (normally
        // empty on first construction, but included for consistency).
        console.log(`🏗 firing Lang_editorBegins for path=${captured_path}`)
        Lang_i_elvis(view, 'Lang_editorBegins',
            { addBookmarkMark, removeBookmarkMark, clearAllBookmarks, saveEffect,
              addGraftMark, removeGraftMark, clearAllGrafts,
              updates: readBookmarks(view), graft_updates: readGrafts(view) })
        }, 0)
    })

    onDestroy(() => {
        if (update_timer) clearTimeout(update_timer)
        if (push_timer)   clearTimeout(push_timer)
        container_ro?.disconnect()
        view?.destroy()
    })
</script>

{#if active_path}
<div class="lte" class:lte-expanded={expanded}>
    {#if docC}
    <div class="lte-bar">
        <!-- doc-picker dropdown + any other Lang actions (compo/compi toggles etc) -->
        <Actions N={lang_actions} />
        <span class="lte-doc" title={active_path}>{active_name}</span>
        <span class="lte-hint">Ctrl+B</span>
        <span class="lte-sel">{sel_from}{sel_from !== sel_to ? `..${sel_to}` : ''}</span>
        <span class="lte-len">{(docC.sc.text as string ?? '').length}c</span>
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
    <!-- Always present: destroying this div destroys the EditorView -->
    <div class="lte-cm" bind:this={container}>
        <!-- Horizontal V chevron — always at the minimap/scrollbar junction.
             Stays in place whether or not minimap is open.
             Points left (<) when closed, right (>) when open — same V char, ±90°. -->
        <button class="lte-mm-chevron" class:open={minimap_open}
                onclick={() => minimap_open = !minimap_open}
                title="{minimap_open ? 'hide minimap' : 'show minimap'}">V</button>
        {#if minimap_open}
        <!-- lte-mm-host overlays the editor canvas; chevron floats over the top corner (z-index 3) -->
        <div class="lte-mm-host">
            <DocMinimap {H} {view} {active_path} />
        </div>
        {/if}
    </div>
    {#if active_doc && bookmarks.length}
    <!-- Point panel: one DocPoint per bookmark on the active doc -->
    <div class="lte-points">
        {#each bookmarks as bm (bm.sc.bookmark)}
            <DocPoint {H} {bm} doc_path={active_path} />
        {/each}
    </div>
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
        --lte-minimap-w:   25%;
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
    .lte-cm    { position: relative; }
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

    /* ── webkit scrollbar — vertical fat, horizontal skinny ─────────────── */
    /* Applies to cm-scroller only.  Outer page scrollbars are unaffected.  */
    /* The 2em vertical track creates the gutter that DocMinimap tucks into. */
    .lte-cm :global(.cm-scroller)::-webkit-scrollbar {
        width:  var(--lte-scrollbar-w);   /* vertical */
        height: 0.5em;                    /* horizontal — stay out of the way */
    }
    .lte-cm :global(.cm-scroller)::-webkit-scrollbar-thumb {
        border-radius: 1em;
        min-height: 4em;
        background: url(i/copper_anodes.jpg);
    }
    .lte-cm :global(.cm-scroller)::-webkit-scrollbar-track {
        border-radius: 1em;
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

    /* Point panel — compact list of bookmarks below the editor */
    .lte-points {
        border-top: 1px solid #141420;
        padding: 3px 4px;
        display: flex; flex-direction: column; gap: 1px;
        max-height: 160px; overflow-y: auto;
        background: #080810;
    }
</style>
