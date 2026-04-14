<script lang="ts">
    // Lang.svelte — ghost for Language / CodeMirror / Lezer integration.
    //
    // Deposits:
    //   whatsthis(state, container, {from?, to?})
    //     — walks the EditorState's Lezer parse tree and i()s TheC nodes
    //       (Line, node, texts, text) into `container`.
    //
    //     Caller owns container lifecycle — whatsthis never empties anything
    //     itself. Pass in a fresh subcontainer per logical scope (eg one per
    //     bookmark) so the caller can delete scopes as units.
    //
    //     opt.from / opt.to (optional) scope the walk via tree.iterate's
    //     range filter — Lezer only enters nodes whose span intersects
    //     [from, to]. Omitting them walks the whole doc.
    //
    // Consumed by w:LangTiles, which runs one whatsthis() call per w/%bookmark
    // into a per-bookmark subcontainer under model/**.

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import { onMount } from "svelte"

    import Langui from "$lib/O/ui/Langui.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region plan

    Lang_plan(this: House, w: TheC) {
        const H = this

        // ── the permanent viewable model ────────────────────────────
        // w/{model:1} — a stable TheC we hand to Cyto as Scannable.
        // i_elvis_req keyed on the req particle won't re-send while this
        // is the same object, so commissioning happens exactly once.
        const model = w.i({ model: 1 })
        w.c.model = model

        // UI registration — Otro mounts this alongside Cytui for H:Lang
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Langui', component: Langui })

        const wa = H.oai_enroll(H, { watched: 'actions' })
        wa.oai({ action: 1, role: 'debookmark'   }, { label: '-marks',  cls: 'save',   fn: () => this.Lang_debookmark(w)  })

        // doc api — a single C on H.ave holding the whole document string.
        // UI pulls via H.ave.find(p => p.sc.langtiles_doc).sc.text
        // UI pushes via elvis 'langtiles_set_doc' → e_langtiles_set_doc below.
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const docC = ave.oai({ langtiles_doc: 1 })
        if (docC.sc.text == null) {
            docC.sc.text = `# yeti etc

i thung/with/etc

[y]
S o yeses/because/blon_itn
  yapto
  o figura/datch/#chang
`
            docC.bump_version()
        }
        w.c.docC = docC

        // ── reach across to Story's Styles ──────────────────────────
        // Story persists Styles under its w.c.The/{Styles:1}.
        // We call The_Styles(storyw) so we get the same TheC.
        // Story's watch_c on that bucket handles save-on-change for
        // edits made from either Cytui.
        const topH    = H.top_House()
        let stylesC: TheC | null = null
        try {
            const storyw = topH.o({H:'Story'})[0].Awo('Story', 'Story')
            stylesC = H.The_Styles(storyw)
        } catch {
            console.warn(`Lang: H:Story not present yet — Cyto will palette-fallback`)
        }

        // ── commission our own Cyto ─────────────────────────────────
        // Scannable = the permanent model C.
        // client_w  = w:Lang itself, so animation_done events come here.
        // No seek / takeTurns yet — this is the simple observer path.
        const commission = new TheC({ c: {}, sc: {
            Scannable:            w.c.model,
            Styles:               stylesC,
            client_w:             w,
            supports_seek:        false,
            supports_takeTurns:   false,
            wants_wave_done:      false,
            wants_animation_done: false,
        }})
        // target our local A:Cyto/w:Cyto, not H:Story's
        H.elvisto(`Cyto/Cyto`, 'Cyto_commission', { req: commission })

        w.c.plan_done = true
    },

//#region w:Lang
    async Lang(A: TheC, w: TheC) {
        const H = this
 
        if (!w.c.plan_done) this.Lang_plan(w)
 
        const model     = w.c.model as TheC
        const state     = w.c.editorState
        const bookmarks = w.o({ bookmark: 1 }) as TheC[]
 
        // Rebuild model from bookmarks. Each bookmark gets its own
        // {bookmark_view:1, bookmark_id, label, from, to} subcontainer and
        // whatsthis() scopes its tree walk to the bookmark's from..to range.
        //
        // Runs whenever editorState is present (ie. at least one bookmark
        // has been added or the doc has been updated since). If there are
        // no bookmarks yet, the model is left alone — no bookmarks = nothing
        // to show.
        model.empty()
        if (state && bookmarks.length) {
            for (const bm of bookmarks) {
                const sub = model.i({
                    bookmark_view: 1,
                    bookmark_id:   bm.sc.bookmark,
                    label:         bm.sc.label,
                    from:          bm.sc.from,
                    to:            bm.sc.to,
                })
                this.whatsthis(state, sub, {
                    from: bm.sc.from as number,
                    to:   bm.sc.to   as number,
                })
            }
        }
 
        w.i({ see: `🟦 tiles ${bookmarks.length} bookmarks` })
        H.elvisto('Cyto/Cyto', 'Cyto_animation_request', { Langy: 1 })
    },

    async Lang_debookmark(w) {
        await w.r({ bookmark: 1 },{})
        this.elvisto(w, 'think', {})
    },

    async e_langtiles_set_doc(this: House, A: TheC, w: TheC, e: TheC) {
        const docC = w.c.docC as TheC | undefined
        if (!docC) return
        const text = e?.sc.text as string | undefined
        if (text == null) return
        // editorState no longer flows through this event — the bookmark
        // add/update events are the sole carriers, because whatsthis() only
        // runs on bookmark scopes now. See e_langtiles_add_bookmark /
        // e_langtiles_update_bookmarks.
        if (docC.sc.text === text) return
        docC.sc.text = text
        docC.bump_version()
        // no main() — UI initiated this, no one else needs waking
    },

