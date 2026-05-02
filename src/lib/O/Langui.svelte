<script lang="ts">
    // Langui — CodeMirror view over one document, identified by `doc` (path string).
    //
    // ── Multi-doc ────────────────────────────────────────────────────────────
    //
    //   Each mounted Langui instance owns exactly one EditorView for one doc.
    //   The parent renders one Langui per open doc, hiding inactive ones with
    //   CSS (display:none) so EditorViews are never destroyed on tab switch.
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
    // ── Immutability note ────────────────────────────────────────────────────
    //
    //   EditorState is immutable; every transaction (including selection-only
    //   moves) produces a new one. The debounced updateListener below guards
    //   with `vu.docChanged`, so cursor movement alone doesn't send update
    //   traffic — only actual document edits schedule the 800ms re-run.

    import { onDestroy } from "svelte"
    import { EditorView, basicSetup } from "codemirror"
    import { EditorState, StateField, StateEffect, type Extension } from "@codemirror/state"
    import { Decoration, type DecorationSet, keymap, ViewUpdate, drawSelection } from "@codemirror/view"
    import { indentService, indentUnit } from "@codemirror/language";
    import { defaultKeymap, indentWithTab } from "@codemirror/commands";

    import { stho, simpleLezerLinter } from "$lib/O/stho"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import Actions from "$lib/O/ui/Actions.svelte"   // doc-picker dropdown + any other Lang actions

    let { H }: { H: House } = $props()

    // container is $state so the creation $effect tracks when the div appears.
    // The div only renders once docC is truthy, so this naturally gates construction.
    let container: HTMLDivElement | undefined = $state()
    let view: EditorView | undefined

    const UPDATE_DELAY_MS = 800
    let update_timer: ReturnType<typeof setTimeout> | null = null

    // Live primary-selection range, updated from the updateListener on every
    // transaction (selection-only transactions included, so cursor moves
    // update the header readout immediately).
    let sel_from = $state(0)
    let sel_to   = $state(0)

    // ── doc list for display ─────────────────────────────────────────────────
    //   Derives the short name of the active doc for the bar header.
    //   The full doc list lives in lang_actions (derived from ave/{lang_actions:1}) registered by Lang.
    let active_name = $derived.by(() => {
        const p = active_path
        if (!p) return 'no doc'
        return p.split('/').pop() ?? p
    })

    // ── private Lang action bar ──────────────────────────────────────────────
    //   Lang enrolls w/{lang_actions:1} into ave.  We derive the action children
    //   from it here and pass them to <Actions> — isolated from H.actions which
    //   belongs to the global button rack shown elsewhere.
    let lang_actions: TheC[] = $state([])

    // ── active doc tracking ──────────────────────────────────────────────────
    let active_path = $state('')   // starts empty; upgraded once ave/{active_doc:1} lands

    // ── ave text-sync ────────────────────────────────────────────────────────
    let docC: TheC | undefined = $state()

    // H.ave is a stable TheC; ob() tracks H.ave.version for Svelte reactivity.
    $effect(() => {
        const la = H.ave.ob({ lang_actions: 1 })[0] as TheC | undefined
        lang_actions = la ? la.o({ action: 1 }) as TheC[] : []

        const sig  = H.ave.ob({ active_doc: 1 })[0] as TheC | undefined
        const path = (sig?.sc.path as string | undefined) ?? active_path
        if (sig?.sc.path) active_path = path

        // use local path, not the $state, to avoid async ordering subtlety
        docC = H.ave.ob({ langtiles_doc: path })[0] as TheC | undefined
    })

    // Re-register view + state whenever the active path changes so the backend
    // knows which doc CM events are coming from.
    $effect(() => {
        if (!view || !active_path) return
        void active_path
        Lang_i_elvis(view, 'Lang_editorBegins', { addBookmarkMark, removeBookmarkMark, clearAllBookmarks, saveEffect })
    })

    let pullable_text = $derived.by(() => {
        void docC?.version
        return (docC?.sc.text as string) ?? ''
    })

    // pull: when docC.text changes from outside (e.g. load from disk), push into the editor
    $effect(() => {
        if (!view) return
        const incoming = pullable_text
        if (incoming === view.state.doc.toString()) return  // already in sync, skip
        view.dispatch({
            changes: { from: 0, to: view.state.doc.length, insert: incoming },
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
    //   becomes true (i.e. the first ave/%langtiles_doc particle has arrived).
    //   We use docC.sc.text as the initial content so the editor is never
    //   constructed with an empty-string placeholder.
    //
    //   Lang_editorBegins is fired inline here (active_path is already set by
    //   the time docC arrives).  The separate active_path $effect above handles
    //   subsequent doc switches that happen after the view exists.
    $effect(() => {
        if (!container || view) return   // only create once; wait for the div
        const initial = (docC?.sc.text as string) ?? 'there was no docC%text'
        view = new EditorView({
            parent: container,
            state: EditorState.create({
                doc: initial,
                extensions: [
                    basicSetup,

                    // < is this per lang?
                    simpleLezerLinter(),
                    // < switchable lang via Compartment
                    stho(),
                    bookmarkField,
                    Keys,
                    EditorView.updateListener.of((v: ViewUpdate) => {
                        const sel = v.state.selection.main;
                        sel_from = sel.from;
                        sel_to = sel.to;
                        // saveEffect: flush bookmark positions immediately, cancel debounce
                        if (v.transactions.some(tr => tr.effects.some(e => e.is(saveEffect)))) {
                            if (update_timer) { clearTimeout(update_timer); update_timer = null }
                            fire_update_bookmarks(v.view)
                            return
                        }
                        if (!v.docChanged) return;
                        const text = v.state.doc.toString();
                        Lang_i_elvis(view,'Lang_set_doc', {text})
                        schedule_update_bookmarks(v.view);
                    }),
                    usualSetup,
                ],
            }),
        });

        // Dispatch e:editorBegins — hands the backend the CM StateEffects it
        // needs to drive bookmarks, and registers view+state via Lang_doc_from_event.
        Lang_i_elvis(view, 'Lang_editorBegins', { addBookmarkMark, removeBookmarkMark, clearAllBookmarks, saveEffect })
    })

    onDestroy(() => {
        if (update_timer) clearTimeout(update_timer)
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
</div>
{/if}

<style>
    .lte {
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
