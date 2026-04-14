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

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

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