//#region e
    // Ctrl+B from the editor — create a w/%bookmark at the current selection.
    //
    // The editor marks the range with a CodeMirror Decoration.mark so from/to
    // track document edits automatically. Periodic e_langtiles_update_bookmarks
    // calls push the live mark positions (and a fresh editorState) back here.
    //
    // e.sc carries: from, to, label?, editorState
    async e_langtiles_add_bookmark(this: House, A: TheC, w: TheC, e: TheC) {
        const from  = e?.sc.from  as number | undefined
        const to    = e?.sc.to    as number | undefined
        const label = (e?.sc.label as string | undefined) ?? ''
        const state = e?.sc.editorState
        if (from == null || to == null) return
 
        const id = `bm_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`
        w.i({ bookmark: id, from, to, label })
        if (state) w.c.editorState = state
        console.log(`🔖 add_bookmark id=${id} [${from}..${to}] ${label}`)
        this.elvisto(w, 'think', {})
    },


    // Fired by the editor ~800ms after the most recent doc-change transaction.
    //
    // Carries the live from/to for every bookmark (the editor is the source of
    // truth for positions — CodeMirror remaps decoration marks on every change,
    // so we read them out and push here) plus a fresh editorState so the next
    // tick's whatsthis() walks see the updated parse tree.
    //
    // e.sc carries: updates=[{id, from, to}], editorState
    //
    // Bookmarks whose id isn't in updates[] are implicitly untouched — this
    // lets the editor also use this event to report "this bookmark's mark was
    // deleted" by simply omitting it. (Not yet consumed, but the shape allows
    // future pruning: compare w/%bookmark ids against updates[].id.)
    async e_langtiles_update_bookmarks(this: House, A: TheC, w: TheC, e: TheC) {
        const updates = e?.sc.updates as Array<{ id: string, from: number, to: number }> | undefined
        const state   = e?.sc.editorState
        if (updates) {
            for (const u of updates) {
                const bm = w.o({ bookmark: u.id })[0] as TheC | undefined
                if (!bm) continue
                if (bm.sc.from === u.from && bm.sc.to === u.to) continue
                bm.sc.from = u.from
                bm.sc.to   = u.to
                bm.bump_version()
            }
        }
        if (state) w.c.editorState = state
        this.elvisto(w, 'think', {})
    },




    whatsthis(state: EditorState, container: TheC, opt: { from?: number, to?: number } = {}) {
        const tree = syntaxTree(state)
        if (!tree || tree.length === 0) return container

        const doc = state.doc
        const range_from = opt.from ?? 0
        const range_to   = opt.to   ?? doc.length

        let line_n = 0
        let lineC: TheC | null = null
        const boundaries = new Set<number>()

        // tree.iterate filters by range — only enters nodes whose span
        // intersects [from, to]. Cleaner than cursor.iterate + manual skip.
        tree.iterate({
            from: range_from,
            to:   range_to,
            enter: (nodeRef) => {
                const { name, from, to } = nodeRef
                const str = doc.sliceString(from, to)

                if (name === 'Program') return

                if (name === 'Line') {
                    line_n++
                    lineC = container.i(_C({ Line: 1, line_n, from, to }))
                    return
                }

                if (!str.trim()) return

                boundaries.add(from)
                boundaries.add(to)

                const target = lineC ?? container
                const nodeC = target.i(_C({ node: 1, name, from, to }))
                if (str.length <= 120) {
                    nodeC.sc.str = str
                }

                const parent = nodeRef.node.parent
                if (parent && parent.name !== 'Line' && parent.name !== 'Program') {
                    nodeC.sc.parent_name = parent.name
                }
            }
        })

        const sorted = [...boundaries].sort((a, b) => a - b)
        if (sorted.length > 1) {
            const textC = container.i(_C({ texts: 1 }))
            for (let i = 0; i < sorted.length - 1; i++) {
                const f = sorted[i], t = sorted[i + 1]
                const s = doc.sliceString(f, t)
                if (s.trim()) {
                    textC.i(_C({ text: 1, from: f, to: t, str: s }))
                }
            }
        }

        return container
    },

    })
    })
</script>