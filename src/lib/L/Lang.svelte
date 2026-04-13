<script lang="ts">
    // Lang.svelte — ghost for Language / CodeMirror / Lezer integration.
    //
    // Deposits:
    //   whatsthis(state, model)  — walk EditorState's Lezer parse tree,
    //                              rebuild model/* as TheC nodes Cyto can scan.

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

    whatsthis(state: EditorState, model: TheC) {
        model.empty()

        const tree = syntaxTree(state)
        if (!tree || tree.length === 0) return model

        const doc = state.doc
        const cursor = tree.cursor()
        let line_n = 0
        let lineC: TheC | null = null
        const boundaries = new Set<number>()

        const visit = () => {
            const { name, from, to } = cursor
            const str = doc.sliceString(from, to)

            if (name === 'Program') return

            if (name === 'Line') {
                line_n++
                lineC = model.i(_C({ Line: 1, line_n }))
                return
            }

            if (!str.trim()) return

            boundaries.add(from)
            boundaries.add(to)

            const target = lineC ?? model
            const nodeC = target.i(_C({ node: 1, name, from, to }))
            if (str.length <= 120) {
                nodeC.sc.str = str
            }

            if (cursor.node.parent && cursor.node.parent.name !== 'Line'
                && cursor.node.parent.name !== 'Program') {
                nodeC.sc.parent_name = cursor.node.parent.name
            }
        }

        cursor.iterate(visit)

        const sorted = [...boundaries].sort((a, b) => a - b)
        if (sorted.length > 1) {
            const textC = model.i(_C({ texts: 1 }))
            for (let i = 0; i < sorted.length - 1; i++) {
                const f = sorted[i], t = sorted[i + 1]
                const s = doc.sliceString(f, t)
                if (s.trim()) {
                    textC.i(_C({ text: 1, from: f, to: t, str: s }))
                }
            }
        }

        return model
    },

    })
    })
</script>
