<script lang="ts">
    import { onMount, onDestroy } from "svelte"
    import { EditorView, basicSetup } from "codemirror"
    import { EditorState, Compartment } from "@codemirror/state"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H }: { H: House } = $props()

    let container: HTMLDivElement
    let view: EditorView | undefined

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

    onMount(() => {
        const initial = (docC?.sc.text as string) ?? ''
        view = new EditorView({
            parent: container,
            state: EditorState.create({
                doc: initial,
                extensions: [
                    basicSetup,
                    EditorView.updateListener.of(u => {
                        if (!u.docChanged) return
                        const text = u.state.doc.toString()
                        // push: elvis to w:LangTiles. It sets docC.sc.text and bumps.
                        H.elvisto('LangTiles/LangTiles', 'langtiles_set_doc', { text })
                    }),
                ],
            }),
        })
    })

    onDestroy(() => { view?.destroy() })
</script>

<div class="lte">
    <div class="lte-bar">
        <span class="lte-title">LangTiles editor</span>
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
    .lte-title { flex: 1; color: #7ab0d4; }
    .lte-len   { color: #3a3a3a; }
    .lte-cm    { min-height: 200px; max-height: 50vh; overflow: auto; }
    .lte-cm :global(.cm-editor) { height: 100%; background: transparent; }
    .lte-cm :global(.cm-content) { font-size: 12px; }
</style>
