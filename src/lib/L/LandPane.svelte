<script lang="ts">
    // LandPane — one CodeMirror on the land page (/Desk?G=Land): its OWN EditorView over its OWN EditorState.  Langui is one view
    //  that swaps states for a single foreground doc; a pane stands alone, so LandFace can sit any number side by side.  It reads
    //   only what its %Pane row says (doc, line, at) plus the text riding the row's .c, and scrolls `line` to its top whenever the
    //    row names a new one — that is how panes ALIGN: `:pane align <method>` sets each pane's line to where the method sits in it.
    //  Read-only: the page is role hacker.  Grammar and theme come from $lib/O/lang (one random hue per pane, as Langui's mount).
    import { onMount } from "svelte"
    import { EditorView, basicSetup } from "codemirror"
    import { EditorState } from "@codemirror/state"
    import { lang, lang_for_path } from "$lib/O/lang/lang"
    let { n, doc, text, line = 1, at = '', onclose, onfold }: {
        n: string, doc: string, text: string, line?: number, at?: string, onclose?: () => void, onfold?: () => void
    } = $props()
    let el: HTMLDivElement
    let view: EditorView | null = $state(null)

    onMount(() => {
        let dead = false
        ;(async () => {
            const exts = await lang(lang_for_path(doc))
            if (dead) return
            view = new EditorView({
                parent: el,
                state: EditorState.create({ doc: text, extensions: [basicSetup, exts, EditorState.readOnly.of(true)] }),
            })
        })()
        return () => { dead = true; view?.destroy(); view = null }
    })
    // the row's line, to the top — on mount and whenever an align moves it
    $effect(() => {
        const v = view, want = line
        if (!v) return
        const l = v.state.doc.line(Math.max(1, Math.min(want || 1, v.state.doc.lines)))
        requestAnimationFrame(() => v.dispatch({ effects: EditorView.scrollIntoView(l.from, { y: 'start' }) }))
    })
    // a re-read that brought new text
    $effect(() => {
        const v = view, t = text
        if (v && t !== v.state.doc.toString()) v.dispatch({ changes: { from: 0, to: v.state.doc.length, insert: t } })
    })
</script>

<div class="pane" data-pane={n}>
    <div class="bar">
        <b>{n}</b> <span class="doc" title={doc}>{doc}</span>{#if at}<span class="at">· {at}</span>{/if}
        <small>:{line}</small>
        {#if onfold}<button type="button" title="fold back to the member" onclick={onfold}>▤</button>{/if}
        {#if onclose}<button type="button" title="close this pane" onclick={onclose}>×</button>{/if}
    </div>
    <div class="cm" bind:this={el}></div>
</div>

<style>
    .pane { display: flex; flex-direction: column; min-width: 0; min-height: 0; border: 1px solid #23453a; border-radius: 6px; overflow: hidden;
        background: #0b1310 }
    .bar { display: flex; gap: 6px; align-items: baseline; padding: 2px 8px; background: #16281f; font: 11px ui-monospace, monospace }
    .doc { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 0 1 auto }
    .at { color: #8fd3b0 }
    small { opacity: .6 }
    button:first-of-type { margin-left: auto }
    button { background: none; border: none; color: #cfe3d8; cursor: pointer; padding: 0 2px }
    .cm { flex: 1 1 auto; min-height: 0; height: 100% }
    .cm :global(.cm-editor) { height: 100% }
    .cm :global(.cm-scroller) { overflow: auto }
</style>
