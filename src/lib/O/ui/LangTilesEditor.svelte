<script lang="ts">
    // LangTilesEditor — CodeMirror view over w/%langtiles_doc with bookmarks.
    //
    // ── Bookmark pipeline ────────────────────────────────────────────────────
    //
    //   Ctrl+M at cursor/selection → addBookmarkMark StateEffect → bookmarkField
    //   installs a Decoration.mark carrying its bookmark_id. The field's
    //   marks.map(tr.changes) in update() automatically remaps from/to on
    //   every subsequent edit (RangeSet is the source of truth for positions).
    //
    //   On each dispatch we fire an elvis to w:LangTiles:
    //     - Ctrl+M:           langtiles_add_bookmark {from,to,label,editorState}
    //     - 800ms post-edit:  langtiles_update_bookmarks {updates,editorState}
    //     - any text change:  langtiles_set_doc       {text}
    //
    //   Note: langtiles_set_doc no longer carries editorState — only the two
    //   bookmark elvises do, because whatsthis() only runs scoped to bookmarks.
    //
    // ── Immutability note ────────────────────────────────────────────────────
    //
    //   EditorState is immutable; every transaction (including selection-only
    //   moves) produces a new one. The debounced updateListener below guards
    //   with `vu.docChanged`, so cursor movement alone doesn't send update
    //   traffic — only actual document edits schedule the 800ms re-run.

    import { onMount, onDestroy } from "svelte"
    import { EditorView, basicSetup } from "codemirror"
    import { EditorState, StateField, StateEffect, type Extension } from "@codemirror/state"
    import { Decoration, type DecorationSet, keymap } from "@codemirror/view"
    import { stho, simpleLezerLinter } from "$lib/L/stho"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H }: { H: House } = $props()

    let container: HTMLDivElement
    let view: EditorView | undefined

    const UPDATE_DELAY_MS = 800
    let update_timer: ReturnType<typeof setTimeout> | null = null

    // Live primary-selection range, updated from the updateListener on every
    // transaction (selection-only transactions included, so cursor moves
    // update the header readout immediately).
    let sel_from = $state(0)
    let sel_to   = $state(0)

    // Find the doc C on H.ave. Same pattern as StoryRun's display effect.
    let docC: TheC | undefined = $state()
    let pullable_text = $derived.by(() => {
        void docC?.version
        return (docC?.sc.text as string) ?? ''
    })

    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        // bump reactivity: touch every particle's version so we re-run on any change
        for (const p of ave) void p.version
        const found = ave.find((p: TheC) => p.sc.langtiles_doc) as TheC | undefined
        docC = found
    })

    // pull: when docC.text changes from outside, push it into the editor
    $effect(() => {
        if (!view) return
        const incoming = pullable_text
        if (incoming === view.state.doc.toString()) return  // already in sync, skip
        view.dispatch({
            changes: { from: 0, to: view.state.doc.length, insert: incoming },
        })
    })

    // ── bookmark StateField ──────────────────────────────────────────────
    //
    //   addBookmarkMark(v)    — install a Decoration.mark spanning v.from..v.to
    //                           carrying v.id in its spec. RangeSet.map handles
    //                           all future position remapping automatically.
    //
    //   readBookmarks(view)   — iterate the field and hand back the live
    //                           [{id, from, to}] so elvises can report the
    //                           current positions to w:LangTiles.

    const addBookmarkMark = StateEffect.define<{ id: string, from: number, to: number }>()

    const bookmarkField = StateField.define<DecorationSet>({
        create: () => Decoration.none,
        update(marks, tr) {
            marks = marks.map(tr.changes)   // auto-remap on every edit
            for (const e of tr.effects) {
                if (e.is(addBookmarkMark)) {
                    const deco = Decoration.mark({
                        class: 'cm-bookmark',
                        attributes: { 'data-bookmark-id': e.value.id },
                        // stashed in spec so readBookmarks can get it back out
                        bookmark_id: e.value.id,
                    } as any).range(e.value.from, e.value.to)
                    marks = marks.update({ add: [deco] })
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

    // ── Ctrl+B: add bookmark at current selection ────────────────────────
    //
    //   Empty selection → expand to the enclosing line, so single-click
    //   bookmarking gives something non-zero-width for whatsthis() to scope
    //   over.  Non-empty selection is used verbatim.

    const ctrlB = keymap.of([{
        key: 'Mod-b',
        run: (v) => {
            const sel = v.state.selection.main
            let from = sel.from, to = sel.to
            if (from === to) {
                const line = v.state.doc.lineAt(from)
                from = line.from; to = line.to
            }
            const id = `bm_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`
            const label = v.state.doc.sliceString(from, to).slice(0, 24).replace(/\s+/g, ' ')
            v.dispatch({ effects: addBookmarkMark.of({ id, from, to }) })
            H.elvisto('LangTiles/LangTiles', 'langtiles_add_bookmark', {
                from, to, label, editorState: v.state,
            })
            return true
        },
    }])

    // ── debounced doc-change → langtiles_update_bookmarks ────────────────

    function schedule_update_bookmarks(v: EditorView) {
        if (update_timer) clearTimeout(update_timer)
        update_timer = setTimeout(() => {
            update_timer = null
            if (!view) return
            const updates = readBookmarks(view)
            H.elvisto('LangTiles/LangTiles', 'langtiles_update_bookmarks', {
                updates,
                editorState: view.state,
            })
        }, UPDATE_DELAY_MS)
    }

    onMount(() => {
        const initial = (docC?.sc.text as string) ?? ''
        view = new EditorView({
            parent: container,
            state: EditorState.create({
                doc: initial,
                extensions: [
                    basicSetup,
                    stho(),
                    // simpleLezerLinter(),
                    bookmarkField,
                    ctrlB,
                    EditorView.updateListener.of(u => {
                        const sel = u.state.selection.main
                        sel_from = sel.from
                        sel_to   = sel.to
                        if (!u.docChanged) return
                        const text = u.state.doc.toString()
                        // push text change only — no editorState here.
                        H.elvisto('LangTiles/LangTiles', 'langtiles_set_doc', { text })
                        // debounced follow-up carries editorState + live mark
                        // positions so bookmarks re-scope to their new ranges
                        schedule_update_bookmarks(u.view)
                    }),
                ],
            }),
        })
    })

    onDestroy(() => {
        if (update_timer) clearTimeout(update_timer)
        view?.destroy()
    })
</script>

<div class="lte">
    <div class="lte-bar">
        <span class="lte-title">LangTiles editor</span>
        <span class="lte-hint">Ctrl+M — add mark</span>
        <span class="lte-sel">{sel_from}{sel_from !== sel_to ? `..${sel_to}` : ''}</span>
        <span class="lte-len">{(docC?.sc.text as string ?? '').length} chars</span>
    </div>
    <div class="lte-cm" bind:this={container}></div>
</div>

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
    .lte-title { color: #7ab0d4; }
    .lte-hint  { flex: 1; color: #3a3a3a; font-style: italic; }
    .lte-sel   { color: #556; font-variant-numeric: tabular-nums; }
    .lte-len   { color: #3a3a3a; }
    .lte-cm    { min-height: 200px; max-height: 50vh; overflow: auto; }
    .lte-cm :global(.cm-editor)  { height: 100%; background: transparent; }
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